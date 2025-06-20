#!/usr/bin/env bash

set -e
set -u
set -o pipefail

cmd_dir="$(dirname "$0")"
source "${cmd_dir}/_util.sh"

usage() {
	cat << EOF
Usage: dotfiles add <file> <target> [local]

Arguments:
	file    The file to add to dotfiles (absolute path or relative to \$HOME)
	target  The target directory in dotfiles (relative to dotfiles root)
	local   Optional: Set to 'true' for machine-specific files

Examples:
	dotfiles add ~/.zshrc shell/zsh
	dotfiles add ~/.gitconfig git true
EOF
}

if [ $# -lt 2 ]; then
	usage
	exit 1
fi

dotfile_path="${1}"
target_dir="${2}"
local="${3:-false}"

# Validate inputs
if [ ! -f "$dotfile_path" ]; then
	fail "File does not exist: $dotfile_path"
fi

if ! is_valid_path "$target_dir"; then
	fail "Invalid target directory: $target_dir"
fi

# Resolve paths
to_folder="$DOTFILES_ROOT"
if [[ "${target_dir}" != "." ]]; then
	to_folder="${DOTFILES_ROOT}/${target_dir}"
fi

# Ensure target directory exists
ensure_dir "$to_folder"

# Map paths for config
mapTo="${dotfile_path/$HOME/\$HOME}"
mapFrom="${to_folder/$DOTFILES_ROOT/\$DOTFILES_ROOT}/$(basename "${dotfile_path}")"

# Determine config file
mappingsFile="$DOTFILES_ROOT/dotfiles.cfg"
if [[ $local == "true" ]]; then
	mappingsFile="$DOTFILES_ROOT/shell/dotfiles.local.cfg"
	ensure_dir "$(dirname "$mappingsFile")"
fi

# Check if mapping already exists
mappingLine="${mapFrom}=>${mapTo}"
if grep -Fxq "$mappingLine" "$mappingsFile" 2>/dev/null; then
	log::warn "Mapping already exists between $mapTo and $mapFrom"
	exit 0
fi

# Backup existing file if it exists
if [ -f "$(eval "echo ${mapFrom}")" ]; then
	backup_file "$(eval "echo ${mapFrom}")"
fi

# Copy file
if [ "$DRY_RUN" == true ]; then
	log::info "[DRY-RUN] Would copy $dotfile_path to $mapFrom"
	log::info "[DRY-RUN] Would add mapping to $mappingsFile: $mappingLine"
else
	# Copy file
	cp "$(eval "echo ${dotfile_path}")" "$(eval "echo ${mapFrom}")"
	log::debug "Copied $dotfile_path to $mapFrom"

	# Add mapping
	echo "$mappingLine" >> "$mappingsFile"
	log::debug "Added mapping to $mappingsFile"

	log::success "Successfully added $dotfile_path to dotfiles"
	
	if [[ $local == "true" ]]; then
		log::info "Note: This file is marked as machine-specific"
	fi
fi