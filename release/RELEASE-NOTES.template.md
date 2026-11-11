<!-- Fill in the <...> fields. Keep the verify block verbatim. -->
# Hemo OS <version> — VMware OVA

A curated, durable Kali-based pentest/red-team distro. VM-first, i3 on X11. Thin
baked core; per-role online tool install via Hemo Welcome.

## Download

The OVA is split into 7-Zip volumes under 2 GiB (GitHub's per-file limit).
Download **every** `.7z.0NN` part plus `SHA256SUMS`, `SHA256SUMS.minisig`, and
`hemo-release.pub` into one folder.

| File | Notes |
| --- | --- |
| `hemo-<version>-vmware.ova.7z.001` … | the image, split |
| `SHA256SUMS` | checksums of the parts |
| `SHA256SUMS.minisig` | minisign signature over `SHA256SUMS` |
| `hemo-release.pub` | public key (also below) |

## Verify, then unpack

Already on a Hemo system? One command checks the signature and the checksums:

```sh
hemo-verify          # run it in the download folder
```

On any machine (the key is published below and fingerprinted
`RWQzpPBysI/5LuAT3QYSxApS/ZTU2xbJKyqrzgvfLSi6N3RlPJeQvoC8`,
id `2EF98FB072F0A433`):

```sh
minisign -Vm SHA256SUMS -p hemo-release.pub && sha256sum -c --ignore-missing SHA256SUMS
7z x hemo-<version>-vmware.ova.7z.001        # reassembles + extracts the .ova
```

`minisign` ships in Kali and most distro repos (it is baked into Hemo). Verify
the signature **before** trusting the `hemo-release.pub` in the download — compare
its id above against a copy you already trust. The public key for this and all
Hemo releases:

```
<paste contents of release/hemo-release.pub here>
```

## First boot

Import the `.ova` in VMware Workstation/Player. Log in as **`hemo`** / **`hemo`**
(no forced change). i3 starts and Hemo Welcome opens — pick your roles to install
tools. The image ships with no network ports listening; change the password
before exposing it.

## What's in it

- Thin baked core: i3 + X11 desktop, Hemo Welcome, the `hemo-*` helpers, the
  theming and role tooling. Full tool sets install per role, online, on first use.
- OS identifies as "Hemo OS (Kali Rolling)".
- Baseline package list attached (`<pkglist filename>`).

## Checksums

Raw image (pre-pack):

```
<contents of hemo-<version>-vmware.ova.sha256>
```
