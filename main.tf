terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "dev-rg" {
  name     = "developer-resources"
  location = "East US"
  tags = {
    environment = "dev"
  }
}

resource "azurerm_virtual_network" "dev-vnet" {
  name                = "developer-network"
  resource_group_name = azurerm_resource_group.dev-rg.name
  location            = azurerm_resource_group.dev-rg.location
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "dev"
  }
}

resource "azurerm_subnet" "dev-subnet" {
  name                 = "developer-subnet"
  resource_group_name  = azurerm_resource_group.dev-rg.name
  virtual_network_name = azurerm_virtual_network.dev-vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "dev-nsg" {
  name                = "deveploer-security-group"
  location            = azurerm_resource_group.dev-rg.location
  resource_group_name = azurerm_resource_group.dev-rg.name

  tags = {
    environment = "dev"
  }
}

resource "azurerm_network_security_rule" "dev-rule" {
  name                        = "developer-rule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.dev-rg.name
  network_security_group_name = azurerm_network_security_group.dev-nsg.name
}

resource "azurerm_subnet_network_security_group_association" "dev-sga" {
  subnet_id                 = azurerm_subnet.dev-subnet.id
  network_security_group_id = azurerm_network_security_group.dev-nsg.id
}

resource "azurerm_public_ip" "dev-ip" {
  name                = "dev-ip"
  resource_group_name = azurerm_resource_group.dev-rg.name
  location            = azurerm_resource_group.dev-rg.location
  allocation_method   = "Dynamic"

  tags = {
    environment = "dev"
  }
}