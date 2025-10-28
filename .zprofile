# =================================================================
# Don's Zprofile Customizations
# =================================================================
# GPG Configuration for commit signing
export GPG_TTY=$(tty)

eval "$(/opt/homebrew/bin/brew shellenv)"
eval "$(fnm env --use-on-cd --shell zsh)"
source $HOME/.local/bin/env
