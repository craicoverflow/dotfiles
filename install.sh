#!/usr/bin/env bash

set -e
set -u
set -o pipefail

git clone git@github.com:craicoverflow/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

echo "export DOTFILES_ROOT=$(pwd)" > .dotfilesrc

cd cmd
./install.sh