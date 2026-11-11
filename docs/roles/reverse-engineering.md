# Reverse Engineering

> binaries, Android/Java, and recovered-artifact analysis

## Who it's for

For reverse engineers and malware or loot analysts.

## What this role does

Disassemblers, debuggers, and unpacking tools for binaries, Android and Java, and recovered artifacts.

## Tools

26 tools install when you select this role.

| Tool | What it does | Reference |
|------|--------------|-----------|
| `ghidra` | Software Reverse Engineering Framework | [github.com/NationalSecurityAgency/ghidra](https://github.com/NationalSecurityAgency/ghidra) |
| `gdb-multiarch` | GNU Debugger (with support for multiple architectures) | [gnu.org/s/gdb](https://www.gnu.org/s/gdb/) |
| `apktool` | Tool for reverse engineering Android apk files | [ibotpeaches.github.io/Apktool](https://ibotpeaches.github.io/Apktool/) |
| `jadx` | Dex to Java decompiler | [github.com/skylot/jadx](https://github.com/skylot/jadx) |
| `dex2jar` | Tools to work with android .dex and java .class files | [github.com/pxb1988/dex2jar/tree/2.x](https://github.com/pxb1988/dex2jar/tree/2.x) |
| `jd-gui` | GUI Java .class decompiler | [jd.benow.ca](http://jd.benow.ca/) |
| `yara` | Pattern matching swiss knife for malware researchers | [virustotal.github.io/yara](https://virustotal.github.io/yara/) |
| `patchelf` | Modify properties of ELF executables | [nixos.org/patchelf.html](https://nixos.org/patchelf.html) |
| `hexedit` | Viewer and editor in hexadecimal or ASCII for files or devices | [github.com/pixel/hexedit](https://github.com/pixel/hexedit) |
| `edb-debugger` | Cross platform x86/x86-64 debugger | [github.com/eteran/edb-debugger](https://github.com/eteran/edb-debugger) |
| `frida` | Tools) | [pypi.org/project/frida](https://pypi.org/project/frida/) |
| `angr` | Symbolic execution / binary analysis | [pypi.org/project/angr](https://pypi.org/project/angr/) |
| `radare2` | Free and advanced command line hexadecimal editor | [radare.org](https://www.radare.org) |
| `binwalk` | Tool library for analyzing binary blobs and executable code | [github.com/ReFirmLabs/binwalk](https://github.com/ReFirmLabs/binwalk) |
| `libimage-exiftool-perl` | Library and program to read and write meta information in multimedia… | [exiftool.org](https://exiftool.org/) |
| `gdb` | GNU Debugger | [gnu.org/s/gdb](https://www.gnu.org/s/gdb/) |
| `pwndbg` | Gdb plugin; run its setup.sh after clone | [github.com/pwndbg/pwndbg](https://github.com/pwndbg/pwndbg) |
| `ltrace` | Tracks runtime library calls in dynamically linked programs | [ltrace.org](https://ltrace.org/) |
| `strace` | System call tracer | [strace.io](https://strace.io) |
| `rizin` | Reverse engineering framework and command-line toolset | [rizin.re](https://rizin.re/) |
| `rizin-cutter` | Reverse engineering platform powered by rizin | [cutter.re](https://cutter.re) |
| `upx-ucl` | Efficient live-compressor for executables | [upx.github.io](https://upx.github.io/) |
| `flare-floss` | String extraction from malware; binary `floss` | [pypi.org/project/flare-floss](https://pypi.org/project/flare-floss/) |
| `python3-pwntools` | Dev / CTF toolkit | [pypi.org/project/pwntools](https://pypi.org/project/pwntools/) |
| `ropper` | ROP gadget finder | [pypi.org/project/ropper](https://pypi.org/project/ropper/) |
| `oletools` | Analyze MS OLE2 files and MS Office documents | [github.com/decalage2/oletools](https://github.com/decalage2/oletools) |

## Installing

Pick this role in **Hemo Welcome** on first boot, or add it later:

```sh
sudo hemo-roles
```

Tools install online at selection time. See the [main README](../../README.md#roles) for the role model.
