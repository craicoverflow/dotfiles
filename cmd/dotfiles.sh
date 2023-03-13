#!/usr/bin/env bash

cmd_dir="$DOTFILES_ROOT/cmd"

CMD="$1"

case "$CMD" in
"install")
  ${cmd_dir}/install.sh
  ;;
"add")
  ${cmd_dir}/add.sh $2 $3 $4
  ;;
"edit")
  $EDITOR $DOTFILES_ROOT
  ;;
*)
esac