#!/usr/bin/env bash
# Hemo OS — one-line installer. Turns a stock Kali machine into Hemo.
#
#   curl -fsSL https://raw.githubusercontent.com/cnmoseman/Hemo-OS/main/install.sh | sudo bash
#
# or, with options (note the `-s --` to pass args through a pipe):
#
#   curl -fsSL .../install.sh | sudo bash -s -- --ref v0.2.0 --declutter
#
# What it does:
#   1. Checks this is a Debian/Kali system and that it's running as root.
#   2. Installs git + curl if missing.
#   3. Clones (or updates) the Hemo OS repo to /opt/hemo-os.
#   4. Walks you through a few choices (notes app, code editor, terminal editor,
#      keep or strip stock Kali), then installs unattended.
#   5. Runs provision.sh — creates the operator user, bakes the desktop + core,
#      applies branding. Tools install PER ROLE after reboot (Hemo Welcome).
#   6. Runs declutter.sh --apply — strips the stock Kali toolset + XFCE so the
#      box ships lean as Hemo. Skip with --no-declutter to keep stock Kali's
#      packages. (Snapshot the VM first; this removes ~7 GB of packages.)
#
# Flags:
#   --ref <tag|branch>   check out a specific release/branch (default: main)
#   --no-declutter       keep the stock Kali toolset + XFCE (don't slim down)
#   --repo <url>         clone from a different URL (fork / mirror / token URL)
#   --src <dir>          where to clone (default: /opt/hemo-os)
#   -y, --yes            no questions: take every default (and don't reboot)
#   -h, --help           show this help
#
# Run from a checkout (`sudo ./install.sh`) it installs that checkout in place —
# no clone — so local changes are what gets tested.
#
# Anything after `--` that isn't a flag above is passed straight to provision.sh.
#
# NOTE: while the repo is PRIVATE, an unauthenticated clone fails. Either make
# the repo public, or pass an authenticated URL, e.g.:
#   ... | sudo bash -s -- --repo https://<user>:<token>@github.com/cnmoseman/Hemo-OS.git
set -euo pipefail

REPO="${HEMO_REPO:-https://github.com/cnmoseman/Hemo-OS.git}"
SRC="${HEMO_SRC:-/opt/hemo-os}"
DEFAULT_SRC="$SRC"
REF="${HEMO_REF:-main}"
DECLUTTER=1            # slim down to lean Hemo by default; --no-declutter opts out
DECL_SET=0             # 1 once a --(no-)declutter flag decided it (skip that question)
SRC_SET=0; [ -n "${HEMO_SRC:-}" ] && SRC_SET=1   # an explicit source dir wins over checkout detection
ASSUME_YES=0
PASSTHRU=()

say(){ printf '\n\033[1;31m[hemo-install]\033[0m %s\n' "$*"; }
die(){ printf '\033[1;31m[hemo-install] FATAL:\033[0m %s\n' "$*" >&2; exit 1; }
# Printed from a heredoc (not sed "$0") so --help works when piped from curl.
usage(){ cat <<'H'
Hemo OS one-line installer — turn a Kali machine into Hemo.

  curl -fsSL https://raw.githubusercontent.com/cnmoseman/Hemo-OS/main/install.sh | sudo bash

Flags (pass through a pipe with `-s --`):
  --ref <tag|branch>   check out a specific release/branch (default: main)
  --no-declutter       keep the stock Kali toolset + XFCE (default: slim down)
  --repo <url>         clone from a different URL (fork / mirror / token URL)
  --src <dir>          where to clone (default: /opt/hemo-os)
  -y, --yes            no questions: take every default (and don't reboot)
  -h, --help           show this help

From a checkout, `sudo ./install.sh` installs that checkout in place.

Anything after `--` not listed above is passed straight to provision.sh.
While the repo is PRIVATE, use a token URL:
  ... | sudo bash -s -- --repo https://<user>:<token>@github.com/cnmoseman/Hemo-OS.git
H
exit 0; }

while [ $# -gt 0 ]; do
  case "$1" in
    --ref)       REF="${2:?--ref needs a value}"; shift 2;;
    --repo)      REPO="${2:?--repo needs a value}"; shift 2;;
    --src)          SRC="${2:?--src needs a value}"; SRC_SET=1; shift 2;;
    --no-declutter) DECLUTTER=0; DECL_SET=1; shift;;
    --declutter)    DECLUTTER=1; DECL_SET=1; shift;;   # explicit; it's the default anyway
    -y|--yes)       ASSUME_YES=1; shift;;
    -h|--help)      usage;;
    --)          shift; PASSTHRU+=("$@"); break;;
    *)           PASSTHRU+=("$1"); shift;;
  esac
done

# ---------------------------------------------------------------- preflight
[ "$(id -u)" -eq 0 ] || die "Run as root. Pipe into 'sudo bash', e.g.:
  curl -fsSL https://raw.githubusercontent.com/cnmoseman/Hemo-OS/main/install.sh | sudo bash"

command -v apt-get >/dev/null 2>&1 || die "This needs a Debian/Kali system (no apt-get found)."
if [ -r /etc/os-release ]; then
  . /etc/os-release
  case "${ID:-}${ID_LIKE:-}" in
    *kali*|*debian*) : ;;
    *) say "WARNING: this looks like '${PRETTY_NAME:-unknown}', not Kali/Debian. Continuing anyway." ;;
  esac
fi

# Run from a checkout? Install it in place (no clone). Piped from curl there is
# no script file, so this never triggers on the one-liner.
LOCAL=0
if [ "$SRC_SET" -eq 0 ] && [ -f "${BASH_SOURCE[0]:-}" ]; then
  HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  # ...except the installer's own clone: re-running /opt/hemo-os/install.sh updates it
  if [ -f "$HERE/provision.sh" ] && [ -d "$HERE/manifest" ] && [ "$HERE" != "$DEFAULT_SRC" ]; then
    SRC="$HERE"; LOCAL=1
  fi
fi

# ---------------------------------------------------------------- walkthrough
# Every choice is asked up front so the long install then runs unattended. The
# keyboard is read from /dev/tty (stdin is the curl pipe). With --yes, or with no
# terminal at all, every question takes its default.
TTY=/dev/tty
interactive(){ [ "$ASSUME_YES" -eq 0 ] && { : <"$TTY"; } 2>/dev/null; }

# pick VAR "Question" "detail" DEFAULT_NUMBER "key:label" ...
pick(){
  local var=$1 q=$2 detail=$3 def=$4 ans i mark
  shift 4
  local keys=() labels=() o
  for o in "$@"; do keys+=("${o%%:*}"); labels+=("${o#*:}"); done
  if ! interactive; then
    printf -v "$var" '%s' "${keys[$((def-1))]}"
    printf -v "${var}_LABEL" '%s' "${labels[$((def-1))]%% — *}"
    return 0
  fi
  printf '\n\033[1m%s\033[0m\n' "$q"
  if [ -n "$detail" ]; then printf '  %s\n' "$detail"; fi
  for i in "${!labels[@]}"; do
    mark=""; [ $((i+1)) -eq "$def" ] && mark="  (default)"
    printf '   %d) %s%s\n' $((i+1)) "${labels[$i]}" "$mark"
  done
  while :; do
    read -r -p "  Choose [$def]: " ans <"$TTY" || ans=""
    ans=${ans:-$def}
    if [[ "$ans" =~ ^[0-9]+$ ]] && [ "$ans" -ge 1 ] && [ "$ans" -le "${#keys[@]}" ]; then break; fi
    echo "  Type a number from 1 to ${#keys[@]}."
  done
  printf -v "$var" '%s' "${keys[$((ans-1))]}"
  printf -v "${var}_LABEL" '%s' "${labels[$((ans-1))]%% — *}"
}

# yesno "Question" y|n   (returns 0 for yes)
yesno(){
  local q=$1 def=$2 ans hint=y/N
  [ "$def" = y ] && hint=Y/n
  while :; do
    read -r -p "$q [$hint] " ans <"$TTY" || ans=""
    case "${ans:-$def}" in [Yy]*) return 0;; [Nn]*) return 1;; esac
  done
}


if interactive; then
  printf '\n\033[1;31m  Hemo OS installer\033[0m\n'
  echo "  A few choices first. After that the install runs on its own (20-40 min)."
  echo "  Press Enter to take the default."
fi
N=$([ "$DECL_SET" -eq 0 ] && echo 4 || echo 3)
pick HEMO_NOTES "1/$N  Notes app" "Where you keep engagement notes." 1 \
  "obsidian:Obsidian — linked Markdown notes, a daily knowledge base" \
  "cherrytree:Cherrytree — tree of notes with screenshots, one-file PDF/HTML export" \
  "both:Both"
pick HEMO_CODE_EDITOR "2/$N  Code editor" "For scripts, exploits and configs." 1 \
  "lazyvim:LazyVim — Neovim set up as a full code editor, in the terminal" \
  "vscodium:VSCodium — graphical VS Code, without Microsoft's telemetry" \
  "both:Both"
pick HEMO_TERM_EDITOR "3/$N  Terminal editor" "Opens for quick edits, git commit messages and sudoedit." 1 \
  "nano:nano — simple, shortcuts shown on screen" \
  "vim:vim — opens Neovim"
if [ "$DECL_SET" -eq 0 ]; then
  pick DECLUTTER "4/4  Kali's stock tools" \
    "Hemo installs tools per role after reboot. Removing Kali's stock toolset and Xfce frees about 7 GB." 1 \
    "1:Remove them — lean Hemo" \
    "0:Keep them"
fi
export HEMO_NOTES HEMO_CODE_EDITOR HEMO_TERM_EDITOR

if interactive; then
  printf '\n\033[1mReady to install\033[0m\n'
  printf '   Notes app:        %s\n' "$HEMO_NOTES_LABEL"
  printf '   Code editor:      %s\n' "$HEMO_CODE_EDITOR_LABEL"
  printf '   Terminal editor:  %s\n' "$HEMO_TERM_EDITOR_LABEL"
  printf '   Stock Kali tools: %s\n' "$([ "$DECLUTTER" -eq 1 ] && echo remove || echo keep)"
  printf '   Source:           %s\n' "$([ "$LOCAL" -eq 1 ] && echo "$SRC (this checkout)" || echo "$REPO ($REF)")"
  yesno "Start the install?" y || die "Cancelled. Nothing was changed."
fi

export DEBIAN_FRONTEND=noninteractive
if ! command -v git >/dev/null 2>&1 || ! command -v curl >/dev/null 2>&1; then
  say "Installing prerequisites (git, curl, ca-certificates)"
  apt-get update -y
  apt-get install -y --no-install-recommends git curl ca-certificates
fi

# ---------------------------------------------------------------- fetch source
# Move a checkout onto $REF — works for a branch, tag, OR bare commit sha
# (a plain `clone --branch` can't take a sha, and silently keeping the default
# branch would install the wrong code).
checkout_ref(){
  local d=$1
  git -C "$d" remote set-url origin "$REPO" 2>/dev/null || true
  if git -C "$d" fetch --depth 1 origin "$REF" 2>/dev/null; then
    git -C "$d" checkout -f -q FETCH_HEAD
  else
    say "WARNING: ref '$REF' not found on the remote — using the cloned default branch instead."
  fi
}

if [ "$LOCAL" -eq 1 ]; then
  say "Installing from this checkout: $SRC"
else
  if [ -d "$SRC/.git" ]; then
    say "Updating existing checkout in $SRC ($REF)"
  else
    say "Cloning $REPO ($REF) -> $SRC"
    rm -rf "$SRC"
    install -d -m755 "$(dirname "$SRC")"
    git clone --depth 1 "$REPO" "$SRC"   # default branch; checkout_ref then moves onto $REF
  fi
  checkout_ref "$SRC"
fi
chmod +x "$SRC"/*.sh 2>/dev/null || true   # re-assert exec bits in case the clone dropped them
[ -x "$SRC/provision.sh" ] || die "provision.sh not found in $SRC — clone looks incomplete."

# ---------------------------------------------------------------- provision
say "Provisioning (this takes a while; log at /var/log/hemo-provision.log)"
( cd "$SRC" && ./provision.sh "${PASSTHRU[@]}" )

# ---------------------------------------------------------------- declutter (default)
if [ "$DECLUTTER" -eq 1 ]; then
  say "Slimming down to lean Hemo: stripping the stock Kali toolset + XFCE.
   (Roles reinstall what you need on first boot. Use --no-declutter to keep stock.)"
  ( cd "$SRC" && ./declutter.sh --apply )
else
  say "Kept the stock Kali toolset + XFCE (--no-declutter).
   To slim down later:  sudo $SRC/declutter.sh --apply   (preview first with no flag)."
fi

# ---------------------------------------------------------------- done
say "Hemo is installed."
cat <<EOF
  Next:
    1. Reboot.
    2. At the login screen, log in as 'hemo' (password: hemo; change it with passwd).
    3. Hemo Welcome opens: pick your role(s). Their tools install online.
  Later:  hemo-welcome (settings) · sudo hemo-roles (add roles) · hemo-theme <role>
  Source kept in $SRC — re-run this installer any time to update.
EOF
if interactive && yesno "Reboot now?" y; then
  say "Rebooting…"
  systemctl reboot
fi
