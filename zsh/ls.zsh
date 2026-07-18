#
# Enhanced ls command
#

if check_or_install_brew_command eza; then
   alias ll='eza --icons -l -a --time-style=long-iso'
   alias llr='ll -T --git-ignore'
else
   alias ll='ls -lFAh --color=auto'
   alias llr='ll'
fi
