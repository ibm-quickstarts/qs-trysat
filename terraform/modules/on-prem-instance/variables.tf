variable "name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "security_group_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "ssh_key_id" {
  type = string
}

variable "zone" {
  type = string
}

variable "resource_group" {
  type = string
}

variable "ssh_private_key_file" {
  description = "location of file with private ssh key.  this is used to remote-exec to the vsi after it is created"
}

variable "bastion_host" {
  type = string
}
