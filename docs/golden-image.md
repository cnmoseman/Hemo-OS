# Golden images: plan

Hemo ships as a prebuilt VMware image (`.ova`) only (owner decision 2026-11-11; the qcow2 and
VDI images were dropped). The golden image is built by hand in VMware;
where this plan mentions qcow2, VDI or the kali-vm build host, that part is reference only.
This document is the plan for making those images "golden": clean, identical for every
download, with no personal data and no sign that any VM was ever run from them.

Status: **plan, not built.** Decided 2026-10-13. Work items are at the end.

## What the user sees

1. Import the image and boot it. GRUB, the Plymouth splash and the login screen are all
   Hemo-branded.
2. The login screen offers one user, `hemo`. The password is `hemo` (printed in the README
   and the release notes). Like Kali's `kali`/`kali`, there is **no forced password
   change**; the user changes it with `passwd` when they choose to (owner decision
   2026-10-13).
3. The i3 desktop starts and **Hemo Welcome** opens to pick roles. Tools install online.

Nothing else happens before Welcome: no Xfce, no setup questions, no leftover windows.

## Definition of clean

An image is golden only if all of these hold. The audit (below) checks each one.

| Area | Requirement |
|---|---|
| Never booted | The published bytes are the bytes the build wrote. Testing boots copies only. |
| Identity | `/etc/machine-id` contains `uninitialized`; no `/var/lib/dbus/machine-id` file (symlink only); no SSH host keys; no `/var/lib/systemd/random-seed`. |
| Users | Only `root` (locked) and `hemo` (password `hemo`, not expired; member of `sudo`). No `kali` user, including in `/etc/passwd-`, `/etc/shadow-`, `/etc/group-`, `/etc/gshadow-`. |
| Homes | `/home/hemo` and `/root` hold only skeleton files: no shell history, no `.cache`, no Firefox profile, no `.ssh`, no `.lesshst`/`.viminfo`/`.python_history`, no PowerShell history (`.local/share/powershell`). |
| Logs | Everything under `/var/log` empty or absent (apt `history.log` records `Requested-By: <user>` when apt runs through sudo); empty `wtmp`, `btmp`, `lastlog`, `faillog`; no journal files. |
| Network | No NetworkManager connections or DHCP leases; `resolv.conf` reset (the build tool can copy the build host's DNS servers in); `sources.list` points at the official Kali mirror with no proxy or local-mirror config. |
| Caches | No apt archives or lists, pip/go/npm caches, `__pycache__`, `/tmp` or `/var/tmp` content. |
| Build host | No trace of the build machine: its hostname, usernames, home paths, email addresses, internal IPs or Wi-Fi names, in the filesystem or in the `.ovf`/`.vbox` metadata. |
| Services | SSH server disabled (or absent). The `hemo`/`hemo` password is public and never forced to change, so no service may accept it over the network. Docker installed but idle. |
| Free space | No deleted data in unused disk blocks. |
| Defaults | Hostname `hemo` (owner decision 2026-10-13), timezone `Etc/UTC`, `en_US.UTF-8`, US keyboard. |
| Completeness | The critical baked binaries a basic boot + role-install test won't exercise are present: `docker`, `dockerd`, `docker-buildx` (container runtime for AdaptixC2 / BloodHound CE), and the desktop essentials `i3`, `qterminal`, `rofi`, `polybar`. A transient apt failure dropped docker on the 0.1.0 golden; `provision.sh` now retries + fails non-zero on a critical miss, and the sysprep audit checks each by on-disk path. |

## How the pipeline achieves it

The pipeline in `build.sh` already gets most of the way, because **the master image is
never booted**. kali-vm builds a root filesystem offline, `scripts/hemo-customize.sh` runs
inside it with `systemd-nspawn` (no boot, no login, no services), and each disk format is
created fresh from that tarball. A fresh filesystem means unused blocks are zero, so no
deleted data survives. The hand-build path (boot a Kali VM, run `provision.sh`, export) is
the opposite: every boot leaves traces. It is a fallback only and is not used for releases.

Steps, with what is new:

1. **Build the rootfs** (`kali-vm -v rootfs -D i3 -T none`). Existing. Xfce is never
   installed, so the "landed in Xfce" bug from the installer tests can't happen here.

2. **Customize** (`hemo-customize.sh`). Existing, with fixes:
   - Write `uninitialized` to `/etc/machine-id`. It currently empties the file, which
     systemd does not treat as a first boot.
   - Write `/etc/hostname` and `/etc/hosts` directly instead of calling `hostnamectl`.
     There is no `hostnamed` inside the build container.
   - Set timezone, locale and keyboard explicitly so nothing is inherited from the build host.
   - Reset `sources.list` to `http.kali.org/kali kali-rolling` and remove any apt proxy
     config that kali-vm or the build host added.
   - Lock `root`; make sure `ssh.service` is disabled.
   - Set the login session the build-time way it already does (write `.dmrc`,
     AccountsService file and `user-session=i3` directly). No daemon is running during the
     build, so nothing can overwrite them.

3. **Seal** (new: `scripts/hemo-seal.sh`). The last thing that runs inside the rootfs,
   after every package install. It cleans everything in the table above: logs, login
   records, journals, apt/pip/go caches, `__pycache__`, `/tmp`, histories, NetworkManager
   state, `resolv.conf`, `*-` and `*.dpkg-old` backup files, SSH host keys, the random
   seed, and machine-id (`uninitialized`). It also resets the Hemo first-boot flags
   (`/var/lib/hemo/firstboot.done`, roles, primary, theme). It works like `virt-sysprep`,
   but it runs on the tarball, so it covers every format at once.

4. **Export** each format (existing), then **seal again**. kali-vm's export stage runs
   *after* the rootfs is sealed: it installs the kernel, GRUB and guest tools, runs
   `apt-get update`, and adds users to groups, which writes new package logs and leaves
   deleted data in free space. A small kali-vm patch adds a final in-image step that
   re-runs the seal, and then always runs kali-vm's `zerofree` step (normally tied to its
   `-z` flag). Add metadata hygiene: the `.ovf` and `.vbox` files must not contain
   build-host paths, and the qcow2 must have no backing file.

5. **Audit** (new: `scripts/hemo-audit.sh`). Opens every finished artifact **read-only**
   with libguestfs (`guestfish --ro`), checks each row of the clean table, and greps the
   filesystem and metadata for a **denylist** of build-host strings (username, real name,
   email, hostname, home path, internal IPs and DNS servers). The denylist lives in a local
   file outside git and is never committed. Any finding fails the build.

6. **Test on copies** (PLAN.md Phase 5). Boot a copy of each format and check:
   - The login screen shows `hemo`, password `hemo` logs in with no forced change, and i3 starts.
   - Hemo Welcome opens, and a role installs.
   - Two clones get different machine-ids and SSH host keys.
   - Nothing is listening on the network.
   Then delete the copies.

7. **Release.** `SHA256SUMS` plus a signature (minisign or GPG), and the baseline package
   list. Then confirm the published files match the checksums taken before testing.
   Every image is packed as **7-Zip split volumes under 2 GiB each** (`.7z.001`,
   `.7z.002`, …) for GitHub's per-file limit (owner decision 2026-10-13: "zip it"). The
   checksums cover the raw images (pre-test) and the `.7z.*` parts (published).

## The first login

Decided 2026-10-13: **behave like Kali.** The account ships as `hemo`/`hemo`, not expired.
No forced change, no password page in Welcome. LightDM shows `hemo`, the user logs in, i3
starts, and Hemo Welcome opens. Because the password is public and permanent until the
user changes it, the image must listen on no network ports (SSH disabled). The audit
checks this.

## Decisions (made 2026-10-13)

1. **Hostname:** `hemo`.
2. **First login:** like Kali. Password `hemo`, no forced change.
3. **Signing:** minisign (small keys, one-line verify). `SHA256SUMS` plus
   `SHA256SUMS.minisig`, and the public key in the repo and the release notes.
4. **Hosting:** 7-Zip split volumes under 2 GiB on GitHub releases.

## Work items

1. Build host with `/dev/kvm` (turn on VT-x/EPT for this VMware guest, or use another Linux
   box), and vendor `kali-vm` into `vendor/kali-vm`.
2. `hemo-customize.sh` fixes from step 2.
3. `scripts/hemo-seal.sh`, called at the end of the customize step in `build.sh`.
4. `scripts/hemo-audit.sh` plus a local denylist file (path in `.gitignore`), run by
   `build.sh` after export; the build fails on any finding.
5. First build, audit, and copy-boot tests on VMware, QEMU and VirtualBox.
6. Signing, `SHA256SUMS` verification, size check, then the first release.
