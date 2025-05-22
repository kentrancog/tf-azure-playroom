resource "azurerm_resource_group" "network" {
  name     = "network-resources"
  location = "australiaeast"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet"
  address_space       = ["172.20.0.0/16"]
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
}

resource "azurerm_subnet" "private" {
  name                 = "private-subnet"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["172.20.0.0/24"]
  service_endpoints    = ["Microsoft.Storage"]

}

resource "azurerm_subnet" "public" {
  name                 = "public-subnet"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["172.20.1.0/24"]
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