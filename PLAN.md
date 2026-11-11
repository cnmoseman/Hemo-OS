# Hemo: Curated Kali VM Build Plan

> **Update 2026-11-11 (owner decision): Hemo ships for VMware only.** Releases are built by hand
> from a stock Kali VMware VM (`provision.sh`, `declutter.sh`, then the scripts in `scripts/`). Where this plan mentions qcow2, VDI, or the multi-format
> `kali-vm` build, that part is reference only; the rest of the design still holds.

**Hemo** is a curated Kali build for an engagement — a red teamer's machine for the months of an op. You build it per job and rebuild between jobs by default; it also **holds up as a persistent install** when you want to keep one. The desktop, environment and operator workflow are chosen on purpose and version-controlled; the offensive and defensive **tools install per role** (chosen for relevance to the operator, not to keep the image small). VM-first today, with the design kept clean enough that an **ISO / bare-metal** path stays open later.

**Governing principle:** fit-for-purpose and durable, never minimal-for-its-own-sake. The test for any tool or package is *relevance* — "does this operator need it, now or over a long op?" — not size. Heavy-but-necessary is in and must work well (BloodHound + neo4j on a red box is the canonical example); unnecessary stays out regardless of size. "Lightweight" means it **runs smooth** (snappy desktop, low idle resource use), decoupled from install footprint. No cut corners on quality of life.

- **Distro / hostname:** Hemo OS, hostname `hemo` — the horned toad (Texas horned lizard); squat, armored, unbothered.
- **Mascot:** a horned toad with big glowing gold eyes (dark theme, gold accent, moss-green secondary). `hemo` is the nod to its party trick: squirting blood from its eyes. Placeholder art still shows the earlier green swamp toad.
- **Default user:** `hemo`, with sudo; default password `hemo`, like Kali's `kali`/`kali`. Not forced to change (owner decision 2026-10-13); change it with `passwd`.
- **Install model:** the image bakes a complete, polished **base** (desktop + environment + QoL + network plumbing + branding). Each operator's offensive/defensive tools install **per role** — picked for relevance so a box carries its discipline's full kit (heavy tools included) and none of another's. See "Role-based install model" below.
- **Lifecycle:** **per-engagement is the default** — build a curated image, clone or rebuild it per op, tear down the clone at the end. Keeping one install persistently (update and add roles over time) is a supported mode on top.
- **Updates / stability:** tools install *current* at setup; after that **the operator controls updates** — freeze during an op so nothing drifts or breaks mid-engagement, update deliberately between ops. Per-job record is the **bill of materials** (`hemo-bom`). Fragile build-from-source tools are pinned.
- **VM sizing:** 80 GB disk (thin-provisioned) / 8 GB RAM (floor 4) / 4 vCPU.
- **Password cracking:** CPU-only by default; on first boot `hemo-gpu` auto-detects a real GPU on the PCI bus (KVM/QEMU with VFIO passthrough, or bare metal) and offers to install drivers + enable the hashcat GPU backend. VMware/VirtualBox clones expose only a paravirtual display adapter, so they stay CPU-only. Large jobs still offload to a real rig.
- **Guest integration:** all three hypervisors' guest tools are baked (open-vm-tools-desktop / qemu-guest-agent + spice-vdagent / virtualbox-guest-x11) so one image gets clipboard, drag-drop and auto-resize on whatever host it lands on — only the matching daemon activates.
- **Releases kept:** every git tag + recipe forever; the base image is re-tagged only on a base/installer change (no calendar cadence).
- **Users:** the author, and anyone who wants it (single-operator setup, no per-team config yet).

## Decisions so far

| Topic | Decision |
|---|---|
| Output formats | VMware OVA only (decided 2026-11-11; qcow2 and VDI dropped) |
| Build host | Dedicated Linux machine or VM with KVM (nested virt if it's a VM) |
| Desktop | i3 (tiling) |
| Install model | Complete baked base; tools install per **role** (online), chosen for relevance — see roles.yml / `hemo-pkg` / `hemo-roles` |
| Lifecycle | **Per-engagement by default** (seal + clone/rebuild per op, `declutter.sh --seal`); keeping one install persistently is supported too |
| Updates | Install current at setup, then operator-controlled; freeze during an op, update deliberately between. Base re-tagged on base/installer change |
| Quality of life | In scope and not cut — suspend/display/network handling, audio, sensible defaults, docs/man-pages/completions kept |
| Target | VM-first (VMware / KVM / VirtualBox); ISO / bare-metal left open for later (don't bake VM-only assumptions). Wireless/RF & mobile out until an ISO path is taken |
| Firmware | **UEFI by default** (GPT + 512M ESP + grub-efi on the removable path; VM metadata marked EFI). `build.sh --firmware bios` keeps legacy MBR + grub-pc. Secure Boot off for now |
| Reproducibility | Per-engagement bill of materials (`hemo-bom`), not a frozen distro; only fragile build-from-source tools are pinned |
| Scope | Full-spectrum / purple: offensive (internal/AD, web/API, cloud, recon, password, post-ex/C2) + defensive (host DFIR, network monitoring) + vuln assessment. Wireless & mobile dropped |
| Tool list | A catalog (apt.yml/extra.yml) grouped into personas (roles.yml); you prune line by line |
| Licensed tools | Never baked in. Installed at first boot from your own storage |
| Non-security apps | Browser, editor/IDE, notes/reporting, shell/terminal tooling (baked) |

## Prior art (what we're building on)

- **Kali's official `kali-vm` builder** ([gitlab](https://gitlab.com/kalilinux/build-scripts/kali-vm)). It's debos-based and already exports `vmware`, `qemu`, `virtualbox`, `ova`, `ovf`, `hyperv`, `vagrant` and `raw`. It supports `-D i3`, `-T none` (no tools), `-P` (extra packages), `-b kali-last-snapshot`, `overlays/` and `scripts/` hooks, and `-r` to reuse a built rootfs for several exports. **This will be our base engine.** We pin it as a submodule rather than reinventing it.
- **pluggero/kali-linux-template** ([github](https://github.com/pluggero/kali-linux-template)): Packer + Ansible, a layered base qcow2 with per-hypervisor stages, and SHA256 artifacts. It's a good reference for the release and checksum layout.
- **TheOneChasingSomething/MyVMHandler** ([github](https://github.com/TheOneChasingSomething/MyVMHandler)): Packer + Ansible golden image with Terraform for disposable VMs. It's a good reference for the "boot up / tear down" side.
- **cisagov/kali-packer** ([github](https://github.com/cisagov/kali-packer)): a well-maintained Packer recipe, AMI only.
- **Exegol** ([exegol.com](https://exegol.com/)): a curated pentest toolset in Docker containers rather than a VM, with Full/AD/Web/Light images. It's worth knowing about because its curated tool lists are a good cross-check for our manifest, and it can sit beside the VM rather than compete with it.
- Others in the space: Parrot Security, BlackArch, Athena OS, and Commando VM on the Windows side. These are full distros or overlays, not a curated-build pipeline like this one.

**Why kali-vm rather than Packer:** Packer drives a full ISO install through boot commands, which is slow and fragile. kali-vm builds the rootfs directly, is maintained by the Kali team, and already handles every format we need. We use Ansible only for things apt can't do.

## Architecture

```
kali-flavor/
├── vendor/kali-vm/          # git submodule, pinned to a specific commit
├── build.sh                 # wrapper: one rootfs build, then export per format  ✓
├── scripts/hemo-customize.sh # in-rootfs thin-core customization hook (nspawn)   ✓
├── provision.sh             # hand-build path: turn a stock Kali VM into Hemo (Windows-friendly)
├── declutter.sh             # trim Kali-default bloat + seal the template for cloning
├── manifest/
│   ├── apt.yml              # Kali/Debian packages. BAKED: base/desktop_i3/plumbing/branding.
│   │                        #   Everything else is a CATALOG the role installer draws from.
│   ├── extra.yml            # pipx / go / git / binary / build / deb tools (non-repo)
│   ├── roles.yml            # personas: which catalog tools each role installs + its theme profile
│   ├── remove.yml           # packages explicitly purged from the base
│   └── licensed.yml         # first-boot-only tools: source URL + checksum, no secrets
├── overlays/
│   ├── etc/skel/.config/    # i3, polybar, kitty, rofi, zsh, flameshot (shipped to the operator)
│   ├── etc/firefox-esr/...  # managed Firefox policy (bookmarks + extensions + hardening)
│   └── usr/local/bin/       # hemo-pkg (resolver/installer), hemo-roles (picker),
│                            #   hemo-role-apply (theming), hemo-theme, hemo-identity,
│                            #   hemo-bom (engagement BoM), shot (report screenshots)
├── firstboot/               # hemo-firstboot.sh + .service: per-clone identity reset + role picker
├── branding/                # GRUB + Plymouth + LightDM theme, SVG art
│                            #   (ansible/ not needed: build.sh customizes via systemd-nspawn)
├── tests/                   # smoke tests run against every built image  (TODO)
└── releases/CHANGELOG.md    # what changed in each base-image tag  (TODO)
```

**Build flow (pipeline — implemented in `build.sh`; needs a Linux/KVM host to run)**

1. `build.sh` reads the BAKED sections (`base desktop_i3 plumbing runtime hardening branding`) straight out of `apt.yml` and calls kali-vm with `-b kali-last-snapshot -D i3 -T none -P <those packages>` to build one thin-core rootfs (59 packages at time of writing).
2. `scripts/hemo-customize.sh` runs inside that rootfs via `systemd-nspawn`: applies overlays, the Firefox policy, sysctl hardening, branding, installs the `hemo-*` helpers and the manifests to `/usr/share/hemo`, creates the `hemo` operator (replacing kali-vm's `kali`), enables AppArmor + docker (idle), purges `remove.yml`, and enables `hemo-firstboot.service` (clearing machine-id/SSH keys so the image boots as a fresh clone). **It installs no offensive/defensive tools** — those install per role on first boot.
3. The same customized rootfs is exported once per format with kali-vm `-r` (reuse): `qemu`, `vmware`, `virtualbox`, plus `ova`. **UEFI by default:** kali-vm only builds UEFI for its hyperv variant, so `vendor/patches/kali-vm-uefi-env.patch` (one line, auto-applied) lets `build.sh` force `UEFI=true`; kali-vm's `image.yaml` then lays out GPT + ESP and installs grub-efi. Its `.vmx`/`.vbox`/`.ova` templates are BIOS-only, so `build.sh` adds `firmware = "efi"` / `<Firmware type="EFI"/>` / `vmw:Config firmware=efi` (regenerating the OVA manifest). qcow2 has no metadata — boot it with OVMF.
4. Post-build: `SHA256SUMS` + a baseline package list (`<name>-base-packages.txt`), artifacts named `hemo-<base-version>-<uefi|bios>-<format>.<ext>`.
5. Tests run (see Phase 5), then the base image is git-tagged and the artifacts are stored.

   Run: `sudo ./build.sh` (all formats, UEFI) · `--firmware bios` · `--rootfs-only` / `--reuse-rootfs` to split build from export · `--formats "qemu ova"` · `--version X.Y.Z`. kali-vm is pinned under `vendor/kali-vm` (entrypoint `build.sh`; rootfs via `-v rootfs`, exports via `-v <variant> -f <format> -r <rootfs>` from its `-o` dir). The patch was rolled against kali-vm `95dc117` (2026-09-21); `build.sh` stops if it no longer applies.

**Lifecycle (boot up / tear down)**

**Default — persistent install.** You install Hemo once and keep it: first boot runs the **role picker** (tick persona(s), tools install, primary role themes the desktop), forces a password change, and regenerates machine identity. From then on it's your box — add roles later with `hemo-roles`, re-skin with `hemo-theme`, update on your schedule. Engagement data lives in `~/engagements/<client>` (and/or a separate attached disk), and `hemo-bom` records what was installed per job.

**Opt-in — clone-per-engagement.** When you want a fresh disposable VM per op, seal a copy as a template (`declutter.sh --seal` strips machine identity + resets the first-boot flag) and snapshot. Each clone then boots into its own first-boot picker and fresh identity; delete the clone at teardown, the template is untouched. Helper scripts per hypervisor (`vmrun`, `virsh`, `VBoxManage`) wrap new/destroy.

## Role-based install model

The baked image is a complete base (desktop + environment + QoL). The offensive and defensive tooling is a **catalog** (sections of `apt.yml`/`extra.yml`) grouped into **personas** in `manifest/roles.yml`. On first boot the operator picks roles; the picked tools install, and the primary role sets the look. Roles exist for **relevance** — a box carries its discipline's full kit (heavy tools included) and not another discipline's — not to keep the image small.

- **Picker** — `hemo-roles` (whiptail). Multi-select checklist built from `roles.yml`; after selection you choose which selected role is **primary**. Runs from `hemo-firstboot` on tty1 before the login screen (so installs run as root, no sudo-password dance), and later as `sudo hemo-roles` to add roles.
- **Resolver / installer** — `hemo-pkg` (Python). Maps a tool name to its install method by reading the manifests from `/usr/share/hemo/manifest`: `apt` (any apt.yml section) · `pipx` · `go` · `git`→/opt · `binary` (release asset) · `build` (compile) · `deb`. `hemo-pkg install-role <role>…` expands roles to a deduped tool list, installs, and records the installed roles to `/var/lib/hemo/roles`.
- **Theming** — `hemo-role-apply <role>` writes the primary role's `profile:` (accent, wallpaper, Firefox bookmark folders, i3 workspace names) into the live config via managed `# >>> hemo:<region>` blocks; `hemo-theme <role>` re-skins without installing.
- **Source seam (offline later):** resolution is separate from fetching. Today every method fetches from the internet; an offline backend can later serve from a baked pinned cache with no change to `roles.yml`, the personas, or the menu.
- **Pins:** in the rolling model an unresolved `PIN-ME` means "use latest/HEAD". Real tags/commits are honoured where set — worth doing for the fragile build-from-source tools (AdaptixC2 / sliver / evilginx).

**Roles** (set as of 2026-10-02, still awaiting a prune): `red_team`, `pentest`, `web`, `reverse`, `blue_host`, `blue_net`, `vuln_assessor`, `full`.

## Phases

### Phase 0: Build host (½ day)
- Set up a Linux box or VM (Debian or Kali) with KVM. Confirm `/dev/kvm` exists. If it's a VM on this Windows PC, enable nested virtualization in VMware Workstation. Windows 11 Home has no Hyper-V, so VMware Workstation or VirtualBox is the host hypervisor.
- Install the kali-vm dependencies (or use its `build-in-container.sh` with podman).
- **Exit check:** an unmodified kali-vm build of `-D i3 -T none -f qemu` boots.

### Phase 1: Baseline audit (1 day)
- Build the bare image (`-T none -D i3`) and capture `dpkg -l`. This is everything we get before choosing anything.
- Go through the baseline package by package and mark each one keep or remove. The bulk of the "complete overhaul" happens here, because even `-T none` brings default desktop apps along.
- **Exit check:** `remove.yml` is approved, and the baseline still boots and logs in to i3.

### Phase 2: Tool catalog + roles (draft, then prune)
- The catalog (`apt.yml`/`extra.yml`) is drafted full-spectrum: recon, internal/AD, web/API, cloud, password/crypto, post-ex/C2, host DFIR, network monitoring, vuln assessment, reversing, reporting. Each entry gets a one-line reason it's there.
- `manifest/roles.yml` groups the catalog into personas and gives each a theme profile. Every `tools:` name must resolve in the catalog (checked by `hemo-pkg resolve`).
- Cross-check against `kali-linux-headless`, Exegol and Athena role lists to catch gaps.
- You prune line by line — both the catalog and the role membership. Anything not approved isn't installed.
- **Exit check:** the catalog + `roles.yml` are signed off; every tool resolves to a source (apt, or an extra.yml entry); fragile build-from-source tools are pinned.

### Phase 3: Non-security apps and environment
- Browser, editor/IDE, notes/reporting, and shell/terminal tooling (see open questions for the exact picks).
- i3 config, status bar, terminal, tmux, zsh, and your dotfiles (from your repo, if you have one).
- Browser policies such as proxy profiles and disabled telemetry, applied as managed policy files in `overlays/`.

### Phase 4: First-boot, role picker and licensed tools  — *implemented (hand-build path)*
- `hemo-firstboot.service` runs `hemo-firstboot` on tty1 before the login screen: identity regeneration (SSH keys, machine-id), then the **role picker** (`hemo-roles`), which installs the selected roles' tools online and applies the primary theme. It self-disables via `/var/lib/hemo/firstboot.done`.
- No forced password change (owner decision 2026-10-13): the default `hemo`/`hemo` works like Kali's `kali`/`kali`.
- Licensed tools (e.g. Burp Pro) are pulled from your storage by URL and checksum — **still stubbed** until a storage source is chosen. Credentials are entered at first boot, never stored in the repo or image.
- **Remaining:** fold the picker into the build pipeline's enable step; resolve the licensed-tool storage source; per-role wallpaper art.

### Phase 5: Testing
- **Automated, on the build host:** boot the qcow2 headless in QEMU, SSH in, and for every manifest entry check that the tool is present and its `--version` runs. Also check that the guest agent is running and nothing on `remove.yml` is installed.
- **VirtualBox:** headless import and boot test with `VBoxManage` on the build host.
- **VMware:** validate the OVA with `ovftool`, then do a manual boot check in Workstation on this PC (VMware testing is hard to automate headlessly on Linux).

### Phase 6: Release + update process (durable install, operator-controlled updates)
- **No calendar cadence.** Tools install current at role-selection time, so the image and the tools decouple. Re-tag and rebuild the **base image** only when the base/overlays/installer change: bump the base version, rebuild, test, write the CHANGELOG, tag, archive.
- **Stability on a long-lived box matters more than freshness.** A persistent install must not silently drift and break mid-op. The operator controls updates — a `hemo-update` style flow (TODO) freezes tooling during an engagement and applies updates deliberately between them, with the pre/post `hemo-bom` as the record.
- Per-engagement reproducibility is the **bill of materials** (`hemo-bom`), captured into the engagement folder at start (baseline) and close (final) — a record of what was actually used per client, without freezing the distro.
- Pin only the fragile build-from-source tools (AdaptixC2 / sliver / evilginx) in `extra.yml` so a bad upstream "latest" can't break a clone. Full pinning returns via the offline cache when a specific job needs it.
- Optional later: a CI job on a self-hosted runner with KVM to automate the base rebuild.

## Reproducibility (rolling model)
- The distro is deliberately **not** frozen. Tools track apt + upstream at install time; the record of truth for any engagement is its **bill of materials** (`hemo-bom`: apt/dpkg + pipx + pip + go-install binaries + /opt git HEADs + installed roles), stored with the evidence.
- When a job genuinely needs byte-exact, repeatable tooling, use the planned **offline cache** backend (a baked, pinned package set behind the same resolver) — the roles, personas and menu don't change, only where `hemo-pkg` fetches from.
- Fragile build-from-source tools stay pinned by tag/commit in `extra.yml` regardless, since "latest" there is the most likely to break a clone.

## Resolved decisions (from the configurator, 2026-10-01)
1. **Name:** Hemo OS. Hostname `hemo`, user `hemo` (so the prompt is `hemo@hemo`). The horned toad is the mascot. (Name history: Toad → Horntoad OS → Hemo OS, settled 2026-10-02.)
2. **Default user:** `hemo`, sudo, default password `hemo` (not forced to change; owner decision 2026-10-13).
3. **Architecture:** amd64 only.
4. **VM sizing:** 80 GB disk (thin), 8 GB RAM (floor 4), 4 vCPU.
5. **Storage for images/licensed installers:** not decided yet — first-boot licensed fetch stays stubbed until a source is given.
6. **Wireless/RF hardware:** not important now — wireless tools install, but no driver/firmware/USB work is scoped yet.
7. **Password cracking:** CPU-only by default; `hemo-gpu` auto-detects a passed-through/real GPU on first boot and offers to enable the hashcat GPU backend (KVM+VFIO or bare metal only — VMware/VirtualBox stay CPU-only). This intentionally reopens the earlier "GPU drivers out of scope" line, but only conditionally — no GPU present means no drivers installed. Large jobs still offload to a real rig.
8. **App picks:** locked — see the configurator and `manifest/`.
9. **Dotfiles:** none yet — i3/zsh/tmux/kitty configs ship from `overlays/` in this repo.
10. **Users:** author + anyone who wants it; single-operator setup, no per-team config.
11. **Releases kept:** all git tags + recipes forever. (Superseded the "last 4 quarterly image artifacts" line — the base image is tagged on base/installer change, not quarterly; see the rolling release model above.)
12. **Install architecture (2026-10-02):** thin baked core + per-role first-boot install (see "Role-based install model"). Replaces the earlier "everything baked / immutable golden image" and quarterly-pinned-release decisions.

Config of record: the configurator artifact's saved picks, mirrored into `manifest/`.
