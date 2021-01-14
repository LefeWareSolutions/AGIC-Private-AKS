provider "azurerm" {
  version = "~>2.0"
  features {}
}

variable "location" {
  description = "Location of the network"
  default     = "eastus"
}


#############################################VNets Creation########################################
resource "azurerm_resource_group" "project1SpokeRg" {
  name = "project1SpokeNetowrking-RG"
  location = "eastus"
}
resource "azurerm_virtual_network" "project1SpokeVNet" {
    name                = "HubVNet"
    address_space       = ["10.5.0.0/16"]
    location            = azurerm_resource_group.hubRg.location
    resource_group_name = azurerm_resource_group.hubRg
}

resource "azurerm_resource_group" "hubRg" {
  name = "HubNetworking-RG"
  location = "eastus"
}
resource "azurerm_virtual_network" "project1SpokeVNet" {
    name                = "Project1SpokeVNet"
    address_space       = ["10.6.0.0/16"]
    location            = azurerm_resource_group.project1SpokeRg.location
    resource_group_name = azurerm_resource_group.project1SpokeRg
}

#######################################VNets Peering########################################

resource "azurerm_virtual_network_peering" "spoke1-hub-peer" {
  name                      = "spoke1-hub-peer"
  resource_group_name       = azurerm_resource_group.project1SpokeRg.name
  virtual_network_name      = azurerm_virtual_network.spoke1-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.hub-vnet.id

  allow_virtual_network_access = true
  allow_forwarded_traffic = true
  allow_gateway_transit   = false
  use_remote_gateways     = true
  depends_on = [azurerm_virtual_network.spoke1-vnet, azurerm_virtual_network.hub-vnet , azurerm_virtual_network_gateway.hub-vnet-gateway]
}



resource "azurerm_subnet" "myterraformsubnet" {
    name                 = "mySubnet"
    resource_group_name  = azurerm_resource_group.myterraformgroup.name
    virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
    address_prefixes       = ["10.0.2.0/24"]
}