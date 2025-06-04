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

variable "subscription_id" {
  description = "The Azure subscription ID where the resources will be created."
  type        = string
  default     = "cc9edc29-0131-47da-b178-c9ffb6e7e2df"
}

variable "backup_file_share" {
  description = "Whether to backup the file share on with Recovery Services Vault"
  type        = number
  default     = 1
}