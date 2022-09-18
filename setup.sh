#!/bin/bash

dotfiles_root=$(pwd)

# fail fast
set -eo pipefail

does_binary_exist() {
  if ! command -v $1 &> /dev/null
  then
    echo "$1 could not be found"
    return 1
  fi
  return 0
}

install_brew_if_not_exists() {
  if ! does_binary_exist "brew"
  then
    echo "Installing brew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
}

git_clone_if_not_exists() {
  if ! git clone "$1" "$2" 2>/dev/null && [ -d "${2}" ] ; then
    echo "Clone failed because the folder ${2} exists"
  fi
}

# Set NVM_DIR so that Bash can find it 
# (since we use ZSH normally, the bash 
# profile does not have these paths configured)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

# Install nvm
if ! does_binary_exist "nvm"
then
  echo "Installing nvm (Node Version Manager)..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
 
  source $HOME/.zshrc

  echo "Installing Node.js..."
  nvm install --lts
fi

install_brew_if_not_exists

echo "Updating brew libraries..."
brew update
brew upgrade

brew install exa
brew install bat

echo "Setting up Neovim..."
brew install neovim
mkdir -p $HOME/.config
ln -sfn "$(pwd)/nvim" $HOME/.config
nvim +'PlugInstall --sync' +qa

echo "Setting up vim-plug..."
# Install vim-plug package manager
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

echo "Installing 'Inconsolata Mono Nerd Font'..."
cd "$HOME/Library/Fonts" && curl -fLo "Inconsolata Mono for Powerline Nerd Font Complete.otf" https://github.com/ryanoasis/nerd-fonts/blob/master/patched-fonts/Inconsolata/complete/Inconsolata%20Regular%20Nerd%20Font%20Complete%20Mono.otf?raw=true
cd "$dotfiles_root"

echo "Setting up oh-my-zsh and plugins"
if [ ! -d "$ZSH" ]; then
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
rm -f "$HOME/.zshrc"
echo "Installing 'zsh-autosuggestions' plugin..."
git_clone_if_not_exists https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
echo "Installing 'zsh-syntaxhighlighting' plugin..."
git_clone_if_not_exists https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
echo "Installing powerlevel10k plugin..."
git_clone_if_not_exists https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k --depth=1

ln -sf "$(pwd)/zsh/config" "$HOME/.zshrc"
echo "Run 'source "$HOME/.zshrc"' for your ZSH profile changes to come into effect"