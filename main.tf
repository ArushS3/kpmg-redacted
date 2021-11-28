terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=2.56.0"
    }
  }
  required_version = ">=0.14.9"
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
tenant_id = "XXXXXXX-XXXX-XXXX-XXXXXXXXXX"
  features {}
}

## Resource Group for resources to be created
resource "azurerm_resource_group" "kpmg-rg" {
  name     =var.resource_group_name
  location = var.location
}
## Front end availability set
resource "azurerm_availability_set" "frontend" {
  name                = "${var.prefix}-fas"
  location            = var.location
  resource_group_name = azurerm_resource_group.kpmg-rg.name

}
## virtual network with three subnets
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.kpmg-rg.name
}

resource "azurerm_subnet" "web" {
  name                 = "${var.prefix}-web"
  resource_group_name  = azurerm_resource_group.kpmg-rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

resource "azurerm_subnet" "app" {
  name                 = "${var.prefix}-app"
  resource_group_name  = azurerm_resource_group.kpmg-rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
  depends_on = [
    azurerm_subnet.web
  ]
}

resource "azurerm_subnet" "db" {
  name                 = "${var.prefix}-db"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.kpmg-rg.name
  address_prefixes     = ["10.0.3.0/24"]
  depends_on = [
    azurerm_subnet.app
  ]
}
resource "azurerm_network_interface" "web-nic-interface" {
    depends_on = [
      azurerm_subnet.web
    ]
    name               = "${var.prefix}-web-nic"
    resource_group_name = azurerm_resource_group.kpmg-rg.name
    location = var.location

    ip_configuration{
        name = "${var.prefix}-ipconfig1"
        subnet_id = azurerm_subnet.web.id
        private_ip_address_allocation = "Dynamic"
    }
}

resource "azurerm_virtual_machine" "web-vm" {
  name = "${var.prefix}-webVM"
  location = var.location
  resource_group_name = azurerm_resource_group.kpmg-rg.name
  network_interface_ids = [azurerm_network_interface.web-nic-interface.id]
  availability_set_id = azurerm_availability_set.frontend.id
  vm_size = "Standard_D2s_v3"
  delete_os_disk_on_termination = true
  
  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name = "web-disk"
    caching = "ReadWrite"
    create_option = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name = "${var.prefix}-webServer"
    admin_username = var.username
    admin_password = var.password
  }



  os_profile_linux_config {
    disable_password_authentication = false
  }
}

 resource "azurerm_availability_set" "backend" {
  name                = "${var.prefix}-bas"
  location            = var.location
  resource_group_name = azurerm_resource_group.kpmg-rg.name
 }

resource "azurerm_network_interface" "app-nic-interface" {
    depends_on = [
      azurerm_subnet.app
    ]
    name = "${var.prefix}-nic"
    resource_group_name = azurerm_resource_group.kpmg-rg.name
    location = var.location

    ip_configuration{
        name = "${var.prefix}-ipconfig2"
        subnet_id = azurerm_subnet.app.id
        private_ip_address_allocation = "Dynamic"
    }
}

resource "azurerm_virtual_machine" "app-vm" {
  name = "app-vm"
  location = var.location
  resource_group_name = azurerm_resource_group.kpmg-rg.name
  network_interface_ids = [ azurerm_network_interface.app-nic-interface.id ]
  availability_set_id = azurerm_availability_set.backend.id
  vm_size = "Standard_D2s_v3"
  delete_os_disk_on_termination = true
  
  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name = "app-disk"
    caching = "ReadWrite"
    create_option = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name = "${var.prefix}-appServer"
    admin_username = var.username
    admin_password = var.password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

resource "azurerm_sql_server" "database" {
    name = "${var.prefix}-db"
    resource_group_name = azurerm_resource_group.kpmg-rg.name
    location = var.location
    version = "12.0"
    administrator_login = var.database_admin
    administrator_login_password = var.database_password
}

resource "azurerm_sql_database" "db" {
  name                = "db"
  resource_group_name = azurerm_resource_group.kpmg-rg.name
  location            = var.location
  server_name         = azurerm_sql_server.database.name
  depends_on = [
   azurerm_sql_server.database
 ] 
}

resource "azurerm_network_security_group" "frontend-nsg" {
  name                = "${var.prefix}-web-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.kpmg-rg.name
  
  security_rule {
    name                       = "ssh-rule-1"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "22"
  }
  
  security_rule {
    name                       = "ssh-rule-2"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_address_prefix      = "10.0.3.0/24"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "22"
}
}

resource "azurerm_subnet_network_security_group_association" "frontend-nsg-subnet" {
  subnet_id                 = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.frontend-nsg.id
  depends_on = [
    azurerm_subnet.web
  ]
}

resource "azurerm_network_security_group" "backend-nsg" {
    name = "${var.prefix}-app-nsg"
    location = var.location
    resource_group_name = azurerm_resource_group.kpmg-rg.name
    depends_on = [
      azurerm_subnet.app
    ]

    security_rule {
        name = "ssh-rule-1"
        priority = 100
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_address_prefix = "10.0.1.0/24"
        source_port_range = "*"
        destination_address_prefix = "*"
        destination_port_range = "22"
    }
    
    security_rule {
        name = "ssh-rule-2"
        priority = 101
        direction = "Outbound"
        access = "Allow"
        protocol = "Tcp"
        source_address_prefix = "10.0.1.0/24"
        source_port_range = "*"
        destination_address_prefix = "*"
        destination_port_range = "22"
    }
}

resource "azurerm_subnet_network_security_group_association" "backend-nsg-subnet" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.backend-nsg.id
  depends_on = [
    azurerm_subnet.app
  ]
}

resource "azurerm_network_security_group" "db-nsg" {
    name = "${var.prefix}-db-nsg"
    location = var.location
    resource_group_name = azurerm_resource_group.kpmg-rg.name

    security_rule {
        name = "ssh-rule-1"
        priority = 101
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_address_prefix = "10.0.2.0/24"
        source_port_range = "*"
        destination_address_prefix = "*"
        destination_port_range = "3306"
    }
    
    security_rule {
        name = "ssh-rule-2"
        priority = 102
        direction = "Outbound"
        access = "Allow"
        protocol = "Tcp"
        source_address_prefix = "10.0.2.0/24"
        source_port_range = "*"
        destination_address_prefix = "*"
        destination_port_range = "3306"
    }
    
    security_rule {
        name = "ssh-rule-3"
        priority = 100
        direction = "Outbound"
        access = "Deny"
        protocol = "Tcp"
        source_address_prefix = "10.0.1.0/24"
        source_port_range = "*"
        destination_address_prefix = "*"
        destination_port_range = "3306"
    }
}

resource "azurerm_subnet_network_security_group_association" "db-nsg-subnet" {
  subnet_id                 = azurerm_subnet.db.id
  network_security_group_id = azurerm_network_security_group.db-nsg.id
  depends_on = [
    azurerm_subnet.db
  ]
}

