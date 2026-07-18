#
# Git Aliases
#

alias fixup='git commit --fixup'
alias fetch='git fetch -t -p -P'

# Returns if the current directory is inside a Git repository
inside_git_repo() {
   git rev-parse --is-inside-work-tree &>/dev/null
}

# Returns the current Git branch name
current_git_branch() {
   git symbolic-ref --quiet --short HEAD 2>/dev/null
}

# Returns the repo's default branch name
default_git_branch() {
   inside_git_repo || return 1
   # Get the remote HEAD reference (i.e. `refs/remotes/origin/HEAD`)
   local remote_head_ref branch remote_name
   remote_head_ref=$(git for-each-ref --format='%(refname)' 'refs/remotes/*/HEAD' | head -n 1)
   # If found, get the branch name from the remote HEAD reference (i.e. `origin/main` -> `main`)
   if [[ -n $remote_head_ref ]]; then
      branch=$(git symbolic-ref --quiet --short "$remote_head_ref" 2>/dev/null)
      branch=${branch#*/}
      [[ -n $branch ]] && echo "$branch" && return 0
   fi
   # If not found, get the first remote and find its default branch
   remote_name=$(git remote | head -n 1)
   [[ -z $remote_name ]] && return 1
   # Get its branch name from the remote HEAD reference (i.e. `origin/main` -> `main`)
   branch=$(git symbolic-ref --quiet --short "refs/remotes/${remote_name}/HEAD" 2>/dev/null)
   branch=${branch#*/}
   [[ -n $branch ]] && echo "$branch" && return 0
}

# Returns if current and default branches are the same
on_default_git_branch() {
   inside_git_repo || return 1
   local current_branch default_branch
   current_branch=$(current_git_branch)
   default_branch=$(default_git_branch)
   [[ -n $current_branch && -n $default_branch && $current_branch == $default_branch ]]
}

# Returns the commit hash where the current local branch diverges from the default branch
diverging_commit() {
   # Ensure we are inside a Git repository
   inside_git_repo || return 1
   # Find the repo's default remote
   local remote
   remote=$(git for-each-ref --format='%(refname:short)' 'refs/remotes/*/HEAD' | head -n 1)
   [[ -z $remote ]] && remote=$(git remote | head -n 1)
   # Calculate and return the commit hash where the current local branch diverges
   # Note by passing the remote, its default branch is used for the comparison
   git merge-base HEAD "$remote"
}

# Autosquash on provided hash. If they don't provide one, auto-calculate where to start:
#   - If on the default branch, use the root commit of the default branch
#   - Otherwise, use the commit where the current branch diverges from the default branch
autosquash() {
   inside_git_repo || { echo "Error: Not a git repository." >&2; return 1; }
   # First, use the hash provided as an argument
   local hash short_hash orig_hash
   for arg in "$@"; do
      [[ $arg != -* ]] && hash=$arg && orig_hash=$arg && break
   done
   # Options
   local dry_run=false
   local verbose=false
   local interactive=false
   [[ $* == *--dry-run* || $* == *-n* ]] && dry_run=true
   [[ $* == *-v* || $* == *--verbose* ]] && verbose=true
   [[ $* == *-i* || $* == *--interactive* ]] && interactive=true
   # If no hash is provided, use root commit on default branch; diverging commit on other branches.
   if [[ -z $hash ]]; then
      if on_default_git_branch; then
         $verbose && echo "No commit hash provided. Using root commit of default branch."
         hash=$(git rev-list --max-parents=0 HEAD)
      else
         $verbose && echo "No commit hash provided. Using diverging commit from default branch."
         hash=$(diverging_commit)
      fi
   else
      $verbose && echo "You provided commit hash: $hash"
   fi
   # If still not found, use the root commit hash of the current branch
   if [[ -z $hash ]]; then
      $verbose && echo "Still no hash was found. Using root commit of current branch."
      hash=$(git rev-list --max-parents=0 HEAD)
   fi
   [[ -z $hash ]] && echo "No commit hash provided and no root commit found." >&2 && return 1
   # Use short hash for display, unless they provided it as an argument
   short_hash=${hash:0:7}
   [[ $hash == $orig_hash ]] && short_hash=$orig_hash
   echo "Autosquashing commits since $short_hash."
   if $dry_run; then
      echo "Dry run! No action taken."
   else
      local params=(--autosquash)
      $interactive && params+=(-i)
      git rebase "${params[@]}" "$hash"
   fi
}
