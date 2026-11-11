# /opt/discover + /opt/penelope exist only if a role that includes them was
# installed (see manifest/extra.yml dests); adding them to PATH is harmless if not.
export PATH="$PATH:/usr/local/bin:/opt/discover:/opt/penelope"
alias ls='ls --color=auto'
alias bat='batcat'
alias fd='fdfind'
# Editor: nano unless setup picked vim (~/.config/hemo/editor). vi/vim open Neovim.
if [ "$(cat ~/.config/hemo/editor 2>/dev/null)" = vim ] && command -v nvim >/dev/null; then
  export EDITOR=nvim VISUAL=nvim
else
  export EDITOR=nano VISUAL=nano
fi
command -v nvim >/dev/null && alias vi=nvim vim=nvim
command -v starship >/dev/null && eval "$(starship init zsh)"
[ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh
[ -f /usr/share/fzf/completion.zsh ] && source /usr/share/fzf/completion.zsh

# >>> hemo:target — `t` prints the current target set by `hemo-target <ip>`.
# Hemo keeps the target in a file, never an exported variable: an exported var is
# visible to every child process and in `env`. Use it as `nmap "$(t)"`.
t() {
  local f="${XDG_CONFIG_HOME:-$HOME/.config}/hemo/target"
  [[ -s $f ]] && print -r -- "$(<$f)"
}
# <<< hemo:target

# >>> hemo:engagement — `eng` is a function (not an alias) so it can cd into
# the engagement directory after `use` or `new`. Everything else passes through.
eng() {
  hemo-engagement "$@"
  case "$1" in
    use|new) local d; d=$(hemo-engagement path 2>/dev/null) && [[ -d "$d" ]] && cd "$d" ;;
  esac
}
# <<< hemo:engagement

# >>> hemo:stamp — stamp each command's execution time (preexec), ONLY when an
# engagement is active. Keeps the tmux transcript / your terminal time-tagged
# without typing anything extra, and records the IP a target would see at that
# moment next to the timestamp (shield + VPN IP when the tunnel is up, arrow +
# public egress when it is not). `HEMO_STAMP=0 <cmd>` disables for one shell;
# unset or empty = on. Prints a muted thin rule just before the command runs.
_hemo_stamp() {
  [[ ${HEMO_STAMP-1} != 0 ]] || return
  hemo-engagement path >/dev/null 2>&1 || return
  local cfg="${XDG_CONFIG_HOME:-$HOME/.config}/hemo"
  local ff="$cfg/stamp-format" tzf="$cfg/stamp-tz" fmt="" tz=""
  if [[ -s $ff ]]; then
    IFS= read -r fmt < "$ff"
  elif [[ -f $ff ]]; then
    return   # file exists & empty = user picked both date+time off
  else
    fmt="%Y-%m-%d %H:%M:%S"   # default when nothing is configured
  fi
  [[ -s $tzf ]] && IFS= read -r tz < "$tzf"
  local stamp
  if [[ -n $tz ]]; then
    stamp=$(TZ="$tz" date "+$fmt")
  else
    stamp=$(date "+$fmt")
  fi
  local ipseg=""
  if (( $+commands[hemo-bar-ip] )); then
    local s=$(hemo-bar-ip stamp 2>/dev/null)
    [[ -n $s ]] && ipseg=" · $s"
  fi
  print -P -- "%F{8}── ${stamp}${ipseg} ──%f"
}
autoload -Uz add-zsh-hook 2>/dev/null && add-zsh-hook preexec _hemo_stamp
# <<< hemo:stamp

# >>> hemo:ssh — advertise a generic terminal type to remote hosts. ssh always
# includes a TERM in its pty request; inside tmux that would be `tmux-256color`,
# which (a) often has no terminfo on the target, garbling the remote display, and
# (b) hints you run a multiplexer. This sets the value to the universal
# `xterm-256color` for the ssh process only — it sends NO extra data (same one
# field, generic value) and does NOT use SendEnv/SetEnv. scp/sftp/git call the ssh
# binary directly, so they are unaffected; `command ssh` bypasses this function.
ssh() { TERM=xterm-256color command ssh "$@"; }
# <<< hemo:ssh

# >>> hemo:fetch — the Hemo lizard + system info when a terminal opens. Only in a
# real terminal (not scripts, pipes or editor sub-shells). Turn it off for one
# shell with HEMO_NO_FETCH=1, or delete this block. Stacks the lizard above
# the info when the terminal is narrower than the side-by-side layout needs
# (logo ~41 cols + info ~40 cols); keeps the art intact at i3 half-screen.
if [[ -o interactive && -t 1 && -z "$HEMO_NO_FETCH" && -z "$NVIM" ]] && command -v fastfetch >/dev/null; then
  if (( ${COLUMNS:-$(tput cols 2>/dev/null || echo 80)} < 85 )); then
    fastfetch --logo-position top
  else
    fastfetch
  fi
fi
# <<< hemo:fetch

# >>> hemo:shell — history, completion, keys, autosuggestions + syntax highlighting
# (Kali's stock .zshrc had these; Hemo replaces that file, so they live here.)
HISTFILE=~/.zsh_history HISTSIZE=50000 SAVEHIST=50000
setopt hist_ignore_dups hist_ignore_space hist_verify share_history extended_history
setopt interactivecomments
mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}"
autoload -Uz compinit && compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}/zcompdump"
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
bindkey -e
bindkey '^[[1;5C' forward-word         # ctrl+→
bindkey '^[[1;5D' backward-word        # ctrl+←
bindkey '^[[H'    beginning-of-line    # home
bindkey '^[[F'    end-of-line          # end
bindkey '^[[3~'   delete-char          # delete
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] \
  && source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
# syntax highlighting must be sourced LAST (it wraps every widget defined before it)
[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] \
  && source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# <<< hemo:shell
