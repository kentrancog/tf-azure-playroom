resource "azurerm_resource_group" "vm" {
  name     = "vm-resources"
  location = "australiaeast"
}

resource "azurerm_network_interface" "vm_nic" {
  name                = "vm_nic"
  location            = azurerm_resource_group.vm.location
  resource_group_name = azurerm_resource_group.vm.name

  ip_configuration {
    name                          = "vm-ip-config"
    subnet_id                     = azurerm_subnet.public.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_public_ip.id
  }
}

resource "azurerm_public_ip" "vm_public_ip" {
  name                = "vm-public-ip"
  location            = azurerm_resource_group.vm.location
  resource_group_name = azurerm_resource_group.vm.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm-linux"
  location            = azurerm_resource_group.vm.location
  resource_group_name = azurerm_resource_group.vm.name
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.vm_nic.id,
  ]
  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub") # Use your SSH public key path
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
  identity {
    type = "SystemAssigned"
  }
  disable_password_authentication = true
  custom_data                     = base64encode(local.mount_script)
}

locals {
  mount_script = templatefile("${path.module}/mount-from-keyvault.sh", {
    storage_account = azurerm_storage_account.premium_files.name
    file_share      = var.file_share_name
    keyvault_name   = azurerm_key_vault.key_vault.name
    secret_name     = azurerm_key_vault_secret.storage_key.name
  })
}

resource "azurerm_network_security_group" "vm_nsg" {
  name                = "vm-nsg"
  location            = azurerm_resource_group.vm.location
  resource_group_name = azurerm_resource_group.vm.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = ["121.74.0.14/32", "202.180.77.121/32"] # home ip, work ip
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "vm_nic_nsg" {
  network_interface_id      = azurerm_network_interface.vm_nic.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

output "vm_public_ip" {
  description = "The public IP address of the Linux VM"
  value       = azurerm_public_ip.vm_public_ip.ip_address
}



resource "azurerm_storage_account" "premium_files" {
  name                     = "stpremiumfiles${random_string.suffix.result}" # must be globally unique
  resource_group_name      = azurerm_resource_group.vm.name
  location                 = azurerm_resource_group.vm.location
  account_kind             = "FileStorage"
  account_tier             = "Premium"
  account_replication_type = "LRS"
  network_rules {
    default_action             = "Deny"
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

output "storage_share_url" {
  value = azurerm_storage_share.premium_share.url
}


resource "azurerm_key_vault" "key_vault" {
  name                = "kv-${random_string.suffix.result}"
  location            = azurerm_resource_group.vm.location
  resource_group_name = azurerm_resource_group.vm.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
}

resource "azurerm_key_vault_access_policy" "vm_access" {
  key_vault_id       = azurerm_key_vault.key_vault.id
  tenant_id          = data.azurerm_client_config.current.tenant_id
  object_id          = azurerm_linux_virtual_machine.vm.identity[0].principal_id
  secret_permissions = ["Get"]
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

output "private_endpoint_ip" {
  description = "The private IP assigned to the Azure Private Endpoint"
  value       = azurerm_private_endpoint.fileshare_endpoint.private_service_connection[0].private_ip_address
}

### Private DNS setup for vNet


resource "azurerm_private_dns_zone" "storage_private_endpoint" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = azurerm_resource_group.vm.name
}


resource "azurerm_private_dns_zone_virtual_network_link" "vnet_storage_private_endpoint_link" {
  name                  = "${azurerm_virtual_network.vnet.name}-storage-zone-link"
  resource_group_name   = azurerm_resource_group.vm.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_private_endpoint.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  tags = var.tags

}
