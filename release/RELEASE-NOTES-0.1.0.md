<!-- DRAFT for the first release. Version held at 0.1.0 and NOT public yet.
     Fill these in AFTER the re-provisioned OVA exists and the release has been packed:
       - <N>              number of .7z.0NN parts (expect ~3 at ~4.78 GB)
       - <raw-sha256>     contents of hemo-0.1.0-vmware.ova.sha256 (pre-pack)
       - <pubkey-line>    the single line from release/hemo-release.pub
       - <pkglist>        the baseline package-list filename, if attached
     Everything else is final copy. -->

# Hemo OS 0.1.0 — VMware OVA

**Hemo OS** is a curated, durable Kali-based pentest / red-team distro. VM-first,
i3 on X11, a thin baked core — the heavy tooling installs per role, online, the
first time you need it, so the image stays small and current instead of shipping
a stale everything-bundle.

This is the first public image. It reports itself as **"Hemo OS (Kali Rolling)"**.

## Download

The OVA is split into 7-Zip volumes under 2 GiB each (GitHub caps a single
release file at 2 GiB). Download **every** `.7z.0NN` part into one folder, plus
`SHA256SUMS`, `SHA256SUMS.minisig`, and `hemo-release.pub`.

| File | What it is |
| --- | --- |
| `hemo-0.1.0-vmware.ova.7z.001` … `.00<N>` | the image, split |
| `SHA256SUMS` | checksums of the parts |
| `SHA256SUMS.minisig` | minisign signature over `SHA256SUMS` |
| `hemo-release.pub` | the public key (also printed below) |
| `hemo-0.1.0-vmware.ova.sha256` | checksum of the raw image (pre-pack) |

## Verify, then unpack

Verify the signature and the parts before you unpack — one line:

```sh
minisign -Vm SHA256SUMS -p hemo-release.pub && sha256sum -c --ignore-missing SHA256SUMS
```

Then reassemble and extract (point 7-Zip at the **`.001`** volume; it pulls in
the rest automatically):

```sh
7z x hemo-0.1.0-vmware.ova.7z.001
```

`minisign` ships in Kali and most distro repos (`apt-get install minisign`). The
public key for this and every Hemo OS release:

```
<pubkey-line>
```

## Import and first boot

Import `hemo-0.1.0-vmware.ova` in VMware Workstation or Player
(*File → Open → the .ova*). Log in as:

- **Username:** `hemo`
- **Password:** `hemo`

No forced password change — it behaves like Kali. i3 starts and **Hemo Welcome**
opens. Pick your roles there and it installs that role's tools online.

> The password is public and permanent until you change it, so the image ships
> with **no network ports listening** (SSH is disabled). Change the password
> before you put the VM on any network you don't control.

## What's in it

A thin baked core — i3 + X11 desktop, Hemo Welcome, the `hemo-*` helpers, the
role theming, and the package tooling. Full tool sets install per role, on
demand, through Hemo Welcome. The roles:

| Role | For |
| --- | --- |
| **Red Team** | C2, post-exploitation, lateral movement, evasion, AD compromise |
| **Penetration Testing** | Generalist assessment — recon, AD, web, passwords, exploitation |
| **Web** | Web and API application testing |
| **Vulnerability Assessor** | Authenticated / unauth scanning, triage, reporting |
| **Reverse** | Binary, Android/Java, and loot analysis — Ghidra, debuggers, more |
| **Blue Host Analyst** | Host / endpoint DFIR — forensics, triage, malware analysis |
| **Blue Net Analyst** | Network security monitoring — IDS, traffic + flow analysis |
| **Full Scope** | Every role's tools — the batteries-included purple build |

Install a role from Hemo Welcome, or from a terminal:

```sh
sudo hemo-pkg install-role red_team      # list-roles shows them all
```

The baseline package list for this image is attached (`<pkglist>`).

## Notes

- **Format:** VMware OVA, for VMware Workstation, Player, and Fusion. Hemo ships
  for VMware only.
- **Updates:** it's Kali Rolling underneath — `sudo apt update && sudo apt
  full-upgrade` keeps the base current; re-run a role in Hemo Welcome to pull new
  tool versions.

## Checksums

Raw image (taken before packing, so the parts provably reconstruct what was
tested):

```
<raw-sha256>  hemo-0.1.0-vmware.ova
```
