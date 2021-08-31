[Interface]
Address = ${peer_ip_addr}/32
PrivateKey = $wg_client_private_key


[Peer]
PublicKey = $wg_server_public_key
Endpoint = ${floating_ip}:65000

# Allow only the following networks to tunnel through VPN:
# - VSI subnet
# - Cluster subnets - You need this to get to the openshift console
# - IBM Cloud Service Endpoint (CSE): 166.8.0.0/14, 166.9.0.0/14
# - Anything else you need to tunnel to
AllowedIPs = 166.8.0.0/14, 166.9.0.0/14%{ for cidr in cidrs ~}, ${cidr}%{ endfor ~}


