# ============================================================================
# Minimal .zshrc for David Reno
# Clean, fast, and functional terminal environment
# ============================================================================

# ----------------------------------------------------------------------------
# Core Shell Configuration
# ----------------------------------------------------------------------------

# History settings
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

# History options
setopt HIST_IGNORE_DUPS      # Don't record duplicate entries
setopt HIST_IGNORE_SPACE     # Don't record entries starting with space
setopt HIST_VERIFY           # Show command with history expansion before running
setopt SHARE_HISTORY         # Share history across sessions
setopt APPEND_HISTORY        # Append to history file
setopt INC_APPEND_HISTORY    # Write to history file immediately

# Directory navigation
setopt AUTO_CD               # Change directory without 'cd'
setopt AUTO_PUSHD            # Push directories to stack automatically
setopt PUSHD_IGNORE_DUPS     # Don't push duplicate directories

# Completion behavior
setopt COMPLETE_IN_WORD      # Allow completion in middle of word
setopt ALWAYS_TO_END         # Move cursor to end after completion

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
export EDITOR="code"  # Change to your preferred editor
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

  # Rancher Desktop Docker socket
  [[ -S "$HOME/.rd/docker.sock" ]] && export DOCKER_HOST="unix://$HOME/.rd/docker.sock"

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
# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Python Environment Manager (pyenv)
# export PYENV_ROOT="$HOME/.pyenv"
# [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
# eval "$(pyenv init -)"

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
alias gl='git log --oneline'

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

# Experimental: Highly readable version of 'red' for testing




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
