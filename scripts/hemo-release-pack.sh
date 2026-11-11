#!/usr/bin/env bash
# hemo-release-pack.sh — package, checksum and sign a release OVA.
#
# Takes one approved raw image (the .ova that passed its import test) and produces
# a release/ directory ready for upload:
#
#   <name>.ova.sha256        raw-image checksum, taken BEFORE packing
#   <name>.ova.7z.001 ...    7-Zip split volumes, each < 2 GiB (GitHub's limit)
#   SHA256SUMS               checksums of the published .7z.* parts
#   SHA256SUMS.minisig       minisign signature over SHA256SUMS
#   hemo-release.pub         the public key (copied in for convenience)
#
# It round-trips the split back to the raw image's pre-pack hash, so the
# published parts provably reconstruct exactly what was tested, and it verifies
# the signature it just made with the committed public key.
#
# It NEVER uploads, tags, or touches GitHub — the owner approves and uploads
# (docs/golden-image.md step 7). The minisign SECRET key never lives in the
# repo: pass it with --seckey or $HEMO_MINISIGN_SECKEY (default
# ~/.minisign/hemo-release.key). minisign prompts for its password itself.
set -euo pipefail

PROG=${0##*/}
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_DIR=$(cd -- "$SCRIPT_DIR/.." && pwd)

PART_SIZE=1900m          # 7z split volume size; keeps each part < 2 GiB
LEVEL=9                  # 7z compression level
TWO_GIB=2147483648       # hard per-file ceiling (2 * 1024^3)

die()  { printf '%s: error: %s\n' "$PROG" "$*" >&2; exit 1; }
note() { printf '>> %s\n' "$*" >&2; }

usage() {
  cat >&2 <<EOF
Usage: $PROG --ova PATH [options]

  --ova PATH        the approved raw image to package (required)
  --outdir DIR      where to write the release files
                    (default: <ova-dir>/release)
  --seckey PATH     minisign secret key
                    (default: \$HEMO_MINISIGN_SECKEY or ~/.minisign/hemo-release.key)
  --pubkey PATH     minisign public key, for the post-sign verify and to copy in
                    (default: $REPO_DIR/release/hemo-release.pub)
  --pkglist PATH    baseline package list to include in the release (optional)
  --no-sign         pack + checksum + round-trip only; skip minisign
  -h, --help        this help

Example:
  $PROG --ova ~/hemo-release/hemo-0.1.0-vmware.ova
EOF
}

ova=""
outdir=""
seckey=${HEMO_MINISIGN_SECKEY:-$HOME/.minisign/hemo-release.key}
pubkey="$REPO_DIR/release/hemo-release.pub"
pkglist=""
do_sign=1

while [ $# -gt 0 ]; do
  case $1 in
    --ova)     ova=${2:?--ova needs a path}; shift 2 ;;
    --outdir)  outdir=${2:?--outdir needs a path}; shift 2 ;;
    --seckey)  seckey=${2:?--seckey needs a path}; shift 2 ;;
    --pubkey)  pubkey=${2:?--pubkey needs a path}; shift 2 ;;
    --pkglist) pkglist=${2:?--pkglist needs a path}; shift 2 ;;
    --no-sign) do_sign=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage; die "unknown argument: $1" ;;
  esac
done

[ -n "$ova" ] || { usage; die "--ova is required"; }
[ -f "$ova" ] || die "ova not found: $ova"

command -v 7z       >/dev/null 2>&1 || die "7z not found (apt-get install p7zip-full)"
command -v sha256sum >/dev/null 2>&1 || die "sha256sum not found"
if [ "$do_sign" -eq 1 ]; then
  command -v minisign >/dev/null 2>&1 || die "minisign not found (apt-get install minisign); or re-run with --no-sign"
  [ -f "$seckey" ] || die "minisign secret key not found: $seckey (set --seckey or \$HEMO_MINISIGN_SECKEY)"
fi

ova=$(cd -- "$(dirname -- "$ova")" && pwd)/$(basename -- "$ova")   # absolutise
base=$(basename -- "$ova")
[ -n "$outdir" ] || outdir=$(dirname -- "$ova")/release
mkdir -p -- "$outdir"
outdir=$(cd -- "$outdir" && pwd)

note "image:   $ova"
note "outdir:  $outdir"

# 1. pre-pack checksum of the raw image --------------------------------------
note "hashing raw image (pre-pack)..."
pre=$(sha256sum -- "$ova" | awk '{print $1}')
printf '%s  %s\n' "$pre" "$base" > "$outdir/$base.sha256"
note "pre-pack sha256: $pre"

# 2. 7-Zip split --------------------------------------------------------------
rm -f -- "$outdir/$base".7z.*          # clear any stale parts
note "packing split volumes ($PART_SIZE, -mx=$LEVEL)..."
7z a -t7z -mx="$LEVEL" -v"$PART_SIZE" -bso0 -bsp0 -- "$outdir/$base.7z" "$ova"

shopt -s nullglob
parts=( "$outdir/$base".7z.[0-9][0-9][0-9] )
shopt -u nullglob
[ ${#parts[@]} -gt 0 ] || die "7z produced no .7z.NNN volumes"
note "produced ${#parts[@]} volume(s)"

# 3. size ceiling -------------------------------------------------------------
for p in "${parts[@]}"; do
  sz=$(stat -c %s -- "$p")
  [ "$sz" -lt "$TWO_GIB" ] || die "part exceeds 2 GiB: $(basename -- "$p") ($sz bytes)"
done
note "all parts < 2 GiB: ok"

# 4. round-trip: reconstruct and compare to the pre-pack hash -----------------
note "round-tripping split -> sha256 (must equal pre-pack)..."
post=$(7z x -so -- "$outdir/$base.7z.001" 2>/dev/null | sha256sum | awk '{print $1}')
[ "$post" = "$pre" ] || die "round-trip mismatch: parts reconstruct to $post, not $pre"
note "round-trip sha256: $post (matches)"

# 5. SHA256SUMS over the published parts (relative names) ---------------------
( cd -- "$outdir" && sha256sum "$base".7z.[0-9][0-9][0-9] > SHA256SUMS )
note "wrote SHA256SUMS over ${#parts[@]} part(s)"

# 6. baseline package list (optional) ----------------------------------------
if [ -n "$pkglist" ]; then
  [ -f "$pkglist" ] || die "pkglist not found: $pkglist"
  cp -- "$pkglist" "$outdir/"
  note "included package list: $(basename -- "$pkglist")"
fi

# 7. sign + verify ------------------------------------------------------------
if [ "$do_sign" -eq 1 ]; then
  note "signing SHA256SUMS with minisign (you'll be prompted for the key password)..."
  ( cd -- "$outdir" && minisign -S -s "$seckey" -m SHA256SUMS )
  if [ -f "$pubkey" ]; then
    note "verifying signature with $pubkey ..."
    ( cd -- "$outdir" && minisign -Vm SHA256SUMS -p "$pubkey" )
    cp -- "$pubkey" "$outdir/hemo-release.pub"
    note "verify: ok"
  else
    note "WARNING: public key not found at $pubkey — signature made but NOT verified."
    note "         commit the matching hemo-release.pub to release/ and verify before upload."
  fi
else
  note "skipped signing (--no-sign)"
fi

# 8. manifest -----------------------------------------------------------------
echo >&2
note "release files in $outdir:"
( cd -- "$outdir" && ls -1 ) | sed 's/^/     /' >&2
echo >&2
note "user verify one-liner (put in the release notes):"
echo "     minisign -Vm SHA256SUMS -p hemo-release.pub && sha256sum -c --ignore-missing SHA256SUMS" >&2
echo >&2
note "done. Nothing was uploaded — the owner approves and uploads (docs/golden-image.md step 7)."
