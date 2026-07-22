#
# nvm support
#

# Configs
: "${NVM_INSTALL_VERSION:=0.40.6}"

export NVM_DIR="$HOME/.nvm"

# Install nvm if it's not already installed
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
   # We use PROFILE=/dev/null to prevent the nvm install script from modifying the user's shell profiles.
   # We will handle that ourselves with this script.
   PROFILE=/dev/null bash -c "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v$NVM_INSTALL_VERSION/install.sh | bash"
fi

# Standard nvm initialization
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

nvm_hook() {
   # If a .nvmrc file exists in the current directory, use the specified Node.js version.
   if [ -f ".nvmrc" ]; then
      nvm use || nvm install
   fi
}

# Execute nvm anytime we change directories
command -v add-zsh-hook &>/dev/null && add-zsh-hook chpwd nvm_hook

# Run nvm on initial shell load
nvm_hook
