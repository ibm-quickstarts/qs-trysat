data "ibm_is_image" "ubuntu" {
  name = "ibm-ubuntu-20-04-minimal-amd64-2"
}

resource "ibm_is_instance" "is_instance" {
  name    = var.name
  image   = data.ibm_is_image.ubuntu.id
  profile = "bx2-2x8"

  resource_group = var.resource_group

  primary_network_interface {
    subnet          = var.subnet_id
    security_groups = [var.security_group_id]
  }

  vpc  = var.vpc_id
  zone = var.zone
  keys = [var.ssh_key_id]

  timeouts {
    # From experience, this sometimes takes longer than 30m, which is the
    # default.
    create = "60m"
    update = "60m"
    delete = "60m"
  }
}

resource "null_resource" "setup_host" {
  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.ssh_private_key_file)
    host        = ibm_is_instance.is_instance.primary_network_interface[0].primary_ipv4_address

    bastion_host = var.bastion_host
  }

  provisioner "file" {
    source      = "${path.module}/setup_host.sh"
    destination = "/tmp/setup_host.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup_host.sh",
      "/tmp/setup_host.sh",
    ]
  }
}
