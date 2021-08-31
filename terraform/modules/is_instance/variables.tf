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

variable "node_role" {
  description = "Node role, such as 'workernode01' or 'controlplane02'"
  type = string
}

variable "profile" {
  description = "VSI profile"
  type = string
  default = "bx2-4x16"
}

variable "bastion_host" {
  type = string
}

variable "node_password" {
  type = string
}

variable "create_floating_ip" {
  type = number
  default = 0
}

variable "onboarding_script_content" {
  type = string
}
