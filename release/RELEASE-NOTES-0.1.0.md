# Hemo OS 0.1.0 — VMware OVA

**Hemo OS** is a curated, durable Kali-based pentest / red-team distro. VM-first,
i3 on X11, a thin baked core — the heavy tooling installs per role, online, the
first time you need it, so the image stays small and current instead of shipping
a stale everything-bundle.

This is the first public image. It reports itself as **"Hemo OS (Kali Rolling)"**.

## Download

**[hemo-0.1.0-vmware.ova](https://pub-2837a6191ae149fcb82eca0c04982e0a.r2.dev/hemo-0.1.0-vmware.ova)** (one file, 5.1 GB). It's hosted outside GitHub
because GitHub caps release files at 2 GiB. Import it as is; there's nothing to extract.

To check it, download these files from this release into the same folder:

| File | What it is |
| --- | --- |
| `SHA256SUMS` | checksum of the `.ova` |
| `SHA256SUMS.minisig` | minisign signature over `SHA256SUMS` |
| `hemo-release.pub` | the public key (also printed below) |

## Verify

```sh
minisign -Vm SHA256SUMS -p hemo-release.pub && sha256sum -c SHA256SUMS
```

`minisign` ships in Kali and most distro repos (`apt-get install minisign`). The
public key for this and every Hemo OS release:

```
RWQzpPBysI/5LuAT3QYSxApS/ZTU2xbJKyqrzgvfLSi6N3RlPJeQvoC8
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


## Notes

- **Format:** VMware OVA, for VMware Workstation, Player, and Fusion. Hemo ships
  for VMware only.
- **Updates:** it's Kali Rolling underneath — `sudo apt update && sudo apt
  full-upgrade` keeps the base current; re-run a role in Hemo Welcome to pull new
  tool versions.

## Checksum

```
76340758e230617e8eb51b4a2ef89846339a4f8433677981e05cd89bc3ef1264  hemo-0.1.0-vmware.ova
```
