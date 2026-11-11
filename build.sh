#!/usr/bin/env bash
# Hemo build pipeline — one thin-core rootfs, exported to every VM format.
#
# NOTE 2026-11-11: Hemo ships for VMware only, built by hand in VMware. This kali-vm
#   pipeline is kept for reference and is not the release path.
#   sudo ./build.sh                          # qemu + vmware + virtualbox + ova, UEFI
#   sudo ./build.sh --version 0.2.0 --formats "qemu ova"
#   sudo ./build.sh --firmware bios          # legacy MBR + grub-pc images instead
#   sudo ./build.sh --rootfs-only            # build + customize the rootfs, stop
#   sudo ./build.sh --reuse-rootfs out/rootfs-<ver>-amd64.tar.gz   # re-export, skip build
#
# WHAT IT DOES (see PLAN.md "Build flow"):
#   1. kali-vm builds ONE rootfs (-v rootfs): -b kali-last-snapshot -D i3 -T none,
#      plus the BAKED apt sections (base/desktop_i3/plumbing/runtime/hardening/
#      branding) read straight out of manifest/apt.yml. No offensive/defensive tools.
#   2. scripts/hemo-customize.sh runs inside that rootfs (systemd-nspawn): lays
#      down overlays, Firefox policy, hardening, the hemo-* helpers, manifests,
#      branding, the operator user, and enables hemo-firstboot. Still no tools.
#   3. The customized rootfs is exported once per format with kali-vm -r (reuse).
#      Firmware defaults to UEFI: GPT + a 512M ESP + grub-efi (installed to the
#      removable path EFI/BOOT/BOOTX64.EFI, so no NVRAM entry is needed), and the
#      .vmx/.vbox/.ova metadata is marked EFI so the VM boots it without tweaking.
#   4. SHA256SUMS + a baseline package list are written next to the artifacts.
#
# Tools install PER ROLE on first boot (hemo-firstboot -> hemo-roles), never here.
#
# REQUIRES a Linux host with /dev/kvm (cannot run on Windows). kali-vm is pinned
# under vendor/kali-vm; vendor/patches/*.patch are applied to it on first run
# (kali-vm only builds UEFI for its hyperv variant; the patch lets us force it).
set -euo pipefail

# ----------------------------------------------------------------- settings
ARCH="amd64"
BRANCH="kali-last-snapshot"       # rolling-but-reproducible base snapshot
DESKTOP="i3"
SIZE="80"                         # GB, thin-provisioned
DISTNAME="hemo"
FORMATS="qemu vmware virtualbox ova"
FIRMWARE="uefi"                   # uefi | bios
ZIP=1
VERSION=""
ROOTFS_ONLY=0
REUSE_ROOTFS=""

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${HEMO_OUT:-$HERE/out}"
WORK="${HEMO_WORK:-$HERE/.build}"
KV_OUT="$WORK/kali-vm"            # kali-vm's -o: the rootfs passed to -r must live here
BAKED_SECTIONS="base desktop_i3 desktop_apps plumbing runtime hardening branding"

# kali-vm entrypoint: env override > pinned submodule > PATH
KALIVM="${HEMO_KALIVM:-}"
[ -z "$KALIVM" ] && [ -x "$HERE/vendor/kali-vm/build.sh" ] && KALIVM="$HERE/vendor/kali-vm/build.sh"
[ -z "$KALIVM" ] && command -v kali-vm >/dev/null 2>&1 && KALIVM="$(command -v kali-vm)"

# ----------------------------------------------------------------- cli
log(){ printf '\n\033[1;31m[hemo-build]\033[0m %s\n' "$*"; }
die(){ printf '\033[1;31m[hemo-build] FATAL:\033[0m %s\n' "$*" >&2; exit 1; }
usage(){ sed -n '2,27p' "$0" | sed 's/^# \{0,1\}//'; exit 0; }

while [ $# -gt 0 ]; do
  case "$1" in
    --version)       VERSION="$2"; shift 2;;
    --formats)       FORMATS="$2"; shift 2;;
    --firmware)      FIRMWARE="$2"; shift 2;;
    --branch)        BRANCH="$2"; shift 2;;
    --size)          SIZE="$2"; shift 2;;
    --arch)          ARCH="$2"; shift 2;;
    --out)           OUT="$2"; shift 2;;
    --rootfs-only)   ROOTFS_ONLY=1; shift;;
    --reuse-rootfs)  REUSE_ROOTFS="$2"; shift 2;;
    --no-zip)        ZIP=0; shift;;
    -h|--help)       usage;;
    *) die "unknown arg: $1 (see --help)";;
  esac
done
case "$FIRMWARE" in uefi|bios) ;; *) die "--firmware must be uefi or bios";; esac

# default version: VERSION file, else git describe, else date
if [ -z "$VERSION" ]; then
  if [ -f "$HERE/VERSION" ]; then VERSION="$(tr -d ' \n' < "$HERE/VERSION")"
  elif git -C "$HERE" describe --tags --always >/dev/null 2>&1; then
    VERSION="$(git -C "$HERE" describe --tags --always 2>/dev/null)"
  else VERSION="0.0.0-$(date -u +%Y%m%d)"; fi
fi
NAME="$DISTNAME-$VERSION"

# ----------------------------------------------------------------- preflight
log "Preflight"
[ "$(id -u)" -eq 0 ] || die "run as root (debos/kali-vm need it): sudo $0"
[ -e /dev/kvm ] || die "/dev/kvm not found — need a Linux host with KVM (nested virt if this is a VM)"
[ -n "$KALIVM" ] || die "kali-vm not found. Clone it pinned:
    git submodule add https://gitlab.com/kalilinux/build-scripts/kali-vm vendor/kali-vm
  or set HEMO_KALIVM=/path/to/kali-vm/build.sh"
for t in python3 systemd-nspawn tar sha256sum; do
  command -v "$t" >/dev/null 2>&1 || die "missing dependency: $t"
done
[ "$ZIP" -eq 1 ] && { command -v 7zr >/dev/null 2>&1 || die "missing dependency: 7zr (apt install 7zip)"; }
python3 -c 'import yaml' 2>/dev/null || die "python3 yaml missing — apt install python3-yaml"

# Hemo patches to kali-vm (idempotent: skip any already applied)
KVDIR="$(dirname "$KALIVM")"
for p in "$HERE"/vendor/patches/kali-vm-*.patch; do
  [ -f "$p" ] || continue
  if git -C "$KVDIR" apply --reverse --check "$p" >/dev/null 2>&1; then continue; fi
  git -C "$KVDIR" apply "$p" || die "kali-vm patch $(basename "$p") no longer applies — re-roll it for the pinned commit"
  echo "  patched kali-vm: $(basename "$p")"
done
grep -q '^UEFI="${UEFI:-}"' "$KALIVM" || [ "$FIRMWARE" = bios ] \
  || die "kali-vm cannot be forced to UEFI (vendor/patches/kali-vm-uefi-env.patch not applied)"

echo "  kali-vm   : $KALIVM"
echo "  version   : $VERSION"
echo "  firmware  : $FIRMWARE"
echo "  formats   : $FORMATS"
echo "  output    : $OUT"
mkdir -p "$OUT" "$WORK" "$KV_OUT"

# kali-vm names the rootfs rootfs-<version>-<arch>.tar.gz and the images
# kali-linux-<version>-<variant>-<arch>; lowercase, no '/' or spaces.
KV_VERSION="$(echo "$NAME" | tr 'A-Z/ ' 'a-z--')"
ROOTFS_TAR="$KV_OUT/rootfs-$KV_VERSION-$ARCH.tar.gz"
kalivm(){ ( cd "$KVDIR" && "$KALIVM" -o "$KV_OUT" "$@" ); }

# ----------------------------------------------------------------- packages
# Read the BAKED apt sections out of the manifest — the single source of truth.
read_baked_pkgs(){
  python3 - "$HERE/manifest/apt.yml" $BAKED_SECTIONS <<'PY'
import sys,yaml
doc=yaml.safe_load(open(sys.argv[1],encoding='utf-8')) or {}
want=sys.argv[2:]
seen=[]
for sec in want:
    for p in (doc.get(sec) or []):
        if isinstance(p,str) and p not in seen: seen.append(p)
print("\n".join(seen))
PY
}

# ----------------------------------------------------------------- 1. rootfs
if [ -n "$REUSE_ROOTFS" ]; then
  [ -f "$REUSE_ROOTFS" ] || die "rootfs not found: $REUSE_ROOTFS"
  [ "$(realpath "$REUSE_ROOTFS")" = "$(realpath -m "$ROOTFS_TAR")" ] || cp -f "$REUSE_ROOTFS" "$ROOTFS_TAR"
  log "Reusing rootfs: $REUSE_ROOTFS (skipping build + customize)"
else
  mapfile -t BAKED < <(read_baked_pkgs)
  [ "${#BAKED[@]}" -gt 0 ] || die "no baked packages parsed from apt.yml (sections: $BAKED_SECTIONS)"
  log "Baked core: ${#BAKED[@]} apt packages from [$BAKED_SECTIONS]"

  log "1/4  Building thin rootfs (kali-vm -v rootfs, tools=none)"
  rm -f "$ROOTFS_TAR"
  kalivm -v rootfs -a "$ARCH" -b "$BRANCH" -D "$DESKTOP" -T none -x "$KV_VERSION" \
      -P "${BAKED[*]}" \
    || die "kali-vm rootfs build failed (check its flags against your pinned commit)"
  [ -f "$ROOTFS_TAR" ] || die "kali-vm did not produce $ROOTFS_TAR"
  echo "  rootfs: $ROOTFS_TAR"

  # ----------------------------------------------------------- 2. customize
  log "2/4  Customizing rootfs (thin core only — no tools)"
  RDIR="$WORK/rootfs"; rm -rf "$RDIR"; mkdir -p "$RDIR"
  tar -xpzf "$ROOTFS_TAR" -C "$RDIR"
  systemd-nspawn -q -D "$RDIR" \
      --bind-ro="$HERE:/opt/hemo-src" \
      --setenv=HEMO_SRC=/opt/hemo-src --setenv=HEMO_OPERATOR=hemo \
      /bin/bash /opt/hemo-src/scripts/hemo-customize.sh \
    || die "customize step failed inside the rootfs"

  # baseline package list of the thin core (for the release record)
  chroot "$RDIR" dpkg-query -W -f='${Package}\t${Version}\n' 2>/dev/null \
    | sort > "$OUT/$NAME-base-packages.txt" \
    && echo "  baseline: $OUT/$NAME-base-packages.txt ($(wc -l < "$OUT/$NAME-base-packages.txt") pkgs)"

  log "Repacking customized rootfs"
  rm -f "$ROOTFS_TAR"
  tar -cpzf "$ROOTFS_TAR" -C "$RDIR" .
  rm -rf "$RDIR"
  cp -f "$ROOTFS_TAR" "$OUT/"   # keep for --reuse-rootfs
fi

if [ "$ROOTFS_ONLY" -eq 1 ]; then
  log "Rootfs-only requested — done. Export later with: $0 --reuse-rootfs \"$OUT/$(basename "$ROOTFS_TAR")\""
  exit 0
fi

# ----------------------------------------------------------------- 3. export
# user-facing name -> "kali-vm variant:format". The variant picks the guest
# agents baked in; ova/raw are hypervisor-neutral so they get all of them.
fmt_pair(){ case "$1" in
  qemu|qcow2)          echo qemu:qemu;;
  vmware|vmdk)         echo vmware:vmware;;
  virtualbox|vbox|vdi) echo virtualbox:virtualbox;;
  ova)                 echo generic:ova;;
  ovf)                 echo generic:ovf;;
  raw)                 echo generic:raw;;
  hyperv)              echo hyperv:hyperv;;
  *) return 1;; esac; }

# kali-vm's VM metadata templates are BIOS-only (only its hyperv variant is UEFI),
# so mark UEFI builds as EFI ourselves, before compressing.
mark_efi(){ # image-basename format
  local img=$1 fmt=$2 d
  case "$fmt" in
    vmware)
      echo 'firmware = "efi"' >> "$KV_OUT/$img.vmwarevm/$img.vmx";;
    virtualbox)
      sed -i 's|^\( *\)<Hardware>$|&\n\1  <Firmware type="EFI"/>|' "$KV_OUT/$img.vbox";;
    ova)
      # VMware reads vmw:Config firmware, VirtualBox reads vbox:Machine Firmware.
      # Editing the .ovf invalidates the .mf, so regenerate it with kali-vm's tool.
      d="$(mktemp -d "$WORK/ova.XXXXXX")"
      tar -xf "$KV_OUT/$img.ova" -C "$d"
      sed -i \
        -e 's|<Envelope |<Envelope xmlns:vmw="http://www.vmware.com/schema/ovf" |' \
        -e 's|^\( *\)</VirtualHardwareSection>$|\1  <vmw:Config ovf:required="false" vmw:key="firmware" vmw:value="efi"/>\n&|' \
        -e 's|^\( *\)<Hardware>$|&\n\1  <Firmware type="EFI"/>|' \
        "$d/$img.ovf"
      ( cd "$d" && "$KVDIR/scripts/generate-mf.sh" "$img.ovf" "$img.vmdk" \
          && tar -cf "$KV_OUT/$img.ova" "$img.ovf" "$img.vmdk" "$img.mf" )
      rm -rf "$d";;
    qemu|raw) : ;;   # no metadata — boot with OVMF (see RUNBOOK)
  esac
}

compress(){ # image-basename format
  local img=$1 fmt=$2
  case "$fmt" in
    vmware)     ( cd "$KV_OUT" && 7zr a -sdel -mx=9 "$img.7z" "$img.vmwarevm" >/dev/null );;
    virtualbox) ( cd "$KV_OUT" && mkdir -p "$img" && mv "$img.vdi" "$img.vbox" "$img/" \
                    && 7zr a -sdel -mx=9 "$img.7z" "$img" >/dev/null );;
    *) : ;;     # qcow2/ova are already compressed
  esac
}

log "3/4  Exporting formats from the one rootfs ($FIRMWARE)"
UEFI_ENV=""; [ "$FIRMWARE" = uefi ] && UEFI_ENV=true
for f in $FORMATS; do
  pair="$(fmt_pair "$f")" || { echo "  ! unknown format: $f (skipped)"; continue; }
  variant="${pair%%:*}"; ff="${pair#*:}"
  img="kali-linux-$KV_VERSION-$variant-$ARCH"
  log "  -> $f (variant $variant, format $ff)"
  # -z is ours (after mark_efi), not kali-vm's; -U/-D/-T are baked into the rootfs
  if ! UEFI="$UEFI_ENV" kalivm -v "$variant" -f "$ff" -s "$SIZE" -r "$ROOTFS_TAR"; then
    echo "  ! export failed for $f (continuing)"; continue
  fi
  [ "$FIRMWARE" = uefi ] && mark_efi "$img" "$ff"
  [ "$ZIP" -eq 1 ] && compress "$img" "$ff"
  for a in "$KV_OUT/$img".*; do
    [ -e "$a" ] || continue
    mv -f "$a" "$OUT/$NAME-$FIRMWARE-$f.${a#"$KV_OUT/$img".}"
  done
done

# ----------------------------------------------------------------- 4. sums
log "4/4  Checksums"
( cd "$OUT" && find . -maxdepth 1 -type f ! -name SHA256SUMS ! -name 'rootfs-*.tar.gz' -printf '%P\0' \
    | sort -z | xargs -0 -r sha256sum > SHA256SUMS ) || true

log "DONE — artifacts in $OUT"
ls -lh "$OUT" | sed 's/^/    /'
cat <<EOF

Next: smoke-test the qcow2 headless (boot in QEMU with OVMF for a UEFI build,
SSH in, check guest agent + that no role tools are present yet), then git-tag
this base version. The image boots into the first-boot role picker; tools
install per role from there.
EOF
