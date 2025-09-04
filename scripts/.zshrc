# =================================================================
# Don's Zsh Customizations
# =================================================================
# This file contains Don's personal zsh configuration that extends
# the upstream .zshrc. It's designed to be sourced at the end of
# the main .zshrc file to avoid merge conflicts.
# =================================================================
autoload -U +X compinit && compinit # Required for loading oh-my-zsh plugins.

source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"

# Initialize Starship prompt (Don's custom prompt)
eval "$(starship init zsh)"

# alias gcm='git checkout $(git_main_branch)'
export ZSH_PLUGINS="$HOME/.oh-my-zsh/plugins"
source "$ZSH_PLUGINS/git/git.plugin.zsh"
source "$ZSH_PLUGINS/common-aliases/common-aliases.plugin.zsh"
source "$ZSH_PLUGINS/encode64/encode64.plugin.zsh"

# =================================================================
# Don's Development Environment Setup
# =================================================================

# GPG Configuration for commit signing
export GPG_TTY=$(tty)


# PyEnv Configuration - Don's Python version management
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
# This is slow. Enable if needed.
# eval "$(pyenv init - zsh)"

# =================================================================
# Don's Tool Integrations
# =================================================================

# Azure CLI Completions (https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-macos?view=azure-cli-latest#completion-isnt-working)
# autoload bashcompinit && bashcompinit
# source $(brew --prefix)/etc/bash_completion.d/az
