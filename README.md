# Lazy Scan Script

This is a wrapper to automate a large amount of the initial enumeration when doing CTF's or Pentests. 

## Installation
Ideally the operating system should be one of the popular pentesting Linux distributions (Kali, Parrot, Black Arch etc.)

However the tools can be easily download on other Linux distro's:

- [smbmap](https://github.com/ShawnDEvans/smbmap)
- [gobuster](https://github.com/OJ/gobuster)
- [nmap](https://nmap.org/)
- [amass](https://github.com/OWASP/Amass)
- [assetfinder](https://github.com/tomnomnom/assetfinder)
- [httprobe](https://github.com/tomnomnom/httprobe)

The tool also makes extensive use of the [nmap-parse-output](https://github.com/ernw/nmap-parse-output#bash-completion) tool. It is recommended to add this the machine's ~/.bashrc.

## Usage

Usage is quite simple. Simply change the permissions modification of the script if necessary and run it with flags.

- -h: Host or ip to scan
- -g: Gobuster if port 80, 443, or 8080 open. Requires -w flag.
- -w: Wordlist for gobuster.
- -v: Have nmap do a version scan on open ports found.
- -s: Smbmap if port 445 found on host. 
- -r: Perform recon on a domain

## To-Do
- Add anonymous RPC check
- Add Aquatone option
- Add Option for full port scan (i.e. 0-65535)


## Contributing
 Please feel free to submit a pull request, or issue request for additional features. I am hoping to learn as much as possible from the community.