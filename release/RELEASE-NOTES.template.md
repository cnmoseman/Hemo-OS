<!-- Template. scripts/hemo-release-pack.sh fills the double-brace placeholders
     (version, file name, download URL, size, sha256), drops this comment, and writes
     RELEASE-NOTES-<version>.md next to the release files. Then write "What's new" by hand. -->
# Hemo OS {{VERSION}} — VMware OVA

**Hemo OS** is a curated, durable Kali-based pentest / red-team distro. VM-first,
i3 on X11, a thin baked core — the heavy tooling installs per role, online, the
first time you need it, so the image stays small and current instead of shipping
a stale everything-bundle.

## What's new

- <change>

## Download

**[{{OVA}}]({{URL}})** (one file, {{SIZE}}). It's hosted outside GitHub because
GitHub caps release files at 2 GiB. Import it as is; there's nothing to extract.

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

On Hemo 0.1.1 or later, `hemo-verify` in the download folder does the same check
with the key built into the system. (0.1.0 has an older key built in, so use the
`minisign` line above there.)

`minisign` ships in Kali and most distro repos (`apt-get install minisign`). The
public key for Hemo OS releases (id `2EF98FB072F0A433`):

```
RWQzpPBysI/5LuAT3QYSxApS/ZTU2xbJKyqrzgvfLSi6N3RlPJeQvoC8
```

## Import and first boot

Import `{{OVA}}` in VMware Workstation, Player or Fusion
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
{{SHA256}}  {{OVA}}
```
