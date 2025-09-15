#!/usr/bin/env bash

set -e
set -u
set -o pipefail

cmd_dir="$DOTFILES_ROOT/cmd"
source "${cmd_dir}/_util.sh"

usage() {
  cat << EOF
dotfiles - A dotfiles management tool

Usage: dotfiles [options] <command> [args]

Options:
  -h, --help     Show this help message
  -v, --verbose  Enable verbose output
  -d, --debug    Enable debug output
  --dry-run      Show what would be done without making changes
  --version      Show version information

Commands:
  install        Install dotfiles on the system
  add <file> <target> [local]  Add a file to dotfiles (local=true for machine-specific)
  edit           Open dotfiles in \$EDITOR
  diff           Show differences between local and tracked files
  apply [file]   Apply changes from dotfiles to local system
  download       Download remote dotfiles
  backup         Create a backup of current dotfiles
  verify         Verify dotfiles configuration
  status         Show status of tracked files

Examples:
  dotfiles add ~/.zshrc shell/zsh
  dotfiles add ~/.gitconfig git local
  dotfiles diff
  dotfiles apply

For more information, visit: https://github.com/yourusername/dotfiles
EOF
}

version() {
  echo "dotfiles version ${VERSION}"
}

# Parse global options
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    -v|--verbose)
      export VERBOSE=true
      shift
      ;;
    -d|--debug)
      export DEBUG=true
      shift
      ;;
    --dry-run)
      export DRY_RUN=true
      shift
      ;;
    --version)
      version
      exit 0
      ;;
    *)
      break
      ;;
  esac
done

# Ensure we have a command
if [ $# -eq 0 ]; then
  usage
  exit 1
fi

CMD="$1"
shift

# Execute command
case "$CMD" in
  "install")
    log::info "Installing dotfiles..."
    "${cmd_dir}/install.sh" "$@"
    ;;
  "add")
    if [ $# -lt 2 ]; then
      log::error "Usage: dotfiles add <file> <target> [local]"
      exit 1
    fi
    "${cmd_dir}/add.sh" "$@"
    ;;
  "edit")
    if [ -z "${DOTFILES_EDITOR:-}" ]; then
      DOTFILES_EDITOR="$EDITOR"
    fi
    cd "${DOTFILES_ROOT}" && "${DOTFILES_EDITOR}" .
    ;;
  "diff")
    "${cmd_dir}/diff.sh" "$@"
    ;;
  "apply")
    "${cmd_dir}/apply.sh" "$@"
    ;;
  "download")
    "${cmd_dir}/download.sh" "$@"
    ;;
  "backup")
    log::info "Creating backup of dotfiles..."
    # TODO: Implement backup functionality
    ;;
  "verify")
    log::info "Verifying dotfiles configuration..."
    validate_config "${DOTFILES_ROOT}/dotfiles.cfg"
    if [ -f "${DOTFILES_ROOT}/shell/dotfiles.local.cfg" ]; then
      validate_config "${DOTFILES_ROOT}/shell/dotfiles.local.cfg"
    fi
    log::success "Configuration files are valid"
    ;;
  "status")
    log::info "Checking status of tracked files..."
    # TODO: Implement status functionality
    ;;
  *)
    log::error "Unknown command: $CMD"
    usage
    exit 1
    ;;
esac
