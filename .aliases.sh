alias cgh="cd ~/code/src/github.com"
alias cggh="cd ~/go/src/github.com"

alias sz="source ~/.zshrc"
alias vz="vim ~/.zshrc"

alias h="history"

alias vs="code ."

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Git
alias gpu="git push"
alias gam="git commit --amend"

alias ms="minishift"
alias osk="operator-sdk"

# Chrome remote debug mode
alias chrome="/usr/bin/google-chrome --remote-debugging-port=9222 &"

eval $(thefuck --alias)

# hub
eval "$(hub alias -s)"

# docker
alias ld='lazydocker'

## FUNCTIONS
gitt-update-branch() {
    # get the current branch
    current=$(git rev-parse --abbrev-ref HEAD)

    # get the remote to update from
    remote=${1:-upstream}

    # update your local branch from the remote
    git checkout master
    git pull $remote master
    git checkout $current
    git rebase master
}

gitt-push-branch() {
    remote=${1:-origin}

    git push $remote --set-upstream $(git rev-parse --abbrev-ref HEAD)
}