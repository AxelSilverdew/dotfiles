source /home/abhiram/.dotfiles/antigen.zsh
# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
unsetopt beep
bindkey -e
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/abhiram/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

#Antigen Stuff

# test load the oh-my-zsh library
antigen use oh-my-zsh

# Bundles from the default repo (robbyrussell's oh-my-zsh).
antigen bundle git
antigen bundle pip
antigen bundle command-not-found

# Syntax highlighting bundle.
antigen bundle zsh-users/zsh-syntax-highlighting

# Load the theme.
antigen theme minimal

# Tell antigen that you're done.
antigen apply

#Exports
export TERM="xterm-256color"
export EDITOR="vi"
export VAGRANT_DEFAULT_PROVIDER=virtualbox
unsetopt nomatch

#Aliases
alias screenfetch='screenfetch -D Arch'
alias neofetch='neofetch --disable title'
alias urlshort='curl -F c=@- https://ptpb.pw/u <<<'
alias s3put='s3-parallel-put'
alias killnvidia='rmmod nvidia_drm nvidia_modeset nvidia'
alias mp3down='youtube-dl --extract-audio --audio-format mp3 --embed-thumbnail'

LS_COLORS=$LS_COLORS:'di=0;33:' ; export LS_COLORS

#Android Studio Exports
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/emulator
