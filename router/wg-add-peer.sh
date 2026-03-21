#!/bin/sh

# ── CONFIG ─────────────────────────────────────────────────────
WG_IFACE="wg0"
WG_PORT="51820"
WG_SERVER_ADDR="10.10.10.1"
DDNS_HOST="vpn.doorlay.com"  

CLIENT_NAME="${1}"                # passed as argument
CLIENT_ADDR="${2}"                # e.g. 10.10.10.3/32
# ───────────────────────────────────────────────────────────────

if [ -z "$CLIENT_NAME" ] || [ -z "$CLIENT_ADDR" ]; then
    echo "Usage: $0 <client-name> <client-ip>"
    echo "  e.g: $0 my-phone 10.10.10.3/32"
    exit 1
fi

# Install qrencode if missing
if ! command -v qrencode > /dev/null; then
    echo ">> Installing qrencode..."
    opkg update && opkg install qrencode
fi

echo ">> Generating keys for ${CLIENT_NAME}..."
mkdir -p /etc/wireguard
wg genkey | tee /etc/wireguard/${CLIENT_NAME}_private.key | wg pubkey > /etc/wireguard/${CLIENT_NAME}_public.key
chmod 600 /etc/wireguard/${CLIENT_NAME}_private.key

CLIENT_PRIVKEY=$(cat /etc/wireguard/${CLIENT_NAME}_private.key)
CLIENT_PUBKEY=$(cat /etc/wireguard/${CLIENT_NAME}_public.key)
SERVER_PUBKEY=$(cat /etc/wireguard/server_public.key)

echo ">> Adding peer to router..."
uci add network wireguard_${WG_IFACE}
uci set network.@wireguard_${WG_IFACE}[-1].description="${CLIENT_NAME}"
uci set network.@wireguard_${WG_IFACE}[-1].public_key="${CLIENT_PUBKEY}"
uci set network.@wireguard_${WG_IFACE}[-1].persistent_keepalive='25'
uci add_list network.@wireguard_${WG_IFACE}[-1].allowed_ips="${CLIENT_ADDR}"
uci commit network
ifup ${WG_IFACE}

echo ">> Generating QR code..."
CLIENT_CONF=$(cat <<EOF
[Interface]
PrivateKey = ${CLIENT_PRIVKEY}
Address = ${CLIENT_ADDR}
DNS = ${WG_SERVER_ADDR}

[Peer]
PublicKey = ${SERVER_PUBKEY}
Endpoint = ${DDNS_HOST}:${WG_PORT}
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF
)

echo "$CLIENT_CONF" | qrencode -t ansiutf8
echo ""
echo "── Raw config (save as ${CLIENT_NAME}.conf if needed) ──"
echo "$CLIENT_CONF"
