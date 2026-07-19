#
# Docker handler
#

check_or_install_brew_command docker --cask

export DOCKER_CLI_HINTS=false
FPATH="$HOME/.docker/completions:$FPATH"
autoload -Uz compinit
compinit -C
