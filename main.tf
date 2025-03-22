#############################################################################
# TERRAFORM CONFIG AND PROVIDERS
#############################################################################

provider "azurerm" {
  features {}
}
 
 terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.75"
    }
  }
}

#############################################################################
# Key Vault RESOURCES
#############################################################################

# This Terraform data source provided by the AzureRM (Azure Provider for Terraform) is used to query and
# retrieve the Azure Client Configuration (e.g. Tenant ID, Subscription ID and other authentication-related information)
data "azurerm_client_config" "current" {}

# Keyvault Creation
resource "azurerm_key_vault" "kv2" {
  name                        = var.key_vault_name
  location                    = var.location
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Create",
      "Get",
    ]

    secret_permissions = [
      "Set",
      "Get",
      "Delete",
      "Purge",
      "List",
      "Recover"
    ]

    # storage_permissions = [
    #   "get",
    # ]
  }
    
}

#Create KeyVault VM password
resource "random_password" "vmpassword" {
  length = 20
  special = true
}


#Create Key Vault Secret for VM Username
resource "azurerm_key_vault_secret" "vmusername" {
  name         = "vmuser-login"
  value        = var.admin_username
  key_vault_id = azurerm_key_vault.kv2.id
  depends_on = [ azurerm_key_vault.kv2 ]
}

#Create Key Vault Secret for VM Password
resource "azurerm_key_vault_secret" "vmpassword" {
  name         = "vmpassword"
  value        = random_password.vmpassword.result
  key_vault_id = azurerm_key_vault.kv2.id
  depends_on = [ azurerm_key_vault.kv2 ]
}

#############################################################################
# AVAILABILITY SET RESOURCE DEPLOYMENT
#############################################################################

resource "azurerm_availability_set" "avail-set2" {
  name                = "av-set-web"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = {
    environment = "web"
  }
}
#############################################################################
# VIRTUAL NETWORK COMPONENTS RESOURCE DEPLOYMENT - VNET, PUBLIC IP, NIC, NSG
#############################################################################
 
resource "azurerm_virtual_network" "example2" {
  name                = var.vnet_name
  address_space       = var.address_space
  location            = var.location
  resource_group_name = var.resource_group_name
}
 
resource "azurerm_subnet" "example" {
  name                 = var.subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.example2.name
  address_prefixes     = var.subnet_prefix
}

resource "azurerm_public_ip" "pip3" {
  count                   = 2
  name                    = "${var.public_ip}-${count.index}"
  location                = var.location
  resource_group_name  = var.resource_group_name
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 30
}

resource "azurerm_network_interface" "nic" {
  count               = 2
  name                = var.nic_names[count.index]
  location            = var.location
  resource_group_name = var.resource_group_name
 
  ip_configuration {
    name                          = "ipconfig${count.index + 1}"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
  }
}

  resource "azurerm_network_security_group" "yoyoavset" {
  name                = var.network_security_group
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                        = "allow-rdp"
    priority                    = 100
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "*"
    destination_port_range      = "3389"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
}
}




#############################################################################
# VIRTUAL MACHINE RESOURCE DEPLOYMENT
#############################################################################

resource "azurerm_windows_virtual_machine" "vm" {
  count                 = 2
  name                  = var.vm_names[count.index]
  depends_on = [ azurerm_key_vault.kv2 ]
  resource_group_name   = var.resource_group_name
  location              = var.location
  size                  = var.vm_size
  admin_username      = azurerm_key_vault_secret.vmusername.name
  admin_password      = azurerm_key_vault_secret.vmpassword.value
  network_interface_ids = [azurerm_network_interface.nic[count.index].id]
  availability_set_id = azurerm_availability_set.avail-set2.id
 
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
 
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_availability_set" "yoyo-avset" {
  name                         = "web-tier-avset"
  location                     = var.location
  resource_group_name  = var.resource_group_name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}