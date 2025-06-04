
# resource "azurerm_key_vault" "key_vault" {
#   name                = "kv-${random_string.suffix.result}"
#   location            = azurerm_resource_group.vm.location
#   resource_group_name = azurerm_resource_group.vm.name
#   tenant_id           = data.azurerm_client_config.current.tenant_id
#   sku_name            = "standard"
# }

# resource "azurerm_key_vault_access_policy" "terraform" {
#   key_vault_id = azurerm_key_vault.key_vault.id
#   tenant_id    = data.azurerm_client_config.current.tenant_id
#   object_id    = data.azurerm_client_config.current.object_id # identity Terraform is using

#   secret_permissions = [
#     "Get",
#     "Set",
#     "Delete",
#     "List",
#     "Purge"
#   ]
# }

# resource "azurerm_key_vault_secret" "storage_key" {
#   name         = "storage-account-key"
#   value        = azurerm_storage_account.premium_files.primary_access_key
#   key_vault_id = azurerm_key_vault.key_vault.id
#   depends_on   = [azurerm_key_vault_access_policy.terraform]
# }