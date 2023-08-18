#!/usr/bin/env bash

set -e
set -u
set -o pipefail

cmd_dir="$(dirname "$0")"
source ${cmd_dir}/_util.sh

dotfile_path="${1}"

to_folder="$DOTFILES_ROOT"
if [[ "${2}" != "." ]]; then
	to_folder="${DOTFILES_ROOT}/${2}"
fi

local="${3:-false}"

if [ ! -f $dotfile_path ]
then
	fail "file '$dotfile_path' does not exist"
fi

to_dir=$to_folder
if [ ! -d $to_dir ]
then
	log::info "Creating directory $to_dir"
	mkdir -p $to_dir
fi

mapTo="${dotfile_path/$HOME/\$HOME}"
mapFrom="${to_folder/$DOTFILES_ROOT/\$DOTFILES_ROOT}/$(basename ${dotfile_path})"

mappingsFile="$DOTFILES_ROOT/dotfiles.cfg"

if [[ $local == "true" ]]; then
	mappingsFile="$DOTFILES_ROOT/shell/dotfiles.local.cfg"
fi

mappingLine="$mapFrom:$mapTo"
if grep -Fxq "${mapFrom}=>${mapTo}" $mappingsFile
then
	log::info "Mapping already found between $mapTo and $mapFrom"
else
	cp $(eval "echo ${dotfile_path}") $(eval "echo ${mapFrom}")
	echo "${mapFrom}=>${mapTo}" >> $mappingsFile
fi