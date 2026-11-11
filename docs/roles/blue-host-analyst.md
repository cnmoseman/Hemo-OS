# Blue Team Host Analyst

> host and endpoint DFIR: forensics, triage, malware, and audit

## Who it's for

For defenders doing host and endpoint DFIR.

## What this role does

Forensics, triage, malware scanning, memory and disk analysis, and system auditing. Log analytics runs as a local Docker stack via hemo-elk rather than as a role tool.

## Tools

29 tools install when you select this role.

| Tool | What it does | Reference |
|------|--------------|-----------|
| `loki` | IOC + YARA scanner (NOT the apt 'loki' genetics pkg) | [github.com/Neo23x0/Loki](https://github.com/Neo23x0/Loki) |
| `capa` | FLARE capability detection in executables (blue_host) | [pypi.org/project/capa](https://pypi.org/project/capa/) |
| `hayabusa` | Security/hayabusa Windows EVTX / Sigma hunting (blue_host) | [github.com/Yamato-Security/hayabusa](https://github.com/Yamato-Security/hayabusa) |
| `velociraptor` | Endpoint DFIR (blue_host) | [github.com/Velocidex/velociraptor](https://github.com/Velocidex/velociraptor) |
| `sleuthkit` | Tools for forensics analysis on volume and filesystem data | [sleuthkit.org/sleuthkit](https://www.sleuthkit.org/sleuthkit) |
| `autopsy` | Graphical interface to SleuthKit | [sleuthkit.org/autopsy](https://www.sleuthkit.org/autopsy/) |
| `yara` | Pattern matching swiss knife for malware researchers | [virustotal.github.io/yara](https://virustotal.github.io/yara/) |
| `chkrootkit` | Rootkit detector | [chkrootkit.org](https://www.chkrootkit.org/) |
| `rkhunter` | Rootkit, backdoor, sniffer and exploit scanner | [rkhunter.sourceforge.net](https://rkhunter.sourceforge.net) |
| `clamav` | Anti-virus utility for Unix - command-line interface | [clamav.net](https://www.clamav.net/) |
| `lynis` | Security auditing tool for Unix based systems | [cisofy.com/lynis](https://cisofy.com/lynis/) |
| `bulk-extractor` | Extracts information without parsing filesystem | [github.com/simsong/bulk_extractor](https://github.com/simsong/bulk_extractor) |
| `foremost` | Forensic program to recover lost files | [sourceforge.net/projects/foremost](https://sourceforge.net/projects/foremost/) |
| `regripper` | Perform forensic analysis of registry hives | [github.com/keydet89/RegRipper3.0](https://github.com/keydet89/RegRipper3.0) |
| `volatility3` | Memory forensics (blue_host role) | [pypi.org/project/volatility3](https://pypi.org/project/volatility3/) |
| `plaso` | Super timeline all the things -- metapackage | [github.com/log2timeline/plaso](https://github.com/log2timeline/plaso) |
| `chainsaw` | EVTX / Sigma hunting (blue_host) | [github.com/WithSecureLabs/chainsaw](https://github.com/WithSecureLabs/chainsaw) |
| `ewf-tools` | Collection of tools for reading and writing EWF files | [github.com/libyal/libewf-legacy](https://github.com/libyal/libewf-legacy) |
| `dc3dd` | Patched version of GNU dd with forensic features | [sourceforge.net/projects/dc3dd](https://sourceforge.net/projects/dc3dd/) |
| `libimage-exiftool-perl` | Library and program to read and write meta information in multimedia… | [exiftool.org](https://exiftool.org/) |
| `binwalk` | Tool library for analyzing binary blobs and executable code | [github.com/ReFirmLabs/binwalk](https://github.com/ReFirmLabs/binwalk) |
| `oletools` | Analyze MS OLE2 files and MS Office documents | [github.com/decalage2/oletools](https://github.com/decalage2/oletools) |
| `pdfid` | Scans PDF files for certain PDF keywords | [blog.didierstevens.com/programs/pdf-tools](https://blog.didierstevens.com/programs/pdf-tools/) |
| `pdf-parser` | Parses PDF files to identify fundamental elements | [blog.didierstevens.com/programs/pdf-tools](https://blog.didierstevens.com/programs/pdf-tools/) |
| `osquery` | Endpoint telemetry / live IR queries (blue_host) | [osquery.io](https://www.osquery.io/) |
| `scalpel` | Fast filesystem-independent file recovery | [github.com/nolaforensix/scalpel-1.60](https://github.com/nolaforensix/scalpel-1.60) |
| `magicrescue` | Recover files by looking for magic bytes | [github.com/jbj/magicrescue](https://github.com/jbj/magicrescue) |
| `guymager` | Forensic imaging tool based on Qt | [guymager.sourceforge.net](https://guymager.sourceforge.net/) |
| `hashdeep` | Recursively compute hashsums or piecewise hashings | [md5deep.sourceforge.net](https://md5deep.sourceforge.net) |

## Installing

Pick this role in **Hemo Welcome** on first boot, or add it later:

```sh
sudo hemo-roles
```

Tools install online at selection time. See the [main README](../../README.md#roles) for the role model.
