#!/usr/bin/env bash

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')"
cmd_dir="$(dirname "$0")"

local="${3:-"false"}"

info() {
  >&2 echo $1
}

debug() {
  >&2 echo $1
}

fail() {
  info "Error: $1"
  exit 1
}

dotfile_path="$1"
to_folder="$DOTFILES_ROOT/$2"

if [ ! -f $dotfile_path ]
then
	fail "file '$dotfile_path' does not exist"
fi

to_dir=$(dirname $to_folder)
if [ ! -d $to_dir ]
then
	info "Creating directory $to_dir"
	mkdir -p $to_dir
fi

cp $dotfile_path $to_folder

mapFrom="${to_folder/$DOTFILES_ROOT/\$DOTFILES_ROOT}"
mapTo="${dotfile_path/$HOME/\$HOME}"

mappingsFile="$DOTFILES_ROOT/shell/symlink-all.sh"

if [[ $local == "true" ]]; then
	mappingsFile="$DOTFILES_ROOT/shell/symlink-local.sh"
fi

mappingLine="$mapFrom:$mapTo"
if grep -Fxq "ln -sf ${mapFrom} ${mapTo}" $mappingsFile
then
	info "Mapping already found between $mapTo and $mapFrom"
else
	echo "ln -sf ${mapFrom} ${mapTo}" >> $mappingsFile
fi

$mappingsFile