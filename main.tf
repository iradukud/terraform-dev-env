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

resource "azurerm_network_interface" "dev-nic" {
  name                = "developer-nic"
  location            = azurerm_resource_group.dev-rg.location
  resource_group_name = azurerm_resource_group.dev-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.dev-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.dev-ip.id
  }

  tags = {
    environment = "dev"
  }
}

resource "azurerm_linux_virtual_machine" "dev-vm" {
  name                = "dev-vm"
  resource_group_name = azurerm_resource_group.dev-rg.name
  location            = azurerm_resource_group.dev-rg.location
  size                = "Standard_b1s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.dev-nic.id,
  ]

  custom_data = filebase64("customdata.tpl")

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/devazurekey.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  provisioner "local-exec" {
    command = templatefile("windows-ssh-script.tpl", {
      hostname     = self.public_ip_address,
      user         = "adminuser",
      identityfile = "~/.ssh/devazurekey"
    })
    interpreter = ["Powershell", "-Command"]
  }

  tags = {
    environment = "dev"
  }
}

data "azurerm_public_ip" "dev-ip-data" {
  name                = azurerm_public_ip.dev-ip.name
  resource_group_name = azurerm_resource_group.dev-rg.name
}