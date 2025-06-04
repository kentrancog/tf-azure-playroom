# resource "azurerm_network_interface" "vm_nic" {
#   name                = "vm_nic"
#   location            = azurerm_resource_group.vm.location
#   resource_group_name = azurerm_resource_group.vm.name

#   ip_configuration {
#     name                          = "vm-ip-config"
#     subnet_id                     = azurerm_subnet.public.id
#     private_ip_address_allocation = "Dynamic"
#     public_ip_address_id          = azurerm_public_ip.vm_public_ip.id
#   }
# }

# resource "azurerm_public_ip" "vm_public_ip" {
#   name                = "vm-public-ip"
#   location            = azurerm_resource_group.vm.location
#   resource_group_name = azurerm_resource_group.vm.name
#   allocation_method   = "Static"
#   sku                 = "Standard"
# }

# resource "azurerm_linux_virtual_machine" "vm" {
#   name                = "vm-linux"
#   location            = azurerm_resource_group.vm.location
#   resource_group_name = azurerm_resource_group.vm.name
#   size                = "Standard_B1s"
#   admin_username      = "azureuser"
#   network_interface_ids = [
#     azurerm_network_interface.vm_nic.id,
#   ]
#   admin_ssh_key {
#     username   = "azureuser"
#     public_key = file("~/.ssh/id_rsa.pub") # Use your SSH public key path
#   }

#   os_disk {
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#   }

#   source_image_reference {
#     publisher = "Canonical"
#     offer     = "0001-com-ubuntu-server-focal"
#     sku       = "20_04-lts"
#     version   = "latest"
#   }
#   identity {
#     type = "SystemAssigned"
#   }
#   disable_password_authentication = true
#   custom_data                     = base64encode(local.mount_script)
# }

# locals {
#   mount_script = templatefile("${path.module}/mount-from-keyvault.sh", {
#     storage_account = azurerm_storage_account.premium_files.name
#     file_share      = var.file_share_name
#     keyvault_name   = azurerm_key_vault.key_vault.name
#     secret_name     = azurerm_key_vault_secret.storage_key.name
#   })
# }

# resource "azurerm_network_security_group" "vm_nsg" {
#   name                = "vm-nsg"
#   location            = azurerm_resource_group.vm.location
#   resource_group_name = azurerm_resource_group.vm.name

#   security_rule {
#     name                       = "SSH"
#     priority                   = 1001
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "22"
#     source_address_prefixes    = [chomp(data.http.my_ip.response_body)]
#     destination_address_prefix = "*"
#   }
# }

# resource "azurerm_network_interface_security_group_association" "vm_nic_nsg" {
#   network_interface_id      = azurerm_network_interface.vm_nic.id
#   network_security_group_id = azurerm_network_security_group.vm_nsg.id
# }

# resource "azurerm_key_vault_access_policy" "vm_access" {
#   key_vault_id       = azurerm_key_vault.key_vault.id
#   tenant_id          = data.azurerm_client_config.current.tenant_id
#   object_id          = azurerm_linux_virtual_machine.vm.identity[0].principal_id
#   secret_permissions = ["Get"]
# }


# # Windows VM

# resource "azurerm_public_ip" "vm_public_ip_win" {
#   name                = "vm-public-ip-win"
#   resource_group_name = azurerm_resource_group.vm.name
#   location            = azurerm_resource_group.vm.location
#   allocation_method   = "Static" # Use "Static" for a fixed IP, incurs cost even if VM is off
#   sku                 = "Standard"   # "Standard" for production, Zonal/Zone-redundant
#   tags                = var.tags
# }

# resource "azurerm_network_security_group" "vm_nsg_win" {
#   name                = "vm_nsg_win"
#   resource_group_name = azurerm_resource_group.vm.name
#   location            = azurerm_resource_group.vm.location
#   tags                = var.tags

#   security_rule {
#     name                       = "AllowRDP"
#     priority                   = 100
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "3389"
#     source_address_prefixes      = [chomp(data.http.my_ip.response_body)]
#     destination_address_prefix = "*"
#   }
# }

# resource "azurerm_network_interface" "vm_nic_win" {
#   name                = "vm_nic_win"
#   resource_group_name = azurerm_resource_group.vm.name
#   location            = azurerm_resource_group.vm.location
#   tags                = var.tags

#   ip_configuration {
#     name                          = "internal"
#     subnet_id                     = azurerm_subnet.public.id
#     private_ip_address_allocation = "Dynamic"
#     public_ip_address_id          = azurerm_public_ip.vm_public_ip_win.id
#   }
# }

# resource "azurerm_network_interface_security_group_association" "vm_nic_nsg_win" {
#   network_interface_id      = azurerm_network_interface.vm_nic_win.id
#   network_security_group_id = azurerm_network_security_group.vm_nsg_win.id
# }

# resource "azurerm_windows_virtual_machine" "vm_win" {
#   name                  = "vm_win"
#   resource_group_name   = azurerm_resource_group.vm.name
#   location              = azurerm_resource_group.vm.location
#   size                  = "Standard_B1s"
#   admin_username        = "adminwin"
#   admin_password        = var.admin_password
#   network_interface_ids = [azurerm_network_interface.vm_nic_win.id]
#   tags                  = var.tags
#   computer_name         = "winvm01"

#   os_disk {
#     name                 = "vm_win-osdisk"
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS" # Or "Premium_LRS" for better performance
#   }

#   source_image_reference {
#     publisher = "MicrosoftWindowsServer"
#     offer     = "WindowsServer"
#     sku       = "2019-Datacenter"
#     version   = "latest"
#   }

#   # Optional: Enable boot diagnostics
#   boot_diagnostics {
#     # storage_account_uri = azurerm_storage_account.diag_storage.primary_blob_endpoint # Requires a storage account
#   }
# }

# # Windows VM public IP if created, keeping it here incase it gets commented out
# output "vm_public_ip_win" {
#   description = "The public IP address of the Windows VM"
#   value       = azurerm_public_ip.vm_public_ip_win.ip_address
# }

