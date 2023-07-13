Download the terraform.exe to your local workspace and add below files to your directory

a) Create  a provider.tf file and add the provider
here 'azurerm'

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.64.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
}

b)Create the below files 

    i.  main.tf- define your resources/modules. Go through the Steps for exmaples

    ii. variables.tf- define the type & default values of variables used for the modules/resources
        example:
          variable "name" {
            description = "(Required) Resource group name"
            type        = string
            default     = "it"
          }

    iii. terraform.auto.tfvars- pass the values for the variables defined 
          name = "we1-rg-threetierarch"


Steps:

1. Create a resource group
https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group.html
example:
resource "azurerm_resource_group" "example" {
  name     = "example"
  location = "West Europe"
}

2. Create a vnet, 3 nsg and 3 subnets(for web, app & db)
https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network

resource "azurerm_network_security_group" "webnsg" {
  name                = "example-security-group"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}
resource "azurerm_network_security_group" "appnsg" {
  name                = "example-security-group"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}
resource "azurerm_network_security_group" "dbnsg" {
  name                = "example-security-group"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_virtual_network" "vnet" {
  name                = "example-network"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]

  subnet {
    name           = "websubnet"
    address_prefix = "10.0.1.0/24"
  }

  subnet {
    name           = "appsubnet"
    address_prefix = "10.0.2.0/24"
    security_group = azurerm_network_security_group.example.id
  }

  subnet {
    name           = "dbsubnet"
    address_prefix = "10.0.3.0/24"
    security_group = azurerm_network_security_group.example.id
  }

  tags = {
    architecture = "3 tier"
  }
}


3. Create the network security rules for each nsg and associate them to the subnets

Websubnet should Allow inbound/outbound traffic from internet to appsubnet, but should not be able to communicate to dbsubnet
Appsubnet should deny traffic from internet, but should be able to communicate with websubnet and dbsubnet 
Similarly, dbsubnet should deny traffic from internet & websubnet, but should be able to reach dbsubnet


https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule
Example
resource "azurerm_network_security_rule" "example" {
  name                        = "test123"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.example.name
  network_security_group_name = azurerm_network_security_group.example.name
}


4. create web & app VMs & NICs with desired configurations along with availablity sets(if required)
https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine
Example:
resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "main" {
  name                  = "${var.prefix}-vm"
  location              = azurerm_resource_group.example.location
  resource_group_name   = azurerm_resource_group.example.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "20.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    architecture = "3 tier"
  }
}

5. Provision the db resources (for eg: sql server, storage account and sql database)
https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/sql_database
Example:
resource "azurerm_sql_server" "example" {
  name                         = "myexamplesqlserver"
  resource_group_name          = azurerm_resource_group.example.name
  location                     = azurerm_resource_group.example.location
  version                      = "12.0"
  administrator_login          = "4dm1n157r470r"
  administrator_login_password = "4-v3ry-53cr37-p455w0rd"

  tags = {
    environment = "production"
  }
}

resource "azurerm_storage_account" "example" {
  name                     = "examplesa"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_sql_database" "example" {
  name                = "myexamplesqldatabase"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  server_name         = azurerm_sql_server.example.name

  tags = {
    environment = "production"
  }
}

6. Now application will have to deploy the application components and configure it to get it up and running.

