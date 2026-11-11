# Blue Team Network Analyst

> network security monitoring: IDS, traffic, and flow analysis

## Who it's for

For defenders doing network security monitoring.

## What this role does

Intrusion detection, traffic capture and replay, and flow analysis. Full-packet indexing (Arkime) and log analytics run as local Docker stacks, not role tools.

## Tools

15 tools install when you select this role.

| Tool | What it does | Reference |
|------|--------------|-----------|
| `tcpdump` | Command-line network traffic analyzer | [tcpdump.org](https://www.tcpdump.org/) |
| `termshark` | Terminal UI for tshark, inspired by Wireshark | [github.com/gcla/termshark](https://github.com/gcla/termshark) |
| `netsniff-ng` | Linux network packet sniffer toolkit | [netsniff-ng.org](http://netsniff-ng.org/) |
| `tcpreplay` | Tool to replay saved tcpdump files at arbitrary speeds | [tcpreplay.appneta.com](http://tcpreplay.appneta.com/) |
| `zeek` | Passive network traffic analyzer | [zeek.org](http://www.zeek.org/) |
| `suricata` | Next Generation Intrusion Detection and Prevention Tool | [suricata.io](https://suricata.io) |
| `snort` | Flexible Network Intrusion Detection System | [snort.org](https://www.snort.org/) |
| `tshark` | Network traffic analyzer - console version | [wireshark.org](https://www.wireshark.org/) |
| `ngrep` | Grep for network traffic | [github.com/jpr5/ngrep](https://github.com/jpr5/ngrep) |
| `tcpflow` | TCP flow recorder | [github.com/simsong/tcpflow](https://github.com/simsong/tcpflow) |
| `p0f` | Passive OS fingerprinting tool | [lcamtuf.coredump.cx/p0f3](https://lcamtuf.coredump.cx/p0f3/) |
| `argus-client` | Network flow (Argus) analysis clients | [openargus.org](https://openargus.org) |
| `nfdump` | Netflow capture daemon | [github.com/phaag/nfdump](https://github.com/phaag/nfdump/) |
| `wireshark` | Network traffic analyzer - graphical interface | [wireshark.org](https://www.wireshark.org/) |
| `networkminer` | PCAP > artifacts (blue_net) | [netresec.com](https://www.netresec.com) |

## Installing

Pick this role in **Hemo Welcome** on first boot, or add it later:

```sh
sudo hemo-roles
```

Tools install online at selection time. See the [main README](../../README.md#roles) for the role model.
