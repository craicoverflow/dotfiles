#!/bin/sh

# delete any old versions of Go
sudo rm -rf /usr/local/go

cd /tmp

wget https://dl.google.com/go/go1.12.1.linux-amd64.tar.gz

tar -C /usr/local -xzf go1.12.1.linux-amd64.tar.gz