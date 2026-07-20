#
# Enhancement of video/image manipulation (ffmpeg and gifsicle)
#

check_or_install_brew_command ffmpeg && check_or_install_brew_command gifsicle
check_or_install_brew_command yt-dlp

alias youtube='yt-dlp -S "ext:mp4:m4a"'

converttogif() {
  ffmpeg -i "$1" -pix_fmt rgb24 -r 15 "$2" && gifsicle -b -V -O3 "$2"
}
