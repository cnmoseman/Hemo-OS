#!/usr/bin/env bash
# hemo-release-pack.sh — package an approved OVA for release.
#
# Hemo ships one .ova, hosted on Cloudflare R2 (GitHub caps release files at
# 2 GiB). The GitHub release carries only the small files that let people check
# the download. Given hemo-<version>-vmware.ova, this writes to --outdir:
#
#   SHA256SUMS               one line: the .ova's checksum
#   SHA256SUMS.minisig       minisign signature over SHA256SUMS
#   hemo-release.pub         the public key
#   RELEASE-NOTES-<ver>.md   release/RELEASE-NOTES.template.md, filled in
#
# Steps, each optional where noted:
#   --audit    read-only look inside the OVA's disk, without importing or
#              mounting it: is the release key built in the current one, is the
#              machine-id 'uninitialized', is the hostname hemo, are there extra
#              home dirs? Needs qemu-utils and e2fsprogs; no root needed.
#   sign       minisign prompts for the key password, so run it in a real
#              terminal. --no-sign skips signing and prints the command to run later.
#   --upload   aws s3 cp to R2 (awscli profile 'r2'), then fetch the PUBLIC URL
#              and check its size and sha256 against the local file.
#
# It never pushes, tags, or creates the GitHub release; the owner does that.
# The minisign SECRET key never lives in the repo.
set -euo pipefail

PROG=${0##*/}
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_DIR=$(cd -- "$SCRIPT_DIR/.." && pwd)

BUCKET=hemo-os
PROFILE=r2
PUBLIC_BASE=https://pub-2837a6191ae149fcb82eca0c04982e0a.r2.dev

die()  { printf '%s: error: %s\n' "$PROG" "$*" >&2; exit 1; }
note() { printf '>> %s\n' "$*" >&2; }

usage() {
  cat >&2 <<EOF
Usage: $PROG --ova PATH [options]

  --ova PATH          the approved image, named hemo-<version>-vmware.ova (required)
  --outdir DIR        where to write the release files (default: <ova-dir>/release-<version>)
  --audit             read-only check of the OVA's disk before anything else
  --no-sign           skip minisign (prints the command to sign later)
  --upload            upload to R2 and verify the public URL
  --seckey PATH       minisign secret key (default: \$HEMO_MINISIGN_SECKEY or ~/.minisign/hemo-release.key)
  --pubkey PATH       public key (default: $REPO_DIR/release/hemo-release.pub)
  --bucket NAME       R2 bucket (default: $BUCKET)
  --profile NAME      awscli profile for R2 (default: $PROFILE)
  --public-base URL   public bucket URL (default: $PUBLIC_BASE)
  -h, --help          this help

Typical release:
  $PROG --ova ~/hemo-release/hemo-0.1.1-vmware.ova --audit --no-sign   # check + sums + notes
  # owner, in a real terminal:  minisign -S -s ~/.minisign/hemo-release.key -m <outdir>/SHA256SUMS
  $PROG --ova ~/hemo-release/hemo-0.1.1-vmware.ova --no-sign --upload  # verifies the signature, uploads
EOF
}

ova="" outdir="" audit=0 do_sign=1 upload=0
seckey=${HEMO_MINISIGN_SECKEY:-$HOME/.minisign/hemo-release.key}
pubkey="$REPO_DIR/release/hemo-release.pub"

while [ $# -gt 0 ]; do
  case $1 in
    --ova)         ova=${2:?--ova needs a path}; shift 2 ;;
    --outdir)      outdir=${2:?--outdir needs a path}; shift 2 ;;
    --audit)       audit=1; shift ;;
    --no-sign)     do_sign=0; shift ;;
    --upload)      upload=1; shift ;;
    --seckey)      seckey=${2:?}; shift 2 ;;
    --pubkey)      pubkey=${2:?}; shift 2 ;;
    --bucket)      BUCKET=${2:?}; shift 2 ;;
    --profile)     PROFILE=${2:?}; shift 2 ;;
    --public-base) PUBLIC_BASE=${2:?}; shift 2 ;;
    -h|--help)     usage; exit 0 ;;
    *) usage; die "unknown argument: $1" ;;
  esac
done

[ -n "$ova" ] || { usage; die "--ova is required"; }
[ -f "$ova" ] || die "ova not found: $ova"
[ -f "$pubkey" ] || die "public key not found: $pubkey"
ova=$(cd -- "$(dirname -- "$ova")" && pwd)/$(basename -- "$ova")
base=$(basename -- "$ova")
[[ $base =~ ^hemo-([0-9]+\.[0-9]+\.[0-9]+)-vmware\.ova$ ]] || die "name must be hemo-<x.y.z>-vmware.ova (got $base)"
version=${BASH_REMATCH[1]}
[ -n "$outdir" ] || outdir=$(dirname -- "$ova")/release-$version
mkdir -p -- "$outdir"
outdir=$(cd -- "$outdir" && pwd)
url="$PUBLIC_BASE/$base"
size=$(stat -c %s -- "$ova")

note "image:   $ova ($size bytes)"
note "version: $version"
note "outdir:  $outdir"

# 1. read-only audit ----------------------------------------------------------
audit_disk() {
  local t tool
  for tool in qemu-storage-daemon debugfs sfdisk tar; do
    command -v "$tool" >/dev/null 2>&1 || die "--audit needs $tool (apt-get install qemu-utils e2fsprogs fdisk)"
  done
  t=$(mktemp -d)
  # The disk is the tar member ending in .vmdk; its data starts one 512-byte
  # header after the block number tar reports.
  local blk vsize off start dev pid
  read -r blk vsize < <(tar tvf "$ova" --block-number | awk '/\.vmdk$/{gsub(":","",$2); print $2, $5; exit}')
  [ -n "${blk:-}" ] || die "no .vmdk inside $base"
  off=$(( (blk + 1) * 512 ))
  : > "$t/disk.raw"
  qemu-storage-daemon \
    --blockdev "{\"node-name\":\"d\",\"driver\":\"vmdk\",\"read-only\":true,\"file\":{\"driver\":\"raw\",\"offset\":$off,\"size\":$vsize,\"read-only\":true,\"file\":{\"driver\":\"file\",\"filename\":\"$ova\",\"read-only\":true}}}" \
    --export "type=fuse,id=e,node-name=d,mountpoint=$t/disk.raw,writable=off" \
    --daemonize --pidfile "$t/qsd.pid" 2>/dev/null || die "could not open the disk image"
  pid=$(cat "$t/qsd.pid")
  # shellcheck disable=SC2064
  trap "kill $pid 2>/dev/null; sleep 1; rm -rf '$t'" EXIT
  start=$(sfdisk -d "$t/disk.raw" 2>/dev/null | awk -F'[=,]' '/start=/{gsub(/ /,"",$2); print $2; exit}')
  [ -n "$start" ] || die "no partition table found on the disk"
  dev="$t/disk.raw?offset=$(( start * 512 ))"
  dcat() { debugfs -R "cat $1" "$dev" 2>/dev/null; }

  local bad=0 mid host homes
  if [ "$(dcat /usr/share/hemo/hemo-release.pub)" = "$(cat "$pubkey")" ]; then
    note "audit: built-in release key matches $pubkey: ok"
  else
    note "audit: FAIL built-in /usr/share/hemo/hemo-release.pub differs from $pubkey"; bad=1
  fi
  mid=$(dcat /etc/machine-id | tr -d '\n')
  [ "$mid" = uninitialized ] && note "audit: machine-id uninitialized: ok" \
    || { note "audit: FAIL machine-id is '$mid' (should be 'uninitialized')"; bad=1; }
  host=$(dcat /etc/hostname | tr -d '\n')
  [ "$host" = hemo ] && note "audit: hostname hemo: ok" || { note "audit: FAIL hostname is '$host'"; bad=1; }
  homes=$(debugfs -R "ls /home" "$dev" 2>/dev/null | tr -s ' ' '\n' | grep -vxE '|\.|\.\.|[0-9]+|\([0-9]+\)' | tr '\n' ' ')
  [ "$homes" = "hemo " ] && note "audit: /home has only hemo: ok" || { note "audit: FAIL /home has: $homes"; bad=1; }
  dcat /etc/apt/apt.conf.d/90hemo-lock-timeout | grep -q 'Lock::Timeout' \
    && note "audit: apt lock timeout present: ok" || { note "audit: FAIL 90hemo-lock-timeout missing"; bad=1; }

  kill "$pid" 2>/dev/null; sleep 1; rm -rf "$t"; trap - EXIT
  [ "$bad" -eq 0 ] || die "audit failed; fix the image before releasing it"
}
[ "$audit" -eq 1 ] && audit_disk

# 2. checksum -------------------------------------------------------------------
sums="$outdir/SHA256SUMS"
if [ -f "$sums" ] && [ "$(awk '{print $2}' "$sums")" = "$base" ] && [ -f "$sums.minisig" ]; then
  note "reusing existing SHA256SUMS (already signed)"
  sha=$(awk '{print $1}' "$sums")
  ( cd -- "$(dirname -- "$ova")" && sha256sum -c --status "$sums" ) || die "the .ova no longer matches the signed SHA256SUMS"
else
  note "hashing image..."
  sha=$(sha256sum -- "$ova" | awk '{print $1}')
  printf '%s  %s\n' "$sha" "$base" > "$sums"
  rm -f -- "$sums.minisig"
fi
note "sha256: $sha"
cp -- "$pubkey" "$outdir/hemo-release.pub"

# 3. sign + verify ----------------------------------------------------------------
if [ ! -f "$sums.minisig" ]; then
  if [ "$do_sign" -eq 1 ]; then
    command -v minisign >/dev/null 2>&1 || die "minisign not found (apt-get install minisign)"
    [ -f "$seckey" ] || die "secret key not found: $seckey"
    [ -t 0 ] || die "signing needs a real terminal for the password; run it there, or use --no-sign"
    note "signing (enter the key password)..."
    minisign -S -s "$seckey" -m "$sums"
  else
    note "not signed yet. In a real terminal run:"
    echo "     minisign -S -s $seckey -m $sums" >&2
  fi
fi
if [ -f "$sums.minisig" ]; then
  minisign -Vm "$sums" -p "$pubkey" >/dev/null || die "signature does NOT verify with $pubkey"
  note "signature verifies with $pubkey: ok"
fi

# 4. release notes ------------------------------------------------------------------
tmpl="$REPO_DIR/release/RELEASE-NOTES.template.md"
notes="$outdir/RELEASE-NOTES-$version.md"
if [ -f "$tmpl" ] && [ ! -f "$notes" ]; then
  human=$(awk -v b="$size" 'BEGIN{printf "%.1f GB", b/1e9}')
  sed -e '1,/-->\s*$/d' -e "s|{{VERSION}}|$version|g" -e "s|{{OVA}}|$base|g" -e "s|{{URL}}|$url|g" \
      -e "s|{{SIZE}}|$human|g" -e "s|{{SHA256}}|$sha|g" "$tmpl" > "$notes"
  note "wrote $notes (fill in What's new)"
fi

# 5. upload + public check ----------------------------------------------------------
if [ "$upload" -eq 1 ]; then
  [ -f "$sums.minisig" ] || die "refusing to upload before SHA256SUMS is signed"
  command -v aws >/dev/null 2>&1 || die "aws not found (apt-get install awscli)"
  note "uploading to s3://$BUCKET/$base (profile $PROFILE)..."
  aws s3 cp "$ova" "s3://$BUCKET/$base" --profile "$PROFILE" \
    --content-type application/octet-stream --only-show-errors
  note "checking the public URL..."
  len=$(curl -sfI "$url" | awk 'tolower($1)=="content-length:"{print $2}' | tr -d '\r')
  [ "$len" = "$size" ] || die "public URL size is '${len:-none}', expected $size: $url"
  pub=$(curl -sf "$url" | sha256sum | awk '{print $1}')
  [ "$pub" = "$sha" ] || die "public download hashes to $pub, expected $sha"
  note "public download matches: ok"
fi

# 6. summary ------------------------------------------------------------------------
echo >&2
note "download URL (site button + docs): $url"
note "attach to the GitHub release v$version:"
for f in SHA256SUMS SHA256SUMS.minisig hemo-release.pub; do
  [ -f "$outdir/$f" ] && echo "     $outdir/$f" >&2 || echo "     $outdir/$f  (MISSING)" >&2
done
note "release body: $notes"
note "nothing was pushed; the owner pushes and publishes."
