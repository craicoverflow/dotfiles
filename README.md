# Enda's Dotfiles

These are my dotfiles, as well as some common packages I have installed on my OS.

## Installation

To install the `dotfiles` binary and all my configurations, simply run the following

```sh
curl https://raw.githubusercontent.com/craicoverflow/dotfiles/main/install.sh | bash
```

This will install the `dotfiles` binary and add it to your path.

## Usage

### Install packages

To install the packages found in `$DOTFILES_ROOT/packages.yaml`:

```sh
dotfiles install
```

If you wish to disable installation of some of these packages, add a `packages-local.yaml` file to the `$DOTFILES_ROOT` folder, and only the configs you need to disable and set the value to `false`:

```diff
---
brew:
  packages:
-   neovim: true
+   neovim: false
-   docker: true
+   docker: true
```

### Compare dotfiles

When there are updates to the dotfiles repo, you can compare the changes with your dotfiles before you apply them:

```sh
dotfiles diff
```

### Apply dotfiles

If you are happy with then changes, run the following command to update your dotfiles:

```sh
dotfiles apply
```

### Add a new dotfile

If you have a dotfile you would like to be managed by this repo, run `dotfiles add <path/to/dotfile> <folder/in/dotfiles-repo>`

```sh
$ dotfiles add ~/.config/gh/config.yml gh
Creating directory /Users/jdoe/dotfiles/gh
```

> TIP: Run `dotfiles add <from> <to> local` to add a dotfile for this repo but ignore it in Git.

### Edit dotfiles

Run the following command to open the dotfiles in your preferred edit (`$EDITOR`):

```sh
dotfiles edit
```
