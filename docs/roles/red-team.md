# Red Team

> C2, post-exploitation, lateral movement, evasion, and AD compromise

## Who it's for

For operators running adversary-emulation and red-team engagements.

## What this role does

Command-and-control, post-exploitation, lateral movement, evasion, and Active Directory compromise. The C2 framework is chosen at setup (AdaptixC2 by default); heavier services such as BloodHound Community Edition run as local Docker stacks.

## Tools

91 tools install when you select this role.

| Tool | What it does | Reference |
|------|--------------|-----------|
| `trevorspray` | O365/Azure password spraying | [pypi.org/project/trevorspray](https://pypi.org/project/trevorspray/) |
| `wireshark` | Network traffic analyzer - graphical interface | [wireshark.org](https://www.wireshark.org/) |
| `tcpdump` | Command-line network traffic analyzer | [tcpdump.org](https://www.tcpdump.org/) |
| `ncat` | NMAP netcat reimplementation | [nmap.org](https://nmap.org/) |
| `netcat-traditional` | TCP/IP swiss army knife | [stearns.org/nc](http://www.stearns.org/nc/) |
| `socat` | Multipurpose relay for bidirectional data transfer | [dest-unreach.org/socat](http://www.dest-unreach.org/socat/) |
| `smbclient` | Command-line SMB/CIFS clients for Unix | [samba.org](https://www.samba.org) |
| `ldap-utils` | OpenLDAP utilities | [openldap.org](https://www.openldap.org/) |
| `krb5-user` | Basic programs to authenticate using MIT Kerberos | [web.mit.edu/kerberos](https://web.mit.edu/kerberos/) |
| `theharvester` | Tool for gathering e-mail accounts and subdomain names from public so… | [github.com/laramies/theHarvester](https://github.com/laramies/theHarvester) |
| `spiderfoot` | OSINT collection and reconnaissance tool | [spiderfoot.net](https://www.spiderfoot.net) |
| `recon-ng` | Web Reconnaissance framework written in Python | [github.com/lanmaster53/recon-ng](https://github.com/lanmaster53/recon-ng) |
| `sherlock` | Find usernames across social networks | [github.com/sherlock-project/sherlock](https://github.com/sherlock-project/sherlock) |
| `maltego` | Open source intelligence and forensics application | [maltego.com](https://www.maltego.com) |
| `dnsrecon` | Powerful DNS enumeration script | [github.com/darkoperator/dnsrecon](https://github.com/darkoperator/dnsrecon) |
| `dnsenum` | Tool to enumerate domain DNS information | [github.com/SparrowOchon/dnsenum2](https://github.com/SparrowOchon/dnsenum2) |
| `metagoofil` | Tool designed for extracting metadata of public documents | [github.com/opsdisk/metagoofil](https://github.com/opsdisk/metagoofil) |
| `holehe` | > which sites it is registered on (OSINT) | [pypi.org/project/holehe](https://pypi.org/project/holehe/) |
| `maigret` | > accounts across sites (OSINT) | [pypi.org/project/maigret](https://pypi.org/project/maigret/) |
| `nmap` | The Network Mapper | [nmap.org](https://nmap.org/) |
| `evil-winrm` | Ultimate WinRM shell for hacking/pentesting | [github.com/Hackplayers/evil-winrm](https://github.com/Hackplayers/evil-winrm) |
| `enum4linux-ng` | Next generation version of enum4linux | [github.com/cddmp/enum4linux-ng](https://github.com/cddmp/enum4linux-ng) |
| `hashcat` | World's fastest and most advanced password recovery utility | [hashcat.net/hashcat](https://hashcat.net/hashcat/) |
| `john` | Active password cracking tool | [github.com/openwall/john](https://github.com/openwall/john) |
| `seclists` | Collection of multiple types of security lists | [github.com/danielmiessler/SecLists](https://github.com/danielmiessler/SecLists) |
| `smbmap` | Handy SMB enumeration tool | [github.com/ShawnDEvans/smbmap](https://github.com/ShawnDEvans/smbmap) |
| `powershell-empire` | PowerShell and Python post-exploitation agent | [github.com/BC-SECURITY/Empire](https://github.com/BC-SECURITY/Empire) |
| `starkiller` | Frontend for Powershell Empire | [github.com/BC-SECURITY/Starkiller](https://github.com/BC-SECURITY/Starkiller) |
| `mimikatz` | Uses admin rights on Windows to display passwords in plaintext | [blog.gentilkiwi.com/mimikatz](https://blog.gentilkiwi.com/mimikatz) |
| `metasploit-framework` | Framework for exploit development and vulnerability research | [metasploit.com](https://www.metasploit.com/) |
| `proxychains4` | Redirect connections through socks/http proxies (proxychains-ng) | [github.com/rofl0r/proxychains-ng](https://github.com/rofl0r/proxychains-ng) |
| `ligolo-ng` | Advanced, yet simple, tunneling/pivoting tool that uses a TUN interface | [github.com/nicocha30/ligolo-ng](https://github.com/nicocha30/ligolo-ng) |
| `chisel` | If not taken from apt | [github.com/jpillora/chisel](https://github.com/jpillora/chisel) |
| `penelope` | Shell handler (single script) | [github.com/brightio/penelope](https://github.com/brightio/penelope) |
| `Villain` | Multi session handler | [github.com/t3l3machus/Villain](https://github.com/t3l3machus/Villain) |
| `donut` | Generates position-independent shellcode from memory and runs them | [github.com/TheWover/donut](https://github.com/TheWover/donut) |
| `PEASS-ng` | WinPEAS + linPEAS privesc enumeration | [github.com/peass-ng/PEASS-ng](https://github.com/peass-ng/PEASS-ng) |
| `pspy` | Pspy64 release asset | [github.com/DominicBreuker/pspy](https://github.com/DominicBreuker/pspy) |
| `PayloadsAllTheThings` | Payloads and bypass techniques for pentests | [github.com/swisskyrepo/PayloadsAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings) |
| `SharpCollection` | Precompiled .NET offensive tools to drop on targets | [github.com/Flangvik/SharpCollection](https://github.com/Flangvik/SharpCollection) |
| `netexec` | Network Execution Tool | [github.com/Pennyw0rth/NetExec](https://github.com/Pennyw0rth/NetExec) |
| `python3-impacket` | Python3 module to easily build and dissect network protocols | [github.com/SecureAuthCorp/impacket](https://github.com/SecureAuthCorp/impacket) |
| `impacket-scripts` | Links to useful impacket scripts examples | [kali.org/tools/impacket-scripts](https://www.kali.org/tools/impacket-scripts/) |
| `bloodhound-ce` | Ce python | [pypi.org/project/bloodhound-ce](https://pypi.org/project/bloodhound-ce/) |
| `certipy-ad` | Tool for attacking AD Certificate Services | [github.com/ly4k/Certipy](https://github.com/ly4k/Certipy) |
| `responder` | LLMNR/NBT-NS/mDNS Poisoner | [github.com/lgandx/Responder](https://github.com/lgandx/Responder) |
| `lsassy` | Remotely extract credentials from LSASS | [pypi.org/project/lsassy](https://pypi.org/project/lsassy/) |
| `donpapi` | Remote DPAPI dumping | [pypi.org/project/donpapi](https://pypi.org/project/donpapi/) |
| `Snaffler` | Snaffler.exe release asset | [github.com/SnaffCon/Snaffler](https://github.com/SnaffCon/Snaffler) |
| `evilginx` | MFA bypass phishing proxy | [github.com/kgretzky/evilginx2](https://github.com/kgretzky/evilginx2) |
| `bettercap` | Complete, modular, portable and easily extensible MITM framework | [bettercap.org](https://www.bettercap.org) |
| `sshuttle` | Transparent proxy server for VPN over SSH | [github.com/sshuttle/sshuttle](https://github.com/sshuttle/sshuttle) |
| `ldeep` | Rich offline LDAP/AD enumeration | [pypi.org/project/ldeep](https://pypi.org/project/ldeep/) |
| `mitm6` | Pwning IPv4 via IPv6 | [pypi.org/project/mitm6](https://pypi.org/project/mitm6/) |
| `pypykatz` | Mimikatz implementation in pure Python | [pypi.org/project/pypykatz](https://pypi.org/project/pypykatz/) |
| `bloodyAD` | CravateRouge/bloodyAD | [pypi.org/project/bloodyAD](https://pypi.org/project/bloodyAD/) |
| `certsync` | Dump NTDS hashes remotely via AD CS | [pypi.org/project/certsync](https://pypi.org/project/certsync/) |
| `coercer` | Coerce a Windows server to authenticate on an arbitrary machine | [pypi.org/project/coercer](https://pypi.org/project/coercer/) |
| `adidnsdump` | Enumerate AD-integrated DNS records | [pypi.org/project/adidnsdump](https://pypi.org/project/adidnsdump/) |
| `aircrack-ng` | Wireless WEP/WPA cracking utilities | [aircrack-ng.org](https://www.aircrack-ng.org/) |
| `wifite` | Python script to automate wireless auditing using aircrack-ng tools | [github.com/kimocoder/wifite2](https://github.com/kimocoder/wifite2) |
| `macchanger` | Utility for manipulating the MAC address of network interfaces | [github.com/alobbs/macchanger](https://github.com/alobbs/macchanger) |
| `medusa` | Fast, parallel, modular, login brute-forcer for network services | [foofus.net/?page_id=51](http://foofus.net/?page_id=51) |
| `ncrack` | High-speed network authentication cracking tool | [nmap.org/ncrack](https://nmap.org/ncrack/) |
| `crunch` | Tool for creating wordlist | [sourceforge.net/projects/crunch-wordlist](http://sourceforge.net/projects/crunch-wordlist/) |
| `rsmangler` | Wordlist mangling tool | [digi.ninja/projects/rsmangler.php](https://digi.ninja/projects/rsmangler.php) |
| `maskprocessor` | High-performance word generator with a per-position configurable charset | [github.com/hashcat/maskprocessor](https://github.com/hashcat/maskprocessor) |
| `hashid` | Identify the different types of hashes used to encrypt data | [psypanda.github.io/hashID](https://psypanda.github.io/hashID/) |
| `samdump2` | Dump Windows 2k/NT/XP password hashes | [ophcrack.sourceforge.net](https://ophcrack.sourceforge.net/) |
| `creddump7` | Python tool to extract credentials and secrets from Windows registry… | [github.com/CiscoCXSecurity/creddump7](https://github.com/CiscoCXSecurity/creddump7) |
| `chntpw` | NT SAM password recovery utility | [pogostick.net/~pnh/ntpasswd](http://pogostick.net/~pnh/ntpasswd/) |
| `gpp-decrypt` | Group Policy Preferences decrypter | [carnal0wnage.attackresearch.com/2012/10/group-policy-preferences-and-getting.html](http://carnal0wnage.attackresearch.com/2012/10/group-policy-preferences-and-getting.html) |
| `passing-the-hash` | Patched tools to use password hashes as authentication input | [passing-the-hash.blogspot.fr](http://passing-the-hash.blogspot.fr) |
| `polenum` | Extracts the password policy from a Windows system | [github.com/Wh1t3Fox/polenum](https://github.com/Wh1t3Fox/polenum/) |
| `set` | Social-Engineer Toolkit | [trustedsec.com/downloads/social-engineer-toolkit](https://www.trustedsec.com/downloads/social-engineer-toolkit/) |
| `weevely` | Stealth tiny web shell | [github.com/epinna/weevely3](https://github.com/epinna/weevely3/) |
| `webshells` | Collection of webshells | [kali.org](https://www.kali.org) |
| `laudanum` | Collection of injectable web files | [sourceforge.net/projects/laudanum](https://sourceforge.net/projects/laudanum/) |
| `windows-binaries` | Various pentesting Windows binaries | [kali.org](https://www.kali.org) |
| `msfpc` | MSFvenom Payload Creator (MSFPC) | [github.com/g0tmi1k/msfpc](https://github.com/g0tmi1k/msfpc) |
| `iodine` | Tool for tunneling IPv4 data through a DNS server | [code.kryo.se/iodine](https://code.kryo.se/iodine) |
| `dns2tcp` | TCP-over-DNS tunnel server and client | [kali.org/tools/dns2tcp](https://www.kali.org/tools/dns2tcp/) |
| `ptunnel` | Tunnel TCP connections over ICMP packets | [mit.edu/afs.new/sipb/user/golem/tmp/ptunnel-0.61.orig/web](http://www.mit.edu/afs.new/sipb/user/golem/tmp/ptunnel-0.61.orig/web/) |
| `udptunnel` | Tunnel UDP packets over a TCP connection | [www1.cs.columbia.edu/~lennox/udptunnel](http://www1.cs.columbia.edu/~lennox/udptunnel/) |
| `proxytunnel` | Help SSH and other protocols through HTTP(S) proxies | [proxytunnel.sourceforge.io](https://proxytunnel.sourceforge.io/) |
| `redsocks` | Arbitrary TCP connection redirector to a SOCKS or HTTPS proxy server | [darkk.net.ru/redsocks](http://darkk.net.ru/redsocks/) |
| `sslh` | Applicative protocol multiplexer | [rutschle.net/tech/sslh/README.html](http://www.rutschle.net/tech/sslh/README.html) |
| `dsniff` | Various tools to sniff network traffic for cleartext insecurities | [github.com/hackerschoice/dsniff](https://github.com/hackerschoice/dsniff) |
| `ettercap-graphical` | Ettercap GUI-enabled executable | [ettercap.github.io/ettercap](https://ettercap.github.io/ettercap/) |
| `spooftooph` | Automates spoofing or cloning Bluetooth devices | [hackfromacave.com/projects/spooftooph.html](http://www.hackfromacave.com/projects/spooftooph.html) |

## Installing

Pick this role in **Hemo Welcome** on first boot, or add it later:

```sh
sudo hemo-roles
```

Tools install online at selection time. See the [main README](../../README.md#roles) for the role model.
