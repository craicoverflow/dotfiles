#!/bin/bash

# Symlink dotfiles
ln -sf $PWD/.zshrc $HOME/.zshrc
ln -sf $PWD/.aliases $HOME/.aliases
ln -sf $PWD/.envs $HOME/.envs
ln -sf $PWD/.gitconfig $HOME/.gitconfig
ln -sf $PWD/.gitmessage $HOME/.gitmessage

# Symlink startup script
ln -sf $PWD/init.d/startup.sh /etc/init.d/startup

if [ -f $PWD/.secrets ]; then
    ln -sf $PWD/.secrets $HOME/.secrets
fi