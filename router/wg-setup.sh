#!/bin/sh

# ── CONFIG ─────────────────────────────────────────────────────
WG_IFACE="wg0"
WG_PORT="51820"
WG_SUBNET="10.10.10.0/24"
WG_SERVER_ADDR="10.10.10.1/24"
LAN_SUBNET="192.168.1.0/24"

CLIENT_NAME="my-laptop"
CLIENT_ADDR="10.10.10.2/32"
# ───────────────────────────────────────────────────────────────

echo ">> Generating keys..."
mkdir -p /etc/wireguard
wg genkey | tee /etc/wireguard/server_private.key | wg pubkey > /etc/wireguard/server_public.key
wg genkey | tee /etc/wireguard/client1_private.key | wg pubkey > /etc/wireguard/client1_public.key

SERVER_PRIVKEY=$(cat /etc/wireguard/server_private.key)
SERVER_PUBKEY=$(cat /etc/wireguard/server_public.key)
CLIENT_PRIVKEY=$(cat /etc/wireguard/client1_private.key)
CLIENT_PUBKEY=$(cat /etc/wireguard/client1_public.key)

chmod 600 /etc/wireguard/*.key

echo ">> Configuring WireGuard interface..."
uci set network.${WG_IFACE}=interface
uci set network.${WG_IFACE}.proto='wireguard'
uci set network.${WG_IFACE}.private_key="${SERVER_PRIVKEY}"
uci set network.${WG_IFACE}.listen_port="${WG_PORT}"
uci add_list network.${WG_IFACE}.addresses="${WG_SERVER_ADDR}"

echo ">> Adding client peer..."
uci add network wireguard_${WG_IFACE}
uci set network.@wireguard_${WG_IFACE}[-1].description="${CLIENT_NAME}"
uci set network.@wireguard_${WG_IFACE}[-1].public_key="${CLIENT_PUBKEY}"
uci set network.@wireguard_${WG_IFACE}[-1].persistent_keepalive='25'
uci add_list network.@wireguard_${WG_IFACE}[-1].allowed_ips="${CLIENT_ADDR}"

uci commit network

echo ">> Configuring firewall..."
# VPN zone
uci add firewall zone
uci set firewall.@zone[-1].name='vpn'
uci set firewall.@zone[-1].input='ACCEPT'
uci set firewall.@zone[-1].output='ACCEPT'
uci set firewall.@zone[-1].forward='ACCEPT'
uci set firewall.@zone[-1].masq='1'
uci add_list firewall.@zone[-1].network="${WG_IFACE}"

# VPN → LAN forwarding
uci add firewall forwarding
uci set firewall.@forwarding[-1].src='vpn'
uci set firewall.@forwarding[-1].dest='lan'

# VPN → WAN forwarding (full tunnel)
uci add firewall forwarding
uci set firewall.@forwarding[-1].src='vpn'
uci set firewall.@forwarding[-1].dest='wan'

# Allow WireGuard port on WAN
uci add firewall rule
uci set firewall.@rule[-1].name='Allow-WireGuard'
uci set firewall.@rule[-1].src='wan'
uci set firewall.@rule[-1].dest_port="${WG_PORT}"
uci set firewall.@rule[-1].proto='udp'
uci set firewall.@rule[-1].target='ACCEPT'

uci commit firewall

echo ">> Bringing up interface..."
ifup ${WG_IFACE}
service firewall restart

echo ""
echo ">> Done! Client config:"
echo "─────────────────────────────────────"
cat <<EOF
[Interface]
PrivateKey = ${CLIENT_PRIVKEY}
Address = ${CLIENT_ADDR}
DNS = 10.10.10.1

[Peer]
PublicKey = ${SERVER_PUBKEY}
Endpoint = vpn.doorlay.com:${WG_PORT}
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF
echo "─────────────────────────────────────"
echo ">> Server public key: ${SERVER_PUBKEY}"
