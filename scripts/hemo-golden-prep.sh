#!/usr/bin/env bash
# hemo-golden-prep — make a provisioned + decluttered Hemo VM match the golden spec
# (docs/golden-image.md) before the offline sysprep pass. Run as root on the build VM.
# Idempotent.
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 1; }
OP=hemo

# hostname
echo hemo > /etc/hostname
if grep -q '^127\.0\.1\.1' /etc/hosts; then sed -i 's/^127\.0\.1\.1.*/127.0.1.1\themo/' /etc/hosts
else printf '127.0.1.1\themo\n' >> /etc/hosts; fi

# timezone / locale / keyboard: nothing inherited from the build host
ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime; echo Etc/UTC > /etc/timezone
sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen; locale-gen >/dev/null
printf 'LANG=en_US.UTF-8\n' > /etc/default/locale
cat > /etc/default/keyboard <<'K'
XKBMODEL="pc105"
XKBLAYOUT="us"
XKBVARIANT=""
XKBOPTIONS=""
BACKSPACE="guess"
K

# apt: official mirror only, no proxies
grep -rlE 'Acquire::(http|https|ftp)::Proxy' /etc/apt/apt.conf /etc/apt/apt.conf.d 2>/dev/null \
  | xargs -r rm -v || true          # grep exits 1 when there is no proxy config
# apt waits for the dpkg lock instead of failing (a first-boot role install that overlaps
# any other apt run otherwise fails every tool; seen on the 0.1.0 test import)
install -D -m644 "$(dirname "$(readlink -f "$0")")/../overlays/etc/apt/apt.conf.d/90hemo-lock-timeout" \
  /etc/apt/apt.conf.d/90hemo-lock-timeout
echo "apt sources (expect http.kali.org/kali kali-rolling + chosen vendor repos only):"
grep -rhvE '^\s*(#|$)' /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null | sed 's/^/  /' || true

# accounts: hemo/hemo not expired, root locked
echo "$OP:$OP" | chpasswd
chage -d "$(date +%F)" -M 99999 -E -1 "$OP"       # not expired, no forced change
passwd -l root >/dev/null
usermod -aG sudo,docker "$OP"

# nothing may listen on the network (the password is public)
systemctl disable ssh.service 2>/dev/null || true
systemctl is-enabled ssh.service 2>/dev/null | grep -qx enabled && { echo "ssh still enabled"; exit 1; }

# first boot: per-clone identity + Welcome
systemctl enable hemo-firstboot.service
rm -f /var/lib/hemo/firstboot.done /var/lib/hemo/roles /var/lib/hemo/primary /var/lib/hemo/theme.env
rm -f "/home/$OP/.config/hemo/setup.done"
echo "golden-prep done"
