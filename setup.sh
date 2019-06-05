#!/bin/bash

dnf update -y

./install/vim.sh
./install/vscode.sh
./install/go.sh 1.11.7

dnf install keepassxc -y

# Gnome Tweak Tool
dnf makecache -y
dnf install gnome-tweak-tool -y

# Dropbox
dnf install https://www.dropbox.com/download?dl=packages/fedora/nautilus-dropbox-2019.02.14-1.fedora.x86_64.rpm -y

# xclip
dnf install xclip -y

dnf install qbittorrent -y

# Enabling the RPM Fusion repositories using command-line utilities
dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm

# Snap
dnf install snapd
ln -s /var/lib/snapd/snap /snap

# Spotify
snap install spotify

# Plex
cd /tmp
wget https://downloads.plex.tv/plex-media-server-new/1.15.3.876-ad6e39743/redhat/plexmediaserver-1.15.3.876-ad6e39743.x86_64.rpm
rpm -i plexmediaserver-1.15.3.876-ad6e39743.x86_64.rpm
rm plexmediaserver-1.15.3.876-ad6e39743.x86_64.rpm
systemctl start plexmediaserver.service
systemctl enable plexmediaserver.service
systemctl status plexmediaserver.service

# Ruby
dnf install ruby ruby-wdevel @development-tools -y

dnf install redhat-rpm-config -y

# Jekyll
gem install jekyll bundler

# increase amount of inotify watchers
echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p

dnf install jq -y

# set up symlinks
./symlinks.sh