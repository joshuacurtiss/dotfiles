# Josh's Dotfiles and Client Setup

This repo will hold all of my scripts and tooling for setting up my environment.

## Setup

Run the installer directly from GitHub:

```sh
/bin/zsh -c "$(curl -fsSL https://raw.githubusercontent.com/joshuacurtiss/dotfiles/HEAD/install.sh)" </dev/tty >/dev/tty 2>&1
```

The installer clones this repo to your user directory at `~/.dotfiles` by default. You can
override that with `DOTFILES_DIR=/some/path` and optionally set `DOTFILES_REPO_URL` or
`DOTFILES_BRANCH` if you need a different source or branch.

It will add the shell source line to the end of the first existing zsh profile file it
finds, preferring `~/.zprofile` and falling back to `~/.zshrc` or `~/.zlogin` if needed.

If you prefer to set things up manually, add this to the top of your profile file:

```sh
source ~/your/path/to/dotfiles/zsh/index.zsh
```

## Local Development

If you want to try rerunning the installer from your local checkout instead of downloading
from GitHub again, you can go to your local checkout and running it like this:

```sh
DOTFILES_DIR="$PWD" DOTFILES_BRANCH="$(git rev-parse --abbrev-ref HEAD)" ./install.sh
```
