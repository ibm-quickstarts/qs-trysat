variable "zone" {
  description = "Zone in which to provision the VSI.  Must be in the same Region as the VPC."
}

variable "vpc_id" {
  default     = ""
  description = "ID of VPC into which to provision the VSI.  A subnet will also be created."
}

variable "region" {
  description = "Region to deploy into"
}

variable "basename" {
  //  default = ""
  description = "Prefix used to name all resources."
}

variable "cidrs" {
  type        = list(string)
  default     = []
  description = "Array of cidrs in the VPC that you want to connect to through the vpn.  For example, you can add the subnet ranges for a ROKS or IKS cluster"
}

variable "ssh_key_id" {
  //  default = ""
  description = "ID of SSH Key already provisioned in the region.  This will be used to access the VSI."
}

variable "ssh_private_key_file" {
  default     = "~/.ssh/id_rsa"
  description = "Location of file with private ssh key.  This is used to remote-exec to the VSI after it is created, and install the SCC Collector"
}

variable "resource_group" {
  type = string
}
