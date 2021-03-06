output "ipaddress_controlplane01_floating" {
  value = module.is_instance_controlplane01.floating_ip
}

output "ipaddress_controlplane01_private" {
  value = module.is_instance_controlplane01.private_ip
}

output "ipaddress_controlplane02_floating" {
  value = module.is_instance_controlplane02.floating_ip
}

output "ipaddress_controlplane02_private" {
  value = module.is_instance_controlplane02.private_ip
}

output "ipaddress_controlplane03_floating" {
  value = module.is_instance_controlplane03.floating_ip
}

output "ipaddress_controlplane03_private" {
  value = module.is_instance_controlplane03.private_ip
}

output "ipaddress_workernode01_floating" {
  value = module.is_instance_workernode01.floating_ip
}

output "ipaddress_workernode01_private" {
  value = module.is_instance_workernode01.private_ip
}

output "ipaddress_workernode02_floating" {
  value = module.is_instance_workernode02.floating_ip
}

output "ipaddress_workernode02_private" {
  value = module.is_instance_workernode02.private_ip
}

output "ipaddress_workernode03_floating" {
  value = module.is_instance_workernode03.floating_ip
}

output "ipaddress_workernode03_private" {
  value = module.is_instance_workernode03.private_ip
}

output "ipaddress_wireguard_floating" {
  value = module.wireguard.vsi_floating_ip
}

output "logdna_ingestion_key" {
  sensitive = true
  value     = ibm_resource_key.logdna_key.credentials.ingestion_key
}

output "ipaddress_onprem_private" {
  value = module.on_prem_instance.private_ip
}

output "node_password" {
  value     = random_password.nodepwd.result
  sensitive = true
}
