#!/usr/bin/env bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# System info
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')"

# Logging levels
DEBUG="${DEBUG:-false}"
VERBOSE="${VERBOSE:-false}"
DRY_RUN="${DRY_RUN:-false}"

log::error() {
  >&2 echo -e "${RED}[ERROR]${NC} $1"
}

log::warn() {
  >&2 echo -e "${YELLOW}[WARN]${NC} $1"
}

log::info() {
  >&2 echo -e "${BLUE}[INFO]${NC} $1"
}

log::success() {
  >&2 echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log::debug() {
  if [ "$DEBUG" == true ]; then
    >&2 echo -e "${YELLOW}[DEBUG]${NC} [$(date +%F_%T)] $1"
  fi
}

log::verbose() {
  if [ "$VERBOSE" == true ]; then
    >&2 echo -e "${BLUE}[VERBOSE]${NC} $1"
  fi
}

fail() {
  log::error "$1"
  exit 1
}

# File operations
rimraf() {
  if [ "$DRY_RUN" == true ]; then
    log::info "[DRY-RUN] Would remove: $1"
    return 0
  fi
  rm -rf "$1"
}

backup_file() {
  local file="$1"
  local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
  
  if [ ! -f "$file" ]; then
    log::debug "No file to backup: $file"
    return 0
  fi

  if [ "$DRY_RUN" == true ]; then
    log::info "[DRY-RUN] Would backup $file to $backup"
    return 0
  fi

  cp "$file" "$backup"
  log::debug "Created backup: $backup"
}

validate_config() {
  local config_file="$1"
  
  if [ ! -f "$config_file" ]; then
    fail "Configuration file not found: $config_file"
  fi

  # Validate format (source=>target)
  while IFS= read -r line; do
    if [[ ! "$line" =~ ^[^=]+\=\>[^=]+$ ]]; then
      fail "Invalid mapping format in $config_file: $line"
    fi
  done < "$config_file"
}

is_valid_path() {
  local path="$1"
  if [[ "$path" =~ ^[./]+ ]] || [[ "$path" =~ ^/ ]] || [[ "$path" =~ ^\$[A-Za-z_][A-Za-z0-9_]*/ ]]; then
    return 0
  fi
  return 1
}

ensure_dir() {
  local dir="$1"
  if [ ! -d "$dir" ]; then
    if [ "$DRY_RUN" == true ]; then
      log::info "[DRY-RUN] Would create directory: $dir"
      return 0
    fi
    mkdir -p "$dir"
    log::debug "Created directory: $dir"
  fi
}

# Version info
VERSION="1.0.0"