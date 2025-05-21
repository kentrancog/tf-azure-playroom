# Generate a random string for unique storage account name
resource "random_string" "sa_suffix" {
  length  = 6
  special = false
  upper   = false
  numeric = true # Ensure it starts with a letter by prefixing if necessary
}


module "storage_account" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.6.2"

  name                     = "${var.storage_account_base_name}${random_string.sa_suffix.result}"
  resource_group_name      = azurerm_resource_group.myResourceGroup.name
  location                 = azurerm_resource_group.myResourceGroup.location
  account_kind             = "FileStorage"
  account_replication_type = "LRS" # Local-Redundant Storage
  account_tier             = "Premium"
  #   allow_nested_items_to_be_public = false
  shared_access_key_enabled = true

  # Optional: enable public network access (not recommended for production without NSG/Firewall rules)
  # public_network_access_enabled = true 

  shares = {
    premiumfileshare = {
      name             = "premiumfileshare"
      quota            = 100       # In GiB
      enabled_protocol = "SMB"     # Or "NFS" if you need Linux-style access
      access_tier      = "Premium" # Only valid for FileStorage        
    }
  }

  tags = var.tags

}

output "storage_share_url" {
  value = module.storage_account.fqdn
}