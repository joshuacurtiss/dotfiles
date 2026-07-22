#
# Suffix Aliases
#

if check_or_install_brew_command jless; then
   alias -s json=jless
   alias -s yaml=jless
   alias -s yml=jless
fi

if command -v code &>/dev/null; then
   alias -s js=code
   alias -s ts=code
   alias -s css=code
fi

if check_or_install_brew_command bat; then
   alias -s md=bat
fi

alias -s txt=less

alias -s pdf=open
alias -s html=open
alias -s htm=open
alias -s jpg=open
alias -s jpeg=open
alias -s mov=open
alias -s mp4=open
alias -s png=open
