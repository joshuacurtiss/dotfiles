#
# Support for Asciinema recordings in zsh
#
# Provided CLI tools:
#   - rec: Start a new Asciinema recording in the current shell session.
#   - play: Convert an Asciinema recording file (.cast) into an HTML file and open it.

# SETTINGS
typeset -ga ASCIINEMA_RECORDINGS_WORK_LABELS
(( ${#ASCIINEMA_RECORDINGS_WORK_LABELS[@]} )) || ASCIINEMA_RECORDINGS_WORK_LABELS=(work grindstone company.com)
: "${ASCIINEMA_PLAYER_VERSION:=3.17.0}"
: "${ASCIINEMA_RECORDINGS_DIR_PERSONAL:=$HOME/Documents/Recordings/Personal}"
: "${ASCIINEMA_RECORDINGS_DIR_WORK:=$HOME/Documents/Recordings/Work}"

check_or_install_brew_command asciinema

# Default recording command
alias rec="asciinema rec --idle-time-limit 3 -c '$SHELL -l'"

# This `play` function converts an Asciinema recording file (.cast) into an HTML file that
# can be opened in a web browser using the Asciinema Player library loaded from CDN.
# Optionally, you can specify a target output file, otherwise it will create a temporary
# file.
function play() {
   local recording_file=$1
   local target=$2
   if [[ -z "$recording_file" ]]; then
      echo "Usage: $0 <file.cast> [output.html] [OPTIONS]" >&2
      echo "Options:" >&2
      echo "  --no-open: Do not open the generated HTML file automatically." >&2
      return
   elif [[ ! -f "$recording_file" ]]; then
      echo "File '$recording_file' not found." >&2
      return
   fi
   # Use directory of target, if provided, otherwise create a temporary directory
   local html_dir="$(dirname "$target")"
   [[ -z "$target" ]] && html_dir="$(mktemp -d)"
   # Use target filename if provided, otherwise derive from recording filename
   local html_file="$(basename "$target")"
   [[ -z "$html_file" ]] && html_file="$(basename "$recording_file" .cast).html"
   local html_path="$html_dir/$html_file"
   echo "
      <html>
      <head>
         <style>body {background-color: #121314;}</style>
         <link rel='stylesheet' type='text/css' href='https://cdn.jsdelivr.net/npm/asciinema-player@$ASCIINEMA_PLAYER_VERSION/dist/bundle/asciinema-player.css' />
      </head>
      <body>
         <div id='recording'></div>
         <script src='https://cdn.jsdelivr.net/npm/asciinema-player@$ASCIINEMA_PLAYER_VERSION/dist/bundle/asciinema-player.min.js'></script>
         <script>
            const player = AsciinemaPlayer.create(
               'data:text/plain;base64,$(base64 -i "$recording_file")',
               document.getElementById('recording'),
               { fit: 'both' }
            );
            player.play();
         </script>
      </body>
      </html>
   " > "$html_path"
   [[ "$*" =~ "--no-open" ]] || open "$html_path"
}

# Receives a label and a command and all of its arguments. It will initiate an Asciinema recording that
# runs the command and saves the recording in a directory based on the label.
record_remote() {
   local label=$1
   local runner=$2
   shift 2

   local rec_dir="$ASCIINEMA_RECORDINGS_DIR_PERSONAL"
   for lbl in "${ASCIINEMA_RECORDINGS_WORK_LABELS[@]}"; do
      if [[ "$label" == *"$lbl"* ]]; then
         rec_dir="$ASCIINEMA_RECORDINGS_DIR_WORK"
         break
      fi
   done
   mkdir -p "$rec_dir"

   # Use the subdomain as a short label, unless it's a pdsh host list or an IP address
   local short_label="${label%%.*}"
   [[ "$label" == pdsh-* ]] && short_label="$label"
   [[ "$label" =~ '^([0-9]{1,3}\.){3}[0-9]{1,3}$' ]] && short_label="$label"
   local timestamp=$(date +"%Y-%m-%d-%H-%M-%S")
   local cast_file="$short_label-$timestamp-$USER.cast"
   local html_file="$short_label-$timestamp-$USER.html"

   local cmd_str
   printf -v cmd_str "%q " "$runner" "$@"

   local zsh_c_arg
   printf -v zsh_c_arg "%q" "$cmd_str"

   asciinema -q rec -i 1 -c "/bin/zsh -l -c $zsh_c_arg" "$rec_dir/$cast_file" && \
   play "$rec_dir/$cast_file" "$rec_dir/$html_file" --no-open
}

# SSH override that automatically records
ssh() {
   # Ask the OG ssh command for the hostname. Doing it this way benefits from ssh's own parsing
   # of the command, including ssh configs for hosts, and aliases.
   local target=$(command ssh -G "$@" 2>/dev/null | awk '$1 == "hostname" { print $2; exit }')
   [[ -z "$target" ]] && target="unknown"
   record_remote "$target" /usr/bin/ssh "$@"
}

# PDSH override that automatically records
pdsh() {
   # Check if the real pdsh is installed, and if not, install it first
   check_or_install_brew_command pdsh
   # Find the original host list from the `-w` argument
   local orig_host_list
   local i=1
   while (( i <= $# )); do
      if [[ "${@[i]}" == "-w" && $((i + 1)) -le $# ]]; then
         orig_host_list="${@[$((i + 1))]}"
         break
      fi
      ((i++))
   done
   # Use `ssh -G` to resolve each host in the list to its canonical hostname
   local clean_line
   local hosts=()
   while read -r line; do
      # Strip carriage returns and leading/trailing whitespace, and make a clean array of hosts
      clean_line=$(echo "$line" | tr -d '\r' | xargs)
      [[ -n "$clean_line" ]] && hosts+=("$clean_line")
   done < <(command pdsh -N -R exec -w "$orig_host_list" bash -c "ssh -G %h 2>/dev/null | awk '/^hostname / {print \$2}'")

   # Join the array elements to make a comma-delimited list of target hosts for the label
   local target=$(IFS=,; echo "${hosts[*]}")
   [[ -z "$target" ]] && target="unknown"
   record_remote "pdsh-$target" /opt/homebrew/bin/pdsh "$@"
}
