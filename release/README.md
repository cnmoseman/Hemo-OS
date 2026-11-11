# release/

Signing material and templates for Hemo OS releases. The packaging itself is done by
`scripts/hemo-release-pack.sh`.

## Files

| File | Committed? | What it is |
| --- | --- | --- |
| `hemo-release.pub` | **yes** | minisign public key. Users verify releases with it; it is also pasted into every release's notes. |
| `hemo-release.key` | **NEVER** | minisign secret key. Lives only on the owner's machine. `.gitignore`d. |
| `RELEASE-NOTES.template.md` | yes | Fill-in template for a release's notes. |

The secret key is a credential — it never enters the repo, a commit, a log, or a
release asset. Only the owner holds it.

## One-time keypair setup (owner)

Done once, before the first release. `minisign` ships in Kali
(`sudo apt-get install minisign`).

```sh
mkdir -p ~/.minisign
minisign -G -s ~/.minisign/hemo-release.key -p /tmp/hemo-release.pub
# choose a strong password when prompted — it protects the secret key

# commit ONLY the public half:
cp /tmp/hemo-release.pub /path/to/Hemo-OS/release/hemo-release.pub
rm /tmp/hemo-release.pub
```

Then commit `release/hemo-release.pub` (public key only). Keep
`~/.minisign/hemo-release.key` backed up somewhere safe and offline; if it is
lost, future releases must switch to a new key and users re-trust it.

## Packing a release

With the owner-approved `.ova` on the dev VM:

```sh
scripts/hemo-release-pack.sh --ova ~/hemo-release/hemo-<version>-vmware.ova
```

It writes a `release/` directory next to the `.ova` containing the split
volumes, `SHA256SUMS`, `SHA256SUMS.minisig`, `hemo-release.pub`, and the
pre-pack `.sha256`. It round-trips the split back to the raw image's pre-pack
hash and verifies the signature before finishing. Nothing is uploaded — the
owner approves and uploads.

## How a user verifies a download

```sh
# with the public key from this directory alongside the files:
minisign -Vm SHA256SUMS -p hemo-release.pub && sha256sum -c --ignore-missing SHA256SUMS
# then reassemble and unpack:
7z x hemo-<version>-vmware.ova.7z.001
```
