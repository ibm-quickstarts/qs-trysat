locals {
  user_data_vsi = <<EOF
#!/bin/bash

# Upgrade first. If we upgrade after, you'll get an interactive prompt saying
# that upgrade of SSH needs clarification on which version of sshd_config to
# use. The proper fix would be https://stackoverflow.com/a/33370375/27641 but
# swapping the order works for now.
DEBIAN_FRONTEND=noninteractive apt-get -y update
DEBIAN_FRONTEND=noninteractive apt-get -y upgrade

# Disable password authentication
# Whether commented or not, make sure they are uncommented and explicitly set to 'no'
grep -q "ChallengeResponseAuthentication" /etc/ssh/sshd_config && sed -i "/^[#]*ChallengeResponseAuthentication[[:space:]]yes.*/c\ChallengeResponseAuthentication no" /etc/ssh/sshd_config || echo "ChallengeResponseAuthentication no" >> /etc/ssh/sshd_config
grep -q "PasswordAuthentication" /etc/ssh/sshd_config && sed -i "/^[#]*PasswordAuthentication[[:space:]]yes/c\PasswordAuthentication no" /etc/ssh/sshd_config || echo "PasswordAuthentication no" >> /etc/ssh/sshd_config

# If any other files are Included, comment out the Include
# Sometimes IBM stock images have an uppercase Include like this.
sed -i "s/^Include/# Include/g" /etc/ssh/sshd_config

service ssh restart

# As a precaution, delete the root password in case it exists
passwd -d root

EOF
}

data "ibm_is_image" "ubuntu20" {
  name = "ibm-ubuntu-20-04-minimal-amd64-2"
}

resource "ibm_is_subnet" "subnet_vsi" {
  name                     = "${var.basename}-subnet-vsi"
  vpc                      = var.vpc_id
  zone                     = var.zone
  total_ipv4_address_count = 32
  resource_group           = var.resource_group
}

resource "ibm_is_security_group" "vsi_sg" {
  name           = "${var.basename}-vsi-sg"
  vpc            = var.vpc_id
  resource_group = var.resource_group
}

resource "ibm_is_security_group_rule" "rule-all-outbound" {
  group     = ibm_is_security_group.vsi_sg.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

resource "ibm_is_security_group_rule" "rule-ssh-inbound" {
  group     = ibm_is_security_group.vsi_sg.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "rule-wireguard-inbound" {
  group     = ibm_is_security_group.vsi_sg.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  udp {
    port_min = 65000
    port_max = 65000
  }
}

resource "ibm_is_instance" "vsi_wireguard" {
  name           = "${var.basename}-vsi-wireguard"
  resource_group = var.resource_group
  profile        = "cx2-2x4"
  image          = data.ibm_is_image.ubuntu20.id
  vpc            = var.vpc_id
  keys           = [var.ssh_key_id]
  zone           = var.zone
  user_data      = local.user_data_vsi

  primary_network_interface {
    subnet          = ibm_is_subnet.subnet_vsi.id
    security_groups = [ibm_is_security_group.vsi_sg.id]
  }

  # Don't respin the VSI if the startup script is updated.
  lifecycle {
    ignore_changes = [
      user_data
    ]
  }

  timeouts {
    # From experience, this sometimes takes longer than 30m, which is the
    # default.
    create = "60m"
    update = "60m"
    delete = "60m"
  }
}

resource "ibm_is_floating_ip" "vsi_wireguard_floatingip" {
  name           = "${var.basename}-fip-wireguard"
  target         = ibm_is_instance.vsi_wireguard.primary_network_interface.0.id
  resource_group = var.resource_group
}

# This will only run if the var.setup_wireguard variable is set to true.
resource "null_resource" "setup_wireguard" {
  depends_on = [ibm_is_floating_ip.vsi_wireguard_floatingip]

  connection {
    type        = "ssh"
    user        = "root"
    password    = ""
    private_key = file(var.ssh_private_key_file)
    host        = ibm_is_floating_ip.vsi_wireguard_floatingip.address
  }

  provisioner "file" {
    content = templatefile("${path.module}/wg0.conf.tpl",
      { ip_addr = ibm_is_instance.vsi_wireguard.primary_network_interface.0.primary_ipv4_address,
    peer_ip_addr = cidrhost(join("/", [ibm_is_instance.vsi_wireguard.primary_network_interface.0.primary_ipv4_address, "30"]), 2) })
    destination = "/root/wg0.conf"
  }

  provisioner "file" {
    content = templatefile("${path.module}/wireguard.client.tpl",
      { peer_ip_addr = cidrhost(join("/", [ibm_is_instance.vsi_wireguard.primary_network_interface.0.primary_ipv4_address, "30"]), 2),
    floating_ip = ibm_is_floating_ip.vsi_wireguard_floatingip.address, cidrs = flatten([[ibm_is_subnet.subnet_vsi.ipv4_cidr_block], var.cidrs]) })

    destination = "/root/wireguard.client"
  }

  provisioner "remote-exec" {
    script = "${path.module}/wireguard.sh"
  }
}
