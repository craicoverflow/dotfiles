#!/bin/sh

# Symlink dotfiles
ln -sf $PWD/.zshrc $HOME/.zshrc
ln -sf $PWD/.aliases.sh $HOME/.aliases
ln -sf $PWD/.envs.sh $HOME/.envs
ln -sf $PWD/.gitconfig $HOME/.gitconfig
ln -sf $PWD/.gitmessage $HOME/.gitmessage
ln -sf $PWD/.tmux.conf $HOME/.tmux.conf
ln -sf $PWD/.commit-msg.json $HOME/.commit-msg.json

# set up global Git hooks
rm -rf $HOME/.git-templates
mkdir -p $HOME/.git-templates
ln -sf $PWD/.git-templates/hooks $HOME/.git-templates/hooks

# Symlink startup script
chmod +x $PWD/init.d/startup.sh
sudo ln -sf $PWD/init.d/startup.sh /etc/init.d/startup

if [ -f $PWD/.secrets.sh ]; then
    ln -sf $PWD/.secrets.sh $HOME/.secrets
fi