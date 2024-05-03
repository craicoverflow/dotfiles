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
  cd ${DOTFILES_ROOT} && ${EDITOR} .
  ;;
"diff")
  ${cmd_dir}/diff.sh
  ;;
"apply")
  ${cmd_dir}/apply.sh
  ;;
"download")
  ${cmd_dir}/download.sh
  ;;
*)
esac
