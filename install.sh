#!/usr/bin/env bash

set -e
set -u
set -o pipefail

git clone git@github.com:craicoverflow/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

echo "export DOTFILES_ROOT=$(pwd)" > ~/.dotfilesrc

echo "" >> ~/.zshrc
echo "## Temporarily adds dotfiles binary to path. Run \`dotfiles apply\` to properly set this to your path" >> ~/.zshrc
echo "export PATH=$(pwd)/bin:$PATH" >> ~/.zshrc

>&2 echo ""
>&2 echo "dotfiles installed successfully. Run \`dotfiles install\` to install packages"
