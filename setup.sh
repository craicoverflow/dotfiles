#!/bin/bash

#./install-vim.sh
#./install-vscode.sh
dnf install keepassxc -y

# Gnome Tweak Tool
dnf makecache -y
dnf install gnome-tweak-tool -y

# Dropbox
dnf install https://www.dropbox.com/download?dl=packages/fedora/nautilus-dropbox-2019.02.14-1.fedora.x86_64.rpm -y

# xclip
dnf install xclip -y

