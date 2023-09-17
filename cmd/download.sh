#!/usr/bin/env bash

# set -e
set -u
set -o pipefail

cmd_dir="$(dirname "$0")"
source ${cmd_dir}/_util.sh

mappingsFile="$DOTFILES_ROOT/dotfiles.cfg"
localMappingsFile="$DOTFILES_ROOT/dotfiles.local.cfg"

cd $DOTFILES_ROOT
git pull origin main -r