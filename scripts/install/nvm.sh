#!/bin/sh

mkdir ~/.nvm

wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash

# fix npm permissions
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'