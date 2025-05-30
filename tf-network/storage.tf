resource "azurerm_storage_account" "premium_files" {
  name                     = "stpremiumfiles${random_string.suffix.result}" # must be globally unique
  resource_group_name      = azurerm_resource_group.vm.name
  location                 = azurerm_resource_group.vm.location
  account_kind             = "FileStorage"
  account_tier             = "Premium"
  account_replication_type = "LRS"
  network_rules {
    default_action             = "Deny"
    ip_rules = [chomp(data.http.my_ip.response_body)]
    virtual_network_subnet_ids = [azurerm_subnet.private.id, azurerm_subnet.public.id]
  }
  tags = var.tags
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  numeric = true
  special = false
}

resource "azurerm_storage_share" "premium_share" {
  name                 = var.file_share_name
  storage_account_name = azurerm_storage_account.premium_files.name
  quota                = 100       # In GiB
  enabled_protocol     = "SMB"     # Or "NFS" if you need Linux-style access
  access_tier          = "Premium" # Only valid for FileStorage
}


resource "azurerm_key_vault" "key_vault" {
  name                = "kv-${random_string.suffix.result}"
  location            = azurerm_resource_group.vm.location
  resource_group_name = azurerm_resource_group.vm.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
}

resource "azurerm_key_vault_access_policy" "terraform" {
  key_vault_id = azurerm_key_vault.key_vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id # identity Terraform is using

  secret_permissions = [
    "Get",
    "Set",
    "Delete",
    "List",
    "Purge"
  ]
}

resource "azurerm_key_vault_secret" "storage_key" {
  name         = "storage-account-key"
  value        = azurerm_storage_account.premium_files.primary_access_key
  key_vault_id = azurerm_key_vault.key_vault.id
  depends_on   = [azurerm_key_vault_access_policy.terraform]
}


resource "azurerm_private_endpoint" "fileshare_endpoint" {
  name                = "pe-fileshare"
  location            = azurerm_resource_group.vm.location
  resource_group_name = azurerm_resource_group.vm.name
  subnet_id           = azurerm_subnet.private.id

  private_service_connection {
    name                           = "psc-fileshare"
    private_connection_resource_id = azurerm_storage_account.premium_files.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = "privatelink.file.core.windows.net"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage_private_endpoint.id]
  }
  tags = var.tags
}

