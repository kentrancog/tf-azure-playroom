
module "linux_vm" {
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "0.19.1" # Use the latest appropriate version

  name                = "mylinuxvmavm01"
  resource_group_name = azurerm_resource_group.myResourceGroup.name
  location            = azurerm_resource_group.myResourceGroup.location
  zone                = "1"

  sku_size       = "Standard_B1s" # Choose an appropriate VM size
  admin_username = "azureuser"    # Your desired admin username

  # SSH Key Configuration
  # The admin_ssh_keys block expects a list of objects,
  # each with 'username' and 'public_key'.
  admin_ssh_keys = [
    {
      username   = "azureuser"               # Must match the admin_username above
      public_key = file("~/.ssh/id_rsa.pub") # Ensure path is correct
    }
  ]
  # disable_password_authentication = true # This is default when SSH keys are provided

  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS" # Or Premium_LRS for better performance
    disk_size_gb         = 30
  }
  os_type = "Linux"

  source_image_reference = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy" # Ubuntu 22.04 LTS
    sku       = "22_04-lts-gen2"               # For Gen2 VM sizes
    version   = "latest"
  }

  # Network Interface Configuration
  # The module will create the NIC and Public IP based on this.
  network_interfaces = {
    network_interface_1 = {
      name = "nic-${module.linux_vm.name}-01"
      network_security_groups = {
        nsg1 = {
          network_security_group_resource_id = module.vm_nsg.resource_id
        }
      }
      ip_configurations = {
        ip_configuration_1 = {
          name                          = "nic-${module.linux_vm.name}-01-ip"
          private_ip_subnet_resource_id = module.avm-res-network-virtualnetwork.subnets.subnet1.resource_id
          create_public_ip_address      = true
          public_ip_address_name        = "nic-${module.linux_vm.name}-01-pip"
        }
      }
    }
  }
  tags = {
    environment = "test"
    DeployedBy  = "TerraformAVM"
  }
}


module "vm_nsg" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.4.0" # Replace with the actual latest stable version

  name                = "nsg-${module.linux_vm.name}"
  resource_group_name = azurerm_resource_group.myResourceGroup.name
  location            = azurerm_resource_group.myResourceGroup.location

  security_rules = {
    AllowSSHFromSpecificIP = {
      name                       = "AllowSSHFromSpecificIP"
      priority                   = 100 # Lower numbers have higher priority (100-4096)
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"  # Any source port
      destination_port_range     = "22" # SSH port
      source_address_prefixes    = ["121.74.0.14/32"]
      destination_address_prefix = "*"
    }
  }
}


# Output the public IP address of the VM
output "vm_public_ip" {
  description = "Public IP address of the Linux VM"
  value       = module.linux_vm.public_ips.network_interface_1-ip_configuration_1.ip_address
}

output "ssh_command" {
  description = "Command to SSH into the VM"
  value       = "ssh ${module.linux_vm.admin_username}@${module.linux_vm.public_ips.network_interface_1-ip_configuration_1.ip_address}"
}