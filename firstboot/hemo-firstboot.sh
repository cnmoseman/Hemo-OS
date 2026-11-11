#!/usr/bin/env bash
# hemo-firstboot — runs ONCE, on the first boot of a fresh clone, as root on the
# console (tty1) before the login screen comes up.
#
# It does the per-clone identity reset, then launches the role picker so the
# operator chooses personas and the chosen tools install online — all with the
# console held, so installs run as root with no sudo-password dance.
#
# Installed by provision.sh / the build pipeline as the systemd unit
# hemo-firstboot.service (Before=display-manager.service, After=network-online).
set -uo pipefail

STATE=/var/lib/hemo
DONE="$STATE/firstboot.done"
mkdir -p "$STATE"

# already run? get out of the way of the login screen.
[ -f "$DONE" ] && exit 0

export HEMO_FIRSTBOOT=1

# ---- per-clone identity reset (SSH/TLS keys; so clones aren't twins) --------
# NOTE: do NOT regenerate the machine-id here. This unit runs late
# (After=network-online.target), long after systemd-journald and systemd-logind
# have already started and latched the boot's machine-id. Changing /etc/machine-id
# at this point makes the on-disk id diverge from the one the running daemons (and
# the D-Bus system bus) hold, which silently breaks logind session creation
# (loginctl shows no session, pkexec/polkit fail with "No session for cookie") and
# makes journalctl report "No journal files were found". The machine-id is already
# handled correctly and early by systemd's own first-boot logic: the seal leaves
# /etc/machine-id empty/uninitialized, and PID 1 commits a fresh id before logind
# and journald start. Only the SSH/TLS keys are safe to regenerate this late.
echo "[hemo] regenerating SSH + TLS host keys for this clone..."
rm -f /etc/ssh/ssh_host_* 2>/dev/null || true
dpkg-reconfigure openssh-server >/dev/null 2>&1 \
  || ssh-keygen -A >/dev/null 2>&1 || true
# the snakeoil TLS key/cert would otherwise be identical in every clone
if [ -x /usr/sbin/make-ssl-cert ]; then
  rm -f /etc/ssl/private/ssl-cert-snakeoil.key /etc/ssl/certs/ssl-cert-snakeoil.pem
  make-ssl-cert generate-default-snakeoil --force-overwrite >/dev/null 2>&1 || true
fi

# ---- role setup: GUI on a desktop, tty picker only when headless ------------
# On a graphical install, role selection + GPU/hardening setup happen in the
# graphical "Hemo Welcome" hub at first login (hemo-welcome, launched from i3).
# This oneshot then only does the identity reset above and gets out of the way.
# Only a headless / server install falls through to the console whiptail picker.
if systemctl is-enabled display-manager.service lightdm.service >/dev/null 2>&1 \
   || [ -e /etc/systemd/system/display-manager.service ]; then
  echo "[hemo] desktop detected — setup continues in Hemo Welcome at first login."
  touch "$DONE"
  exit 0
fi

# ---- headless fallback: console role picker ---------------------------------
plymouth quit 2>/dev/null || true
chvt 1 2>/dev/null || true
clear || true
cat <<'BANNER'

   ####  Hemo  —  curated Kali  —  authorized testing only  ####

   First boot (headless): pick your role(s). Tools install over the network.

BANNER

if ! ping -c1 -W3 1.1.1.1 >/dev/null 2>&1 && ! ping -c1 -W3 8.8.8.8 >/dev/null 2>&1; then
  echo "[hemo] No network detected — run 'sudo hemo-roles' once you're online."
  touch "$DONE"; exit 0
fi

hemo-roles; rc=$?
if [ "$rc" -eq 0 ]; then echo "[hemo] role setup complete."
elif [ "$rc" -eq 10 ]; then echo "[hemo] no role chosen — run 'sudo hemo-roles' later."
else echo "[hemo] role setup failed — run 'sudo hemo-roles' later."; fi

if command -v hemo-gpu >/dev/null 2>&1; then
  gpu="$(hemo-gpu detect 2>/dev/null || true)"
  if [ -n "$gpu" ] && [ "$gpu" != none ]; then
    whiptail --title "Hemo — GPU detected" --yesno \
      "A discrete GPU is available:\n\n  $gpu\n\nInstall drivers + enable hashcat GPU? (reboot after)" 14 72 \
      && { echo "[hemo] enabling GPU…"; hemo-gpu enable || echo "[hemo] run 'sudo hemo-gpu enable' later."; }
  fi
fi

touch "$DONE"
echo "[hemo] done — starting the console login."
exit 0
