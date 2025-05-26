variable "private_connection_resource_id" {
  description = "The resource id of the private connection to connect to."
  type        = string
  default     = "/subscriptions/c44ae216-12c8-48c8-8226-093e235caa23/resourceGroups/vm-resources/providers/Microsoft.Storage/storageAccounts/stpremiumfilesk530yc"
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