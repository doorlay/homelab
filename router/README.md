### Overview
Run `wg-setup.sh` to create a new WireGuard interface on your OpenWRT router. Copy the lines between the line breaks at the end, paste into a .conf file, and import this into your WireGuard client.

The above script has a hardcoded domain, `vpn.doorlay.com`, which redirects to my WAN ip. To guard against that ip changing and breaking VPN access, ensure you run https://github.com/K0p1-Git/cloudflare-ddns-updater or something similar on a server. 
