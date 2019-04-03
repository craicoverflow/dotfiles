#!/bin/sh

dnf -y install dnf-plugins-core

# Get the current Fedora version
releasever=$(sed -e 's#.*=\(\)#\1#' <<< "$(cat /etc/os-release | grep "VERSION_ID=*")")

cat <<EOF | sudo tee /etc/yum.repos.d/docker-ce.repo
[docker-ce-stable]
name=Docker CE Stable
baseurl=https://download.docker.com/linux/fedora/$releasever/x86_64/stable
enabled=1
gpgcheck=1
gpgkey=https://download.docker.com/linux/fedora/gpg
EOF

dnf -y install docker-ce

systemctl enable --now docker

usermod -aG docker $(whoami)