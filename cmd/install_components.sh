#!/usr/bin/env bash

# Component installation functions

get_config() {
  cat "$generated_dotfiles_specfile"
}

get_config_value() {
  local path="$1"
  local outputFormat="${2:-yaml}"

  get_config | yq "$path" -o "$outputFormat"
}

get_enabled_items() {
  local path="$1"
  get_config_value "$path | with_entries(select(.value == true)) | to_entries | .[].key"
}

get_disabled_items() {
  local path="$1"
  get_config_value "$path | with_entries(select(.value == false)) | to_entries | .[].key"
}

# Homebrew installation
install_brew_core() {
  install_brew
  
  if [ "$DRY_RUN" = true ]; then
    log::info "[DRY-RUN] Would update and upgrade Homebrew"
    return 0
  fi
  
  execute "brew update" "homebrew-update"
  execute "brew upgrade" "homebrew-upgrade"

  install_packages yq
  execute "brew tap vmware-tanzu/carvel" "homebrew-tap"
  install_packages ytt
}

install_brew_packages() {
  install_brew_core

  # Handle taps
  local brew_taps=($(get_enabled_items '.brew.taps'))
  log::info "Managing Homebrew taps"
  
  for tap in "${brew_taps[@]}"; do
    if [ "$DRY_RUN" = true ]; then
      log::info "[DRY-RUN] Would tap: $tap"
    else
      execute "brew tap $tap" "tap-$tap"
    fi
  done

  local brew_untaps=($(get_disabled_items '.brew.taps'))
  for tap in "${brew_untaps[@]}"; do
    if [ "$DRY_RUN" = true ]; then
      log::info "[DRY-RUN] Would untap: $tap"
    else
      execute "brew untap $tap || true" "untap-$tap"
    fi
  done

  # Install packages
  local brew_packages=($(get_enabled_items '.brew.packages'))
  if [ ${#brew_packages[@]} -gt 0 ]; then
    log::info "Installing Homebrew packages"
    install_packages "${brew_packages[@]}"
  fi

  # Uninstall disabled packages
  local brew_uninstall=($(get_disabled_items '.brew.packages'))
  if [ ${#brew_uninstall[@]} -gt 0 ]; then
    log::info "Uninstalling disabled Homebrew packages"
    for package in "${brew_uninstall[@]}"; do
      if brew list "$package" &>/dev/null; then
        if [ "$DRY_RUN" = true ]; then
          log::info "[DRY-RUN] Would uninstall: $package"
        else
          execute "brew uninstall $package" "uninstall-$package"
        fi
      fi
    done
  fi
}

# VSCode installation
install_vscode() {
  local enabled=($(get_config_value '.vscode.enabled'))
  if [ "$enabled" = false ]; then
    log::info "VSCode installation is disabled"
    return 0
  fi

  install_packages visual-studio-code
}

# Kubectl and related tools installation
install_kubectl_krew() {
  local enabled=($(get_config_value '.kubectl.krew.enabled'))
  if [ "$enabled" = false ]; then
    log::info "Uninstalling Krew"
    rimraf "$HOME/.krew"
    return 0
  fi

  if ! command -v kubectl &>/dev/null; then
    log::error "kubectl is required to use krew. Please enable in spec or install via alternative method"
    return 1
  fi

  if [ -d "$HOME/.krew" ]; then
    log::info "Krew is already installed"
  else
    log::info "Installing Krew"
    if [ "$DRY_RUN" = true ]; then
      log::info "[DRY-RUN] Would install Krew"
    else
      local temp_dir
      temp_dir="$(mktemp -d)"
      cd "$temp_dir" || return 1
      
      local krew="krew-${OS}_${ARCH}"
      execute "curl -fsSLO 'https://github.com/kubernetes-sigs/krew/releases/latest/download/${krew}.tar.gz'" "krew-download"
      execute "tar zxvf '${krew}.tar.gz'" "krew-extract"
      execute "./${krew} install krew" "krew-install"
      
      cd - || return 1
      rm -rf "$temp_dir"
    fi
  fi

  # Install plugins
  local enabled_plugins=($(get_enabled_items '.kubectl.krew.plugins'))
  if [ ${#enabled_plugins[@]} -gt 0 ]; then
    log::info "Installing Krew plugins"
    for plugin in "${enabled_plugins[@]}"; do
      if [ "$DRY_RUN" = true ]; then
        log::info "[DRY-RUN] Would install Krew plugin: $plugin"
      else
        execute "kubectl krew install $plugin" "krew-plugin-$plugin"
      fi
    done
  fi

  # Uninstall disabled plugins
  local disabled_plugins=($(get_disabled_items '.kubectl.krew.plugins'))
  if [ ${#disabled_plugins[@]} -gt 0 ]; then
    log::info "Uninstalling disabled Krew plugins"
    for plugin in "${disabled_plugins[@]}"; do
      if kubectl krew list | grep -q "^$plugin\$"; then
        if [ "$DRY_RUN" = true ]; then
          log::info "[DRY-RUN] Would uninstall Krew plugin: $plugin"
        else
          execute "kubectl krew uninstall $plugin" "krew-uninstall-$plugin"
        fi
      fi
    done
  fi

  if [ "$DRY_RUN" != true ]; then
    log::info "Updating Krew plugins"
    execute "kubectl krew upgrade" "krew-upgrade"
  fi
}

install_kubectl() {
  local enabled=($(get_config_value '.kubectl.enabled'))

  case "$enabled" in
    "$flag_ignore")
      log::debug "Ignoring kubectl installation"
      ;;
    false)
      log::info "Uninstalling kubectl and its dependencies"
      install_kubectl_krew # This will handle uninstallation since enabled=false
      for pkg in kubectx kubernetes-cli; do
        if [ "$DRY_RUN" = true ]; then
          log::info "[DRY-RUN] Would uninstall: $pkg"
        else
          execute "brew uninstall $pkg" "uninstall-$pkg"
        fi
      done
      ;;
    true)
      install_packages kubernetes-cli
      install_kubectl_krew
      ;;
  esac

  # Handle kubectx
  local kubectx_enabled=($(get_config_value '.kubectl.kubectx'))
  if [ "$kubectx_enabled" = true ]; then
    install_packages kubectx
  elif [ "$kubectx_enabled" = false ]; then
    if [ "$DRY_RUN" = true ]; then
      log::info "[DRY-RUN] Would uninstall: kubectx"
    else
      execute "brew uninstall kubectx" "uninstall-kubectx"
    fi
  fi
}

# Shell configuration
install_shell_config() {
  local zsh_theme=($(get_config_value '.zsh.theme'))
  export ZSH_THEME="$zsh_theme"
  declare -a ZSH_PLUGINS=()

  # Install plugins
  while IFS= read -r plugin_json; do
    local name source enabled
    name=$(echo "$plugin_json" | jq -r '.name')
    source=$(echo "$plugin_json" | jq -r '.source')
    enabled=$(echo "$plugin_json" | jq -r '.enabled')

    if [ "$source" = "null" ]; then
      ZSH_PLUGINS+=("$name")
      continue
    fi

    local plugin_location="$zsh_root/plugins/$name"
    
    if [ "$enabled" = false ]; then
      if [ "$DRY_RUN" = true ]; then
        log::info "[DRY-RUN] Would uninstall zsh plugin: $name"
      else
        log::info "Uninstalling zsh plugin: $name"
        rimraf "$plugin_location"
      fi
      continue
    fi
    
    ZSH_PLUGINS+=("$name")

    if [ -d "$plugin_location" ]; then
      if [ "$DRY_RUN" != true ]; then
        log::info "Updating zsh plugin: $name"
        (cd "$plugin_location" && git pull)
      fi
    else
      if [ "$DRY_RUN" = true ]; then
        log::info "[DRY-RUN] Would install zsh plugin: $name"
      else
        log::info "Installing zsh plugin: $name"
        git clone --depth 1 "https://$source" "$plugin_location"
      fi
    fi
  done < <(get_config_value '.zsh.plugins' json | jq -c '.[]')

  # Install theme
  local theme_path="$zsh_root/themes/spaceship-prompt"
  if [ "$DRY_RUN" = true ]; then
    log::info "[DRY-RUN] Would install/update spaceship theme"
  else
    if [ -d "$theme_path" ]; then
      (cd "$theme_path" && git pull)
    else
      git clone --depth 1 https://github.com/spaceship-prompt/spaceship-prompt "$theme_path"
    fi
    ln -sf "$theme_path/spaceship.zsh-theme" "$zsh_root/themes/spaceship.zsh-theme"
  fi

  # Generate zsh profile
  if [ "$DRY_RUN" = true ]; then
    log::info "[DRY-RUN] Would generate zsh profile"
  else
    export PLUGINS="${ZSH_PLUGINS[*]}"
    export THEME="$ZSH_THEME"
    envsubst '$PLUGINS,$THEME' < "$DOTFILES_ROOT/shell/zsh/_templates/core.tmpl" > "$DOTFILES_ROOT/shell/zsh/core"
  fi
}

# Hook execution
exec_hooks() {
  local hooks
  hooks=($(get_config_value '.hooks[]' json | jq -r '.[]'))
  
  for hook in "${hooks[@]}"; do
    local script_path="$DOTFILES_ROOT/$hook"
    
    if [ -f "$script_path" ]; then
      if [ "$DRY_RUN" = true ]; then
        log::info "[DRY-RUN] Would execute hook: $script_path"
      else
        log::debug "Running hook: $script_path"
        execute "$script_path" "hook-$(basename "$script_path")"
      fi
    else
      log::warn "Hook script not found: $script_path"
    fi
  done
} 