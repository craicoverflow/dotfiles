#!/bin/sh

dnf update -y && dnf install openvpn unzip -y

cd /etc/openvpn

wget https://downloads.nordcdn.com/configs/archives/servers/ovpn.zip

dnf install ca-certificates -y

unzip ovpn.zip

rm ovpn.zip

cd /etc/openvpn/ovpn_udp/