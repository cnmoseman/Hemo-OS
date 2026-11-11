# Default apps

> Everything baked into every Hemo install, whatever role you pick. Role tools are separate; see the [role pages](roles/).

These are installed by `provision.sh` (and the image build) before any role. Each links to its project page.

## Core & shell

| Package | What it does | Reference |
|---------|--------------|-----------|
| `build-essential` | Informational list of build-essential packages | [pkg.kali.org/pkg/build-essential](https://pkg.kali.org/pkg/build-essential) |
| `python3-dev` | Header files and a static library for Python (default) | [python.org](https://www.python.org/) |
| `libxml2-dev` | GNOME XML library - development files | [xmlsoft.org](http://xmlsoft.org) |
| `libxslt1-dev` | XSLT 1.0 processing library - development kit | [gitlab.gnome.org/GNOME/libxslt/-/wikis/home](https://gitlab.gnome.org/GNOME/libxslt/-/wikis/home) |
| `libssl-dev` | Secure Sockets Layer toolkit - development files | [openssl-library.org](https://openssl-library.org) |
| `libffi-dev` | Foreign Function Interface library (development files) | [sourceware.org/libffi](https://sourceware.org/libffi/) |
| `pkg-config` | Manage compile and link flags for libraries (transitional package) | [pkgconf.org](http://pkgconf.org/) |
| `cargo` | Rust package manager | [rust-lang.org](http://www.rust-lang.org/) |
| `zsh` | Shell with lots of features | [zsh.org](https://www.zsh.org/) |
| `zsh-autosuggestions` | Fish-like fast/unobtrusive autosuggestions for zsh | [github.com/zsh-users/zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) |
| `zsh-syntax-highlighting` | Fish shell like syntax highlighting for zsh | [github.com/zsh-users/zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting/) |
| `powershell` | PowerShell (`pwsh`); `$mod+Shift+Return` opens it with the same Starship prompt as zsh | [microsoft.com/powershell](https://microsoft.com/powershell) |
| `goshs` | Quick file-transfer web server (`hemo-serve`); HTTP/HTTPS/WebDAV/SMB with upload | [github.com/patrickhener/goshs](https://github.com/patrickhener/goshs) |
| `minisign` | Verify Hemo release downloads (`hemo-verify`) against the signed checksums | [jedisct1.github.io/minisign](https://jedisct1.github.io/minisign/) |
| `nano` | Small, friendly text editor inspired by Pico | [nano-editor.org](https://www.nano-editor.org/) |
| `tmux` | Terminal multiplexer, themed; `prefix + H` logs the pane into the active engagement (`hemo-tmux-log`) | [github.com/tmux/tmux/wiki](https://github.com/tmux/tmux/wiki) |
| `fzf` | General-purpose command-line fuzzy finder | [github.com/junegunn/fzf](https://github.com/junegunn/fzf) |
| `ripgrep` | Recursively searches directories for a regex pattern | [github.com/BurntSushi/ripgrep](https://github.com/BurntSushi/ripgrep) |
| `bat` | Cat(1) clone with syntax highlighting and git integration | [github.com/sharkdp/bat](https://github.com/sharkdp/bat) |
| `fd-find` | Simple, fast and user-friendly alternative to find | [github.com/sharkdp/fd](https://github.com/sharkdp/fd) |
| `git` | Fast, scalable, distributed revision control system | [git-scm.com](https://git-scm.com/) |
| `pipx` | Execute binaries from Python packages in isolated environments | [github.com/pypa/pipx](https://github.com/pypa/pipx) |
| `golang` | Go programming language compiler - metapackage | [go.dev](https://go.dev) |
| `curl` | Command line tool for transferring data with URL syntax | [curl.se](https://curl.se/) |
| `wget` | Retrieves files from the web | [gnu.org/software/wget](https://www.gnu.org/software/wget/) |
| `jq` | Lightweight and flexible command-line JSON processor | [jqlang.github.io/jq](https://jqlang.github.io/jq) |
| `pandoc` | General markup converter | [pandoc.org](https://pandoc.org/) |
| `keepassxc` | Cross Platform Password Manager (transitional package) | [keepassxc.org](https://keepassxc.org/) |
| `neovim` | Heavily refactored vim fork | [neovim.io](https://neovim.io/) |
| `open-vm-tools` | Open VMware Tools for virtual machines hosted on VMware (CLI) | [github.com/vmware/open-vm-tools](https://github.com/vmware/open-vm-tools) |
| `open-vm-tools-desktop` | Open VMware Tools for virtual machines hosted on VMware (GUI) | [github.com/vmware/open-vm-tools](https://github.com/vmware/open-vm-tools) |
| `qemu-guest-agent` | Guest-side qemu-system agent | [qemu.org](http://www.qemu.org/) |
| `spice-vdagent` | Spice agent for Linux | [spice-space.org](https://www.spice-space.org/) |
| `virtualbox-guest-x11` | X86 virtualization solution - X11 guest utilities | [virtualbox.org](https://www.virtualbox.org) |

## Desktop (i3)

| Package | What it does | Reference |
|---------|--------------|-----------|
| `rofi` | Window switcher, run dialog and dmenu replacement | [github.com/DaveDavenport/rofi](https://github.com/DaveDavenport/rofi/) |
| `polybar` | Fast and easy-to-use tool for creating status bars | [polybar.github.io](https://polybar.github.io/) |
| `dunst` | Dmenu-ish notification-daemon | [dunst-project.org](https://dunst-project.org/) |
| `qterminal` | Default interactive terminal (`$mod+Return`); kitty is selectable in Welcome setup | [github.com/lxqt/qterminal](https://github.com/lxqt/qterminal) |
| `kitty` | Fast, GPU-based terminal; kept as the fixed-size report/screenshot terminal (`$mod+Mod1+Return`) and a selectable default | [sw.kovidgoyal.net/kitty](https://sw.kovidgoyal.net/kitty/) |
| `flameshot` | Powerful yet simple-to-use screenshot software | [flameshot.org](https://flameshot.org) |
| `firefox-esr` | Mozilla Firefox web browser - Extended Support Release (ESR) | [pkg.kali.org/pkg/firefox-esr](https://pkg.kali.org/pkg/firefox-esr) |
| `autorandr` | Automatically select a display configuration for connected devices | [github.com/phillipberndt/autorandr](https://github.com/phillipberndt/autorandr) |
| `feh` | Imlib2 based image viewer | [feh.finalrewind.org](https://feh.finalrewind.org/) |
| `x11-xserver-utils` | X server utilities | [pkg.kali.org/pkg/x11-xserver-utils](https://pkg.kali.org/pkg/x11-xserver-utils) |
| `picom` | Lightweight compositor for X11 | [github.com/yshui/picom](https://github.com/yshui/picom) |
| `i3lock-color` | Improved screen locker | [github.com/Raymo111/i3lock-color](https://github.com/Raymo111/i3lock-color) |
| `xss-lock` | Invoke external screen lock in response to XScreenSaver events | [github.com/wavexx/xss-lock](https://github.com/wavexx/xss-lock) |
| `autotiling` | Automatically switch the window split orientation in sway and i3; paired with `hemo-open` which picks the orientation from the mouse pointer position instead | [github.com/nwg-piotr/autotiling](https://github.com/nwg-piotr/autotiling/) |
| `kali-themes-common` | Kali Themes (data files) | [pkg.kali.org/pkg/kali-themes-common](https://pkg.kali.org/pkg/kali-themes-common) |
| `fonts-font-awesome` | FontAwesome free icon webfonts (current version) | [fontawesome.io](http://fontawesome.io/) |
| `fonts-jetbrains-mono` | Free and open-source typeface for developers | [jetbrains.com/lp/mono](https://www.jetbrains.com/lp/mono/) |
| `maim` | Takes screenshots of your desktop | [github.com/naelstrof/maim](https://github.com/naelstrof/maim) |
| `xdotool` | Simulate (generate) X11 keyboard/mouse input events | [github.com/jordansissel/xdotool](https://github.com/jordansissel/xdotool/) |
| `xclip` | Command line interface to X selections | [github.com/astrand/xclip](https://github.com/astrand/xclip) |
| `imagemagick` | Image manipulation programs -- binaries | [imagemagick.org](https://www.imagemagick.org/) |

## Applications & daily-driver

| Package | What it does | Reference |
|---------|--------------|-----------|
| `btop` | Modern and colorful command line resource monitor that shows usage an… | [github.com/aristocratos/btop](https://github.com/aristocratos/btop) |
| `fastfetch` | Neofetch-like tool for fetching system information | [github.com/fastfetch-cli/fastfetch](https://github.com/fastfetch-cli/fastfetch) |
| `gimp` | GNU Image Manipulation Program | [gimp.org](https://www.gimp.org/) |
| `thunar` | File Manager for Xfce | [docs.xfce.org/xfce/thunar/start](https://docs.xfce.org/xfce/thunar/start) |
| `thunar-archive-plugin` | Archive plugin for Thunar file manager | [docs.xfce.org/xfce/thunar/archive](https://docs.xfce.org/xfce/thunar/archive) |
| `thunar-volman` | Thunar extension for volumes management | [docs.xfce.org/xfce/thunar/thunar-volman](https://docs.xfce.org/xfce/thunar/thunar-volman) |
| `lf` | Terminal file manager written in Go | [github.com/gokcehan/lf](https://github.com/gokcehan/lf) |
| `mc` | Midnight Commander - a powerful file manager | [midnight-commander.org](https://www.midnight-commander.org) |
| `zathura` | Document viewer with a minimalistic interface | [pwmt.org/projects/zathura](https://pwmt.org/projects/zathura) |
| `zathura-pdf-poppler` | PDF support for zathura | [pwmt.org/projects/zathura](https://pwmt.org/projects/zathura) |
| `pipewire` | Audio and video processing engine multimedia server | [pipewire.org](https://pipewire.org/) |
| `pipewire-pulse` | PipeWire PulseAudio daemon | [pipewire.org](https://pipewire.org/) |
| `wireplumber` | Modular session / policy manager for PipeWire | [gitlab.freedesktop.org/pipewire/wireplumber](https://gitlab.freedesktop.org/pipewire/wireplumber) |
| `pavucontrol` | PulseAudio Volume Control | [freedesktop.org/software/pulseaudio/pavucontrol](https://freedesktop.org/software/pulseaudio/pavucontrol/) |
| `pamixer` | Pulseaudio command line mixer | [github.com/cdemoulins/pamixer](https://github.com/cdemoulins/pamixer) |
| `network-manager-gnome` | Transitional package for network-manager-applet and nm-connection-editor | [networkmanager.dev](https://networkmanager.dev) |
| `p7zip-full` | 7-Zip archiver with high compression ratio | [packages.debian.org/p7zip-full](https://packages.debian.org/p7zip-full) |
| `unzip` | De-archiver for .zip files | [infozip.sourceforge.net/UnZip.html](https://infozip.sourceforge.net/UnZip.html) |
| `zip` | Archiver for .zip files | [infozip.sourceforge.net/Zip.html](https://infozip.sourceforge.net/Zip.html) |
| `xarchiver` | GTK+ frontend for most used compression formats | [github.com/ib/xarchiver](https://github.com/ib/xarchiver) |
| `gvfs` | Userspace virtual filesystem - GIO module | [gitlab.gnome.org/GNOME/gvfs](https://gitlab.gnome.org/GNOME/gvfs) |
| `gvfs-backends` | Userspace virtual filesystem - backends | [gitlab.gnome.org/GNOME/gvfs](https://gitlab.gnome.org/GNOME/gvfs) |
| `udisks2` | D-Bus service to access and manipulate storage devices | [freedesktop.org/wiki/Software/udisks](https://www.freedesktop.org/wiki/Software/udisks) |
| `ntfs-3g` | Read/write NTFS driver for FUSE | [github.com/tuxera/ntfs-3g/wiki](https://github.com/tuxera/ntfs-3g/wiki) |
| `exfatprogs` | ExFAT file system utilities | [github.com/exfatprogs/exfatprogs](https://github.com/exfatprogs/exfatprogs) |
| `cifs-utils` | Common Internet File System utilities | [wiki.samba.org/index.php/LinuxCIFS_utils](https://wiki.samba.org/index.php/LinuxCIFS_utils) |
| `lxappearance` | LXDE GTK+ theme switcher | [github.com/lxde/lxappearance](https://github.com/lxde/lxappearance) |
| `fonts-noto` | Metapackage to pull in all Noto fonts | [google.com/get/noto](https://www.google.com/get/noto/) |
| `fonts-noto-color-emoji` | Color emoji font from Google | [fonts.google.com/noto/specimen/Noto+Color+Emoji](https://fonts.google.com/noto/specimen/Noto+Color+Emoji) |
| `fonts-nerd-symbols` | Nerd Fonts symbols fallback for fontconfig | [github.com/ryanoasis/nerd-fonts](https://github.com/ryanoasis/nerd-fonts) |
| `copyq` | Advanced clipboard manager with editing and scripting features | [hluk.github.io/CopyQ](https://hluk.github.io/CopyQ/) |
| `udiskie` | Automounter for removable media for Python | [github.com/coldfix/udiskie](https://github.com/coldfix/udiskie) |
| `nsxiv` | Neo simple X image viewer | [codeberg.org/nsxiv/nsxiv](https://codeberg.org/nsxiv/nsxiv) |
| `gammastep` | Adjust display hue to outside lighting conditions | [gitlab.com/chinstrap/gammastep](https://gitlab.com/chinstrap/gammastep) |
| `python3-gi` | Python 3 bindings for gobject-introspection libraries | [pygobject.readthedocs.io](https://pygobject.readthedocs.io/) |
| `gir1.2-gtk-3.0` | GTK graphical user interface library -- gir bindings | [gtk.org](https://www.gtk.org/) |
| `gir1.2-gdkpixbuf-2.0` | GDK Pixbuf library - GObject-Introspection | [gtk.org](https://www.gtk.org/) |
| `python3-pil` | Python Imaging Library (Python3) | [python-pillow.github.io](http://python-pillow.github.io/) |
| `yad` | Tool for creating graphical dialogs from shell scripts | [sourceforge.net/projects/yad-dialog](http://sourceforge.net/projects/yad-dialog/) |
| `lxpolkit` | LXDE PolicyKit authentication agent | [github.com/lxde/lxsession](https://github.com/lxde/lxsession) |
| `libreoffice-writer` | Office productivity suite -- word processor | [libreoffice.org](http://www.libreoffice.org) |
| `libreoffice-calc` | Office productivity suite -- spreadsheet | [libreoffice.org](http://www.libreoffice.org) |
| `libreoffice-impress` | Office productivity suite -- presentation | [libreoffice.org](http://www.libreoffice.org) |
| `libreoffice-gtk3` | Office productivity suite -- GTK+ 3 integration | [libreoffice.org](http://www.libreoffice.org) |
| `cherrytree` | Hierarchical note taking application — optional; add it from Hemo Welcome → Apps & tools | [giuspen.net/cherrytree](https://www.giuspen.net/cherrytree/) |
| `network-manager-openconnect-gnome` | Network management framework (OpenConnect plugin GNOME GUI) | [gnome.org/projects/NetworkManager](https://www.gnome.org/projects/NetworkManager/) |
| `network-manager-openvpn-gnome` | Network management framework (OpenVPN plugin GNOME GUI) | [networkmanager.dev](https://networkmanager.dev) |
| `network-manager-vpnc-gnome` | Network management framework (VPNC plugin GNOME GUI) | [networkmanager.dev](https://networkmanager.dev) |
| `network-manager-l2tp-gnome` | Network management framework (L2TP plugin GNOME GUI) | [github.com/nm-l2tp/NetworkManager-l2tp](https://github.com/nm-l2tp/NetworkManager-l2tp) |
| `network-manager-strongswan` | Network management framework (strongSwan plugin) | [wiki.strongswan.org/projects/strongswan/wiki/NetworkManager](https://wiki.strongswan.org/projects/strongswan/wiki/NetworkManager) |
| `texlive-xetex` | TeX Live: XeTeX and packages | [tug.org/texlive](http://www.tug.org/texlive/) |
| `texlive-latex-recommended` | TeX Live: LaTeX recommended packages | [tug.org/texlive](http://www.tug.org/texlive/) |
| `texlive-latex-extra` | TeX Live: LaTeX additional packages | [tug.org/texlive](http://www.tug.org/texlive/) |
| `texlive-fonts-recommended` | TeX Live: Recommended fonts | [tug.org/texlive](http://www.tug.org/texlive/) |
| `lmodern` | Scalable PostScript and OpenType fonts based on Computer Modern | [gust.org.pl/projects/e-foundry/latin-modern](http://www.gust.org.pl/projects/e-foundry/latin-modern/) |
| `weasyprint` | Document factory for creating PDF files from HTML | [weasyprint.org](https://weasyprint.org/) |

## Network plumbing

| Package | What it does | Reference |
|---------|--------------|-----------|
| `freerdp3-x11` | RDP client for Windows Terminal Services (X11 client tramsitional pac… | [freerdp.com](https://www.freerdp.com/) |
| `openvpn` | Virtual private network daemon | [openvpn.net/community](https://openvpn.net/community/) |
| `wireguard-tools` | Fast, modern, secure kernel VPN tunnel (userland utilities) | [wireguard.com](https://www.wireguard.com) |

## Container runtime

| Package | What it does | Reference |
|---------|--------------|-----------|
| `docker.io` | Linux container runtime | [mobyproject.org](https://mobyproject.org) |
| `docker-buildx` | Docker CLI plugin for extended build capabilities with BuildKit (prog… | [github.com/docker/buildx](https://github.com/docker/buildx) |

## Hardening

| Package | What it does | Reference |
|---------|--------------|-----------|
| `apparmor` | User-space parser utility for AppArmor | [apparmor.net](https://apparmor.net/) |
| `apparmor-utils` | Utilities for controlling AppArmor | [apparmor.net](https://apparmor.net/) |
| `bubblewrap` | Utility for unprivileged chroot and namespace manipulation | [github.com/containers/bubblewrap](https://github.com/containers/bubblewrap) |
| `ufw` | Program for managing a Netfilter firewall | [launchpad.net/ufw](https://launchpad.net/ufw) |
| `auditd` | User space tools for security auditing | [people.redhat.com/sgrubb/audit](https://people.redhat.com/sgrubb/audit/) |

## Boot & login branding

| Package | What it does | Reference |
|---------|--------------|-----------|
| `plymouth` | Boot animation, logger and I/O multiplexer | [freedesktop.org/wiki/Software/Plymouth](https://www.freedesktop.org/wiki/Software/Plymouth) |
| `plymouth-themes` | Boot animation, logger and I/O multiplexer - themes | [freedesktop.org/wiki/Software/Plymouth](https://www.freedesktop.org/wiki/Software/Plymouth) |
| `lightdm` | Simple display manager | [github.com/ubuntu/lightdm](https://github.com/ubuntu/lightdm) |
| `lightdm-gtk-greeter` | Simple display manager (GTK+ greeter) | [github.com/Xubuntu/lightdm-gtk-greeter](https://github.com/Xubuntu/lightdm-gtk-greeter) |
| `librsvg2-bin` | Command-line utility to convert SVG files | [gnome.pages.gitlab.gnome.org/librsvg](https://gnome.pages.gitlab.gnome.org/librsvg/) |
| `imagemagick` | Image manipulation programs -- binaries | [imagemagick.org](https://www.imagemagick.org/) |

## Also installed (not from the Kali repo)

| App | What it does | Reference |
|-----|--------------|-----------|
| `yazi` | Terminal file manager with image previews | [github.com/sxyazi/yazi](https://github.com/sxyazi/yazi) |
| `greenclip` | Clipboard manager for rofi | [github.com/erebe/greenclip](https://github.com/erebe/greenclip) |
| `starship` | Cross-shell prompt | [starship.rs](https://starship.rs) |
| `obsidian` | Markdown knowledge base (default notes app) | [obsidian.md](https://obsidian.md) |
| `vscodium` | VS Code without telemetry (opt-in at setup) | [vscodium.com](https://vscodium.com) |

See the [main README](../README.md) for the install flow and the role model.
