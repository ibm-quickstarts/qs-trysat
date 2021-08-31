[Interface]
Address = ${ip_addr}/32
# SaveConfig = true
PrivateKey = $wg_server_private_key

PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o ens3 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o ens3 -j MASQUERADE

ListenPort = 65000

[Peer]
PublicKey = $wg_client_public_key
AllowedIPs = ${peer_ip_addr}/32

# Optionally add more clients by repeating the peer section for other clients