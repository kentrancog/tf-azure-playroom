variable "resource_group_name" {
  description = "The name of the resource group to create."
  type        = string
  default     = "myResourceGroup"
}

variable "location" {
  description = "The Azure region where resources will be created."
  type        = string
  default     = "australiaeast"
}

variable "storage_account_base_name" {
  description = "Base name for the storage account. A random suffix will be added for uniqueness."
  type        = string
  default     = "mystorageaccount"
}

variable "file_share_name" {
  description = "Name of the file share to create."
  type        = string
  default     = "myfileshare"
}

variable "file_share_quota_gb" {
  description = "Quota for the file share in GB."
  type        = number
  default     = 100
}

variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default = {
    environment = "test"
    project     = "AVMStorage"
    deployed_by = "Terraform"
  }
}