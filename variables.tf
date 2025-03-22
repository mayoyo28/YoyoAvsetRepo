#############################################################################
# VARIABLES
#############################################################################

variable "resource_group_name" {
  type        = string
  default     = "rg-mawofolajin-training-cc-001"
}
 
variable "location" {
  type        = string
  default     = "East US"
}
 
variable "vnet_name" {
  type        = string
  default     = "vnet-yoyoavset-001"
}
 
variable "subnet_name" {
  type        = string
  default     = "subnet-yoyoavset-001"
}
 
variable "address_space" {
  description = "The address space for the VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}
 
variable "subnet_prefix" {
  description = "The address prefix for the Subnet"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "public_ip"{
    default = "pip-web-yoyoazset"
}
 
variable "admin_username" {
  type        = string
  default     = "adminuser"
}
 
variable "key_vault_name"{
    default = "kv2-vm-yoyoavset"
}
 
variable "vm_size" {
  description = "The size of the VMs"
  type        = string
  default     = "Standard_DS1_v2"
}
 
variable "vm_names" {
  description = "List of VM names"
  type        = list(string)
  default     = ["vm1-yoyoavset", "vm2-yoyoavset"]
}
 
variable "nic_names" {
  description = "List of NIC names"
  type        = list(string)
  default     = ["nic-vm1-yoyoavset", "nic-vm2-yoyoavset"]

}

variable "network_security_group"{
    default = "nsg-vm-web-yoyo"
}

 