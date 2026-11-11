#!/usr/bin/env bash
# Hemo declutter — remove UNNECESSARY Kali-default packages, keep everything
# that earns its place. Run INSIDE the VM as root, AFTER provision.sh.
#
#   sudo ./declutter.sh                  # DRY RUN — shows what would go, removes nothing
#   sudo ./declutter.sh --apply          # remove the unnecessary packages
#   sudo ./declutter.sh --apply --seal   # remove AND seal this as a clone template
#   sudo ./declutter.sh --seal           # just seal (reset identity + first-boot), no removal
#
# PRINCIPLE (durable daily-driver, not a throwaway): "bloat" here means
# genuinely-unused software (other desktop environments, games), NOT quality-of-
# life. Docs, man pages, shell completions and the like are KEPT and protected.
# It removes the kali-linux-default / -large / -everything metapackages, then
# autoremoves what was only present as their dependency. Protected packages and
# their own dependencies survive.
#
# SEALING (--seal) is OPT-IN because the DEFAULT lifecycle is a PERSISTENT box
# you keep. Seal only when turning this install into a reusable clone template:
# it strips the machine identity and resets the first-boot flag so each clone
# gets a fresh identity and re-runs the role picker. Never do this to a box you
# intend to keep.
#
# SNAPSHOT THE VM FIRST. Removing packages is hard to undo cleanly.

set -uo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Run as root: sudo $0"; exit 1; }

APPLY=0; SEAL=0
for a in "$@"; do
  case "$a" in
    --apply) APPLY=1 ;;
    --seal)  SEAL=1 ;;
    *) echo "unknown arg: $a (use --apply and/or --seal)"; exit 1 ;;
  esac
done
export DEBIAN_FRONTEND=noninteractive

say(){ printf '\n\033[1;31m[hemo]\033[0m %s\n' "$*"; }

# ------------------------------------------------- KEEP: never remove these
# Mirrors manifest/apt.yml plus desktop, base, and guest agents. Marking a
# top-level package manual keeps its dependencies too, so list tools, not deps.
# ROLE MODEL: offensive/defensive tools are NOT baked — they install per role on
# first boot — so they are NOT in KEEP. We protect only the thin baked core:
# base CLI, i3 desktop, report tooling, guest agents, and client plumbing.
KEEP=(
  # base + shell + the role-system deps
  zsh zsh-autosuggestions zsh-syntax-highlighting tmux fzf ripgrep bat fd-find git pipx golang curl wget jq pandoc
  keepassxc neovim sudo ca-certificates python3-yaml whiptail
  # guest integration for all hypervisors (do NOT lose these — clipboard/resize)
  open-vm-tools open-vm-tools-desktop qemu-guest-agent spice-vdagent virtualbox-guest-x11
  # desktop we actually use
  i3 i3status i3lock xss-lock rofi polybar dunst kitty flameshot firefox-esr
  xorg lightdm feh picom network-manager x11-xserver-utils
  # report/screenshot consistency
  fonts-jetbrains-mono fonts-font-awesome maim xdotool xclip imagemagick
  # desktop apps + daily-driver QoL
  thunar thunar-archive-plugin thunar-volman lf mc zathura zathura-pdf-poppler nsxiv
  pipewire pipewire-pulse wireplumber pavucontrol pamixer copyq udiskie
  gammastep network-manager-applet nm-connection-editor yad lxpolkit fastfetch
  p7zip-full unzip zip xarchiver gvfs gvfs-backends udisks2 ntfs-3g exfatprogs cifs-utils
  lxappearance fonts-noto fonts-noto-color-emoji fonts-nerd-symbols feh x11-xserver-utils
  cherrytree libreoffice-writer libreoffice-calc libreoffice-impress libreoffice-gtk3
  # client-VPN plugins + report engine
  network-manager-openconnect-gnome network-manager-openvpn-gnome
  network-manager-vpnc-gnome
  network-manager-l2tp-gnome network-manager-strongswan
  texlive-xetex texlive-latex-recommended texlive-latex-extra texlive-fonts-recommended
  lmodern weasyprint
  # base client plumbing (wireshark/tcpdump/netcat/SMB/LDAP/Kerberos are
  # role tools since 2026-10-09 — roles that want them install them manual)
  freerdp3-x11 openvpn wireguard-tools
  # baked OS hardening (always-on + operator-toggled via hemo-harden)
  apparmor apparmor-utils bubblewrap
  ufw auditd
  # container runtime for BloodHound CE + future docker services
  docker.io docker-compose
  # keep the base metapackages that define a working Kali.
  # NOTE: kali-linux-headless / -tools-top10 / -system-gui are DELIBERATELY not
  # here — they are the stock toolset we strip (see META below); roles reinstall
  # what's wanted. kali-desktop-i3 stays, so everything IT depends on (incl.
  # xfce4-power-manager, qt5ct/qt6ct, thunar, lxappearance) is protected too.
  kali-linux-core kali-desktop-i3
  # provision.sh's hand path installs i3 itself, not kali-desktop-i3, so name what
  # that metapackage would have protected: the desktop core (kali-menu, grant-root,
  # dbus-x11, xserver-xorg-legacy …) and the Qt theme hook hemo-role-apply relies on
  # (QT_QPA_PLATFORMTHEME=qt5ct). Without these, --apply autoremoves them.
  kali-desktop-core qt5ct qt6ct xfce4-power-manager
  # keep the Kali theme/icon set the greeter + GTK config reference
  kali-themes kali-themes-common
  # disk / filesystem / recovery utilities a daily driver keeps (these would
  # otherwise be autoremoved as former toolset deps)
  gdisk gparted cryptsetup cryptsetup-initramfs testdisk
  smartmontools hdparm squashfs-tools dos2unix
  # wireless + serial plumbing, build helpers, python packaging, misc utils
  iw rfkill nasm upx-ucl xsltproc libglib2.0-bin screen plocate
  python3-pip python3-venv python3-virtualenv
  # quality-of-life — a daily driver keeps its docs, help and comforts
  man-db manpages bash-completion less pciutils usbutils
  pipewire pulseaudio-utils network-manager
)

say "Protecting ${#KEEP[@]} curated packages (apt-mark manual)"
PROTECTED=0
for p in "${KEEP[@]}"; do
  if dpkg -s "$p" >/dev/null 2>&1; then
    apt-mark manual "$p" >/dev/null 2>&1 && PROTECTED=$((PROTECTED+1))
  fi
done
echo "  protected $PROTECTED installed packages"

# ------------------------------------------------- metapackages that pull bloat
# The stock Kali toolset. kali-linux-default pulls -headless (~150 CLI tools) +
# -tools-top10 + -system-gui; removing all four and autoremoving their orphans
# strips the baked attack toolset. Roles reinstall what each persona needs
# (manifest/roles.yml); the protected KEEP set + kali-desktop-i3's deps survive.
META=(kali-linux-default kali-linux-headless kali-tools-top10 kali-system-gui
      kali-linux-large kali-linux-everything)
PRESENT_META=()
for m in "${META[@]}"; do dpkg -s "$m" >/dev/null 2>&1 && PRESENT_META+=("$m"); done

# ------------------------------------------------- explicit extras to purge
# Clearly-safe bloat if present: the XFCE desktop (Hemo is pure i3 — see the
# XFCE note below), plus games and screensavers. kali-desktop-i3 depends on
# xfce4-power-manager and qt5ct/qt6ct, so those are NOT listed and stay.
EXTRA=(
  # XFCE top-level packages only — the metapackages that pin the desktop plus
  # the standalone session/WM. We DON'T list the deeper XFCE libraries/plugins
  # (xfconf, xfce4-settings, xfdesktop4, xfce4-panel, …): those come out via
  # `apt-get autoremove` once nothing manual needs them, which (unlike naming
  # them here) will never drag out a protected package such as thunar or
  # xfce4-power-manager that shares a low-level XFCE library.
  #   kali-desktop-xfce Depends xfce4, so xfce4 can't go until it (and
  #   kali-undercover, the Windows-look disguise, which also wants xfce4) go too.
  kali-desktop-xfce kali-undercover
  xfce4 xfce4-session xfwm4 xfce4-notifyd xfce4-screensaver
  # XFCE bundled apps Hemo replaces (thunar/zathura/nsxiv/kitty/flameshot)
  mousepad ristretto parole atril engrampa mate-calc
  xfce4-taskmanager xfce4-screenshooter catfish
  # accessibility / on-screen-keyboard stack pulled by kali-desktop-xfce
  orca onboard speech-dispatcher
  # games + screensavers
  gnome-games aisleriot gnome-mahjongg gnome-mines gnome-sudoku
  xscreensaver
)
PRESENT_EXTRA=()
for e in "${EXTRA[@]}"; do dpkg -s "$e" >/dev/null 2>&1 && PRESENT_EXTRA+=("$e"); done

say "Plan"
echo "  metapackages to remove : ${PRESENT_META[*]:-none}"
echo "  extra packages to purge: ${PRESENT_EXTRA[*]:-none}"

if [ "$APPLY" -eq 0 ] && [ "$SEAL" -eq 0 ]; then
  say "DRY RUN — simulating; nothing will be removed (add --apply to remove, --seal to seal)"
  if [ ${#PRESENT_META[@]} -gt 0 ]; then
    echo "--- would remove metapackages + orphaned deps: ---"
    apt-get remove --purge -s "${PRESENT_META[@]}" 2>/dev/null \
      | grep -E '^(Remv|Purg)' | sed 's/^/  /'
  fi
  echo
  echo "--- would then autoremove these orphans: ---"
  apt-get autoremove --purge -s 2>/dev/null | grep -E '^(Remv|Purg)' | sed 's/^/  /' | head -n 300
  REMCOUNT=$(apt-get autoremove --purge -s 2>/dev/null | grep -cE '^(Remv|Purg)')
  say "Dry run complete. ~$REMCOUNT packages would be autoremoved."
  echo "Review the list above, SNAPSHOT the VM, then re-run with:  sudo $0 --apply"
  exit 0
fi

# ------------------------------------------------- APPLY (remove unnecessary)
if [ "$APPLY" -eq 1 ]; then
  BEFORE=$(df --output=used / | tail -1)
  say "APPLYING — removing unnecessary packages"

  [ ${#PRESENT_META[@]}  -gt 0 ] && apt-get remove --purge -y "${PRESENT_META[@]}"
  if [ ${#PRESENT_EXTRA[@]} -gt 0 ]; then
    # kali-desktop-xfce is marked Protected, so apt -y refuses to remove it without
    # --allow-remove-essential. Allow that only if the simulated removal touches no
    # truly Essential package (dpkg Essential: yes).
    ESS=$(apt-get remove --purge -s "${PRESENT_EXTRA[@]}" 2>/dev/null | awk '/^(Remv|Purg)/{print $2}' \
          | xargs -r dpkg-query -W -f='${Package} ${Essential}\n' 2>/dev/null | awk '$2=="yes"{print $1}')
    if [ -n "$ESS" ]; then echo "refusing: would remove Essential packages: $ESS"; exit 1; fi
    apt-get remove --purge -y --allow-remove-essential "${PRESENT_EXTRA[@]}"
  fi
  apt-get autoremove --purge -y
  apt-get clean

  AFTER=$(df --output=used / | tail -1)
  RECLAIMED=$(( (BEFORE - AFTER) / 1024 ))
  say "Removal done. Reclaimed ~${RECLAIMED} MB."
  echo "Verify the desktop + a few tools still work."
fi

# ------------------------------------------------- SEAL (opt-in: clone template)
if [ "$SEAL" -eq 1 ]; then
  say "Sealing as a clone template (--seal)"
  echo "This strips machine identity + resets first boot. Do NOT run on a box you keep."
  rm -f /var/lib/hemo/firstboot.done /var/lib/hemo/roles \
        /var/lib/hemo/primary /var/lib/hemo/theme.env 2>/dev/null || true
  rm -f /etc/ssh/ssh_host_* 2>/dev/null || true
  : > /etc/machine-id 2>/dev/null || true          # systemd regenerates on boot
  rm -f /var/lib/dbus/machine-id 2>/dev/null || true
  echo "  reset first-boot state + machine identity (picker re-runs per clone)"
  echo "Snapshot NOW and don't boot this template again (a boot consumes the first-boot flag)."
fi
echo
echo "Note: Hemo is pure i3. The XFCE desktop is removed (see EXTRA above), but"
echo "xfce4-power-manager and qt5ct/qt6ct stay — kali-desktop-i3 depends on them."
echo "The login greeter is lightdm-gtk-greeter (not XFCE); NetworkManager, its"
echo "applet, and Thunar are protected in KEEP, so the desktop stays usable."
