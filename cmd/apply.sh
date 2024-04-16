#!/usr/bin/env bash

set -e
set -u
set -o pipefail

cmd_dir="$(dirname "$0")"
source ${cmd_dir}/_util.sh

mappingsFile="$DOTFILES_ROOT/dotfiles.cfg"
localMappingsFile="$DOTFILES_ROOT/dotfiles.local.cfg"

apply_files() {
	file="$1"

	if [ ! -f "$file" ]; then
    	return
	fi

	while read l; do
		from=$(eval "echo ${l%=>*}")
		to=$(eval "echo ${l#*=>}")

		count=$(echo $(diff $to $from --suppress-common-lines | wc -l))

		if [[ "$count" != 0 ]]; then
			cp -r $from $to
		fi

	done <$file
}

log::info "Applying all dotfiles..."

apply_files $mappingsFile
apply_files $localMappingsFile

log::info "Dotfiles updated."
