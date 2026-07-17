# Josh's Dotfiles and Client Setup

This repo will hold all of my scripts and tooling for setting up my environment.

## Setup

Check out this repo somewhere. I usually check it out at `~/proj/joshuacurtiss/dotfiles`,
but you can change that path accordingly.

```bash
mkdir -p ~/proj/joshuacurtiss && cd ~/proj/joshuacurtiss && \
git clone git@github.com:joshuacurtiss/dotfiles.git
```

Then add this to the top of `~/.zprofile`:

```bash
# Configs
# ... set any configurations you need to customize...

# Josh's Dotfiles
source ~/proj/joshuacurtiss/dotfiles/zsh/index.zsh
```
