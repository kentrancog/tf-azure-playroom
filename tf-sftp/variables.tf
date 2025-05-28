variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default = {
    environment = "test"
    project     = "testproject"
    deployed_by = "Terraform"
  }
}

variable "subscription_id" {
  description = "The Azure subscription ID where the resources will be created."
  type        = string
  default     = "cc9edc29-0131-47da-b178-c9ffb6e7e2df"
}