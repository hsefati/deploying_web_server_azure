terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/22"]
  location            = var.location
  resource_group_name = var.resourceGroupName
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = var.resourceGroupName
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "main" {
  count = var.vmInstances
  name                = "${var.prefix}-nic-${count.index}"
  resource_group_name = var.resourceGroupName
  location            = var.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    "${var.tagsKey}" = var.tagsValue
  }
}

resource "azurerm_public_ip" "main" {
  name                = "${var.prefix}-PublicIp"
  resource_group_name = var.resourceGroupName
  location            = var.location
  allocation_method   = "Static"

  tags = {
    "${var.tagsKey}" = var.tagsValue
  }
}

resource "azurerm_lb" "main" {
  name                = "${var.prefix}-LoadBalancer"
  location            = var.location
  resource_group_name = var.resourceGroupName

  frontend_ip_configuration {
    name                 = "${var.prefix}-PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.main.id
  }

  tags = {
    "${var.tagsKey}" = var.tagsValue
  }
}

resource "azurerm_lb_backend_address_pool" "main" {
  loadbalancer_id     = azurerm_lb.main.id
  name                = "${var.prefix}-BackEndAddressPool"
}

resource "azurerm_availability_set" "main" {
  name                = "${var.prefix}-availability-set"
  location            = var.location
  resource_group_name = var.resourceGroupName

  tags = {
    "${var.tagsKey}" = var.tagsValue
  }
}

resource "azurerm_network_security_group" "AllowVnetInBound" {
  name                = "AllowAccessToOthemVMsonSubnet"
  location            = var.location
  resource_group_name = var.resourceGroupName

  security_rule {
    name                       = "AllowVnetInBound"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  tags = {
    "${var.tagsKey}" = var.tagsValue
  }
}

resource "azurerm_network_security_group" "DenyInternetAccess" {
  name                = "DenyDirectAccessFromInternet"
  location            = var.location
  resource_group_name = var.resourceGroupName

  security_rule {
    name                       = "DenyInternetAccess"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  tags = {
    "${var.tagsKey}" = var.tagsValue
  }
}

data "azurerm_image" "main" {
  name                = var.packerImageName
  resource_group_name = var.resourceGroupName
}

resource "azurerm_linux_virtual_machine" "main" {
  count = var.vmInstances
  name                            = "${var.prefix}-vm-${count.index}"
  resource_group_name             = var.resourceGroupName
  location                        = var.location
  size                            = "Standard_B1s"
  admin_username                  = var.username
  admin_password                  = var.password
  disable_password_authentication = false
  availability_set_id = azurerm_availability_set.main.id
  network_interface_ids = [element(azurerm_network_interface.main.*.id, count.index)]
  source_image_id = data.azurerm_image.main.id

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  tags = {
    "${var.tagsKey}" = var.tagsValue
  }
}