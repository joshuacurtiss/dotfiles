#
# Two commands: "suggest" and "explain" which use Ollama AI to generate and explain shell commands
#

# Configs
: "${SUGGEST_MODEL:=qwen2.5-coder:7b}"

check_or_install_brew_command ollama --cask

function wait_for_ollama() {
   verbose=false && [[ $* == *--verbose* ]] && verbose=true
   $verbose && echo -n 'Waiting for Ollama to be ready.'
   local allowed_attempts=30
   while ! ollama list &>/dev/null; do
      ((allowed_attempts--))
      if [[ $allowed_attempts -le 0 ]]; then
         $verbose && echo -n ' '
         echo 'Ollama did not start.' 2>/dev/null
         return 1
      fi
      $verbose && echo -n '.'
      sleep 1
   done
   $verbose && echo ' Ready!'
   return 0
}

function check_or_install_suggest_model() {
   if ! ollama list | grep -q "$SUGGEST_MODEL"; then
      # Ask the user if they want to download the model
      echo -n "Ollama model $SUGGEST_MODEL not found. Do you want to download it? [Y/n] "
      read -r response
      response=${response:-y}
      response=$(echo "${response:0:1}" | tr '[:upper:]' '[:lower:]')
      if [[ $response != "y" ]]; then
         echo "Model not downloaded."
         return 1
      fi
      ollama pull "$SUGGEST_MODEL"
   fi
}

SUGGEST_OS_NAME=$OSTYPE
[[ "$OSTYPE" == "linux-gnu"* ]] && SUGGEST_OS_NAME="Linux"
[[ "$OSTYPE" == "darwin"* ]] && SUGGEST_OS_NAME="macOS"

suggest() {
   wait_for_ollama || return 1
   check_or_install_suggest_model || return 1
   local bold=$(tput bold)
   local green=$(tput setaf 2)
   local norm=$(tput sgr0)
   local options_explanation="$bold'y'$norm: Run. $bold'n'$norm: Skip. $bold'a'$norm: Ask question. $bold'e'$norm: Explain the code."
   local options="Y/n/a/e"
   local cmd
   local highlighted_cmd
   local response
   if command -v pbcopy &>/dev/null; then
      options_explanation="$options_explanation $bold'c'$norm: Copy to clipboard."
      options="$options/c"
   fi
   cmd=$(
      ollama run --hidethinking --keepalive 1m $SUGGEST_MODEL \
         "You are a program that outputs $SHELL code that satisfies the requirements \
         given in natural language. Assume the user is running $SHELL on \
         $SUGGEST_OS_NAME. Use any builtin commands. Additionally, here are all of the \
         custom commands installed and available to you: \
         $(brew list -l | awk '{print $9}') \
         IMPORTANT: Do not make up fake commands or parameters. The command should run \
         in one line, so if you have multiple commands, separate them with '&&' or ';'. \
         You will output $SHELL code only, with no intro text or formatting. DO NOT wrap \
         the output with backticks. Example requirements: \"List all files and folders \
         in the current folder.\" Example output: ls -a  Here are your requirements: \
         $*   Output:"
   )
   highlighted_cmd="$bold$green$cmd$norm"
   echo "This is my suggestion. Always review before running suggested code."
   echo "$options_explanation\n\n$highlighted_cmd\n"
   while true; do
      echo -n "Run this command? [$options] "
      read -r response
      response=${response:-y}
      response=$(echo "${response:0:1}" | tr '[:upper:]' '[:lower:]')
      case "$response" in
         y) echo "$highlighted_cmd" ; eval "$cmd" ; break ;;
         a) suggest_clarification "$cmd" ;;
         c) echo -n "$cmd" | pbcopy && echo "Copied \"$highlighted_cmd\" to clipboard." ; break ;;
         e) explain "$cmd" ;;
         n) echo "Command not run." ; break ;;
         *) echo "Invalid option. $options_explanation" ;;
      esac
   done
}

suggest_clarification() {
   wait_for_ollama || return 1
   check_or_install_suggest_model || return 1
   local question
   echo -n "What is your question? "
   read -r question
   question=${question:-"What exactly does this command do, and how does it work"}
   ollama run $SUGGEST_MODEL \
      "You have provided the following command as a suggested command to run:

      $1

      I have a question about this command. $question? Assume the command will run in \
      $SHELL on $SUGGEST_OS_NAME, but you do not need to mention that explicitly. \
      IMPORTANT: DO NOT USE MARKDOWN. Use plain text. Also, use concise language."
}

explain() {
   wait_for_ollama || return 1
   check_or_install_suggest_model || return 1
   ollama run $SUGGEST_MODEL \
      "Explain the following shell statements. Assume the user is running $SHELL on \
      $SUGGEST_OS_NAME, but you do not need to mention that explicitly. IMPORTANT: DO NOT \
      USE MARKDOWN. Use plain text. Also, use concise language. Statement: $*"
}
