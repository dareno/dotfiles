# ============================================================================
# Minimal .zshrc for David Reno
# Clean, fast, and functional terminal environment
# ============================================================================

# ----------------------------------------------------------------------------
# Core Shell Configuration
# ----------------------------------------------------------------------------

## History settings

HISTSIZE=10000
SAVEHIST=10000
export HISTFILE=$ZDOTDIR/.zsh_history

## History behavior

setopt APPEND_HISTORY       # Append to history file, don't overwrite
setopt INC_APPEND_HISTORY   # Write commands immediately after execution
unsetopt SHARE_HISTORY      # Avoid cross-window history races/confusion

setopt HIST_IGNORE_DUPS     # Don't record consecutive duplicate entries
setopt HIST_IGNORE_SPACE    # Don't record commands starting with space
setopt HIST_VERIFY          # Show history expansion before running
setopt HIST_REDUCE_BLANKS   # Remove superfluous whitespace from commands

# Directory navigation
setopt AUTO_CD               # Change directory without 'cd'
setopt AUTO_PUSHD            # Push directories to stack automatically
setopt PUSHD_IGNORE_DUPS     # Don't push duplicate directories

# Completion behavior
setopt COMPLETE_IN_WORD      # Allow completion in middle of word
setopt ALWAYS_TO_END         # Move cursor to end after completion

# Enable comments in interactive zsh (chat LLMs like to comment)
setopt interactivecomments

# OpenSpec shell completions configuration
fpath=("/Users/dreno200/.zsh/completions" $fpath)

# ----------------------------------------------------------------------------
# Shell Completion
# ----------------------------------------------------------------------------

# Initialize completion system (fast, cached)
autoload -Uz compinit
ZCD="${ZDOTDIR:-$HOME}/.zcompdump"
if [[ ! -f $ZCD ]]; then
  compinit -d "$ZCD"
else
  compinit -C -d "$ZCD"
fi

# Completion styling
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'  # Case insensitive
zstyle ':completion:*' list-colors ''  # Use LS_COLORS for file completion

# ----------------------------------------------------------------------------
# Environment Variables & Paths
# ----------------------------------------------------------------------------

# Keep path/fpath unique to avoid duplicates
typeset -U path fpath

# Helper to prepend to PATH if directory exists and isn't already present
path_prepend() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  case ":$PATH:" in (*":$dir:"*) ;; (*) PATH="$dir:$PATH" ;; esac
}

# Add local bin to PATH if it exists
[[ -d "$HOME/.local/bin" ]] && path_prepend "$HOME/.local/bin"

# Common exports
export EDITOR="windsurf"  # Change to your preferred editor
export CLICOLOR=1

# ----------------------------------------------------------------------------
# OS detection and per-OS config
# ----------------------------------------------------------------------------
case "$OSTYPE" in
  darwin*)   OS_FAMILY="macos" ;;
  linux-gnu*) OS_FAMILY="linux" ;;
  *)         OS_FAMILY="other" ;;
esac
export OS_FAMILY

if [[ $OS_FAMILY == macos ]]; then
  # Homebrew (mac only; ignore on Linux)
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  # macOS defaults
  alias ls='ls -G'
  export BROWSER=open
  alias open='open'

  # Rancher Desktop CLI and Docker socket
  [[ -S "$HOME/.rd/docker.sock" ]] && export DOCKER_HOST="unix://$HOME/.rd/docker.sock"
  [[ -d "$HOME/.rd/bin" ]] && path_prepend "$HOME/.rd/bin"

  # Override system Go (from /etc/paths.d/go) with Homebrew Go
  [[ -d "/opt/homebrew/bin" ]] && path_prepend "/opt/homebrew/bin"

elif [[ $OS_FAMILY == linux ]]; then
  # Linux defaults
  alias ls='ls --color=auto'
  export BROWSER=xdg-open
  alias open='xdg-open'

  # Clipboard shims for pbcopy/pbpaste
  if ! command -v pbcopy >/dev/null 2>&1; then
    if command -v xclip >/dev/null 2>&1; then
      alias pbcopy='xclip -selection clipboard'
      alias pbpaste='xclip -selection clipboard -o'
    elif command -v wl-copy >/dev/null 2>&1; then
      alias pbcopy='wl-copy'
      alias pbpaste='wl-paste'
    fi
  fi
fi

# Optional: common toolchains
[[ -d "$HOME/.cargo/bin" ]] && path_prepend "$HOME/.cargo/bin"
[[ -d "$HOME/go/bin" ]] && path_prepend "$HOME/go/bin"

# PostgreSQL client tools
[[ -d "/opt/homebrew/opt/postgresql@17/bin" ]] && path_prepend "/opt/homebrew/opt/postgresql@17/bin"

# ----------------------------------------------------------------------------
# Fuzzy Finder (fzf)
# ----------------------------------------------------------------------------
# Source fzf key bindings and completion (if installed)
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# fzf configuration
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
if command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow \
    --exclude .git --exclude node_modules --exclude venv --exclude __pycache__ \
    --exclude build --exclude dist"
else
  export FZF_DEFAULT_COMMAND="find . -type f -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/venv/*' -not -path '*/__pycache__/*' -not -path '*/build/*' -not -path '*/dist/*' -not -path '*/.DS_Store' -not -path '*/.Trash/*' 2>/dev/null"
fi
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# ----------------------------------------------------------------------------
# Prompt (Starship)
# ----------------------------------------------------------------------------

# Initialize starship prompt
# Conditionally initialize Starship prompt
if [[ "$TERM_PROGRAM" != "vscode" ]] && command -v starship >/dev/null 2>&1; then
  # Initialize Starship for non-VS Code/Windsurf terminals
  eval "$(starship init zsh)"
fi


# Simple function to reset Starship and restore default zsh prompt
noprompt() {
  unfunction precmd preexec prompt_starship_setup 2>/dev/null
  PROMPT='%n@%m %~ %# '
  RPROMPT=''
  echo "Switched to default zsh prompt for this session"
}

# ----------------------------------------------------------------------------
# Optional Tool Hooks (Commented Out - Enable as Needed)
# ----------------------------------------------------------------------------

# Node Version Manager (nvm)
export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"

# Python Environment Manager (pyenv)
# NOTE: For login shells, pyenv also recommends `eval "$(pyenv init --path)"` in ~/.zprofile.

# export PYENV_REHASH_TIMEOUT=1
# export PYENV_ROOT="$HOME/.pyenv"
# [[ -d "$PYENV_ROOT/bin" ]] && path_prepend "$PYENV_ROOT/bin"
# if command -v pyenv >/dev/null 2>&1; then
#   eval "$(pyenv init - zsh)"
# fi

# Python Virtual Environment Wrapper
# export WORKON_HOME="$HOME/.virtualenvs"
# [[ -f /usr/local/bin/virtualenvwrapper.sh ]] && source /usr/local/bin/virtualenvwrapper.sh

# Ruby Version Manager (rbenv)
# eval "$(rbenv init - zsh)"

# ----------------------------------------------------------------------------
# Aliases
# ----------------------------------------------------------------------------

# Better defaults
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Git shortcuts (if you use git)
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline -n 10 --graph'

# dotfile backup (uses ~/.config/dotignore)
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME -c core.excludesFile=$HOME/.config/dotignore'


# Utility
if echo | grep --color=auto "" >/dev/null 2>&1; then
  alias grep='grep --color=auto'
fi
alias mkdir='mkdir -p'  # Create parent directories as needed
alias h='history'
alias c='clear'
alias rsyncp='rsync -a' # rsync archive (no verbose file listing, just final summary)
alias cal='cal -3'

# ----------------------------------------------------------------------------
# Custom Functions
# ----------------------------------------------------------------------------

# Quick directory creation and navigation
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Find and edit files quickly with fzf (if available)
fe() {
    local file
    if [[ $# -eq 0 ]]; then
        # No arguments: open fzf to browse and select
        file=$(fzf --preview 'head -100 {}') && ${EDITOR:-code} "$file"
    else
        # With arguments: use as initial query, auto-select if only one match
        file=$(fzf --preview 'head -100 {}' --query "$*" --select-1 --exit-0)
        [[ -n $file ]] && ${EDITOR:-code} "$file"
    fi
}




# Interactive selection of recent files with fzf and open in VS Code (Recent EDit)


# Shared: Get default exclude patterns
_recent_exclude_patterns() {
  echo \
    .cfg \
    node_modules \
    venv \
    __pycache__ \
    build \
    dist \
    .DS_Store \
    .Trash \
    '.sync_*' \
    Library \
    site-packages \
    uv-env \
    '*mypy*' \
    .smartclient \
    .docker \
    .cache \
    Downloads \
    .local \
    '*_history*'
}

# Shared: Build fd exclude args from patterns
_recent_fd_exclude_args() {
  local patterns=("$@")
  local args=()
  for pattern in "${patterns[@]}"; do
    args+=(--exclude "$pattern")
  done
  echo "${args[@]}"
}

# Shared: List files sorted by mtime, with excludes
_recent_file_list() {
  local fd_exclude_args=("$@")
  local stat_cmd
  if stat --version >/dev/null 2>&1; then
    stat_cmd=(stat -c '%Y|||%n')   # GNU (Linux): epoch|||path
  else
    stat_cmd=(stat -f '%m|||%Sm|||%N')  # BSD (macOS)
  fi
  if [[ $OS_FAMILY == linux ]]; then
    fd --type f --hidden -0 "${fd_exclude_args[@]}" . \
      | xargs -0 "${stat_cmd[@]}" 2>/dev/null \
      | sort -nr \
      | awk -F '\\|\\|\\|' '{ epoch=$1; path=$2; cmd=sprintf("date -d @%s +\"%b %e %T %Y\"", epoch); cmd | getline human; close(cmd); printf "%s %s\n", human, path }'
  else
    fd --type f --hidden -0 "${fd_exclude_args[@]}" . \
      | xargs -0 "${stat_cmd[@]}" 2>/dev/null \
      | sort -nr \
      | awk -F '\\|\\|\\|' '{print $2 " " $3}'
  fi
}

# Interactive selection of recent files with fzf and open in VS Code (Recent EDit)
red() {
  # Usage: red [additional-exclude-pattern ...]
  if ! command -v fd >/dev/null 2>&1; then
    echo "[red] Error: fd is not installed. Please install fd to use this function." >&2
    return 1
  fi
  local MAX_FILES=200000
  local EXCLUDE_PATTERNS=($(_recent_exclude_patterns))
  if [[ $# -gt 0 ]]; then
    EXCLUDE_PATTERNS+=("$@")
  fi
  local fd_exclude_args=($(_recent_fd_exclude_args "${EXCLUDE_PATTERNS[@]}"))
  local file_count
  file_count=$(fd --type f --hidden "${fd_exclude_args[@]}" . | wc -l)
  if (( file_count > MAX_FILES )); then
    echo "[red] Warning: $file_count files found. This may be slow. Consider narrowing your search."
    echo -n "Continue anyway? [y/N]: "
    read user_response
    [[ $user_response =~ ^[Yy]$ ]] || return 1
  fi
  local preview_script='
    file_path=$(echo {} | sed -E "s/^[A-Za-z]+ [0-9]+ [0-9]+:[0-9]+:[0-9]+ [0-9]+ //");
    if [[ -f "$file_path" ]]; then
      if file --mime "$file_path" | grep -q "inode/x-empty"; then
        echo "[empty file]"
      elif file --mime "$file_path" | grep -q text; then
        cat "$file_path"
      else
        echo "[binary file]"
      fi
    fi
  '
  local selection file_path
  selection=$(_recent_file_list "${fd_exclude_args[@]}" | fzf --ansi --preview "$preview_script")
  if [[ -n "$selection" ]]; then
    file_path=$(echo "$selection" | sed -E "s/^[A-Za-z]+ [0-9]+ [0-9]+:[0-9]+:[0-9]+ [0-9]+ //")
    ${EDITOR:-code} "$file_path"
  else
    echo "No file selected."
  fi
}


# Display n most recent files, with excludes and fd for performance
recent() {
  # Usage: recent [count] [additional-exclude-pattern ...]
  local count=20
  if [[ $# -gt 0 && $1 =~ ^[0-9]+$ ]]; then
    count=$1
    shift
  fi
  local EXCLUDE_PATTERNS=($(_recent_exclude_patterns))
  if [[ $# -gt 0 ]]; then
    EXCLUDE_PATTERNS+=("$@")
  fi
  local fd_exclude_args=($(_recent_fd_exclude_args "${EXCLUDE_PATTERNS[@]}"))
  _recent_file_list "${fd_exclude_args[@]}" | head -n $count
}


# Delete local branches that have been merged or whose PR is closed/merged.
# Checks merge status against origin/$base (not local $base) so a stale local
# main branch doesn't cause merged branches to be silently skipped.
#
# Usage: git-cleanup-merged [base-branch] [--dry-run]
#   base-branch  default: main
#   --dry-run    print what would be deleted without deleting anything
git-cleanup-merged() {
  local base=${1:-main}
  local dry_run=false
  [[ "${2}" == "--dry-run" ]] && dry_run=true

  # gh is required to look up PR state for branches not reachable from $base
  if ! command -v gh &>/dev/null; then
    echo "error: gh is not installed. Install it from https://cli.github.com/" >&2
    return 1
  fi
  if ! gh repo view &>/dev/null; then
    echo "error: gh cannot access the current repo. Run 'gh auth login' or check your token." >&2
    return 1
  fi

  # Sync remote tracking refs and remove refs for deleted remote branches
  git fetch --prune

  local branch
  # Read branch names without word-splitting; --format avoids the leading '*' on current branch
  while IFS= read -r branch; do
    [[ "$branch" == "$base" ]] && continue

    # Check reachability against origin/$base, not local $base.
    # Local $base may lag behind the remote even after fetch; origin/$base is current.
    if git merge-base --is-ancestor "$branch" "origin/$base" 2>/dev/null; then
      echo "merged:              $branch"
      [[ "$dry_run" == false ]] && git branch -d "$branch"
      continue
    fi

    # Branch is not in origin/$base's history — look up its PR state
    local pr_state
    if ! pr_state=$(gh pr list --head "$branch" --state all \
        --json state --jq '.[0].state' 2>/dev/null); then
      echo "gh error (skipping): $branch" >&2
      continue
    fi

    case "$pr_state" in
      MERGED)
        # PR was merged via squash/rebase — the branch commit isn't an ancestor
        # of $base but the work is already in, so force-delete is correct.
        echo "merged (via PR):     $branch"
        [[ "$dry_run" == false ]] && git branch -D "$branch"
        ;;
      CLOSED)
        # PR was closed without merging — leave the branch alone in case the
        # work needs to be revisited.
        echo "closed, not merged (skipping): $branch"
        ;;
      OPEN)
        echo "open PR (skipping):  $branch"
        ;;
      null|"")
        # jq returns the string "null" when the array is empty (no PR found)
        echo "no PR found (skipping): $branch"
        ;;
      *)
        echo "unknown state '$pr_state' (skipping): $branch"
        ;;
    esac
  done < <(git branch --format='%(refname:short)')
}

# Stopwatch: prints HH:MM:SS, Ctrl+C to stop
stopwatch() {
  emulate -L zsh
  trap 'print; return' INT TERM
  SECONDS=0
  while true; do
    printf "\r%02d:%02d:%02d" $((SECONDS/3600)) $((SECONDS%3600/60)) $((SECONDS%60))
    sleep 1
  done
}
# ----------------------------------------------------------------------------
# Local Customizations
# ----------------------------------------------------------------------------

# Source local customizations if they exist
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# Added by Windsurf
export PATH="$HOME/.codeium/windsurf/bin:$PATH"

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="$HOME/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

# Final PATH de-duplication (ensures no duplicate entries remain)
path=($path)
