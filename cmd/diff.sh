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
		
		# create the files if they do not exist
		# useful for local configs 
		if [[ ! -e $from ]]; then
    		touch $from
		fi
		if [[ ! -e $to ]]; then
    		touch $to
		fi

		count=$(echo $(diff $from $to --suppress-common-lines | wc -l))
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
