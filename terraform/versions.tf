terraform {
  # Terraform 0.14.3 or later is required for the -raw flag on `terraform
  # output`.
  required_version = ">= 0.14.3"
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.23.2"
    }
  }
}
