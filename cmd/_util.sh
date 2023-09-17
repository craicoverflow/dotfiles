#!/usr/bin/env bash

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')"
DEBUG="${DEBUG:-false}"

log::info() {
  >&2 echo $1
}

log::debug() {
  if [ "$DEBUG" == true ]; then
    log::info "[$(date +%F_%T)] [DEBUG] $1"
  fi
}

fail() {
  log::info "Error: $1"
  exit 1
}

rimraf() {
  rm -rf "$1"
}