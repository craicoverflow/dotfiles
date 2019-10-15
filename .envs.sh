export GOPATH="$HOME/go"
export CODE="$HOME/code"

PATH="$HOME/.local/bin:$HOME/bin:$GOPATH/bin:$PATH"
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:/usr/local/go/bin

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

export PATH

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export EDITOR=vim

# DIRECTORIES

## integr8ly
export INTEGREATLY_INSTALLER=$GO/src/github.com/integr8ly/installation

# mobile developer console
export MOBILE_DEVELOPER_CONSOLE=$CODE/src/github.com/aerogear/mobile-developer-console
export MOBILE_DEVELOPER_CONSOLE_OPERATOR=$GO/src/github.com/aerogear/mobile-developer-console-operator

# mobile security service
export MOBILE_SECURITY_SERVICE=$GOPATH/src/github.com/aerogear/mobile-security-service
export MOBILE_SECURITY_SERVICE_OPERATOR=$GOPATH/src/github.com/aerogear/mobile-security-service-operator

export DOTFILES=$CODE/src/github.com/craicoverflow/dotfiles