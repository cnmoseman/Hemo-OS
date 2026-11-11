# Hemo — hand-built VMware image runbook

How to turn a fresh Kali VM into a Hemo VMware image, on Windows 11 Home.
No Linux build host needed. You run these; I can't do them for you.

## What you need

- **VMware Workstation Pro** — free for personal use. (Workstation, not Hyper-V;
  Hyper-V isn't on Win 11 Home anyway.)
- **The official Kali VMware image** from kali.org → Get Kali → Virtual Machines
  → VMware (a `.7z` you extract to a `.vmx` + disks). ~ a few GB.
- `provision.sh` from this repo.

## Firmware: UEFI vs BIOS

Hemo targets **UEFI** (it's what modern laptops ship with, it's required for
Secure Boot later, and it's what the `build.sh` images use). The official Kali
VMware download is **BIOS/MBR**, and an existing VM can't be switched to UEFI
without repartitioning — so:

- **Quick test (BIOS, today's path):** use the Kali VMware download as below.
  Everything works; GRUB just runs in legacy mode.
- **UEFI hand-build:** in Workstation create a *new* VM (Custom → Linux /
  Debian 12 64-bit), then *before first boot* VM → Settings → Options →
  Advanced → Firmware type **UEFI** (leave Secure Boot unticked). Install from
  the Kali **installer ISO** (minimal is fine), then continue from step 3.
  Check it took: `[ -d /sys/firmware/efi ] && echo UEFI`.
- **Release OVA:** built from Kali's stock VMware image (BIOS), so it imports
  and boots as-is. Hemo ships for VMware only.

## Steps

1. **Import & boot.** Extract the Kali VMware download, open the `.vmx` in
   Workstation, start it. Default login is `kali` / `kali`.

2. **Size it** (VM must be powered off): VM → Settings → set memory **8 GB**,
   processors **4**. The virtual disk is already thin-provisioned.

3. **Get the repo in.** Open a terminal in the VM and clone it (or copy it in with
   VMware drag-and-drop or a shared folder):
   ```
   git clone https://github.com/cnmoseman/hemo-os.git
   cd hemo-os
   ```

4. **Provision.**
   ```
   sudo ./provision.sh
   ```
   It logs to `/var/log/hemo-provision.log` and prints any package names
   that need a second look at the end. Re-run it safely if something failed.

5. **Finish the manual bits** (not scripted, by choice):
   - **Burp Pro**: Community is already installed; add Pro later from your own storage.
   - **AdaptixC2**: needs compiling — skip for now or follow its README.

6. **Reboot and check.** Log in as `hemo` (default password `hemo`, like
   Kali's `kali`/`kali`; change it with `passwd`). Confirm i3 starts and a few tools run
   (`nmap --version`, `nxc --help`, `ffuf -V`).

6a. **Boot & login branding (optional).** `provision.sh` runs this for you, but
   to (re)apply it alone — e.g. after dropping in real mascot art:
   ```
   sudo ./branding/install-branding.sh
   ```
   It applies the GRUB theme, the Plymouth boot-glow animation, and the LightDM
   login background from `branding/assets/` (`hemo-mark.png` toad, `hemo-logo.png`
   disc emblem, `hemo-bg.png`/`hemo-bg.svg` background). Replace those and re-run
   to rebrand. In a VM the Plymouth animation may render plainly depending on the
   guest video driver; GRUB and the login screen always theme correctly.

6b. **Declutter (optional).** To trim Kali-default bloat while keeping the
   Hemo tools, snapshot first, then:
   ```
   sudo ./declutter.sh            # preview — removes nothing
   sudo ./declutter.sh --apply    # remove, after you've reviewed the list
   ```
   It protects the curated core + i3 desktop, drops the stock toolset
   (`kali-linux-default` / `-headless` / `-tools-top10` / `-system-gui`) and the
   XFCE desktop, autoremoves their orphans, and reports space reclaimed (~7 GB
   on a dirtied VM). Roles reinstall the tools each persona needs. The greeter
   is `lightdm-gtk-greeter` and NetworkManager/Thunar are protected, so the
   desktop stays usable; `xfce4-power-manager` + `qt5ct`/`qt6ct` are kept
   (kali-desktop-i3 depends on them).

7. **Clean before saving** (optional but recommended for a golden image):
   ```
   sudo apt-get clean && sudo rm -rf /tmp/* ~/.cache
   # wipe shell history, regenerate SSH host keys on first boot, etc.
   ```

8. **Save it as your golden image.** Power off, then either:
   - **Snapshot** (VM → Snapshot → Take Snapshot "hemo-base") and clone from
     it per engagement (VM → Manage → Clone → Linked Clone), **or**
   - **Export OVA**: `"C:\Program Files (x86)\VMware\VMware Workstation\OVFTool\ovftool.exe" hemo.vmx hemo.ova`
     — a single portable file you re-import for each engagement.

## Per-engagement use

- Clone (linked clone = fast, little disk) or re-import the OVA.
- Keep engagement data on a **separate virtual disk / shared folder**, so
  deleting the clone never deletes evidence.
- Delete the clone when done. The golden image stays untouched.

## Changing the identity (user @ host)

The clone ships as `hemo@hemo`. To make it anything you like, e.g. `james@office`:

```
sudo hemo-identity james office     # renames user hemo -> james, host hemo -> office
sudo hemo-identity james            # just the user
```

Run it right after first boot, before working as the default user (Linux can't
rename a user with running processes — use a root TTY, Ctrl+Alt+F2, or add
`--force`). To make a *new default* for every future build instead, change
`OPERATOR=` in `provision.sh` (and the hostname in `branding`/host config).

## Report screenshots (consistent sizing/formatting)

Hemo is set up so report screenshots come out identical every time:

- **Terminal:** kitty opens at a fixed size on every launch (110×32 cells,
  JetBrains Mono 11), so any terminal screenshot has the same dimensions.
- **`shot` (recommended for reports):** `$mod+Print` captures the active window,
  adds a consistent dark border + 1px edge, resizes to a fixed width (1100px),
  saves to `~/engagements/screenshots`, and copies it to the clipboard — paste
  straight into the report. `$mod+Shift+Print` does the same for a region.
  Tune without editing the script: `SHOT_WIDTH=1280 shot`, `SHOT_PAD=24 shot`.
- **Flameshot:** `Print` for annotated region captures; it auto-saves to the
  same folder with a `hemo_<date>` name and copies to the clipboard, using
  the Hemo accent for annotations.

All of this lives in `overlays/` and is applied by `provision.sh`. Change the
numbers there once and every future image/clone inherits them.

## Reality check

This image is **Kali-default plus the Hemo tools** — it is not stripped
lean, and its package versions are whatever the repo served on build day.
Releases are built by hand in VMware and ship for VMware only. The
`kali-vm` pipeline in `PLAN.md` (multi-format, needs a Linux host with KVM) is
reference only and is not used for releases.
