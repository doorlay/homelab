### Overview
Run `wg-setup.sh` to create a new WireGuard interface on your OpenWRT router. Copy the lines between the line breaks at the end, paste into a .conf file, and import this into your WireGuard client.

To add a new peer, run `wg-add-peer.sh {client name} {client ip}` and scan the outputted QR code (or copy the .conf file  directly). Increment the IP for each new device — 10.10.10.3, 10.10.10.4, etc.

The above script has a hardcoded domain, `vpn.doorlay.com`, which redirects to my WAN ip. To guard against that ip changing and breaking VPN access, ensure you run https://github.com/K0p1-Git/cloudflare-ddns-updater or something similar on a server. 
