resource "azurerm_resource_group" "storage" {
  name     = "storage-resources"
  location = "australiaeast"
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  numeric = true
  special = false
}

resource "azurerm_storage_account" "premium_files" {
  name                     = "stpremiumfiles${random_string.suffix.result}" # must be globally unique
  resource_group_name      = azurerm_resource_group.storage.name
  location                 = azurerm_resource_group.storage.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"


  is_hns_enabled = true
  sftp_enabled   = true


  network_rules {
    default_action = "Deny"
    ip_rules       = [chomp(data.http.my_ip.response_body)]
  }
  tags = var.tags
}

resource "azurerm_storage_container" "testcontainer" {
  name                  = "testcontainer"
  storage_account_id    = azurerm_storage_account.premium_files.id
  container_access_type = "private"
}

resource "azurerm_storage_blob" "example" {
  name                   = "test.txt"
  storage_account_name   = azurerm_storage_account.premium_files.name
  storage_container_name = azurerm_storage_container.testcontainer.name
  type                   = "Block"
  source                 = "test.txt"
}


resource "azurerm_storage_account_local_user" "sftp_user" {
  name               = "sftpuser"
  storage_account_id = azurerm_storage_account.premium_files.id
  home_directory     = azurerm_storage_container.testcontainer.name # Set home directory to the created container

  # You can choose between password and/or SSH key authentication
  ssh_key_enabled      = true
  ssh_password_enabled = false # Set to true if you want password authentication

  # Define permissions for the user
  permission_scope {
    permissions {
      read   = true
      write  = true
      delete = true
      list   = true
      create = true
    }
    service       = "blob" # SFTP works with blob storage
    resource_name = azurerm_storage_container.testcontainer.name
  }

  # If ssh_key_enabled is true, provide at least one SSH key
  ssh_authorized_key {
    description = "User's SSH Key"
    key         = file("~/.ssh/id_rsa.pub")
  }
}


# Output the SFTP endpoint
output "sftp_endpoint" {
  value = "${azurerm_storage_account.premium_files.name}.blob.core.windows.net"
}

# Output the SFTP username
output "sftp_username" {
  value = "${azurerm_storage_account.premium_files.name}.${azurerm_storage_account_local_user.sftp_user.name}"
}
