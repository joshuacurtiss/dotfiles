#
# Miscellaneous aliases
#

# Shortcuts for pausing and resuming processes
alias pause='kill -STOP'
alias resume='kill -CONT'

# Weather
alias weather='curl wttr.in\?format=4'
alias forecast='curl wttr.in'

# Build cleanup
alias cleanbuilds='command rm -Rf builds dist dist_electron .cache .temp .nyc_output coverage .vuepress/.cache .vuepress/.temp .vuepress/dist vuepress-docs/.vuepress/.cache vuepress-docs/.vuepress/.temp vuepress-docs/.vuepress/dist vuepress-docs/.temp'
alias cleanproj='cleanbuilds node_modules vuepress-docs/node_modules .vuepress/node_modules bower_components vendor'
