#!/usr/bin/env bash

set -e
set -u
set -o pipefail

cmd_dir="$(dirname "$0")"
source ${cmd_dir}/_util.sh

mappingsFile="$DOTFILES_ROOT/dotfiles.cfg"
localMappingsFile="$DOTFILES_ROOT/dotfiles.local.cfg"

is_initial_apply="${1:-false}"

apply_files() {
	file="$1"
	initial_apply="$2"

	if [ ! -f "$file" ]; then
    	return
	fi

	while read l; do
		from=$(eval "echo ${l%=>*}")
		to=$(eval "echo ${l#*=>}")

		count=$(echo $(diff $to $from --suppress-common-lines | wc -l))

		if [[ "$count" != 0 ]]; then
			if [[ "${is_initial_apply,,}" == "true" ]]; then
				cp -r $to $from
			else
				cp -r $from $to
			fi
		fi

	done <$file
}

log::info "Applying all dotfiles..."

apply_files $mappingsFile $is_initial_apply
apply_files $localMappingsFile $is_initial_apply

log::info "Dotfiles updated."
