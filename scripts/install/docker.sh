#!/bin/sh

dnf -y install dnf-plugins-core

cat <<EOF | sudo tee /etc/yum.repos.d/docker-ce.repo
[docker-ce-stable]
name=Docker CE Stable
baseurl=https://download.docker.com/linux/fedora/$(rpm -E %fedora)/x86_64/stable
enabled=1
gpgcheck=1
gpgkey=https://download.docker.com/linux/fedora/gpg
EOF

dnf -y install docker-ce

systemctl enable --now docker

usermod -aG docker $(whoami)