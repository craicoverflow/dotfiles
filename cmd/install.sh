#!/usr/bin/env bash

set -o pipefail

INSTALLDIR=$(pwd)
cmd_dir="$(dirname "$0")"
generated_dotfiles_specfile="$DOTFILES_ROOT/packages-generated.yaml"
zsh_root=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
YQ_PATH="${YQ_PATH:-yq}"

source ${cmd_dir}/_util.sh

flag_ignore="ignore"

execute() {
  eval "$@"
}

binary_exists() {
  if ! command -v $1 &> /dev/null
  then
    echo "$1 could not be found"
    return 1
  fi
}

install_brew() {
  log::info "Installing Homebrew ⚙️ "
  if ! binary_exists brew
  then
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    log::info "Homebrew is already installed 😊"
  fi
}

get_config() {
  cat $generated_dotfiles_specfile
}

init_config() {
  yyq e ". *n load(\"$DOTFILES_ROOT/packages.yaml\")" $DOTFILES_ROOT/packages-local.yaml > $generated_dotfiles_specfile
}

get_config_value() {
  path="$1"

  get_config | execute "$YQ_PATH '$path'"
}

brew_install() {
  packages=("$@")
  for p in "${packages[@]}"
  do
    : 
    log::info "⚙️ Installing $p."
    brew install $p && log::info "$p is installed."
  done
}

brew_uninstall() {
  packages=("$@")
  for p in "${packages[@]}"
  do
    : 
    if brew list $p &>/dev/null; then
      log::info "⚙️ Uninstalling $p."
      brew uninstall $p && log::info "$p is uninstalled."
    fi
  done
}

get_enabled_items() {
  path="$1"

  get_config_value "$path | with_entries(select(.value == true)) | to_entries | .[].key"
}

get_disabled_items() {
  path="$1"

  get_config_value "$path | with_entries(select(.value == false)) | to_entries | .[].key"
}

install_brew_core() {
  install_brew
  brew update
  brew upgrade

  brew_install yq
  brew tap vmware-tanzu/carvel
  brew_install ytt
}

install_brew_packages() {
  install_brew_core

  brew_taps=($(get_enabled_items '.brew.taps'))
  
  log::info "Adding Homebrew taps."
  for t in "${brew_taps[@]}"
  do
    : 
    brew tap $t
  done

  log::info "Removing unwanted Homebrew taps."
  brew_untaps=($(get_disabled_items '.brew.taps'))
  for t in "${brew_untaps[@]}"
  do
    :
    log::info "Removing brew tap $t"
    brew untap $t || true
  done

  brew_install_packages=($(get_enabled_items '.brew.packages'))

  log::info "Installing Homebrew packages."
  for i in "${brew_install_packages[@]}"
  do
    : 
      brew_install $i
  done

  return

  brew_uninstall_packages=($(get_disabled_items '.brew.packages'))

  log::info "Uninstalling unwanted Homebrew packages."
  for i in "${brew_uninstall_packages[@]}"
  do
    : 
      brew_uninstall $i
  done
}

install_vscode() {
  enabled=($(get_config_value '.vscode.enabled'))
  if [ $enabled == false ]; then
    return
  fi
  brew_install visual-studio-code

  enabled_extensions=($(get_enabled_items '.vscode.extensions'))
  log::info "Installing Visual Studio Code extensions."
  for i in "${enabled_extensions[@]}"
  do
    : 
      if ! code --list-extensions | grep $i &>/dev/null; then
        log::info "Installing extension $i ⚙️ "
        code --install-extension $i && log::info "$i is installed."
      fi
  done

  disabled_extensions=($(get_disabled_items '.vscode.extensions'))
  log::info "Uninstalling Visual Studio Code extensions."
  for i in "${disabled_extensions[@]}"
  do
    : 
      if ! code --list-extensions | grep $i &>/dev/null; then
        log::info "Uninstalling extension $1i⚙️ "
        code --uninstall-extension $i && log::info "$i is uninstalled."
      fi
  done
}

install_kubectl_krew() {
  enabled=($(get_config_value '.kubectl.krew.enabled'))
  if [ $enabled == false ]; then
    log::info "Uninstalling Krew."
    rimraf $HOME/.krew
    return
  fi

  if ! binary_exists kubectl; then
    log::info "kubectl is required to use krew. Please enable in spec or install via alternative method."
  fi

  if [ -d $HOME/.krew ]; then
    log::info "Krew is already installed."
  else
    log::info "Installing Krew."
    set -x; cd "$(mktemp -d)" &&
    KREW="krew-${OS}_${ARCH}" &&
    curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
    tar zxvf "${KREW}.tar.gz" &&
    ./"${KREW}" install krew
  fi

  enabled_plugins=($(get_enabled_items '.kubectl.krew.plugins'))
  log::info "Installing Krew extensions."
  for i in "${enabled_plugins[@]}"
  do
    : 
      log::info "Installing plugins $i"
      kubectl krew install $i && log::info "$i is installed."
  done
  disabled_extensions=($(get_disabled_items '.kubectl.krew.plugins'))
  log::info "Uninstalling Krew extensions."
  for i in "${disabled_extensions[@]}"
  do
    : 
      if kubectl krew | grep $i &>/dev/null; then
        kubectl krew uninstall $i && log::info "$i is uninstalled."
      fi
  done

  log::info "Updating Krew plugins.."
  kubectl krew upgrade
}

uninstall_kubectl_krew() {
  log::info "Uninstalling Krew"
  rimraf $HOME/.krew
}

install_kubectl() {
  enabled=($(get_config_value '.kubectl.enabled'))

  if [[ $enabled == $flag_ignore ]]
  then
    log::debug "Ignoring kubectl installation"
  elif [ $enabled == false ]
  then
    log::info "Uninstalling kubectl and its dependencies: krew, kubectx, kubens"
    uninstall_kubectl_krew
    brew_uninstall kubectx kubernetes-cli
    return
  elif [ $enabled == true ]
  then
    brew_install kubernetes-cli
  fi

  kubectx_enabled=($(get_config_value '.kubectl.kubectx'))
  if [[ $kubectx_enabled == true ]]
  then
    brew_install kubectx
  elif [[ $kubectx_enabled == false ]]
  then
    brew_uninstall kubectx
  fi
  
  install_kubectl_krew
}

git_clone() {
  repo="$1"
  location="$2"

  if [[ -d $location && -d $location/.git ]]
  then
      cd $location
      git pull
      return
  fi

  git clone --depth 1 $1 $2
}

install_from_github() {
  org="$1"
  repo="$2"
  download_location="$3"

  git_clone https://github.com/$org/$repo $download_location
}

omz_install() {
  org="$1"
  repo="$2"

  install_from_github $org $repo /plugins/$repo
}

uninstall_oh_my_zsh_plugin() {
  rimraf
}

install_zsh_plugins() {
  for plugin in $(echo $(get_config_value '.zsh' | execute ${YQ_PATH} eval -o=j | jq -cr '.plugins[]')); do
    name=$(echo $plugin | jq -r '.name')
    source=$(echo $plugin | jq -r '.source')

    # If source is null the package will already be installed
    if [[ $source == null ]]
    then
      ZSH_PLUGINS+=($name)
      continue
    fi

    enabled=$(echo $plugin | jq -r '.enabled')

    plugin_location=$zsh_root/plugins/$name
    
    if [[ $enabled == false ]]
    then
      log::info "Uninstalling zsh plugin '$name'"
      rimraf $plugin_location
      continue
    fi
      
    ZSH_PLUGINS+=($name)

    if [ -d $plugin_location ]; then
      log::info "zsh plugin '$name' already installed. Updating.."
      cd $plugin_location
      continue
    fi

    log::info "Installing zsh plugin '$name'"
    git_clone https://$source $plugin_location
  done
}

setup_zsh_profile() {
  export PLUGINS=${ZSH_PLUGINS[@]}
  export THEME=${ZSH_THEME}
  envsubst '$PLUGINS,$THEME' < $DOTFILES_ROOT/shell/zsh/_templates/config.tmpl > $DOTFILES_ROOT/shell/zsh/config
}

install_zsh() {
  zsh_theme=($(get_config_value '.zsh.theme'))
  ZSH_THEME=$zsh_theme

  install_zsh_plugins

  git_clone https://spaceship-prompt/spaceship-prompt $zsh_root/themes/spaceship-prompt
  ln -sf "$zsh_root/themes/spaceship-prompt/spaceship.zsh-theme" "$zsh_root/themes/spaceship.zsh-theme"
}

init() {
  init_config
  install_zsh
  setup_zsh_profile
  install_brew_packages
  install_vscode
  install_kubectl
}

init
