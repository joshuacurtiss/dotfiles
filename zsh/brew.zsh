#
# Ensure Homebrew is installed and up to date
#

# Find brew binary even if PATH is not initialized yet
find_brew_bin() {
   local candidates=(
      /opt/homebrew/bin/brew
      /usr/local/bin/brew
      /home/linuxbrew/.linuxbrew/bin/brew
   )
   local b
   for b in "${candidates[@]}"; do
      [[ -x "$b" ]] && echo "$b" && return 0
   done
   return 1
}

check_brew() {
   local no_eval=false
   [[ $* =~ --no-eval ]] && no_eval=true
   local brew_bin
   # If brew is find, set up the environment for it
   if brew_bin="$(find_brew_bin)"; then
      $no_eval || eval "$("$brew_bin" shellenv)";
      return 0
   fi
   # If brew is not found, install it
   echo "Homebrew is not installed. Installing now!" >&2
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
      echo "Homebrew installation failed." >&2
      return 1
   }
   # After installation, check for brew binary again
   brew_bin="$(find_brew_bin)" || {
      echo "Homebrew installed, but brew binary was not found." >&2
      return 1
   }
   # If you got here, set up the environment for the newly installed brew
   eval "$("$brew_bin" shellenv)"
}

function check_or_install_brew_command() {
   local cmd=$1
   if ! command -v "$cmd" &>/dev/null; then
      echo "The $cmd command is not installed. Installing now!" >&2
      shift
      check_brew --no-eval && brew install -y $@ "$cmd"
      # If the installation fails, exit the script
      if [[ $? -ne 0 ]]; then
         echo "Installation of $cmd failed." >&2
         return 1
      fi
   fi
   return 0
}

check_brew
