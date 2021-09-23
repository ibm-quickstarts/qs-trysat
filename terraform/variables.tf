# All these variables are supplied from the .envrc file in TF_VAR_xxx environment
# variables.

variable "RESOURCE_PREFIX" {
  type = string
}

variable "LOCATION_REGION" {
  type = string
  default = "eu-gb"
}

variable "IAAS_REGION" {
  type = string
  default = "eu-gb"
}

variable "COS_REGION" {
  type = string
  default = "eu"
}

variable "WORKER_NODE_PROFILE" {
  type = string
  default = "bx2-4x16"
}

variable "CREATE_FLOATING_IP" {
  type = number
  default = 0
}

variable "IC_API_KEY" {
  type = string
}

