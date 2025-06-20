#!/usr/bin/env bash

set -euo pipefail

# Constants
readonly INSTALLDIR=$(pwd)
readonly cmd_dir="$(dirname "$0")"
readonly generated_dotfiles_specfile="$DOTFILES_ROOT/config-generated.yaml"
readonly zsh_root=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
readonly YQ_PATH="${YQ_PATH:-yq}"
readonly flag_ignore="ignore"

# Source utilities
source "${cmd_dir}/_util.sh"

# Global arrays for tracking
ZSH_PLUGINS=()
ZSH_THEME=""

# Cleanup function for error handling
cleanup() {
  local exit_code=$?
  if [ $exit_code -ne 0 ]; then
    log::error "Installation failed. Cleaning up temporary files..."
    [ -f "$generated_dotfiles_specfile.tmp" ] && rm -f "$generated_dotfiles_specfile.tmp"
  fi
  exit $exit_code
}

# Set up error handling
trap cleanup EXIT

# Validate environment and dependencies
check_dependencies() {
  log::debug "Checking dependencies..."
  local deps=("yq" "git" "curl")
  local missing_deps=()
  
  for dep in "${deps[@]}"; do
    if ! command -v "$dep" &>/dev/null; then
      missing_deps+=("$dep")
    fi
  done
  
  if [ ${#missing_deps[@]} -gt 0 ]; then
    log::error "Missing required dependencies: ${missing_deps[*]}"
    log::info "Please install missing dependencies and try again"
    return 1
  fi
}

# Validate required environment variables
validate_environment() {
  log::debug "Validating environment..."
  local required_vars=("DOTFILES_ROOT")
  
  for var in "${required_vars[@]}"; do
    if [ -z "${!var:-}" ]; then
      fail "Required environment variable not set: $var"
    fi
  done
  
  if [ ! -d "$DOTFILES_ROOT" ]; then
    fail "DOTFILES_ROOT directory does not exist: $DOTFILES_ROOT"
  fi
}

# Safe command execution
execute() {
  log::debug "Executing: $*"
  if [ "$DRY_RUN" == "true" ]; then
    log::info "[DRY-RUN] Would execute: $*"
    return 0
  fi
  "$@"
}

# Check if binary exists
binary_exists() {
  local binary="$1"
  if ! command -v "$binary" &>/dev/null; then
    log::debug "$binary could not be found"
    return 1
  fi
  return 0
}

# Install Homebrew
install_brew() {
  log::info "Installing Homebrew ⚙️"
  if ! binary_exists brew; then
    if [ "$DRY_RUN" == "true" ]; then
      log::info "[DRY-RUN] Would install Homebrew"
      return 0
    fi
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    log::info "Homebrew is already installed 😊"
  fi
}

# Get configuration
get_config() {
  if [ ! -f "$generated_dotfiles_specfile" ]; then
    fail "Generated config file not found: $generated_dotfiles_specfile"
  fi
  cat "$generated_dotfiles_specfile"
}

# Initialize configuration with validation
init_config() {
  log::debug "Initializing config..."
  
  # Validate base config exists
  if [ ! -f "$DOTFILES_ROOT/config.yaml" ]; then
    fail "Base configuration file not found: $DOTFILES_ROOT/config.yaml"
  fi
  
  # Create local config if it doesn't exist
  local local_config="$DOTFILES_ROOT/config.local.yaml"
  if [ ! -f "$local_config" ]; then
    log::debug "Creating empty local config file"
    if [ "$DRY_RUN" != "true" ]; then
      echo "{}" > "$local_config"
    fi
  fi
  
  # Generate merged config
  local temp_config="${generated_dotfiles_specfile}.tmp"
  if [ "$DRY_RUN" == "true" ]; then
    log::info "[DRY-RUN] Would generate merged config file"
    return 0
  fi
  
  execute "${YQ_PATH}" '. *n load("'"$DOTFILES_ROOT/config.yaml"'")' "$local_config" > "$temp_config"
  mv "$temp_config" "$generated_dotfiles_specfile"
  
  log::debug "Config initialized successfully"
}

# Get configuration value with error handling
get_config_value() {
  local path="$1"
  local outputFormat="${2:-yaml}"
  
  if ! get_config | "${YQ_PATH}" "$path" -o "$outputFormat" 2>/dev/null; then
    log::warn "Failed to get config value for path: $path"
    return 1
  fi
}

# Install brew packages with error handling
brew_install() {
  local packages=("$@")
  for package in "${packages[@]}"; do
    log::info "⚙️ Installing $package"
    if [ "$DRY_RUN" == "true" ]; then
      log::info "[DRY-RUN] Would install brew package: $package"
      continue
    fi
    
    if brew install "$package"; then
      log::success "$package installed successfully"
    else
      log::error "Failed to install $package"
      return 1
    fi
  done
}

# Uninstall brew packages with error handling
brew_uninstall() {
  local packages=("$@")
  for package in "${packages[@]}"; do
    if brew list "$package" &>/dev/null; then
      log::info "⚙️ Uninstalling $package"
      if [ "$DRY_RUN" == "true" ]; then
        log::info "[DRY-RUN] Would uninstall brew package: $package"
        continue
      fi
      
      if brew uninstall "$package"; then
        log::success "$package uninstalled successfully"
      else
        log::warn "Failed to uninstall $package"
      fi
    fi
  done
}

# Get enabled items from config
get_enabled_items() {
  local path="$1"
  get_config_value "$path | with_entries(select(.value == true)) | to_entries | .[].key" "yaml"
}

# Get disabled items from config
get_disabled_items() {
  local path="$1"
  get_config_value "$path | with_entries(select(.value == false)) | to_entries | .[].key" "yaml"
}

# Install core brew components
install_brew_core() {
  install_brew
  
  if [ "$DRY_RUN" != "true" ]; then
    log::info "Updating Homebrew..."
    brew update
    log::info "Upgrading Homebrew packages..."
    brew upgrade
  fi

  brew_install yq
  execute brew tap vmware-tanzu/carvel
  brew_install ytt
}

# Install brew taps
install_brew_taps() {
  log::info "Managing Homebrew taps..."
  
  # Add taps
  local brew_taps
  if brew_taps=($(get_enabled_items '.brew.taps')); then
    for tap in "${brew_taps[@]}"; do
      log::info "Adding brew tap: $tap"
      if [ "$DRY_RUN" != "true" ]; then
        execute brew tap "$tap"
      fi
    done
  fi

  # Remove unwanted taps
  local brew_untaps
  if brew_untaps=($(get_disabled_items '.brew.taps')); then
    for tap in "${brew_untaps[@]}"; do
      log::info "Removing brew tap: $tap"
      if [ "$DRY_RUN" != "true" ]; then
        execute brew untap "$tap" || true
      fi
    done
  fi
}

# Install brew packages
install_brew_packages_only() {
  local brew_install_packages
  if brew_install_packages=($(get_enabled_items '.brew.packages')); then
    log::info "Installing Homebrew packages..."
    brew_install "${brew_install_packages[@]}"
  fi

  local brew_uninstall_packages
  if brew_uninstall_packages=($(get_disabled_items '.brew.packages')); then
    log::info "Uninstalling unwanted Homebrew packages..."
    brew_uninstall "${brew_uninstall_packages[@]}"
  fi
}

# Main brew installation function
install_brew_packages() {
  install_brew_core
  install_brew_taps
  install_brew_packages_only
}

# Install VS Code and extensions
install_vscode() {
  local enabled
  if ! enabled=$(get_config_value '.vscode.enabled'); then
    log::debug "VS Code configuration not found, skipping"
    return 0
  fi
  
  if [ "$enabled" != "true" ]; then
    log::debug "VS Code disabled, skipping"
    return 0
  fi
  
  brew_install visual-studio-code
}

# Install kubectl krew
install_kubectl_krew() {
  local enabled
  if ! enabled=$(get_config_value '.kubectl.krew.enabled'); then
    log::debug "Krew configuration not found, skipping"
    return 0
  fi
  
  if [ "$enabled" == "false" ]; then
    log::info "Uninstalling Krew..."
    rimraf "$HOME/.krew"
    return 0
  fi

  if ! binary_exists kubectl; then
    log::warn "kubectl is required to use krew. Please enable in spec or install via alternative method."
    return 1
  fi

  if [ -d "$HOME/.krew" ]; then
    log::info "Krew is already installed."
  else
    log::info "Installing Krew..."
    if [ "$DRY_RUN" != "true" ]; then
      (
        set -x
        cd "$(mktemp -d)"
        local krew="krew-${OS}_${ARCH}"
        curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${krew}.tar.gz"
        tar zxvf "${krew}.tar.gz"
        ./"${krew}" install krew
      )
    fi
  fi

  # Install enabled plugins
  local enabled_plugins
  if enabled_plugins=($(get_enabled_items '.kubectl.krew.plugins')); then
    log::info "Installing Krew plugins..."
    for plugin in "${enabled_plugins[@]}"; do
      log::info "Installing plugin: $plugin"
      if [ "$DRY_RUN" != "true" ]; then
        execute kubectl krew install "$plugin"
      fi
    done
  fi
  
  # Uninstall disabled plugins
  local disabled_plugins
  if disabled_plugins=($(get_disabled_items '.kubectl.krew.plugins')); then
    log::info "Uninstalling Krew plugins..."
    for plugin in "${disabled_plugins[@]}"; do
      if [ "$DRY_RUN" != "true" ] && kubectl krew list | grep -q "$plugin"; then
        log::info "Uninstalling plugin: $plugin"
        execute kubectl krew uninstall "$plugin"
      fi
    done
  fi

  if [ "$DRY_RUN" != "true" ]; then
    log::info "Updating Krew plugins..."
    execute kubectl krew upgrade
  fi
}

# Uninstall kubectl krew
uninstall_kubectl_krew() {
  log::info "Uninstalling Krew"
  rimraf "$HOME/.krew"
}

# Install kubectl and related tools
install_kubectl() {
  local enabled
  if ! enabled=$(get_config_value '.kubectl.enabled'); then
    log::debug "kubectl configuration not found, skipping"
    return 0
  fi

  if [ "$enabled" == "$flag_ignore" ]; then
    log::debug "Ignoring kubectl installation"
    return 0
  elif [ "$enabled" == "false" ]; then
    log::info "Uninstalling kubectl and its dependencies: krew, kubectx, kubens"
    uninstall_kubectl_krew
    brew_uninstall kubectx kubernetes-cli
    return 0
  elif [ "$enabled" == "true" ]; then
    brew_install kubernetes-cli
    install_kubectl_krew
  fi

  # Handle kubectx
  local kubectx_enabled
  if kubectx_enabled=$(get_config_value '.kubectl.kubectx'); then
    if [ "$kubectx_enabled" == "true" ]; then
      brew_install kubectx
    elif [ "$kubectx_enabled" == "false" ]; then
      brew_uninstall kubectx
    fi
  fi
}

# Git clone with pull if exists
git_clone() {
  local repo="$1"
  local location="$2"

  if [[ -d "$location" && -d "$location/.git" ]]; then
    log::info "Repository already exists, updating: $location"
    if [ "$DRY_RUN" != "true" ]; then
      (cd "$location" && git pull)
    fi
    return 0
  fi

  log::info "Cloning repository: $repo -> $location"
  if [ "$DRY_RUN" != "true" ]; then
    execute git clone --depth 1 "$repo" "$location"
  fi
}

# Install from GitHub
install_from_github() {
  local org="$1"
  local repo="$2"
  local download_location="$3"

  git_clone "https://github.com/$org/$repo" "$download_location"
}

# Install Zsh plugins
install_zsh_plugins() {
  local plugins_config
  if ! plugins_config=$(get_config_value '.zsh' | execute "${YQ_PATH}" eval -o=j); then
    log::warn "Failed to get zsh configuration"
    return 1
  fi
  
  for plugin in $(echo "$plugins_config" | jq -cr '.plugins[]'); do
    local name source enabled plugin_location
    
    name=$(echo "$plugin" | jq -r '.name')
    source=$(echo "$plugin" | jq -r '.source // empty')
    enabled=$(echo "$plugin" | jq -r '.enabled // true')

    # If source is null/empty, the package is built-in
    if [[ -z "$source" ]]; then
      ZSH_PLUGINS+=("$name")
      continue
    fi

    plugin_location="$zsh_root/plugins/$name"
    
    if [[ "$enabled" == "false" ]]; then
      log::info "Uninstalling zsh plugin: $name"
      rimraf "$plugin_location"
      continue
    fi
      
    ZSH_PLUGINS+=("$name")

    if [ -d "$plugin_location" ]; then
      log::info "zsh plugin '$name' already installed. Updating..."
      if [ "$DRY_RUN" != "true" ]; then
        (cd "$plugin_location" && git pull)
      fi
      continue
    fi

    log::info "Installing zsh plugin: $name"
    git_clone "https://$source" "$plugin_location"
  done
}

# Setup Zsh profile
setup_zsh_profile() {
  local plugins_string="${ZSH_PLUGINS[*]}"
  local theme="$ZSH_THEME"
  local template_file="$DOTFILES_ROOT/shell/zsh/_templates/core.tmpl"
  local output_file="$DOTFILES_ROOT/shell/zsh/core"
  
  if [ ! -f "$template_file" ]; then
    log::warn "Zsh template file not found: $template_file"
    return 1
  fi
  
  log::info "Setting up Zsh profile with plugins: $plugins_string"
  
  if [ "$DRY_RUN" == "true" ]; then
    log::info "[DRY-RUN] Would generate Zsh profile with theme: $theme, plugins: $plugins_string"
    return 0
  fi
  
  PLUGINS="$plugins_string" THEME="$theme" envsubst '$PLUGINS,$THEME' < "$template_file" > "$output_file"
}

# Install Zsh configuration
install_zsh() {
  local zsh_theme
  if ! zsh_theme=$(get_config_value '.zsh.theme'); then
    log::warn "Failed to get zsh theme, using default"
    zsh_theme="robbyrussell"
  fi
  ZSH_THEME="$zsh_theme"

  install_zsh_plugins

  # Install Spaceship theme
  local spaceship_dir="$zsh_root/themes/spaceship-prompt"
  git_clone "https://github.com/spaceship-prompt/spaceship-prompt" "$spaceship_dir"
  
  if [ "$DRY_RUN" != "true" ]; then
    ln -sf "$spaceship_dir/spaceship.zsh-theme" "$zsh_root/themes/spaceship.zsh-theme"
  fi
}

# Execute post-install hooks
exec_hooks() {
  local hooks_config
  if ! hooks_config=$(get_config_value '.hooks[]' json); then
    log::debug "No hooks configured"
    return 0
  fi
  
  for hook in $(echo "$hooks_config" | jq -r '.'); do
    local script_path="$DOTFILES_ROOT/$hook"

    if [ ! -f "$script_path" ]; then
      log::warn "Hook script not found: $script_path"
      continue
    fi
    
    if [ ! -x "$script_path" ]; then
      log::warn "Hook script not executable: $script_path"
      continue
    fi

    log::info "Running hook: $script_path"
    if [ "$DRY_RUN" == "true" ]; then
      log::info "[DRY-RUN] Would execute hook: $script_path"
    else
      execute "$script_path"
    fi
  done
}

# Main initialization function
init() {
  log::info "Starting dotfiles installation..."
  
  validate_environment
  check_dependencies
  init_config
  install_zsh
  setup_zsh_profile
  install_brew_packages
  install_vscode
  install_kubectl
  exec_hooks
  
  log::success "Dotfiles installation completed successfully!"
}

# Run initialization
init
