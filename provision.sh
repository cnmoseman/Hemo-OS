#!/usr/bin/env bash
# Hemo provisioner — run INSIDE a fresh Kali VM as root.
#
#   sudo ./provision.sh
#
# Turns a stock Kali image into Hemo: creates the operator user, installs
# the curated tool set, i3 + desktop apps, and a light rebrand. Safe to re-run.
#
# This is the "build by hand" path (works on Windows + VMware). Versions are
# whatever the Kali repo serves today — NOT pinned. The pinned, reproducible,
# multi-format build is the separate kali-vm pipeline (see PLAN.md).

set -uo pipefail

OPERATOR="hemo"
HOSTNAME_NEW="hemo"
# App choices — set these as env vars. Without them a re-run keeps what was recorded
# last time (here or in Hemo Welcome); a first run takes the defaults.
NOTES="${HEMO_NOTES:-$(cat /var/lib/hemo/notes-choice 2>/dev/null)}"
CODE_EDITOR="${HEMO_CODE_EDITOR:-$(cat /var/lib/hemo/editor-choice 2>/dev/null)}"
TERM_EDITOR="${HEMO_TERM_EDITOR:-$(cat "/home/$OPERATOR/.config/hemo/editor" 2>/dev/null)}"
case "$NOTES" in obsidian|cherrytree|both) ;; *) NOTES=obsidian ;; esac   # single default; Cherrytree is add-on (Welcome)
case "$CODE_EDITOR" in lazyvim|vscodium|both) ;; *) CODE_EDITOR=lazyvim ;; esac
case "$TERM_EDITOR" in nano|vim) ;; *) TERM_EDITOR=nano ;; esac
wants(){ [ "$1" = "$2" ] || [ "$1" = both ]; }   # wants <choice> <app>
OPT=/opt/hemo
LOG=/var/log/hemo-provision.log

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ "$(id -u)" -eq 0 ] || { echo "Run as root: sudo $0"; exit 1; }
mkdir -p "$OPT"
exec > >(tee -a "$LOG") 2>&1
echo "=== Hemo provision started $(date) ==="
echo "    notes: $NOTES · code editor: $CODE_EDITOR · terminal editor: $TERM_EDITOR"

say(){ printf '\n\033[1;31m[hemo]\033[0m %s\n' "$*"; }

# Install apt packages one by one so a single bad/renamed name can't abort
# the whole run; missing ones are reported at the end.
MISSING=()
apt_get(){
  for p in "$@"; do
    if apt-get install -y --no-install-recommends "$p" >/dev/null 2>&1; then
      echo "  + $p"
    else
      echo "  ! $p (not found / failed)"; MISSING+=("$p")
    fi
  done
}

# Critical packages (the container runtime): a transient apt hiccup must NOT be
# silently swallowed the way `apt_get` tolerates a renamed name — that is exactly
# how docker went missing on the 0.1.0 golden. Install, and on failure refresh
# the lists and retry once; if it still fails, record it in CRITICAL so the run
# ends non-zero and the image can't be sealed/shipped with it absent.
CRITICAL=()
apt_get_critical(){
  for p in "$@"; do
    if apt-get install -y --no-install-recommends "$p" >/dev/null 2>&1; then
      echo "  + $p"
    else
      echo "  … $p failed — refreshing package lists and retrying once"
      apt-get update -y >/dev/null 2>&1
      if apt-get install -y --fix-missing --no-install-recommends "$p" >/dev/null 2>&1; then
        echo "  + $p (on retry)"
      else
        echo "  !! $p (CRITICAL — not installed)"; CRITICAL+=("$p")
      fi
    fi
  done
}

# ---------------------------------------------------------------- base system
say "Updating package lists"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y

say "Build toolchain (source-built pipx wheels: lxml, cryptography, …)"
apt_get build-essential python3-dev libxml2-dev libxslt1-dev libssl-dev libffi-dev pkg-config cargo cmake

say "Base CLI tooling"
apt_get zsh zsh-autosuggestions zsh-syntax-highlighting goshs minisign tmux fzf ripgrep bat fd-find git pipx golang curl wget jq pandoc \
        keepassxc neovim python3-yaml whiptail pciutils \
        open-vm-tools open-vm-tools-desktop qemu-guest-agent spice-vdagent \
        virtualbox-guest-x11
# ^ guest integration for all three hypervisors (clipboard/drag-drop/resize);
#   the matching daemon activates on the detected host, the others stay idle.
# PowerShell is a promised role tool (pwsh), so install it critically: a soft
# apt_get would swallow a transient failure and ship an image with no pwsh (seen
# on a fresh provision 2026-10-19). Critical = refresh lists + retry once, and
# surface it loudly in the CRITICAL summary if it still can't be installed.
apt_get_critical powershell

say "i3 desktop + apps"
apt_get i3 i3status i3lock-color xss-lock autotiling rofi polybar dunst kitty flameshot firefox-esr \
        xorg lightdm feh picom autorandr x11-xserver-utils

say "Report/screenshot consistency tooling"
apt_get fonts-jetbrains-mono maim xdotool xclip imagemagick

say "Desktop apps + daily-driver QoL"
apt_get thunar thunar-archive-plugin thunar-volman lf mc \
        zathura zathura-pdf-poppler nsxiv \
        pipewire pipewire-pulse wireplumber pavucontrol pamixer \
        network-manager-applet nm-connection-editor \
        fastfetch copyq udiskie gammastep yad python3-gi gir1.2-gtk-3.0 gir1.2-gdkpixbuf-2.0 lxpolkit \
        p7zip-full unzip zip xarchiver \
        gvfs gvfs-backends udisks2 ntfs-3g exfatprogs cifs-utils \
        lxappearance fonts-noto fonts-noto-color-emoji fonts-nerd-symbols kali-themes-common \
        libreoffice-writer libreoffice-calc libreoffice-impress libreoffice-gtk3

if wants "$NOTES" cherrytree; then apt_get cherrytree; fi

say "Client-VPN plugins (reach a client network via nm-applet)"
apt_get network-manager-openconnect-gnome network-manager-openvpn-gnome \
        network-manager-vpnc-gnome \
        network-manager-l2tp-gnome \
        network-manager-strongswan
# Fortinet SSL VPN plugin isn't in all snapshots; add if present:
#   network-manager-fortisslvpn-gnome

say "Report engine (pandoc PDF: XeLaTeX subset + HTML/CSS path)"
apt_get texlive-xetex texlive-latex-recommended texlive-latex-extra \
        texlive-fonts-recommended lmodern weasyprint

# ---- non-repo desktop extras: best-in-class tools not in apt -----------------
# yazi (TUI FM), greenclip (rofi clipboard), patched JetBrainsMono Nerd Font.
# apt fallbacks (lf, copyq, fonts-nerd-symbols) are already installed above, so
# a failure here degrades gracefully.
say "Desktop extras from upstream (yazi / greenclip / Nerd Font)"
ARCH_TAG=x86_64-unknown-linux-musl
# yazi
if ! command -v yazi >/dev/null 2>&1; then
  ytmp=$(mktemp -d)
  if curl -fsSL "https://github.com/sxyazi/yazi/releases/latest/download/yazi-${ARCH_TAG}.zip" -o "$ytmp/y.zip" 2>/dev/null \
     && unzip -qo "$ytmp/y.zip" -d "$ytmp" 2>/dev/null; then
    find "$ytmp" -type f \( -name yazi -o -name ya \) -exec install -m755 {} /usr/local/bin/ \; \
      && echo "  + yazi" || echo "  ! yazi extract failed"
  else echo "  ! yazi download failed (apt 'lf' is the fallback)"; fi
  rm -rf "$ytmp"
fi
# greenclip (static binary)
if ! command -v greenclip >/dev/null 2>&1; then
  curl -fsSL "https://github.com/erebe/greenclip/releases/latest/download/greenclip" \
    -o /usr/local/bin/greenclip 2>/dev/null && chmod 755 /usr/local/bin/greenclip \
    && echo "  + greenclip" || echo "  ! greenclip download failed (apt 'copyq' is the fallback)"
fi
# patched JetBrainsMono Nerd Font (exact glyph alignment for polybar/starship)
if ! fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd Font"; then
  ftmp=$(mktemp -d)
  if curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" -o "$ftmp/f.zip" 2>/dev/null \
     && unzip -qo "$ftmp/f.zip" '*NerdFontMono*' -d /usr/local/share/fonts/ 2>/dev/null; then
    fc-cache -f >/dev/null 2>&1; echo "  + JetBrainsMono Nerd Font"
  else echo "  ! Nerd Font download failed (apt 'fonts-nerd-symbols' is the fallback)"; fi
  rm -rf "$ftmp"
fi

# ------------------------------------------------- baked plumbing (role model)
# Offensive/defensive tools are NO LONGER baked here. They install on first boot
# per the role(s) the operator picks (see hemo-roles / hemo-pkg / roles.yml).
# Only the thin core is baked: base CLI, i3 desktop, report tooling, and the
# network plumbing the role tools assume is already present.

say "Plumbing (base clients / transport)"
# wireshark / tcpdump / netcat / socat / SMB / LDAP / Kerberos are role tools now
# (apt.yml net_clients -> roles.yml); only the clients every role uses stay baked.
apt_get freerdp3-x11 openvpn wireguard-tools

# ---------------------------------------------------------- baked desktop apps
# Editor / notes / shell niceties are part of the baked environment. The
# offensive + defensive security tools are NOT installed here anymore — they
# install per role on first boot (see the role-system section below).
say "GUI apps not in the Kali repo"
# VSCodium: only when picked in the walkthrough (instead of / with LazyVim).
if wants "$CODE_EDITOR" vscodium && ! command -v codium >/dev/null; then
  wget -qO /usr/share/keyrings/vscodium.gpg.key https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg || true
  echo 'deb [signed-by=/usr/share/keyrings/vscodium.gpg.key] https://download.vscodium.com/debs vscodium main' \
    > /etc/apt/sources.list.d/vscodium.list
  apt-get update -y >/dev/null 2>&1; apt_get codium
fi
# Obsidian installs later through hemo-pkg (needs the manifests; see "editors").
command -v starship >/dev/null || { curl -sS https://starship.rs/install.sh | sh -s -- -y >/dev/null 2>&1 && echo "  + starship" || echo "  ! starship"; }

# ---------------------------------------------------------------- operator user
say "Operator user: $OPERATOR"
if ! id "$OPERATOR" >/dev/null 2>&1; then
  # only groups that exist (wireshark is a role tool now; hemo-pkg adds the group later)
  grps=sudo; for g in wireshark kali-trusted; do getent group "$g" >/dev/null && grps="$grps,$g"; done
  useradd -m -s /usr/bin/zsh -G "$grps" "$OPERATOR"
  echo "$OPERATOR:hemo" | chpasswd
  echo "  user $OPERATOR created (default password: hemo, like Kali's kali/kali; change it with passwd)"
fi

# Default the login session to i3 (NOT Kali's Xfce default) for EVERY human user
# (the operator and the stock `kali` user), via lightdm's user-session plus each
# user's ~/.dmrc and AccountsService record (the greeter's remembered session).
# let `sudo hemo-*` find the helpers in /usr/local/bin (default secure_path omits it)
printf 'Defaults secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"\n' > /etc/sudoers.d/10-hemo-path
chmod 0440 /etc/sudoers.d/10-hemo-path
visudo -cf /etc/sudoers.d/10-hemo-path >/dev/null 2>&1 || rm -f /etc/sudoers.d/10-hemo-path
install -d /etc/lightdm/lightdm.conf.d
printf '[Seat:*]\nuser-session=i3\n' > /etc/lightdm/lightdm.conf.d/60-hemo-session.conf

# default terminal: kitty is the ONLY terminal baked, and the default ($mod+Return,
# the Kali menu's CLI launchers and rofi all go through x-terminal-emulator). It is
# also the report/screenshot terminal (hemo-shotterm + Welcome build windows). qterminal
# is NOT baked — the Welcome "Apps & tools" step installs it on demand (and removes kitty)
# for users who prefer it. Thunar handles folders (else an editor like VSCodium wins).
if [ -x /usr/bin/kitty ]; then
  update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/kitty 40 >/dev/null 2>&1 || true
  update-alternatives --set x-terminal-emulator /usr/bin/kitty >/dev/null 2>&1 || true
fi
M=/etc/xdg/mimeapps.list
[ -f "$M" ] || printf '[Default Applications]\n' > "$M"
grep -q '^\[Default Applications\]' "$M" || printf '[Default Applications]\n' >> "$M"
sed -i '/^inode\/directory=/d' "$M"
sed -i '/^\[Default Applications\]/a inode/directory=thunar.desktop' "$M"
install -d /var/lib/AccountsService/users
hemo_session_dbus(){   # $1 = user; best effort (no daemon in a chroot build)
  local uid; uid=$(id -u "$1" 2>/dev/null) || return 0
  busctl call org.freedesktop.Accounts /org/freedesktop/Accounts org.freedesktop.Accounts \
    FindUserByName s "$1" >/dev/null 2>&1 || return 0
  for m in SetXSession SetSession; do
    busctl call org.freedesktop.Accounts "/org/freedesktop/Accounts/User$uid" \
      org.freedesktop.Accounts.User "$m" s i3 >/dev/null 2>&1 || true
  done
}
getent passwd | awk -F: '$3>=1000 && $3<60000 {print $1":"$6}' | while IFS=: read -r u h; do
  [ -d "$h" ] || continue
  printf '[Desktop]\nSession=i3\n' > "$h/.dmrc"
  chown "$u:" "$h/.dmrc" 2>/dev/null || true
  a="/var/lib/AccountsService/users/$u"
  if [ -f "$a" ]; then   # edit in place: keep Icon/Language/etc.
    sed -i '/^\(X\)\?Session=/d' "$a"
    grep -q '^\[User\]' "$a" || printf '[User]\n' >> "$a"
    sed -i '/^\[User\]/a Session=i3\nXSession=i3' "$a"
  else
    printf '[User]\nSession=i3\nXSession=i3\nSystemAccount=false\n' > "$a"
  fi
  # accounts-daemon caches each user and rewrites this file on any later change (the
  # branding step's SetIconFile), dropping a Session= line it never saw, so the greeter
  # fell back to "Default Xsession" (Xfce) on a clean install. Set it through the
  # daemon as well so its cache agrees.
  hemo_session_dbus "$u"
  # Fallback: the greeter's "Default Xsession" (lightdm-xsession) runs ~/.xsession
  # if present (else x-session-manager = Xfce). Picking Xfce explicitly still works.
  if [ ! -e "$h/.xsession" ]; then
    printf '#!/bin/sh\n# Hemo: "Default Xsession" -> i3\nexec i3\n' > "$h/.xsession"
    chmod 755 "$h/.xsession"; chown "$u:" "$h/.xsession" 2>/dev/null || true
  fi
  echo "  default login session -> i3 ($u)"
done

# ---------------------------------------------------------- container runtime
# BloodHound CE (and future heavy services) run as Docker containers, idle until
# invoked. Install the runtime now; do NOT start any service here.
# NOTE: on Kali/Debian `docker.io` is the daemon only — the `docker` CLI lives in
# the separate `docker-cli` package, which docker.io merely *Recommends*. With our
# --no-install-recommends install that CLI is skipped unless named explicitly, so
# docker.io reports "newest" while `docker` is command-not-found. List docker-cli.
# Likewise `docker compose` v2 is NOT part of docker-buildx (buildx = `docker buildx`
# only); it's the `docker-compose` package (v2.x on Kali, installs the compose plugin).
# AdaptixC2 (`hemo-adaptix build`) and BloodHound (`hemo-bloodhound`) hard-require it.
say "Container runtime (for BloodHound CE + future docker services)"
apt_get_critical docker.io docker-cli docker-compose docker-buildx
if command -v docker >/dev/null 2>&1; then
  systemctl enable docker >/dev/null 2>&1 && echo "  + docker enabled"
  usermod -aG docker "$OPERATOR" 2>/dev/null \
    && echo "  + $OPERATOR added to the docker group (re-login for it to take effect)"
else
  # daemon installed but the CLI binary isn't here — docker-cli is what's missing
  echo "  !! docker CLI absent after install (CRITICAL)"
  case " ${CRITICAL[*]} " in *" docker-cli "*) ;; *) CRITICAL+=(docker-cli);; esac
fi
echo "  BloodHound CE is NOT started here — bring it up on demand: hemo-bloodhound up"

# ---------------------------------------------------------------- dotfiles / i3
say "Desktop config + report tooling (from overlays/)"
U=/home/$OPERATOR
if [ -d "$SCRIPT_DIR/overlays/etc/skel" ]; then
  if [ -e "$U/.config/i3/config" ]; then
    # Re-run: the operator's dotfiles exist and may carry role-theme state that
    # hemo-role-apply wrote into them. Do NOT clobber it. (rm -rf ~/.config to reset.)
    echo "  dotfiles already present — left as-is (preserves applied role theme)"
    # ...but refresh the shipped, non-stateful pieces: i3 window rules/look, picom, GTK look
    # (hemo-accent.css is role state — only seeded if missing).
    S="$SCRIPT_DIR/overlays/etc/skel/.config"
    install -D -m644 "$S/i3/config.d/hemo-windows.conf" "$U/.config/i3/config.d/hemo-windows.conf"
    install -D -m644 "$S/i3/config.d/hemo-look.conf"    "$U/.config/i3/config.d/hemo-look.conf"
    install -D -m644 "$S/i3/config.d/hemo-keys.conf"    "$U/.config/i3/config.d/hemo-keys.conf"
    install -D -m644 "$S/picom/picom.conf"              "$U/.config/picom/picom.conf"
    install -D -m644 "$S/dunst/dunstrc"                 "$U/.config/dunst/dunstrc"
    sed -i 's|^bindsym \$mod+Shift+e exec "i3-nagbar .*$|bindsym $mod+Shift+e exec --no-startup-id hemo-power|' "$U/.config/i3/config"
    if ! grep -q '^include ~/.config/i3/config.d/' "$U/.config/i3/config"; then
      if grep -q '^font pango:' "$U/.config/i3/config"; then
        sed -i '/^font pango:/a include ~/.config/i3/config.d/*.conf' "$U/.config/i3/config"
      else
        printf '\ninclude ~/.config/i3/config.d/*.conf\n' >> "$U/.config/i3/config"
      fi
    fi
    # rofi launcher theme + pinned-apps grid (hemo-colors.rasi is role state — kept)
    install -D -m644 "$S/rofi/config.rasi" "$U/.config/rofi/config.rasi"
    install -D -m644 "$S/rofi/pinned.rasi" "$U/.config/rofi/pinned.rasi"
    install -D -m644 "$S/rofi/power.rasi"  "$U/.config/rofi/power.rasi"
    [ -e "$U/.config/hemo/pinned" ] || install -D -m644 "$S/hemo/pinned" "$U/.config/hemo/pinned"
    sed -i 's|^bindsym \$mod+d exec rofi -show drun$|# launcher: $mod+d = app launcher (pinned apps first)\nbindsym $mod+d exec --no-startup-id hemo-launcher\n# Hemo welcome / settings hub\nbindsym $mod+Shift+d exec --no-startup-id hemo-welcome --settings|' "$U/.config/i3/config"
    sed -i 's|^bindsym \$mod+Shift+d exec rofi -show drun$|bindsym $mod+Shift+d exec --no-startup-id hemo-welcome --settings|' "$U/.config/i3/config"
    # workspaces are no longer role-themed: swap the old managed block for the static
    # number bindings (+ $mod+F2 rename) the skel config ships
    if grep -q '^# >>> hemo:workspaces' "$U/.config/i3/config"; then
      sed -i -e '/^# >>> hemo:workspaces/,/^# <<< hemo:workspaces/d' -e '/^# workspaces — names + bindings are rewritten per primary role\.$/d' "$U/.config/i3/config"
      sed -n '/^# workspaces — plain numbers/,/hemo-ws-rename$/p' "$SCRIPT_DIR/overlays/etc/skel/.config/i3/config" >> "$U/.config/i3/config"
    fi
    grep -q hemo-guest-session "$U/.config/i3/config" \
      || sed -i '/^exec --no-startup-id autorandr --change$/a exec --no-startup-id hemo-guest-session    # VM guest agent: host clipboard, drag-drop, auto-resize' "$U/.config/i3/config"
    # target helper `t` (hemo-target) for shells set up before it existed
    grep -q 'hemo:target' "$U/.zshrc" 2>/dev/null \
      || sed -n '/^# >>> hemo:target/,/^# <<< hemo:target/p' "$SCRIPT_DIR/overlays/etc/skel/.zshrc" | sed '1i\\' >> "$U/.zshrc"
    # fastfetch on terminal open (before hemo:shell, which must stay last).
    # Upgrade the old single-line form to the narrow-width stacking form so a
    # half-screen i3 split doesn't smoosh the lizard.
    if grep -q 'hemo:fetch' "$U/.zshrc" 2>/dev/null; then
      if ! grep -q 'logo-position top' "$U/.zshrc" 2>/dev/null; then
        sed -i '/^# >>> hemo:fetch/,/^# <<< hemo:fetch/d' "$U/.zshrc"
        sed -n '/^# >>> hemo:fetch/,/^# <<< hemo:fetch/p' "$SCRIPT_DIR/overlays/etc/skel/.zshrc" | sed '1i\\' >> "$U/.zshrc"
      fi
    else
      sed -n '/^# >>> hemo:fetch/,/^# <<< hemo:fetch/p' "$SCRIPT_DIR/overlays/etc/skel/.zshrc" | sed '1i\\' >> "$U/.zshrc"
    fi
    # hemo-open: prepend to the five window-openers so a new window splits off
    # the tile under the mouse (focus_follows_mouse + xdotool mousemove_relative).
    # Idempotent — the patterns insist on the pre-migration form.
    sed -i -E \
      -e 's|^bindsym \$mod\+Return exec x-terminal-emulator$|bindsym $mod+Return exec --no-startup-id hemo-open x-terminal-emulator|' \
      -e 's|^bindsym \$mod\+Shift\+Return exec --no-startup-id hemo-pwsh$|bindsym $mod+Shift+Return exec --no-startup-id hemo-open hemo-pwsh|' \
      -e 's|^bindsym \$mod\+Mod1\+Return exec --no-startup-id hemo-shotterm$|bindsym $mod+Mod1+Return exec --no-startup-id hemo-open hemo-shotterm|' \
      -e 's|^bindsym \$mod\+Shift\+Return exec --no-startup-id hemo-shotterm$|bindsym $mod+Shift+Return exec --no-startup-id hemo-open hemo-shotterm|' \
      -e 's|^bindsym \$mod\+t exec --no-startup-id thunar$|bindsym $mod+t exec --no-startup-id hemo-open thunar|' \
      -e 's|^bindsym \$mod\+b exec --no-startup-id firefox-esr$|bindsym $mod+b exec --no-startup-id hemo-open firefox-esr|' \
      -e 's|^bindsym \$mod\+d exec --no-startup-id hemo-launcher$|bindsym $mod+d exec --no-startup-id hemo-open hemo-launcher|' \
      "$U/.config/i3/config"
    # ssh TERM override (generic remote terminal type; opsec + terminfo)
    grep -q 'hemo:ssh' "$U/.zshrc" 2>/dev/null \
      || sed -n '/^# >>> hemo:ssh/,/^# <<< hemo:ssh/p' "$SCRIPT_DIR/overlays/etc/skel/.zshrc" | sed '1i\\' >> "$U/.zshrc"
    # tmux config (seed only if absent, so user edits are kept)
    [ -e "$U/.config/tmux/tmux.conf" ] || install -D -m644 "$S/tmux/tmux.conf" "$U/.config/tmux/tmux.conf"
    # history/completion/autosuggest/syntax-highlight block (appended last: highlighting must load last)
    grep -q 'hemo:shell' "$U/.zshrc" 2>/dev/null \
      || sed -n '/^# >>> hemo:shell/,/^# <<< hemo:shell/p' "$SCRIPT_DIR/overlays/etc/skel/.zshrc" | sed '1i\\' >> "$U/.zshrc"
    sed -i 's|^exec --no-startup-id udiskie -t .*$|exec --no-startup-id udiskie --smart-tray   # auto-mount removable media; tray icon only while a drive is plugged in|' "$U/.config/i3/config"
    # network/VPN tray (added after first ship): hemo-net-icons builds the accent
    # tray glyphs AND launches nm-applet. Seed it only if neither it nor a bare
    # nm-applet line is already present, so re-provisions never double-launch.
    grep -qE 'exec --no-startup-id (hemo-net-icons|nm-applet)' "$U/.config/i3/config" \
      || sed -i '/^exec --no-startup-id udiskie --smart-tray/a exec --no-startup-id hemo-net-icons         # accent network glyphs (Hemo-Net) + launch nm-applet tray (VPN/connections)' "$U/.config/i3/config"
    # volume keys: show an on-screen level (hemo-vol) instead of silent pamixer
    sed -i -e 's|^bindsym XF86AudioRaiseVolume exec --no-startup-id pamixer -i .*$|bindsym XF86AudioRaiseVolume exec --no-startup-id hemo-vol up|' \
           -e 's|^bindsym XF86AudioLowerVolume exec --no-startup-id pamixer -d .*$|bindsym XF86AudioLowerVolume exec --no-startup-id hemo-vol down|' \
           -e 's|^bindsym XF86AudioMute exec --no-startup-id pamixer -t.*$|bindsym XF86AudioMute exec --no-startup-id hemo-vol mute|' "$U/.config/i3/config"
    # night-light location/temps (toggle = $mod+Shift+b); seed if missing
    [ -e "$U/.config/gammastep/config.ini" ] || install -D -m644 "$S/gammastep/config.ini" "$U/.config/gammastep/config.ini"
    # fastfetch with the Hemo lizard logo; seed if missing (colors follow the accent)
    [ -e "$U/.config/fastfetch/config.jsonc" ] || install -D -m644 "$S/fastfetch/config.jsonc" "$U/.config/fastfetch/config.jsonc"
    # qterminal defaults (colorScheme=Hemo); seed if missing — hemo-role-apply owns colorScheme after
    [ -e "$U/.config/qterminal.org/qterminal.ini" ] || install -D -m644 "$S/qterminal.org/qterminal.ini" "$U/.config/qterminal.org/qterminal.ini"
    install -D -m644 "$S/gtk-3.0/settings.ini" "$U/.config/gtk-3.0/settings.ini"
    install -D -m644 "$S/gtk-3.0/gtk.css"      "$U/.config/gtk-3.0/gtk.css"
    [ -e "$U/.config/gtk-3.0/hemo-accent.css" ] \
      || install -D -m644 "$S/gtk-3.0/hemo-accent.css" "$U/.config/gtk-3.0/hemo-accent.css"
    echo "  refreshed i3 window rules + look + keys, picom, dunst, rofi launcher, GTK dark theme"
  else
    cp -rT "$SCRIPT_DIR/overlays/etc/skel" "$U"
    echo "  copied kitty / flameshot / i3 / polybar / zshrc"
  fi
else
  echo "  overlays/ not found next to script — writing minimal kitty config"
  install -d "$U/.config/kitty"
  printf 'font_size 11.0\nremember_window_size no\ninitial_window_width 110c\ninitial_window_height 32c\nbackground #0e1113\nforeground #e8e9e7\ncursor #e9c24a\n' \
    > "$U/.config/kitty/kitty.conf"
fi
# helper scripts (shot, hemo-identity, ...)
if [ -d "$SCRIPT_DIR/overlays/usr/local/bin" ]; then
  # regular files only — skip __pycache__/ and *.pyc; no 2>/dev/null so a real
  # install failure surfaces instead of being masked
  find "$SCRIPT_DIR/overlays/usr/local/bin" -maxdepth 1 -type f ! -name '*.pyc' \
    -exec install -m755 {} /usr/local/bin/ \;
  echo "  installed helper scripts (shot, hemo-identity, hemo-bom, hemo-welcome)"
fi
# hide the Kali menu's ~190 terminal launchers from the app launcher (GUI tools
# stay); the apt hook re-runs it so entries added by later installs are hidden too
/usr/local/bin/hemo-menu-tidy --quiet || true
printf '%s\n' 'DPkg::Post-Invoke { "[ -x /usr/local/bin/hemo-menu-tidy ] && /usr/local/bin/hemo-menu-tidy --quiet || true"; };' \
  > /etc/apt/apt.conf.d/99hemo-menu-tidy
# Overlay fonts, installed system-wide: HemoGlyphs (lizard logo glyph U+E000 for
# polybar) + a vendored JetBrainsMono Nerd Font Mono Regular. The Nerd Font is the
# OFFLINE FLOOR for braille + icon glyphs: plain fonts-jetbrains-mono has NO braille,
# so without this qterminal renders fastfetch's braille logo through a proportional
# fallback (DejaVu Sans) and smooshes it. The online download block above adds the
# rest of the family (bold/italic) when the network is reachable.
if [ -d "$SCRIPT_DIR/overlays/usr/local/share/fonts" ]; then
  install -d /usr/local/share/fonts
  find "$SCRIPT_DIR/overlays/usr/local/share/fonts" -maxdepth 1 -type f \
       \( -name '*.ttf' -o -name '*.otf' \) -exec install -m644 -t /usr/local/share/fonts {} +
  fc-cache -f /usr/local/share/fonts >/dev/null 2>&1 || true
fi
# qterminal "Hemo" + "HemoShot" color schemes. qtermwidget >=2.4 (current Kali)
# enumerates ONLY /usr/share/qtermwidget*/color-schemes/ — the user data dir is
# not scanned — so both schemes must live here. Baked copies ship as a sane
# default; hemo-role-apply --qterminal-schemes (run at the end of this script,
# and on every root re-theme) refreshes them with the live role + report
# standard values.
for qd in "$SCRIPT_DIR"/overlays/usr/share/qtermwidget*/color-schemes/Hemo.colorscheme; do
  dstdir="/usr/share/$(basename "$(dirname "$(dirname "$qd")")")/color-schemes"
  [ -f "$qd" ] || continue
  install -D -m644 "$qd" "$dstdir/Hemo.colorscheme" 2>/dev/null || true
  # ship HemoShot as a copy of Hemo (report-standard-fed refresh happens below)
  install -D -m644 "$qd" "$dstdir/HemoShot.colorscheme" 2>/dev/null || true
done
# hemo-welcome desktop entries (app-menu + XDG autostart for non-i3 DEs)
install -D -m644 "$SCRIPT_DIR/overlays/usr/share/applications/hemo-welcome.desktop" \
  /usr/share/applications/hemo-welcome.desktop 2>/dev/null || true
install -D -m644 "$SCRIPT_DIR/overlays/usr/share/applications/hemo-setup.desktop" \
  /usr/share/applications/hemo-setup.desktop 2>/dev/null || true
install -D -m644 "$SCRIPT_DIR/overlays/etc/xdg/autostart/hemo-welcome.desktop" \
  /etc/xdg/autostart/hemo-welcome.desktop 2>/dev/null || true
# firefox-esr managed policy: bookmarks + extensions + hardening (from overlays/)
if [ -f "$SCRIPT_DIR/overlays/etc/firefox-esr/policies/policies.json" ]; then
  install -D -m644 "$SCRIPT_DIR/overlays/etc/firefox-esr/policies/policies.json" \
    /etc/firefox-esr/policies/policies.json
  echo "  installed Firefox policy (bookmarks + extensions + hardening)"
fi

# ---------------------------------------------------------------- role system
# Manifests are the source of truth hemo-pkg resolves against at role-install
# time; the first-boot oneshot runs the picker before the login screen.
say "Role system (manifests + first-boot picker)"
install -d /usr/share/hemo/manifest /usr/share/hemo/wallpapers /var/lib/hemo
if [ -f "$SCRIPT_DIR/release/hemo-release.pub" ]; then
  install -m644 "$SCRIPT_DIR/release/hemo-release.pub" /usr/share/hemo/hemo-release.pub
  echo "  installed release verification key -> /usr/share/hemo/hemo-release.pub"
fi
if [ -d "$SCRIPT_DIR/manifest" ]; then
  install -m644 "$SCRIPT_DIR/manifest/"*.yml /usr/share/hemo/manifest/ 2>/dev/null || true
  echo "  installed manifests -> /usr/share/hemo/manifest"
fi
install -d /usr/share/hemo/flowers
if [ -d "$SCRIPT_DIR/overlays/usr/share/hemo/flowers" ]; then
  install -m644 "$SCRIPT_DIR/overlays/usr/share/hemo/flowers/"*.svg /usr/share/hemo/flowers/ 2>/dev/null || true
  echo "  installed role-picker flowers -> /usr/share/hemo/flowers"
fi
# Firefox policy MASTER = full bookmark set; hemo-role-apply thins the live file
# down to the primary role's folders.
if [ -f "$SCRIPT_DIR/overlays/etc/firefox-esr/policies/policies.json" ]; then
  install -D -m644 "$SCRIPT_DIR/overlays/etc/firefox-esr/policies/policies.json" \
    /usr/share/hemo/policies.master.json
fi
# Point Firefox at that policy (it reads /etc/firefox/policies/) and drop Kali's
# unwanted toolbar links from new profiles; the apt hook redoes it after upgrades.
install -D -m644 "$SCRIPT_DIR/overlays/etc/apt/apt.conf.d/99hemo-firefox" \
  /etc/apt/apt.conf.d/99hemo-firefox 2>/dev/null || true
install -D -m644 "$SCRIPT_DIR/overlays/etc/apt/apt.conf.d/90hemo-lock-timeout" \
  /etc/apt/apt.conf.d/90hemo-lock-timeout 2>/dev/null || true
# Hemo is minimal on purpose: hide kali-motd's "minimal installation" banner.
install -D -m644 "$SCRIPT_DIR/overlays/etc/kali-motd/disable-minimal-warning" \
  /etc/kali-motd/disable-minimal-warning 2>/dev/null || true
/usr/local/bin/hemo-firefox-defaults && echo "  Firefox: Hemo policy active, Kali toolbar links trimmed"
# Base wallpaper (used by the `full` role and as a last resort). Prefer the PNG
# art in branding/wallpapers/MainWC.png; else rasterize the SVG.
if [ -f "$SCRIPT_DIR/branding/wallpapers/MainWC.png" ]; then
  install -m644 "$SCRIPT_DIR/branding/wallpapers/MainWC.png" /usr/share/hemo/wallpapers/hemo-bg.png \
    && echo "  base wallpaper -> hemo-bg.png (MainW.png)"
elif command -v rsvg-convert >/dev/null 2>&1 && [ -f "$SCRIPT_DIR/branding/assets/hemo-bg.svg" ]; then
  rsvg-convert -w 2560 -h 1440 "$SCRIPT_DIR/branding/assets/hemo-bg.svg" \
    -o /usr/share/hemo/wallpapers/hemo-bg.png 2>/dev/null \
    && echo "  rendered base wallpaper -> hemo-bg.png"
fi
# Base palette (Saddle): single source of truth for neutral colors.
if [ -f "$SCRIPT_DIR/branding/palette.env" ]; then
  install -m644 "$SCRIPT_DIR/branding/palette.env" /usr/share/hemo/palette.env \
    && echo "  installed base palette -> /usr/share/hemo/palette.env"
fi
# Report (team screenshot) standard for hemo-report.
if [ -d "$SCRIPT_DIR/overlays/usr/share/hemo/report" ]; then
  install -d /usr/share/hemo/report
  install -m644 "$SCRIPT_DIR/overlays/usr/share/hemo/report/"* /usr/share/hemo/report/ 2>/dev/null \
    && echo "  installed report standard -> /usr/share/hemo/report"
fi
# Shell prompt presets for Appearance > Prompt (hemo-appearance / hemo-report).
if [ -d "$SCRIPT_DIR/overlays/usr/share/hemo/prompts" ]; then
  install -d /usr/share/hemo/prompts
  install -m644 "$SCRIPT_DIR/overlays/usr/share/hemo/prompts/"*.toml /usr/share/hemo/prompts/ 2>/dev/null \
    && echo "  installed prompt presets -> /usr/share/hemo/prompts"
fi
# fastfetch logo (the Hemo lizard; ~/.config/fastfetch/config.jsonc points here).
if [ -d "$SCRIPT_DIR/overlays/usr/share/hemo/fastfetch" ]; then
  install -d /usr/share/hemo/fastfetch
  install -m644 "$SCRIPT_DIR/overlays/usr/share/hemo/fastfetch/"*.txt /usr/share/hemo/fastfetch/ 2>/dev/null \
    && echo "  installed fastfetch logo -> /usr/share/hemo/fastfetch"
fi
# hemo-open system defaults (bias / skip_classes / autotiling_pause_ms / timeout).
# User overrides at ~/.config/hemo/open.conf. See `hemo-open --help`.
if [ -f "$SCRIPT_DIR/overlays/usr/share/hemo/open.conf" ]; then
  install -D -m644 "$SCRIPT_DIR/overlays/usr/share/hemo/open.conf" \
    /usr/share/hemo/open.conf \
    && echo "  installed hemo-open defaults -> /usr/share/hemo/open.conf"
fi
# Per-role desktop wallpapers (source art in branding/wallpapers/; names must match each
# role's profile.wallpaper in manifest/roles.yml).
for pair in \
  "RedTeamWC.png:hemo-bg-redteam.png" \
  "PenTestWC.png:hemo-bg-pentest.png" \
  "WebWC.png:hemo-bg-web.png" \
  "ReverseWC.png:hemo-bg-reverse.png" \
  "BlueHostAnnalystWC.png:hemo-bg-bluehost.png" \
  "BlueNetAnalystWC.png:hemo-bg-bluenet.png" \
  "VulnAssesorWC.png:hemo-bg-vuln.png"; do
  src="${pair%%:*}"; dst="${pair##*:}"
  [ -f "$SCRIPT_DIR/branding/wallpapers/$src" ] \
    && install -m644 "$SCRIPT_DIR/branding/wallpapers/$src" "/usr/share/hemo/wallpapers/$dst" \
    && echo "  wallpaper $dst"
done
# Default rofi launcher banner: the Hemo OS logo bar, cropped from the source art
# to its bar box. hemo-launcher uses it before the wallpaper fallback.
if [ -f "$SCRIPT_DIR/branding/assets/HemoOSBanner.png" ] && command -v convert >/dev/null 2>&1; then
  install -d /usr/share/hemo/banners
  convert "$SCRIPT_DIR/branding/assets/HemoOSBanner.png" -crop 2080x240+47+235 +repage \
    /usr/share/hemo/banners/default.png 2>/dev/null \
    && echo "  installed default launcher banner (Hemo OS bar)"
fi
# Optional per-role launcher banners: drop <role>.png into banners/ in the repo
# and hemo-launcher uses it instead of cropping the wallpaper. None = wallpaper.
if [ -d "$SCRIPT_DIR/banners" ]; then
  install -d /usr/share/hemo/banners
  install -m644 "$SCRIPT_DIR/banners/"*.png /usr/share/hemo/banners/ 2>/dev/null \
    && echo "  installed per-role launcher banners"
fi
# First-boot oneshot: runs the role picker on tty1 before lightdm.
if [ -f "$SCRIPT_DIR/firstboot/hemo-firstboot.sh" ]; then
  install -m755 "$SCRIPT_DIR/firstboot/hemo-firstboot.sh" /usr/local/sbin/hemo-firstboot
  install -m644 "$SCRIPT_DIR/firstboot/hemo-firstboot.service" /etc/systemd/system/
  systemctl enable hemo-firstboot.service >/dev/null 2>&1 \
    && echo "  enabled hemo-firstboot.service (role picker runs on next boot)" \
    || echo "  ! could not enable hemo-firstboot.service"
fi
# report folder + point flameshot/shot at this operator's home
install -d -o "$OPERATOR" -g "$OPERATOR" "$U/engagements/screenshots"
sed -i "s#/home/hemo/#/home/$OPERATOR/#g" "$U/.config/flameshot/flameshot.ini" 2>/dev/null || true
chown -R "$OPERATOR:$OPERATOR" "$U"

# ---------------------------------------------------------------- notes + editors
say "Notes app + editors"
# Obsidian: pinned .deb (version + URL in manifest/extra.yml), via hemo-pkg.
if wants "$NOTES" obsidian && ! command -v obsidian >/dev/null 2>&1; then
  /usr/local/bin/hemo-pkg install obsidian \
    || echo "  ! Obsidian install failed — retry later: sudo hemo-pkg install obsidian"
fi
# Record the answers so Hemo Welcome doesn't ask again, re-runs keep them, and
# welcome-apply knows whether Obsidian was wanted.
echo "$CODE_EDITOR" > /var/lib/hemo/editor-choice
echo "$NOTES" > /var/lib/hemo/notes-choice
install -d -o "$OPERATOR" -g "$OPERATOR" "$U/.config/hemo"
echo "$TERM_EDITOR" > "$U/.config/hemo/editor" && chown "$OPERATOR:$OPERATOR" "$U/.config/hemo/editor"
echo "  terminal editor (\$EDITOR) for $OPERATOR: $TERM_EDITOR"
# Shells set up before the editor choice existed: swap the old "nvim if installed"
# block for the skel one that reads ~/.config/hemo/editor (or add it if absent).
if [ -f "$U/.zshrc" ] && ! grep -q 'hemo/editor' "$U/.zshrc"; then
  python3 - "$U/.zshrc" "$SCRIPT_DIR/overlays/etc/skel/.zshrc" <<'PY'
import re, sys
rc, skel = sys.argv[1:]
s, k = open(rc).read(), open(skel).read()
i = k.index("# Editor: nano unless")
block = k[i:k.index("\n", k.index("command -v nvim >/dev/null && alias", i)) + 1]
old = re.compile(r"# Editor: Neovim \(LazyVim\) when installed, else nano.*?\nfi\n", re.S)
s = old.sub(lambda m: block, s, count=1) if old.search(s) else s.rstrip("\n") + "\n\n" + block
open(rc, "w").write(s)
PY
  echo "  ~/.zshrc: \$EDITOR now follows ~/.config/hemo/editor"
fi
# Launcher pins: drop a notes app that wasn't picked, and Wireshark (a role tool now).
if [ -f "$U/.config/hemo/pinned" ]; then
  sed -i '/^org\.wireshark\.Wireshark$/d' "$U/.config/hemo/pinned"
  wants "$NOTES" obsidian || sed -i '/^md\.obsidian\.Obsidian$/d' "$U/.config/hemo/pinned"
  wants "$NOTES" cherrytree || sed -i '/^cherrytree$/d' "$U/.config/hemo/pinned"
fi
if wants "$CODE_EDITOR" lazyvim; then
  # an operator from before nvim shipped in skel: seed the PINNED config, so
  # hemo-lazyvim doesn't fall back to cloning the unpinned upstream starter
  [ -f "$U/.config/nvim/lua/config/lazy.lua" ] || [ ! -d "$SCRIPT_DIR/overlays/etc/skel/.config/nvim" ] \
    || { cp -a "$SCRIPT_DIR/overlays/etc/skel/.config/nvim" "$U/.config/nvim"; chown -R "$OPERATOR:$OPERATOR" "$U/.config/nvim"; }
  say "Code editor: Neovim + LazyVim (plugins download now, so the first launch is instant)"
  SUDO_USER="$OPERATOR" /usr/local/bin/hemo-lazyvim || echo "  ! LazyVim setup had issues — it finishes on first launch, or run: sudo hemo-lazyvim"
fi

# ---------------------------------------------------------------- rebrand
say "Rebrand -> $HOSTNAME_NEW"
hostnamectl set-hostname "$HOSTNAME_NEW" 2>/dev/null || echo "$HOSTNAME_NEW" > /etc/hostname
sed -i "s/127.0.1.1.*/127.0.1.1\t$HOSTNAME_NEW/" /etc/hosts 2>/dev/null || true
cat > /etc/motd <<'MOTD'

   Hemo  —  curated Kali  —  authorized testing only

MOTD
# OS name: "Hemo OS (Kali Rolling)" — display names only, ID stays kali. The apt
# hook re-applies it after every dpkg run (base-files updates land in *.kali).
/usr/local/bin/hemo-os-release || echo "  ! hemo-os-release failed (OS still shows as Kali)"
printf '%s\n' 'DPkg::Post-Invoke { "[ -x /usr/local/bin/hemo-os-release ] && /usr/local/bin/hemo-os-release --quiet || true"; };' \
  > /etc/apt/apt.conf.d/99hemo-os-release

# ---------------------------------------------------------------- boot branding
if [ -f "$SCRIPT_DIR/branding/install-branding.sh" ]; then
  say "Boot & login branding (GRUB + Plymouth glow + login)"
  bash "$SCRIPT_DIR/branding/install-branding.sh" || echo "  ! branding step had issues (non-fatal)"
fi

# ---------------------------------------------------------------- hardening
# Baked, ALWAYS-ON bits only (safe for an offensive box). ufw is
# installed here but left DISABLED — the operator engages them with
# `hemo-harden on` when roaming hostile networks. See manifest/apt.yml.
say "OS hardening (always-on safe bits; ufw installed but off)"
apt_get apparmor apparmor-utils bubblewrap \
        ufw auditd

# AppArmor on (Kali kernel supports it); make sure the roaming tools stay off.
systemctl enable apparmor >/dev/null 2>&1 && echo "  + apparmor enabled"
systemctl disable --now ufw >/dev/null 2>&1 || true
command -v ufw >/dev/null 2>&1 && ufw --force disable >/dev/null 2>&1 || true

# Low-risk sysctls (do NOT impede tooling) from the overlay.
if [ -f "$SCRIPT_DIR/overlays/etc/sysctl.d/99-hemo-hardening.conf" ]; then
  install -D -m644 "$SCRIPT_DIR/overlays/etc/sysctl.d/99-hemo-hardening.conf" \
    /etc/sysctl.d/99-hemo-hardening.conf
  sysctl --system >/dev/null 2>&1 && echo "  + safe sysctls applied"
fi

# The BROWSER sandbox is the /usr/local/bin/firefox-esr bwrap wrapper, already
# installed from overlays/ in the desktop-config step (self-guards if bwrap is
# absent). Pentest tools are NOT sandboxed (they need raw sockets).
echo "  + firefox-esr sandbox via bubblewrap (overlays wrapper)"
echo "  (roaming hardening is OFF — engage with: sudo hemo-harden on)"

# Refresh the qtermwidget color schemes (Hemo + HemoShot) from the live role +
# report standard. Needed because qtermwidget >=2.4 reads only /usr/share, so
# the baked copies above are a placeholder until role-apply replaces them.
if command -v hemo-role-apply >/dev/null 2>&1; then
  hemo-role-apply --qterminal-schemes 2>/dev/null || true
fi

# ---------------------------------------------------------------- cleanup
say "Cleanup"
apt-get autoremove -y >/dev/null 2>&1
apt-get clean

echo
echo "=== Hemo provision finished $(date) ==="
if [ ${#MISSING[@]} -gt 0 ]; then
  say "Packages that need attention (renamed or not in this snapshot):"
  printf '    %s\n' "${MISSING[@]}"
  echo "  Check names against: apt-cache search <name>"
fi
echo "Reboot, then log in as '$OPERATOR' — Hemo Welcome opens so you can pick your"
echo "role(s); their tools install online. Later: 'sudo hemo-roles' adds roles,"
echo "'hemo-theme <role>' re-skins. See RUNBOOK.md for turning this into a VMware image."

# Critical packages missing => the run did not fully succeed. Fail loudly and
# non-zero so the build flow stops and the image is never sealed
# with the container runtime (etc.) silently absent. The seal/sysprep audit also
# checks for these independently.
if [ ${#CRITICAL[@]} -gt 0 ]; then
  echo
  say "CRITICAL packages missing — this install is NOT complete and must not be sealed:"
  printf '    %s\n' "${CRITICAL[@]}"
  echo "  Fix the apt source / network, then re-run: sudo ./provision.sh"
  exit 1
fi
