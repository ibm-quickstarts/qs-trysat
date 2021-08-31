output "floating_ip" {
  value = var.create_floating_ip > 0 ? ibm_is_floating_ip.fip[0].address : ""
}

output "private_ip" {
  value = ibm_is_instance.is_instance.primary_network_interface.0.primary_ipv4_address
}
