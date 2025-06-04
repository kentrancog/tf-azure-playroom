resource "azurerm_recovery_services_vault" "vault" {
  count = var.backup_file_share ? 1 : 0
  name                = "recovery-vault"
  location            = azurerm_resource_group.vm.location
  resource_group_name = azurerm_resource_group.vm.name
  sku                 = "Standard"
  soft_delete_enabled = true
  storage_mode_type = "ZoneRedundant"
  tags = var.tags
}


resource "azurerm_backup_protected_file_share" "file_share_backup" {
  count = var.backup_file_share ? 1 : 0
  name = "backup-${azurerm_storage_share.premium_share.name}"
    resource_group_name = azurerm_resource_group.vm.name
    recovery_vault_name = azurerm_recovery_services_vault.vault[0].name
    storage_account_id = azurerm_storage_account.premium_files.id
    file_share_name = azurerm_storage_share.premium_share.name
    backup_policy_id = azurerm_backup_policy_file_share.default.id
    depends_on = [azurerm_recovery_services_vault.vault, azurerm_backup_policy_file_share.default]
    # lifecycle {
    #     ignore_changes = [
    #         backup_policy_id, # Ignore changes to the backup policy
    #     ]
    # }
}