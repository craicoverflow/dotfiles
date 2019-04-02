#!/bin/sh

# Install Hack font
cd /tmp
wget https://github.com/source-foundry/Hack/releases/download/v3.003/Hack-v3.003-ttf.zip
unzip Hack-v3.003-ttf.zip
mv ttf /usr/share/fonts/hack
fc-cache -f -v