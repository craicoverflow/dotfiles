# /bin/sh

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

breww() {
  if ! does_binary_exist "brew"
  then
    echo "brew is missing from your computer. Installing it for you..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  if [ "$1" == "install" ]; then
    echo "Installing package '$2'"
  fi
  brew "$@"
}

ln -sf "$(pwd)/zsh/config" $HOME/.zshrc

# Install nvm
if ! does_binary_exist "nvm"
then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
  source $HOME/.zshrc

  echo "Installing Node.js"
  nvm install --lts
fi

echo "Setting up Neovim..."
breww install neovim
mkdir -p $HOME/.config
ln -sfn "$(pwd)/nvim" $HOME/.config
nvim +'PlugInstall --sync' +qa

echo "Setting up vim-plug..."
# Install vim-plug package manager
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

echo "Installing 'Inconsolata Mono Nerd Font'..."
cd $HOME/Library/Fonts && curl -fLo "Inconsolata Mono for Powerline Nerd Font Complete.otf" https://github.com/ryanoasis/nerd-fonts/blob/master/patched-fonts/Inconsolata/complete/Inconsolata%20Regular%20Nerd%20Font%20Complete%20Mono.otf?raw=true

