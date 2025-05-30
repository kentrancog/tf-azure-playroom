variable "file_share_name" {
  description = "Name of the file share to create."
  type        = string
  default     = "fileshare"
}

variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default = {
    environment = "test"
    project     = "testproject"
    deployed_by = "Terraform"
  }
}

variable "admin_password" {
    description = "The password for the created Windows VM"
    type        = string
}
