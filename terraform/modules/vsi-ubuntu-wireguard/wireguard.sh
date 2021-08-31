#!/bin/bash

until [[ -f /var/lib/cloud/instance/boot-finished ]]; do
  sleep 1
done

# Install wireguard
apt-get install -y wireguard
apt-get install -y wireguard-dkms wireguard-tools linux-headers-$(uname -r)


# Prepare for wireguard
# Enable Active IP forwarding
grep -q "net.ipv4.ip_forward" /etc/sysctl.conf && sed -i "/^[#]*net.ipv4.ip_forward[[:space:]]*=[[:space:]]*1/c\net.ipv4.ip_forward = 1" /etc/sysctl.conf || echo "net.ipv4.ip_forward = 1" >> /etc/ssh/sshd_config
sysctl -p

mkdir /root/wireguard
cd /root/wireguard

umask 077

# generate server keys
wg genkey | tee wg_server_private_key | wg pubkey > wg_server_public_key

# generate client keys
wg genkey | tee wg_client_private_key | wg pubkey > wg_client_public_key

cd ..

# Fill in the private and public keys in the client and server config files
sed -i "s/\$wg_client_public_key/$(sed 's:/:\\/:g' wireguard/wg_client_public_key)/" wg0.conf
sed -i "s/\$wg_client_private_key/$(sed 's:/:\\/:g' wireguard/wg_client_private_key)/" wireguard.client

sed -i "s/\$wg_server_public_key/$(sed 's:/:\\/:g' wireguard/wg_server_public_key)/" wireguard.client
sed -i "s/\$wg_server_private_key/$(sed 's:/:\\/:g' wireguard/wg_server_private_key)/" wg0.conf

# Remove the generated secrets so they're not lying around
rm -rf wireguard

# Move the server config to where wireguard expects to find it
mv wg0.conf /etc/wireguard

# start the wireguard server
wg-quick up wg0

# Enable the Wireguard service to automatically restart after the VSI is stopped and started.
systemctl enable wg-quick@wg0

# Note the wireguard.client file should be copied to your local machine and deleted from this machine