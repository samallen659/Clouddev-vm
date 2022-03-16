terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.97.0"
    }
  }
  cloud {
    organization = "sama"

    workspaces {
      name = "Clouddev-vm"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "tls_private_key" "linux_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "linuxkey" {
  filename = "linuxkey.pem"
  content  = tls_private_key.linux_key.private_key_pem
}

# Create a resource group
resource "azurerm_resource_group" "rg_terra" {
  name     = "rg_terra"
  location = "UK south"
}

resource "azurerm_virtual_network" "rg_terra_vnet" {
  name                = "rg_terra_vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg_terra.location
  resource_group_name = azurerm_resource_group.rg_terra.name
}

resource "azurerm_subnet" "rg_terra_subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.rg_terra.name
  virtual_network_name = azurerm_virtual_network.rg_terra_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "linuxPubIP" {
  name                = "linuxPubIP"
  location            = azurerm_resource_group.rg_terra.location
  resource_group_name = azurerm_resource_group.rg_terra.name
  allocation_method   = "Dynamic"

  tags = {
    environment = "Terraform Demo"
  }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "rg_terra_nsg" {
  name                = "rg_terra_nsg"
  location            = "uk south"
  resource_group_name = azurerm_resource_group.rg_terra.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}

resource "azurerm_network_interface" "terraformNIC" {
  name                = "terraformNIC"
  location            = azurerm_resource_group.rg_terra.location
  resource_group_name = azurerm_resource_group.rg_terra.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.rg_terra_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.linuxPubIP.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "terraformNSGAssociation" {
  network_interface_id      = azurerm_network_interface.terraformNIC.id
  network_security_group_id = azurerm_network_security_group.rg_terra_nsg.id
}


resource "azurerm_linux_virtual_machine" "linux_testing" {
  name                = "linuxTesting"
  resource_group_name = azurerm_resource_group.rg_terra.name
  location            = azurerm_resource_group.rg_terra.location
  size                = "Standard_B2s"
  admin_username      = "adminuser"
  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.linux_key.public_key_openssh
  }
  computer_name = "linuxTesting"
  network_interface_ids = [
    azurerm_network_interface.terraformNIC.id,
  ]


  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  depends_on = [
    azurerm_network_interface.terraformNIC,
    tls_private_key.linux_key
  ]
}