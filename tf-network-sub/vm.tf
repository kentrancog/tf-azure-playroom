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
    subnet_id                     = azurerm_subnet.private.id
    private_ip_address_allocation = "Dynamic"
    # public_ip_address_id          = azurerm_public_ip.vm_public_ip.id
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
#   custom_data                     = base64encode(local.mount_script)
}

# locals {
#   mount_script = templatefile("${path.module}/mount-from-keyvault.sh", {
#     storage_account = azurerm_storage_account.premium_files.name
#     file_share      = var.file_share_name
#     keyvault_name   = azurerm_key_vault.key_vault.name
#     secret_name     = azurerm_key_vault_secret.storage_key.name
#   })
# }

