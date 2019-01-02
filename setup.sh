#!/bin/bash
ln -sf $PWD/.zshrc $HOME/.zshrc
ln -sf $PWD/.aliases $HOME/.aliases
ln -sf $PWD/.envs $HOME/.envs
ln -sf $PWD/.gitconfig $HOME/.gitconfig

if [ -f $PWD/.secrets ]; then
    ln -sf $PWD/.secrets $HOME/.secrets
fi