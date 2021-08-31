data "ibm_is_image" "rhel7" {
  name = "ibm-redhat-7-6-minimal-amd64-1"
}

resource "ibm_is_instance" "is_instance" {
  name    = var.name
  image   = data.ibm_is_image.rhel7.id
  profile = var.profile

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

  volumes = [ibm_is_volume.data_volume.id]
}

resource "ibm_is_volume" "data_volume" {
  # This is best practice, as theoretically each VSI should have a data volume
  # of >= 100GiB in addition to the boot volume.
  # See https://github.ibm.com/garage-satellite-guild/try-sat/issues/96 for the history.
  name     = "${var.name}-datavol"
  capacity = 100
  profile  = "general-purpose"
  zone     = var.zone
}

resource "ibm_is_floating_ip" "fip" {
  name           = "${var.name}-fip"
  target         = ibm_is_instance.is_instance.primary_network_interface[0].id
  resource_group = var.resource_group
  count          = var.create_floating_ip
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

  provisioner "file" {
    content     = var.onboarding_script_content
    destination = "/tmp/onboarding_script_${var.node_role}.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup_host.sh",
      "chmod +x /tmp/onboarding_script_${var.node_role}.sh",
      "/tmp/setup_host.sh ${var.node_role} ${var.node_password}",
    ]
  }
}
