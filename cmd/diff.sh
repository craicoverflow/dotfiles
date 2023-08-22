#!/usr/bin/env bash

# set -e
set -u
set -o pipefail

cmd_dir="$(dirname "$0")"
source ${cmd_dir}/_util.sh

mappingsFile="$DOTFILES_ROOT/dotfiles.cfg"
localMappingsFile="$DOTFILES_ROOT/dotfiles.local.cfg"

print_diff() {
	file="$1"

	if [ ! -f "$file" ]; then
    	return
	fi

	bold=$(tput bold)
	normal=$(tput sgr0)
	border="--------"
	while read l; do
		from=$(eval "echo ${l%=>*}")
		to=$(eval "echo ${l#*=>}")

		count=$(echo $(diff $to $from --suppress-common-lines | wc -l))
		if [[ "$count" != 0 ]]; then
			printf "${bold}FILE: $to : SOURCE: $from"
			echo ""
			echo $border
			echo "${normal}"
			diff $to $from -y --color
			echo ""
		fi
	done <$file
}

print_diff $mappingsFile
print_diff $localMappingsFile