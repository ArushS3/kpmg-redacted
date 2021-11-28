variable "resource_group_name" {
  description = "The name of the resource group in which the resources will be created."
  default     = "azure-rg"   

}

variable "location" {
  description = "metadata of resources created"
  type = string
  default = "East US"
}

variable "prefix" {
  default = "tech-challenge-kpmg"
}

variable "username" {
  type = string
  default = "kpmg_webuser"

}

variable "password" {
  type = string
  default = "Kpmg@123456#"
}

variable "database_admin" {
  type = string
  default = "mradministrator"
}
  
variable "database_password" {
  type = string
  default = "thisIsDog11"
}