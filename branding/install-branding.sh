#!/usr/bin/env bash
# Hemo — boot & login branding installer. Run INSIDE the VM as root.
#
#   sudo ./branding/install-branding.sh
#
# Applies: GRUB theme, Plymouth boot-glow animation, and the LightDM login
# background. Art sources, first match wins per slot:
#   BOOT LOGO (Plymouth): assets/hemo-logo-text.png (disc + "HemoOS" wordmark)
#     -> assets/hemo-logo.png
#   USER PICTURE (greeter + ~/.face): assets/hemo-head.png (toad head on the disc)
#   BACKGROUND (grub): plain light tan ($TAN), unless assets/hemo-bg.png exists
#   LOGIN BACKGROUND: branding/wallpapers/Login.png, widened to the screen edges (hemo-greeter-bg)
# Drop in your own and re-run to rebrand.
#
# VM note: Plymouth animation can look plain or flicker under some guest video
# drivers; GRUB and the login screen always render. This only changes looks,
# not boot behavior.

set -uo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Run as root: sudo $0"; exit 1; }
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
say(){ printf '\n\033[1;31m[hemo-branding]\033[0m %s\n' "$*"; }

export DEBIAN_FRONTEND=noninteractive
say "Dependencies"
apt-get install -y --no-install-recommends \
  plymouth plymouth-themes librsvg2-bin imagemagick \
  lightdm lightdm-gtk-greeter fonts-jetbrains-mono >/dev/null 2>&1 || \
  echo "  (some deps may already be present / named differently — continuing)"

# ---- rasterize SVG -> PNG (rsvg-convert > inkscape > imagemagick) ----
rasterize(){ # src w h out
  if   command -v rsvg-convert >/dev/null 2>&1; then rsvg-convert -w "$2" -h "$3" "$1" -o "$4";
  elif command -v inkscape    >/dev/null 2>&1; then inkscape "$1" -w "$2" -h "$3" -o "$4" >/dev/null 2>&1;
  elif command -v convert      >/dev/null 2>&1; then convert -background none "$1" -resize "${2}x${3}" "$4";
  else echo "  ! no SVG rasterizer found"; return 1; fi
}

DARK="#15130f"   # Hemo dark theme background, used to pad raster art to size
TAN="#d6c198"    # wallpaper background tan (branding/wallpapers/*W.png) — plain login/GRUB background

# make_png OUT W H BG SRC...  — first existing SRC wins. SVG is rasterized;
# raster (jpg/png) is resized and PADDED (not stretched) onto BG ("none" = keep
# transparent). Lets the branding/concept/*.jpg defaults be overridden by assets/*.png|svg.
make_png(){
  local out=$1 w=$2 h=$3 bg=$4; shift 4
  local src=""
  for s in "$@"; do [ -f "$s" ] && { src="$s"; break; }; done
  [ -z "$src" ] && { echo "  ! no source art for $(basename "$out")"; return 1; }
  case "${src,,}" in
    *.svg) rasterize "$src" "$w" "$h" "$out" || return 1;;
    *) command -v convert >/dev/null 2>&1 || { echo "  ! imagemagick 'convert' missing"; return 1; }
       convert "$src" -resize "${w}x${h}" -background "$bg" -gravity center \
         -extent "${w}x${h}" "$out" 2>/dev/null || return 1;;
  esac
  echo "  $(basename "$out") <- $(basename "$src")"
}

# ---- Plymouth theme ----
say "Plymouth boot glow"
PT=/usr/share/plymouth/themes/hemo
mkdir -p "$PT"
cp "$HERE/plymouth/hemo.plymouth" "$HERE/plymouth/hemo.script" "$PT/"
# logo: the disc emblem with the "HemoOS" wordmark (transparent outside the disc).
make_png "$PT/logo.png" 360 360 none \
  "$HERE/assets/hemo-logo-text.png" "$HERE/assets/hemo-logo.png" || true
update-alternatives --install /usr/share/plymouth/themes/default.plymouth \
  default.plymouth "$PT/hemo.plymouth" 200 >/dev/null 2>&1 || true
if command -v plymouth-set-default-theme >/dev/null 2>&1; then
  plymouth-set-default-theme hemo >/dev/null 2>&1 || true
fi
update-initramfs -u >/dev/null 2>&1 && echo "  initramfs rebuilt" || echo "  ! update-initramfs failed"

# ---- backgrounds ----
say "Backgrounds"
mkdir -p /usr/share/backgrounds /boot/grub/themes/hemo /usr/share/hemo/branding
# login/GRUB background: plain light tan, unless custom art is dropped in
if [ -f "$HERE/assets/hemo-bg.png" ]; then
  make_png /usr/share/backgrounds/hemo-bg.png 1920 1080 "$TAN" "$HERE/assets/hemo-bg.png" || true
else
  convert -size 1920x1080 "xc:$TAN" /usr/share/backgrounds/hemo-bg.png \
    && echo "  hemo-bg.png <- plain $TAN"
fi
cp /usr/share/backgrounds/hemo-bg.png /boot/grub/themes/hemo/background.png 2>/dev/null || true
# desktop base wallpaper (role-apply fallback) is the flower art provision.sh installs
# from branding/wallpapers/MainWC.png; only seed it from the login background if it's missing.
install -d /usr/share/hemo/wallpapers
[ -f /usr/share/hemo/wallpapers/hemo-bg.png ] || \
  cp /usr/share/backgrounds/hemo-bg.png /usr/share/hemo/wallpapers/hemo-bg.png 2>/dev/null || true
# the "HemoOS" wordmark lettering cut from the logo (transparent, no disc/lizard),
# used as the text-only brand in hemo-welcome's settings sidebar.
# cream wordmark (dark surfaces) + dark recolor (light-mode sidebar)
for w in hemo-wordmark.png hemo-wordmark-dark.png; do
  [ -f "$HERE/assets/$w" ] && install -m644 "$HERE/assets/$w" "/usr/share/hemo/branding/$w" \
    && echo "  $w <- $w"
done

# toad marks for in-app headers: hemo-mark.png = cream (on dark surfaces),
# hemo-mark-dark.png = brown (on light surfaces). hemo-welcome picks per mode.
for m in hemo-mark.png hemo-mark-dark.png; do
  [ -f "$HERE/assets/$m" ] && install -m644 "$HERE/assets/$m" "/usr/share/hemo/branding/$m" \
    && echo "  $m <- $m"
done

# ---- GRUB theme ----
say "GRUB theme"
cp "$HERE/grub/theme.txt" /boot/grub/themes/hemo/theme.txt
# themed menu font (named so theme.txt can reference it); falls back gracefully
JBM="$(fc-match -f '%{file}' 'JetBrains Mono' 2>/dev/null)"
if [ -n "$JBM" ] && [ -f "$JBM" ] && command -v grub-mkfont >/dev/null 2>&1; then
  grub-mkfont -n "Hemo Mono" -s 16 -o /boot/grub/themes/hemo/font16.pf2 "$JBM" 2>/dev/null || true
  grub-mkfont -n "Hemo Mono" -s 14 -o /boot/grub/themes/hemo/font14.pf2 "$JBM" 2>/dev/null || true
else
  echo "  ! JetBrains Mono / grub-mkfont unavailable — theme uses default font"
fi
# All GRUB settings live in a drop-in, not /etc/default/grub: Kali's
# /etc/default/grub.d/kali-themes.cfg is sourced AFTER /etc/default/grub and resets
# GRUB_THEME, so a later-sorting drop-in is what wins (and survives kali-themes
# upgrades). It also works in the image-build rootfs, which has no bootloader yet
# (kali-vm installs grub-pc or grub-efi later and its update-grub reads this file).
install -d /etc/default/grub.d
cat > /etc/default/grub.d/zz-hemo.cfg <<'GRUBCFG'
# Hemo: sourced after kali-themes.cfg (alphabetical), so the Hemo theme wins.
GRUB_THEME="/boot/grub/themes/hemo/theme.txt"
# 1280x720, not 1920x1080: vmwgfx keeps GRUB's mode until open-vm-tools resizes
# the guest, so Plymouth draws into whatever GRUB set. A 1080-tall mode in the
# ~1918x839 VMware window gets cropped and the boot logo lands near the bottom;
# a mode smaller than the window is shown centred instead.
GRUB_GFXMODE="1280x720,auto"
GRUB_GFXPAYLOAD_LINUX=keep
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
# /etc/grub.d/05_debian_theme runs AFTER 00_header's `set theme=` and emits a
# `background_image /usr/share/grub/themes/kali/grub-4x3.png`, which repaints the
# themed menu Kali-blue (the "second Kali menu" after ours). Setting GRUB_BACKGROUND
# (even empty) makes 05_debian_theme take the user-background branch, fail on the
# empty path, and skip the desktop-base Kali wallpaper — so the Hemo theme is final.
GRUB_BACKGROUND=""
# Single-OS machine, so skip drawing the GRUB menu. It waits 1s on a blank
# screen; press Esc during that second to get the menu back.
GRUB_TIMEOUT_STYLE=hidden
GRUB_TIMEOUT=1
GRUBCFG
if [ -f /boot/grub/grub.cfg ]; then
  update-grub >/dev/null 2>&1 && echo "  grub updated" || echo "  ! update-grub failed"
else
  echo "  no bootloader yet (image build) — zz-hemo.cfg applies when GRUB is installed"
fi

# ---- LightDM login ----
say "LightDM login screen"
if [ -d /etc/lightdm ]; then
  cp "$HERE/lightdm/lightdm-gtk-greeter.conf" /etc/lightdm/lightdm-gtk-greeter.conf
  # greeter-only GTK theme: Adwaita-dark with the login box in Hemo brown
  rm -rf /usr/share/themes/Hemo-Greeter
  cp -r "$HERE/lightdm/Hemo-Greeter" /usr/share/themes/Hemo-Greeter
  # toad head as the default user picture: greeter fallback, new users (skel), and
  # existing users still on Kali's stock ~/.face. A user's own custom picture is kept.
  make_png /usr/share/hemo/branding/hemo-head.png 256 256 none "$HERE/assets/hemo-head.png" || true
  if [ -f /usr/share/hemo/branding/hemo-head.png ]; then
    kali_face=""; [ -f /etc/skel/.face ] && kali_face="$(sha256sum < /etc/skel/.face)"
    for h in /home/*; do
      [ -d "$h" ] || continue
      if [ ! -e "$h/.face" ] || [ "$(sha256sum < "$h/.face")" = "$kali_face" ]; then
        install -m644 -o "$(stat -c %U "$h")" -g "$(stat -c %G "$h")" \
          /usr/share/hemo/branding/hemo-head.png "$h/.face"
        ln -sfn .face "$h/.face.icon"; chown -h "$(stat -c %U:%G "$h")" "$h/.face.icon"
        echo "  $h/.face <- hemo-head.png"
      fi
    done
    install -m644 /usr/share/hemo/branding/hemo-head.png /etc/skel/.face
    ln -sfn .face /etc/skel/.face.icon
  fi
  # The login box shows the HemoOS logo + wordmark instead, with no disc so it sits
  # straight on the brown box: it's the greeter default, and the AccountsService
  # icon of every user still on the Hemo head (~/.face itself stays the head — the
  # lock screen uses it).
  convert "$HERE/assets/hemo-logo-text-mark.png" -resize 200x200 -background none -gravity center \
    -extent 256x256 /usr/share/hemo/branding/hemo-login.png && echo "  hemo-login.png <- hemo-logo-text-mark.png"
  if [ -f /usr/share/hemo/branding/hemo-login.png ]; then
    for h in /home/*; do
      u=$(basename "$h"); uid=$(id -u "$u" 2>/dev/null) || continue
      cmp -s "$h/.face" /usr/share/hemo/branding/hemo-head.png || continue
      busctl call org.freedesktop.Accounts "/org/freedesktop/Accounts/User$uid" \
        org.freedesktop.Accounts.User SetIconFile s /usr/share/hemo/branding/hemo-login.png \
        >/dev/null 2>&1 && echo "  $u login picture <- hemo-login.png"
      # that save rewrites the user's AccountsService file from the daemon's cache;
      # re-assert the i3 session so it can't be dropped (provision.sh sets it too)
      for m in SetXSession SetSession; do
        busctl call org.freedesktop.Accounts "/org/freedesktop/Accounts/User$uid" \
          org.freedesktop.Accounts.User "$m" s i3 >/dev/null 2>&1 || true
      done
    done
  fi
  # login background: branding/wallpapers/Login.png widened so the flowers sit on the far
  # edges (hemo-edge-art). hemo-greeter-bg re-renders it at the greeter's real
  # size on every login screen; pre-render 1920x1080 so there's always one.
  if [ -f "$HERE/wallpapers/Login.png" ]; then
    install -m644 "$HERE/wallpapers/Login.png" /usr/share/hemo/branding/login-art.png
    for t in hemo-edge-art hemo-greeter-bg; do
      install -m755 "$HERE/../overlays/usr/local/bin/$t" /usr/local/bin/$t
    done
    install -d /var/cache/hemo
    /usr/local/bin/hemo-edge-art /var/cache/hemo/login-bg.png 1920 1080 \
      && chmod 644 /var/cache/hemo/login-bg.png && echo "  login-bg.png <- branding/wallpapers/Login.png (edges)"
  fi
  install -d /var/cache/hemo
  [ -s /var/cache/hemo/login-bg.png ] || cp /usr/share/backgrounds/hemo-bg.png /var/cache/hemo/login-bg.png
  mkdir -p /etc/lightdm/lightdm.conf.d
  printf '[Seat:*]\ngreeter-session=lightdm-gtk-greeter\ndisplay-setup-script=/usr/local/bin/hemo-greeter-bg\n' \
    > /etc/lightdm/lightdm.conf.d/50-hemo.conf
  echo "  greeter configured"
else
  echo "  ! /etc/lightdm not present (is lightdm installed?) — skipped"
fi

say "Done. Reboot to see: GRUB theme -> boot glow -> themed login."
