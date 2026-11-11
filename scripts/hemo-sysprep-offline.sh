#!/usr/bin/env bash
# hemo-sysprep-offline — prepare the Hemo VMware build disk as a golden image, from a
# Kali Live session. The build VM is OFF; this runs in the Live ISO's RAM, so the target
# disk is only mounted under /mnt and nothing writes to it except this script.
#
#   sudo bash /tmp/hemo-sysprep/hemo-sysprep-offline.sh --check    # read-only audit
#   sudo bash /tmp/hemo-sysprep/hemo-sysprep-offline.sh --apply    # prepare, then zero free space
#   sudo bash scripts/hemo-sysprep-offline.sh --preview /          # audit logic on the live build VM
#
# Intended for a disposable build disk, not a machine you keep.
# The spec it enforces is docs/golden-image.md "Definition of clean".
set -uo pipefail
MODE=${1:-}; PREVIEW_ROOT=${2:-}
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
[ "$(id -u)" -eq 0 ] || { echo "run as root (sudo)"; exit 1; }
case "$MODE" in --check|--apply|--preview) ;; *) echo "usage: $0 --check|--apply|--preview /"; exit 2;; esac

STAGE=/var/tmp/hemo-sysprep          # where C7 stages this script + its inputs on the build disk
if [ "$MODE" = --preview ]; then
  T=${PREVIEW_ROOT:-/}; T=${T%/}
  [ -f "$STAGE/seal.conf" ] && . "$STAGE/seal.conf"
  DENY=$STAGE/denylist
  OPERATOR=${OPERATOR:-hemo}; BUILD_USER=${BUILD_USER:-kali}; OPERATOR_UID=${OPERATOR_UID:-1000}
  SWAP_KIND=${SWAP_KIND:-none}; ALLOW_KEYS=${ALLOW_KEYS:-}
else
  grep -qw 'boot=live' /proc/cmdline || { echo "refusing: not a Kali Live session"; exit 1; }
  case "$HERE" in /tmp/*) ;; *) echo "refusing: copy hemo-sysprep to /tmp first (Part D2)"; exit 1;; esac
  . "$HERE/seal.conf"; DENY="$HERE/denylist"
  DEV=$(blkid -U "$ROOT_UUID") || { echo "no filesystem with UUID $ROOT_UUID"; exit 1; }
  [ "$(findmnt -n -o SOURCE /)" != "$DEV" ] || { echo "refusing: $DEV is the running root"; exit 1; }
  findmnt -n "$DEV" >/dev/null && { echo "refusing: $DEV is already mounted (umount it first)"; exit 1; }
  swapoff -a 2>/dev/null || true
  T=/mnt/hemo-target; mkdir -p "$T"
  if [ "$MODE" = --check ]; then mount -o ro "$DEV" "$T" || exit 1
  else mount "$DEV" "$T" || exit 1; fi
  trap 'mountpoint -q "$T" && umount "$T"' EXIT
fi
[ -f "$DENY" ] || { echo "denylist missing ($DENY)"; [ "$MODE" = --apply ] && exit 1; }

# run a command inside the target root (directly when previewing the running system)
inroot(){ if [ -z "$T" ]; then "$@"; else chroot "$T" "$@"; fi; }

# ---------------- prepare (only on --apply) ----------------
prepare(){
  local r="$T" u="$BUILD_USER" op="$OPERATOR"
  echo "== build account ($u)"
  if inroot id "$u" >/dev/null 2>&1; then
    local uid; uid=$(inroot id -u "$u")
    userdel -R "$r" -r "$u" 2>&1 | grep -v 'mail spool' || true
    groupdel -R "$r" "$u" 2>/dev/null || true
    echo "   removing $(find "$r" -xdev -uid "$uid" 2>/dev/null | wc -l) leftover files owned by uid $uid"
    find "$r" -xdev -uid "$uid" -prune -exec rm -rf {} + 2>/dev/null || true
    rm -f "$r/var/lib/AccountsService/users/$u" "$r/var/lib/AccountsService/icons/$u"
  fi
  # give the operator the build account's old uid so the image matches Kali's layout
  local cur; cur=$(inroot id -u "$op")
  if [ "$cur" != "$OPERATOR_UID" ] && ! inroot getent passwd "$OPERATOR_UID" >/dev/null \
     && ! inroot getent group "$OPERATOR_UID" >/dev/null; then
    echo "   $op uid $cur -> $OPERATOR_UID"
    groupmod -R "$r" -g "$OPERATOR_UID" "$op" 2>/dev/null || true
    usermod  -R "$r" -u "$OPERATOR_UID" -g "$OPERATOR_UID" "$op"
    find "$r" -xdev -uid "$cur" -exec chown -h "$OPERATOR_UID" {} + 2>/dev/null || true
    find "$r" -xdev -gid "$cur" -exec chgrp -h "$OPERATOR_UID" {} + 2>/dev/null || true
  fi
  rm -f "$r/etc/sudoers.d/99-hemo-build-temp"
  rm -f "$r"/etc/{passwd,shadow,group,gshadow,subuid,subgid}- "$r"/etc/*.dpkg-old "$r"/etc/*.dpkg-dist
  find "$r/var/backups" -mindepth 1 -delete 2>/dev/null || true

  echo "== homes"
  for h in "$r/root" "$r/home/$op"; do
    rm -rf "$h/.cache" "$h/.local/state" "$h/.local/share/Trash" "$h/.ssh" "$h/.mozilla" \
           "$h/.bash_history" "$h/.zsh_history" "$h/.zhistory" "$h/.python_history" \
           "$h/.lesshst" "$h/.viminfo" "$h/.wget-hsts" "$h/.Xauthority" "$h/.ICEauthority" \
           "$h/.xsession-errors" "$h/.xsession-errors.old" "$h/.sudo_as_admin_successful" \
           "$h"/.zcompdump* "$h/.local/share/recently-used.xbel" "$h/.local/share/powershell" "$h/.npm" "$h/go/pkg" 2>/dev/null || true
  done

  echo "== logs, state, caches, temp"
  find "$r/var/log" -type f -delete 2>/dev/null || true
  rm -rf "$r/var/log/journal"/* "$r/var/lib/systemd/coredump"/* "$r/var/crash"/* 2>/dev/null || true
  [ -f "$r/var/lib/wtmpdb/wtmp.db" ] && rm -f "$r/var/lib/wtmpdb/wtmp.db"
  rm -f "$r"/var/lib/lastlog/* 2>/dev/null || true
  find "$r/tmp" "$r/var/tmp" -mindepth 1 -delete 2>/dev/null || true
  rm -rf "$r/var/lib/docker"/* "$r/var/lib/containerd"/* 2>/dev/null || true
  rm -f "$r/var/lib/plocate/plocate.db" 2>/dev/null || true
  rm -rf "$r/var/lib/sudo"/* "$r/var/lib/systemd/timers"/* "$r/var/lib/systemd/linger"/* \
         "$r/var/lib/upower"/* "$r/var/spool/cron/crontabs"/* "$r/var/mail"/* 2>/dev/null || true
  # apt: no lists, no archives (hemo-pkg runs apt-get update before every install)
  find "$r/var/lib/apt/lists" -mindepth 1 -maxdepth 1 -type f -delete 2>/dev/null || true
  rm -f "$r"/var/lib/apt/lists/partial/* "$r"/var/cache/apt/*.bin \
        "$r"/var/cache/apt/archives/*.deb "$r"/var/cache/apt/archives/partial/* 2>/dev/null || true
  find "$r/usr" "$r/opt" "$r/root" "$r/home" -xdev -type d -name __pycache__ -prune \
       -exec rm -rf {} + 2>/dev/null || true

  echo "== swap ($SWAP_KIND)"
  case "$SWAP_KIND" in
    file) local sf="$r$SWAP_FILE"
          if [ -f "$sf" ]; then
            local mb=$(( $(stat -c %s "$sf") / 1048576 ))
            dd if=/dev/zero of="$sf" bs=1M count="$mb" conv=notrunc status=none
            chmod 600 "$sf"; mkswap "$sf" >/dev/null
          fi ;;
    part) local sd; sd=$(blkid -U "$SWAP_UUID") && {
            dd if=/dev/zero of="$sd" bs=1M status=none 2>/dev/null
            mkswap -U "$SWAP_UUID" "$sd" >/dev/null; } ;;
  esac

  echo "== network state"
  rm -f "$r"/etc/NetworkManager/system-connections/* "$r"/var/lib/NetworkManager/* \
        "$r"/var/lib/dhcp/* 2>/dev/null || true
  rm -f "$r/etc/resolv.conf"; : > "$r/etc/resolv.conf"      # NetworkManager rewrites it

  echo "== per-machine identity (regenerated on first boot of each clone)"
  echo uninitialized > "$r/etc/machine-id"
  rm -f "$r/var/lib/dbus/machine-id"; ln -s /etc/machine-id "$r/var/lib/dbus/machine-id"
  rm -f "$r"/etc/ssh/ssh_host_* "$r/var/lib/systemd/random-seed" \
        "$r/var/lib/systemd/credential.secret" 2>/dev/null || true
  rm -f "$r/etc/ssl/private/ssl-cert-snakeoil.key" "$r/etc/ssl/certs/ssl-cert-snakeoil.pem" 2>/dev/null || true

  echo "== login defaults -> $op / i3"
  rm -rf "$r/var/lib/lightdm"/* "$r/var/lib/lightdm"/.[!.]* "$r/var/cache/lightdm"/* 2>/dev/null || true
  install -d "$r/var/lib/AccountsService/users"
  local icon=/usr/share/hemo/branding/hemo-login.png
  { printf '[User]\nSession=i3\nXSession=i3\n'
    [ -f "$r$icon" ] && printf 'Icon=%s\n' "$icon"
    printf 'SystemAccount=false\n'; } > "$r/var/lib/AccountsService/users/$op"
  printf '[Desktop]\nSession=i3\n' > "$r/home/$op/.dmrc"
  inroot chown "$op:$op" "/home/$op/.dmrc" 2>/dev/null || true

  echo "== first-boot flags"
  rm -f "$r"/var/lib/hemo/{firstboot.done,roles,primary,theme.env} \
        "$r/home/$op/.config/hemo/setup.done" 2>/dev/null || true

  echo "== self (the staged sysprep inputs)"
  rm -rf "$r$STAGE" 2>/dev/null || true
}

# ---------------- audit ----------------
FAIL=0; bad(){ echo "  FAIL  $*"; FAIL=1; }; ok(){ echo "  ok    $*"; }
audit(){
  local r="$T" B="$BUILD_USER" O="$OPERATOR"
  inroot id "$B" >/dev/null 2>&1 && bad "$B still present" || ok "no $B user"
  [ -d "$r/home/$B" ] && bad "/home/$B exists" || ok "no /home/$B"
  grep -qs "^$B:" "$r"/etc/{passwd,shadow,group,gshadow,subuid,subgid}- \
    && bad "$B in /etc/*- backups" || ok "no $B in /etc/*- backups"
  grep -qsE "^$B:|[:,]$B(,|\$)" "$r/etc/group" && bad "$B still in /etc/group" || ok "no $B in /etc/group"
  [ "$(inroot id -u "$O" 2>/dev/null)" = "$OPERATOR_UID" ] && ok "$O uid $OPERATOR_UID" \
    || bad "$O uid is not $OPERATOR_UID"
  inroot id -nG "$O" 2>/dev/null | grep -qw sudo && ok "$O in sudo" || bad "$O not in sudo"
  local sh; sh=$(grep "^$O:" "$r/etc/shadow" 2>/dev/null)
  case "$(echo "$sh" | cut -d: -f2)" in ''|'!'*|'*'*) bad "$O has no usable password";; *) ok "$O password set";; esac
  [ "$(echo "$sh" | cut -d: -f3)" = 0 ] && bad "$O password forced to change" || ok "$O password not expired"
  case "$(grep '^root:' "$r/etc/shadow" | cut -d: -f2)" in '!'*|'*'*) ok "root locked";; *) bad "root not locked";; esac
  grep -q '^uninitialized$' "$r/etc/machine-id" && ok "machine-id uninitialized" || bad "machine-id not uninitialized"
  [ -L "$r/var/lib/dbus/machine-id" ] || [ ! -e "$r/var/lib/dbus/machine-id" ] \
    && ok "dbus machine-id not a file" || bad "dbus machine-id is a file"
  ls "$r"/etc/ssh/ssh_host_* >/dev/null 2>&1 && bad "ssh host keys present" || ok "no ssh host keys"
  [ -e "$r/var/lib/systemd/random-seed" ] && bad "random-seed present" || ok "no random-seed"
  inroot systemctl is-enabled ssh.service 2>/dev/null | grep -qx enabled && bad "ssh enabled" || ok "ssh not enabled"
  inroot systemctl is-enabled hemo-firstboot.service 2>/dev/null | grep -qx enabled \
    && ok "hemo-firstboot enabled" || bad "hemo-firstboot not enabled"
  [ -e "$r/var/lib/hemo/firstboot.done" ] || [ -e "$r/home/$O/.config/hemo/setup.done" ] \
    && bad "first-boot flag set" || ok "first-boot flags clear"
  [ -f "$r/etc/sudoers.d/99-hemo-build-temp" ] && bad "build sudoers left" || ok "no build sudoers"
  [ -n "$(find "$r/var/log" -type f 2>/dev/null)" ] && bad "logs remain" || ok "logs empty"
  [ -n "$(find "$r/tmp" "$r/var/tmp" -mindepth 1 2>/dev/null)" ] && bad "/tmp or /var/tmp not empty" || ok "temp empty"
  [ -n "$(find "$r/var/lib/apt/lists" -maxdepth 1 -type f ! -name lock 2>/dev/null)" ] \
    && bad "apt lists present" || ok "apt lists empty"
  ls "$r"/etc/NetworkManager/system-connections/* >/dev/null 2>&1 && bad "NM connections present" || ok "no NM connections"
  [ "$(cat "$r/etc/hostname" 2>/dev/null)" = hemo ] && ok "hostname hemo" || bad "hostname not hemo"
  [ -e "$r/usr/share/xsessions/xfce.desktop" ] && bad "xfce session present" || ok "no xfce session"
  grep -q '^Session=i3' "$r/var/lib/AccountsService/users/$O" 2>/dev/null \
    && ok "greeter session i3" || bad "greeter session not i3"
  grep -q '^Session=i3' "$r/home/$O/.dmrc" 2>/dev/null && ok ".dmrc i3" || bad ".dmrc not i3"
  for h in "$r/root" "$r/home/$O"; do
    for f in .bash_history .zsh_history .python_history .local/share/powershell .lesshst .viminfo .cache .ssh .mozilla; do
      [ -e "$h/$f" ] && bad "${h#$r}/$f present"
    done
  done
  # private keys: every hit must be regenerated per clone or listed in ALLOW_KEYS
  local k
  while IFS= read -r k; do
    case " $ALLOW_KEYS " in *" ${k#$r} "*) ;; *) bad "private key: ${k#$r}";; esac
  done < <(grep -rlI -- '-----BEGIN [A-Z ]*PRIVATE KEY-----' "$r/etc" "$r/var" "$r/root" "$r/home" "$r/opt" 2>/dev/null \
           | grep -v "^$r$STAGE/")
  # denylist: every forbidden string absent (fixed string, any case, binaries too)
  if [ -s "$DENY" ]; then
    local s n=0
    while IFS= read -r s; do s=${s%$'\r'}; [ -z "$s" ] && continue; n=$((n+1))
      if grep -rlaiF --exclude-dir=hemo-sysprep -- "$s" "$r/etc" "$r/home" "$r/root" "$r/var" \
           "$r/usr/local" "$r/opt" 2>/dev/null | head -1 | grep -q .; then
        bad "denylist entry #$n found (grep -rlaiF it under ${r:-/})"; fi
    done < "$DENY"
    ok "denylist checked ($n entries)"
  else bad "denylist empty or missing"; fi
  # critical baked binaries: things a basic boot + role-install test won't
  # exercise, so a provision-time apt hiccup can drop them silently — docker did
  # on the 0.1.0 golden. An image must not ship without them. Checked by on-disk
  # path (not dpkg name) so a package rename can't mask a genuine miss.
  local spec cname cpath
  for spec in \
      "docker:/usr/bin/docker" \
      "dockerd:/usr/sbin/dockerd" \
      "docker-buildx:/usr/libexec/docker/cli-plugins/docker-buildx" \
      "docker-compose:/usr/libexec/docker/cli-plugins/docker-compose" \
      "i3:/usr/bin/i3" \
      "qterminal:/usr/bin/qterminal" \
      "rofi:/usr/bin/rofi" \
      "polybar:/usr/bin/polybar"; do
    cname=${spec%%:*}; cpath=${spec#*:}
    [ -e "$r$cpath" ] && ok "baked: $cname" || bad "baked package MISSING: $cname ($cpath)"
  done
}

if [ "$MODE" = --apply ]; then prepare; fi
echo; echo "== audit (${T:-/})"; audit

# ---------------- zero free space (only --apply) ----------------
if [ "$MODE" = --apply ] && [ "$FAIL" -eq 0 ]; then
  echo "== zero free space"
  if ! command -v zerofree >/dev/null && ls "$HERE"/zerofree_*.deb >/dev/null 2>&1; then
    dpkg -i "$HERE"/zerofree_*.deb >/dev/null 2>&1 || true
  fi
  sync; umount "$T"
  fsck -fy "$DEV" >/dev/null 2>&1 || true
  if command -v zerofree >/dev/null; then zerofree -v "$DEV"; else
    mount "$DEV" "$T"; dd if=/dev/zero of="$T/zero.fill" bs=1M 2>/dev/null || true
    sync; rm -f "$T/zero.fill"; sync; umount "$T"
  fi
fi

if [ "$FAIL" -ne 0 ]; then echo; echo "AUDIT FAILED — do not export"; exit 1; fi
echo; echo "sysprep $MODE complete"
