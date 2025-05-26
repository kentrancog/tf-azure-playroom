resource "azurerm_resource_group" "network" {
  name     = "network-resources"
  location = "australiaeast"
  tags     = var.tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet"
  address_space       = ["172.30.0.0/16"]
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  tags                = var.tags
}

resource "azurerm_subnet" "private" {
  name                 = "private-subnet"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["172.30.0.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
}

resource "azurerm_subnet" "public" {
  name                 = "public-subnet"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["172.30.1.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
}

# Public Route Table
resource "azurerm_route_table" "public" {
  name                = "public-rt"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
}

# Route to Internet (for public subnet)
resource "azurerm_route" "public_internet" {
  name                = "internet-route"
  resource_group_name = azurerm_resource_group.network.name
  route_table_name    = azurerm_route_table.public.name
  address_prefix      = "0.0.0.0/0"
  next_hop_type       = "Internet"
}

# Associate Public Route Table
resource "azurerm_subnet_route_table_association" "public" {
  subnet_id      = azurerm_subnet.public.id
  route_table_id = azurerm_route_table.public.id
}

# Private Route Table (no route to internet)
resource "azurerm_route_table" "private" {
  name                = "private-rt"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
}

# Associate Private Route Table
resource "azurerm_subnet_route_table_association" "private" {
  subnet_id      = azurerm_subnet.private.id
  route_table_id = azurerm_route_table.private.id
}


# DNS setup - private zone + vnet link + private endpoint for Azure Files

resource "azurerm_private_dns_zone" "storage_private_endpoint" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = azurerm_resource_group.vm.name
}


resource "azurerm_private_dns_zone_virtual_network_link" "vnet_storage_private_endpoint_link" {
  name                  = "${azurerm_virtual_network.vnet.name}-storage-zone-link"
  resource_group_name   = azurerm_resource_group.vm.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_private_endpoint.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  tags                  = var.tags

}

resource "azurerm_private_endpoint" "fileshare_endpoint" {
  name                = "target-fileshare"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  subnet_id           = azurerm_subnet.private.id

  private_service_connection {
    name                           = "to-psc-fileshare"
    private_connection_resource_id = var.private_connection_resource_id
    subresource_names              = ["file"]
    is_manual_connection           = true
    request_message                = "From Tenant ${data.azurerm_client_config.current.tenant_id} Subscription ${data.azurerm_client_config.current.subscription_id}"
  }
  private_dns_zone_group {
    name                 = "privatelink.file.core.windows.net"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage_private_endpoint.id]
  }
  tags = var.tags
}



resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["172.30.2.0/24"]
}


resource "azurerm_public_ip" "bastion_public_ip" { # Used for Azure Bastion for non Developer SKUs
  name                = "bastion-public-ip"
  location            = azurerm_resource_group.vm.location
  resource_group_name = azurerm_resource_group.vm.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bast" {
  name                = "bast"
  location            = azurerm_resource_group.vm.location
  resource_group_name = azurerm_resource_group.vm.name
  # sku = "Developer"
  # virtual_network_id = azurerm_virtual_network.vnet.id  # required for Developer SKU

  ip_configuration { # Only used for non Developer SKUs
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion_public_ip.id
  }
}









