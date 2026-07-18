#
# Enhanced cd command (zoxide and fzf)
#

check_or_install_brew_command zoxide && eval "$(zoxide init zsh --cmd cd)"
check_or_install_brew_command fzf && source <(fzf --zsh)

# cd aliases
alias cd..='cd ..'
alias 1up='cd ..'
alias 2up='cd ../..'
alias 3up='cd ../../..'
alias 4up='cd ../../../..'
alias 5up='cd ../../../../..'
alias 6up='cd ../../../../../..'
alias 7up='cd ../../../../../../..'
