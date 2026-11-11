#!/usr/bin/env bash
# hemo-customize.sh — bake the Hemo THIN CORE into a rootfs.
#
# Runs INSIDE the build rootfs (chroot / systemd-nspawn), invoked by build.sh
# after kali-vm has produced a `-T none -D i3` rootfs and BEFORE any image is
# exported. It is the pipeline counterpart of provision.sh, with one hard rule:
#
#   IT INSTALLS NO OFFENSIVE / DEFENSIVE TOOLS.
#
# Those install per role on first boot (hemo-firstboot -> hemo-roles). This step
# only lays down the durable base: overlays, Firefox policy, hardening config,
# the hemo-* helpers, the manifests, branding, the operator user, and the
# first-boot oneshot. The baked apt packages themselves come from kali-vm -P
# (build.sh passes the base/desktop_i3/plumbing/runtime/hardening/branding
# sections of apt.yml); this script does not apt-install the core either.
#
# It expects the repo mounted/copied at $HEMO_SRC (default /opt/hemo-src).
set -uo pipefail

SRC="${HEMO_SRC:-/opt/hemo-src}"
OPERATOR="${HEMO_OPERATOR:-hemo}"
HOSTNAME_NEW="${HEMO_HOSTNAME:-hemo}"
U="/home/$OPERATOR"

[ "$(id -u)" -eq 0 ] || { echo "hemo-customize: must run as root (in the chroot)"; exit 1; }
[ -d "$SRC" ] || { echo "hemo-customize: repo not found at $SRC (set HEMO_SRC)"; exit 1; }
export DEBIAN_FRONTEND=noninteractive
say(){ printf '\n\033[1;31m[hemo-customize]\033[0m %s\n' "$*"; }

# ---------------------------------------------------------------- helper bins
say "hemo-* helper scripts -> /usr/local/bin"
# regular files only — skip __pycache__/ and *.pyc; no 2>/dev/null so a real
# install failure surfaces instead of being masked
find "$SRC/overlays/usr/local/bin" -maxdepth 1 -type f ! -name '*.pyc' \
  -exec install -m755 {} /usr/local/bin/ \;
echo "  installed $(find "$SRC/overlays/usr/local/bin" -maxdepth 1 -type f ! -name '*.pyc' | wc -l) helpers"
# hide the Kali menu's ~190 terminal launchers from the app launcher (GUI tools
# stay); the apt hook re-runs it so entries added by later installs are hidden too
/usr/local/bin/hemo-menu-tidy --quiet || true
printf '%s\n' 'DPkg::Post-Invoke { "[ -x /usr/local/bin/hemo-menu-tidy ] && /usr/local/bin/hemo-menu-tidy --quiet || true"; };' \
  > /etc/apt/apt.conf.d/99hemo-menu-tidy
# Hemo Glyphs: the lizard logo as a font glyph (U+E000) for polybar
install -D -m644 "$SRC/overlays/usr/local/share/fonts/HemoGlyphs.ttf" /usr/local/share/fonts/HemoGlyphs.ttf \
  && fc-cache -f /usr/local/share/fonts >/dev/null 2>&1 || true
# hemo-welcome desktop entries (app-menu + XDG autostart)
install -D -m644 "$SRC/overlays/usr/share/applications/hemo-welcome.desktop" \
  /usr/share/applications/hemo-welcome.desktop 2>/dev/null || true
install -D -m644 "$SRC/overlays/usr/share/applications/hemo-setup.desktop" \
  /usr/share/applications/hemo-setup.desktop 2>/dev/null || true
install -D -m644 "$SRC/overlays/etc/xdg/autostart/hemo-welcome.desktop" \
  /etc/xdg/autostart/hemo-welcome.desktop 2>/dev/null || true

# ---------------------------------------------------------------- skel / dots
# Ship the desktop config through /etc/skel so the operator (and any future
# user) is created with it, and also lay it into the operator home below.
say "Desktop config -> /etc/skel"
if [ -d "$SRC/overlays/etc/skel" ]; then
  cp -rT "$SRC/overlays/etc/skel" /etc/skel
  echo "  copied kitty / i3 / polybar / rofi / zsh / flameshot into /etc/skel"
fi

# ---------------------------------------------------------------- system files
say "System overlays (Firefox policy, sysctl hardening)"
if [ -f "$SRC/overlays/etc/firefox-esr/policies/policies.json" ]; then
  install -D -m644 "$SRC/overlays/etc/firefox-esr/policies/policies.json" \
    /etc/firefox-esr/policies/policies.json
  echo "  Firefox managed policy installed"
fi
if [ -f "$SRC/overlays/etc/sysctl.d/99-hemo-hardening.conf" ]; then
  install -D -m644 "$SRC/overlays/etc/sysctl.d/99-hemo-hardening.conf" \
    /etc/sysctl.d/99-hemo-hardening.conf
  echo "  safe sysctls installed (applied at boot)"
fi

# ---------------------------------------------------------------- manifests
say "Role manifests -> /usr/share/hemo"
install -d /usr/share/hemo/manifest /usr/share/hemo/wallpapers /var/lib/hemo
install -m644 "$SRC/manifest/"*.yml /usr/share/hemo/manifest/ 2>/dev/null \
  && echo "  installed manifests the role installer resolves against"
install -d /usr/share/hemo/flowers
install -m644 "$SRC/overlays/usr/share/hemo/flowers/"*.svg /usr/share/hemo/flowers/ 2>/dev/null \
  && echo "  installed role-picker flowers"
# Base wallpaper + palette. Prefer branding/wallpapers/MainWC.png for hemo-bg.png (else the
# branding installer's SVG render remains).
[ -f "$SRC/branding/wallpapers/MainWC.png" ] \
  && install -m644 "$SRC/branding/wallpapers/MainWC.png" /usr/share/hemo/wallpapers/hemo-bg.png \
  && echo "  base wallpaper -> hemo-bg.png (MainW.png)"
[ -f "$SRC/branding/palette.env" ] \
  && install -m644 "$SRC/branding/palette.env" /usr/share/hemo/palette.env \
  && echo "  installed base palette -> /usr/share/hemo/palette.env"
if [ -d "$SRC/overlays/usr/share/hemo/report" ]; then
  install -d /usr/share/hemo/report
  install -m644 "$SRC/overlays/usr/share/hemo/report/"* /usr/share/hemo/report/ 2>/dev/null \
    && echo "  installed report standard -> /usr/share/hemo/report"
fi
# Shell prompt presets for Appearance > Prompt (hemo-appearance / hemo-report).
if [ -d "$SRC/overlays/usr/share/hemo/prompts" ]; then
  install -d /usr/share/hemo/prompts
  install -m644 "$SRC/overlays/usr/share/hemo/prompts/"*.toml /usr/share/hemo/prompts/ 2>/dev/null \
    && echo "  installed prompt presets -> /usr/share/hemo/prompts"
fi
# fastfetch logo (the Hemo lizard; ~/.config/fastfetch/config.jsonc points here).
if [ -d "$SRC/overlays/usr/share/hemo/fastfetch" ]; then
  install -d /usr/share/hemo/fastfetch
  install -m644 "$SRC/overlays/usr/share/hemo/fastfetch/"*.txt /usr/share/hemo/fastfetch/ 2>/dev/null \
    && echo "  installed fastfetch logo -> /usr/share/hemo/fastfetch"
fi
# Per-role desktop wallpapers (source art in branding/wallpapers/; names must match each
# role's profile.wallpaper in manifest/roles.yml). Base hemo-bg.png comes from
# branding/install-branding.sh.
for pair in \
  "RedTeamWC.png:hemo-bg-redteam.png" \
  "PenTestWC.png:hemo-bg-pentest.png" \
  "WebWC.png:hemo-bg-web.png" \
  "ReverseWC.png:hemo-bg-reverse.png" \
  "BlueHostAnnalystWC.png:hemo-bg-bluehost.png" \
  "BlueNetAnalystWC.png:hemo-bg-bluenet.png" \
  "VulnAssesorWC.png:hemo-bg-vuln.png"; do
  src="${pair%%:*}"; dst="${pair##*:}"
  [ -f "$SRC/branding/wallpapers/$src" ] \
    && install -m644 "$SRC/branding/wallpapers/$src" "/usr/share/hemo/wallpapers/$dst" \
    && echo "  wallpaper $dst"
done
# Default rofi launcher banner: the Hemo OS logo bar (cropped to its bar box).
if [ -f "$SRC/branding/assets/HemoOSBanner.png" ] && command -v convert >/dev/null 2>&1; then
  install -d /usr/share/hemo/banners
  convert "$SRC/branding/assets/HemoOSBanner.png" -crop 2080x240+47+235 +repage \
    /usr/share/hemo/banners/default.png 2>/dev/null \
    && echo "  installed default launcher banner (Hemo OS bar)"
fi
# Optional per-role launcher banners (banners/<role>.png); none = wallpaper crop.
if [ -d "$SRC/banners" ]; then
  install -d /usr/share/hemo/banners
  install -m644 "$SRC/banners/"*.png /usr/share/hemo/banners/ 2>/dev/null \
    && echo "  installed per-role launcher banners"
fi
# Firefox policy MASTER (full bookmark set; hemo-role-apply thins it per role).
if [ -f "$SRC/overlays/etc/firefox-esr/policies/policies.json" ]; then
  install -D -m644 "$SRC/overlays/etc/firefox-esr/policies/policies.json" \
    /usr/share/hemo/policies.master.json
fi
# Point Firefox at that policy (it reads /etc/firefox/policies/) and drop Kali's
# unwanted toolbar links from new profiles; the apt hook redoes it after upgrades.
install -D -m644 "$SRC/overlays/etc/apt/apt.conf.d/99hemo-firefox" \
  /etc/apt/apt.conf.d/99hemo-firefox
install -D -m644 "$SRC/overlays/etc/apt/apt.conf.d/90hemo-lock-timeout" \
  /etc/apt/apt.conf.d/90hemo-lock-timeout
install -D -m644 "$SRC/overlays/etc/kali-motd/disable-minimal-warning" \
  /etc/kali-motd/disable-minimal-warning 2>/dev/null || true
/usr/local/bin/hemo-firefox-defaults && echo "  Firefox: Hemo policy active, Kali toolbar links trimmed"

# ---------------------------------------------------------------- hardening on
say "Hardening: enable AppArmor, keep roaming bits OFF"
systemctl enable apparmor >/dev/null 2>&1 || true
systemctl disable ufw >/dev/null 2>&1 || true   # engaged via hemo-harden
# Browser sandbox is the /usr/local/bin/firefox-esr bwrap wrapper installed from
# overlays/ above (self-guards if bwrap is absent). Nothing to do here.

# ---------------------------------------------------------------- runtime
say "Container runtime (BloodHound CE + future services; nothing started)"
systemctl enable docker >/dev/null 2>&1 && echo "  docker enabled (idle)"

# ---------------------------------------------------------------- operator
say "Operator user: $OPERATOR (default password $OPERATOR, like Kali's kali/kali; no forced change)"
# kali-vm seeds a default 'kali' user; replace it with ours.
if id kali >/dev/null 2>&1 && [ "$OPERATOR" != kali ]; then
  deluser --remove-home kali >/dev/null 2>&1 || userdel -r kali 2>/dev/null || true
  echo "  removed default 'kali' user"
fi
if ! id "$OPERATOR" >/dev/null 2>&1; then
  # only groups that exist (wireshark is a role tool now; hemo-pkg adds the group later)
  grps=sudo; for g in docker wireshark kali-trusted; do getent group "$g" >/dev/null && grps="$grps,$g"; done
  useradd -m -s /usr/bin/zsh -G "$grps" "$OPERATOR"
  echo "$OPERATOR:$OPERATOR" | chpasswd
fi
# make sure the operator carries the desktop config even if created pre-skel
cp -rT /etc/skel "$U" 2>/dev/null || true
install -d -o "$OPERATOR" -g "$OPERATOR" "$U/engagements/screenshots"
sed -i "s#/home/hemo/#$U/#g" "$U/.config/flameshot/flameshot.ini" 2>/dev/null || true
# Default the login session to i3 (not Kali's Xfce default), via lightdm + ~/.dmrc + AccountsService.
# let `sudo hemo-*` find the helpers in /usr/local/bin (default secure_path omits it)
printf 'Defaults secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"\n' > /etc/sudoers.d/10-hemo-path
chmod 0440 /etc/sudoers.d/10-hemo-path
visudo -cf /etc/sudoers.d/10-hemo-path >/dev/null 2>&1 || rm -f /etc/sudoers.d/10-hemo-path
install -d /etc/lightdm/lightdm.conf.d
printf '[Seat:*]\nuser-session=i3\n' > /etc/lightdm/lightdm.conf.d/60-hemo-session.conf

# default apps: kitty for terminal tools (the Kali menu's 190 CLI launchers and
# rofi go through x-terminal-emulator), Thunar for folders (else an editor like VSCodium wins)
if [ -x /usr/bin/kitty ]; then
  update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/kitty 20 >/dev/null 2>&1 || true
  update-alternatives --set x-terminal-emulator /usr/bin/kitty >/dev/null 2>&1 || true
fi
M=/etc/xdg/mimeapps.list
[ -f "$M" ] || printf '[Default Applications]\n' > "$M"
grep -q '^\[Default Applications\]' "$M" || printf '[Default Applications]\n' >> "$M"
sed -i '/^inode\/directory=/d' "$M"
sed -i '/^\[Default Applications\]/a inode/directory=thunar.desktop' "$M"
printf '[Desktop]\nSession=i3\n' > "$U/.dmrc"
# "Default Xsession" (lightdm-xsession) runs ~/.xsession if present, else Xfce
[ -e "$U/.xsession" ] || { printf '#!/bin/sh\n# Hemo: "Default Xsession" -> i3\nexec i3\n' > "$U/.xsession"; chmod 755 "$U/.xsession"; }
install -d /var/lib/AccountsService/users
printf '[User]\nSession=i3\nXSession=i3\nSystemAccount=false\n' \
  > "/var/lib/AccountsService/users/$OPERATOR"
chown -R "$OPERATOR:$OPERATOR" "$U"

# ---------------------------------------------------------------- identity
say "Branding + hostname"
hostnamectl set-hostname "$HOSTNAME_NEW" 2>/dev/null || echo "$HOSTNAME_NEW" > /etc/hostname
sed -i "s/127.0.1.1.*/127.0.1.1\t$HOSTNAME_NEW/" /etc/hosts 2>/dev/null || true
printf '\n   Hemo  —  curated Kali  —  authorized testing only\n\n' > /etc/motd
# OS name: "Hemo OS (Kali Rolling)" — display names only, ID stays kali. The apt
# hook re-applies it after every dpkg run (base-files updates land in *.kali).
/usr/local/bin/hemo-os-release || echo "  ! hemo-os-release failed (OS still shows as Kali)"
printf '%s\n' 'DPkg::Post-Invoke { "[ -x /usr/local/bin/hemo-os-release ] && /usr/local/bin/hemo-os-release --quiet || true"; };' \
  > /etc/apt/apt.conf.d/99hemo-os-release
if [ -f "$SRC/branding/install-branding.sh" ]; then
  bash "$SRC/branding/install-branding.sh" || echo "  ! branding step had issues (non-fatal)"
fi

# ---------------------------------------------------------------- remove.yml
say "Purge packages listed in remove.yml (baseline declutter)"
PURGE=$(python3 - "$SRC/manifest/remove.yml" <<'PY' 2>/dev/null || true
import sys,yaml
d=yaml.safe_load(open(sys.argv[1],encoding='utf-8')) or {}
print(" ".join(d.get("purge",[]) or []))
PY
)
if [ -n "${PURGE// }" ]; then
  apt-get purge -y $PURGE >/dev/null 2>&1 && echo "  purged: $PURGE"
  apt-get autoremove --purge -y >/dev/null 2>&1 || true
else
  echo "  remove.yml purge list is empty (nothing to do)"
fi

# ---------------------------------------------------------------- first boot
say "Enable the first-boot role picker"
install -m755 "$SRC/firstboot/hemo-firstboot.sh" /usr/local/sbin/hemo-firstboot
install -m644 "$SRC/firstboot/hemo-firstboot.service" /etc/systemd/system/
# `systemctl enable` manages symlinks fine in a chroot; fall back if it balks.
systemctl enable hemo-firstboot.service >/dev/null 2>&1 \
  || ln -sf /etc/systemd/system/hemo-firstboot.service \
       /etc/systemd/system/multi-user.target.wants/hemo-firstboot.service
echo "  hemo-firstboot.service enabled (runs the picker on first boot)"
# Make sure this image boots as a FRESH clone: no stale done-flag or identity.
rm -f /var/lib/hemo/firstboot.done
: > /etc/machine-id
rm -f /etc/ssh/ssh_host_* 2>/dev/null || true

say "Thin core baked. Offensive/defensive tools install per role on first boot."
