#!/usr/bin/env zsh
#shellcheck shell=bash

REPO_URL="${DOTFILES_REPO_URL:-https://github.com/joshuacurtiss/dotfiles.git}"
REPO_BRANCH="${DOTFILES_BRANCH:-main}"
REPO_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
PROFILE_CANDIDATES=("$HOME/.zprofile" "$HOME/.zshrc" "$HOME/.zlogin")

# Borrowing from brew.zsh:
find_brew_bin() {
   local candidates=(
      /opt/homebrew/bin/brew
      /usr/local/bin/brew
      /home/linuxbrew/.linuxbrew/bin/brew
   )
   local candidate
   for candidate in "${candidates[@]}"; do
      [[ -x "$candidate" ]] && printf '%s\n' "$candidate" && return 0
   done
   return 1
}

# Borrowing from brew.zsh:
check_brew() {
   local brew_bin
   # If brew is find, set up the environment for it
   if brew_bin="$(find_brew_bin)"; then
      eval "$("$brew_bin" shellenv)"
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

check_git() {
   if ! command -v git &>/dev/null; then
      echo "git is not available after Homebrew setup. Aborting." >&2
      return 1
   fi
}

clone_or_update_repo() {
   # If the repo already exists, update it
   if [[ -d "$REPO_DIR/.git" ]]; then
      if ! git -C "$REPO_DIR" fetch origin "$REPO_BRANCH"; then
         echo "Failed to fetch latest dotfiles." >&2
         return 1
      fi
      if ! git -C "$REPO_DIR" checkout "$REPO_BRANCH"; then
         echo "Failed to checkout branch: $REPO_BRANCH" >&2
         return 1
      fi
      if ! git -C "$REPO_DIR" pull --ff-only origin "$REPO_BRANCH"; then
         echo "Failed to update dotfiles repository." >&2
         return 1
      fi
      return 0
   fi
   # Abort if the destination exists but is not a git repository
   if [[ -e "$REPO_DIR" ]]; then
      echo "Destination exists but is not a git repository: $REPO_DIR" >&2
      return 1
   fi
   # Otherwise, proceed with cloning the repository
   mkdir -p "$(dirname "$REPO_DIR")"
   if ! git clone --branch "$REPO_BRANCH" "$REPO_URL" "$REPO_DIR"; then
      echo "Failed to clone dotfiles repository." >&2
      return 1
   fi
}

choose_profile_file() {
   local candidate
   for candidate in "${PROFILE_CANDIDATES[@]}"; do
      if [[ -f "$candidate" ]]; then
         printf '%s\n' "$candidate"
         return 0
      fi
   done
   printf '%s\n' "$HOME/.zprofile"
}

check_profile_source_line() {
   local profile_file="$1"
   local source_line="source $REPO_DIR/zsh/"
   local candidate
   # Check if the source line is already present in any of the profile candidates
   for candidate in "${PROFILE_CANDIDATES[@]}"; do
      [[ -f "$candidate" ]] && grep -Fq "$source_line" "$candidate" && return 0
   done
   return 1
}

write_profile_source_line() {
   [[ -n ${ZSH_VERSION-} ]] && setopt localoptions ksharrays
   local profile_file="$1"
   local source_line_base="source $REPO_DIR/zsh"
   local dotfile_ext='.zsh'

   # Get dotfiles directory
   local dotfiles_dir="$REPO_DIR/zsh"
   if [[ ! -d "$dotfiles_dir" ]]; then
      echo "Dotfiles directory not found: $dotfiles_dir" >&2
      return 1
   fi

   # Get the desired dotfiles to source from the user
   local selected_dotfiles=()
   while [[ ${#selected_dotfiles[@]} -eq 0 ]]; do
      echo
      if yorn "Do you want to install all the dotfiles?"; then
         selected_dotfiles+=(index)
      else
         local index
         local selected_indices=()
         # Find all dotfiles in the directory, excluding index
         local dotfiles=()
         while IFS= read -r -d $'\0' file; do
            basefilename="$(basename "$file" "$dotfile_ext")"
            [[ $basefilename == index ]] && continue
            [[ $basefilename == brew ]] && continue
            dotfiles+=("$basefilename")
         done < <(find "$dotfiles_dir" -maxdepth 1 -type f -name "*$dotfile_ext" -print0 | sort -z)
         # Warn user about specific dotfile selection
         echo
         echo "Warning: By selecting specific dotfiles, you won't get future added dotfiles"
         echo "unless you manually add them to your profile file later."
         echo
         echo "Brew is always included automatically."
         echo
         # Prompt the user with the multi-select menu
         echo 'Please select the dotfiles you want to install:'
         selected_indices=($(multi_select_menu "${dotfiles[@]}"))
         # If selection is not empty, always add "brew" first
         [[ ${#selected_indices[@]} -gt 0 ]] && selected_dotfiles+=(brew)
         for index in "${selected_indices[@]}"; do
            selected_dotfiles+=("${dotfiles[index]}")
         done
      fi
   done

   # Write the source line(s) to the profile file
   [[ ! -f "$profile_file" ]] && echo "# Profile for $USER" > "$profile_file"
   {
      echo
      echo "# Josh's dotfiles:"
      for dotfile in "${selected_dotfiles[@]}"; do
         echo "$source_line_base/$dotfile$dotfile_ext"
      done
   } >> "$profile_file"
}

# Asks a yes/no question and returns 0 for 'yes' and 1 for 'no'. If the user does not
# provide a response, it uses the default value.
# $1: The question to ask
# $2: The default answer (optional, default is 'y')
function yorn() {
   local question=$1
   local default=${2:-y}
   while true; do
      echo -n "$question " >&2
      [[ $default =~ [Yy] ]] && echo -n "[Y/n]: " >&2 || echo -n "[y/N]: " >&2
      read -r response
      [[ -z $response ]] && response=$default
      response=$(echo "${response:0:1}" | tr '[:upper:]' '[:lower:]')
      if [[ $response == y ]]; then
         return 0
      elif [[ $response == n ]]; then
         return 1
      else
         echo "Please answer 'y' or 'n'." >&2
      fi
   done
}

# Multi-select menu in pure bash/zsh
multi_select_menu() {
   local is_zsh=0
   [[ -n ${ZSH_VERSION-} ]] && is_zsh=1
   local cursor=0
   local key
   local key_tail
   local options=("$@")
   local selected=()

   if (( is_zsh )); then
      setopt localoptions ksharrays
   fi

   # Find the length of the longest option, set selections to false, and count the number
   # of lines in the menu, while prepping the menu for those lines.
   local maxlen=0
   local menu_lines=1
   for ((i=0; i<${#options[@]}; i++)); do
      (( menu_lines++ ))
      (( ${#options[i]} > maxlen )) && maxlen=${#options[i]}
      selected[i]=false
      echo >&2
   done
   local padlen=$((maxlen + 7))

   tput cuu $menu_lines >&2 && tput sc >&2 && tput civis >&2
   while true; do
      tput rc >&2
      for ((i=0; i<${#options[@]}; i++)); do
         tput el >&2
         box=○ && ${selected[i]} && box=◉
         # shellcheck disable=SC2059
         printf -v line "%-*s" "$padlen" " $box ${options[i]}"
         ((cursor==i)) && tput setab 4 >&2 && tput setaf 7 >&2
         echo "$line" >&2
         tput sgr0 >&2
      done
      tput dim >&2
      echo "Use ↑/↓ to move, SPACE to select/deselect, ENTER to confirm." >&2
      tput sgr0 >&2

      # Read key
      if (( is_zsh )); then
         IFS= read -rsk1 key
      else
         IFS= read -rsn1 key
      fi
      if [[ $key == $'\x1b' ]]; then
         if (( is_zsh )); then
            IFS= read -rsk2 key_tail
         else
            IFS= read -rsn2 key_tail
         fi
         key+=$key_tail
         if [[ $key == $'\x1b[A' ]]; then
            ((cursor--))
            ((cursor<0)) && cursor=$((${#options[@]}-1))
         elif [[ $key == $'\x1b[B' ]]; then
            ((cursor++))
            ((cursor>=${#options[@]})) && cursor=0
         fi
      elif [[ $key == " " ]]; then
         if ${selected[cursor]}; then selected[cursor]=false; else selected[cursor]=true; fi
      elif [[ $key == "" || $key == $'\n' || $key == $'\r' ]]; then
         break
      fi
   done

   # Show cursor
   tput cnorm >&2

   # Collect selected items
   local result=()
   for ((i=0; i<${#selected[@]}; i++)); do
      ${selected[i]} && result+=("$i")
   done
   echo "${result[@]}"
}

main() {
   echo 'The first thing I do is check for Homebrew and install it if it is not present.'
   echo 'So, I may ask for your password as part of installing Homebrew.'
   check_brew || return 1
   check_git || return 1
   clone_or_update_repo || return 1
   local profile_file
   profile_file="$(choose_profile_file)"
   check_profile_source_line "$profile_file" || write_profile_source_line "$profile_file"
   echo
   echo 'Sourcing your profile now will initiate the rest of the setup process.'
   if yorn "Is it okay to source your $profile_file file now?"; then
      # shellcheck source=/dev/null
      source "$profile_file"
   fi
   echo 'Setup complete! Open a new terminal session for changes to take effect, or'
   echo 'source your profile file yourself like this:'
   echo
   echo "  source $profile_file"
   echo
}

main "$@"
