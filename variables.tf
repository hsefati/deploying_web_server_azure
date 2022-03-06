variable "username" {
  description = "admin username for VM"
}

variable "password" {
  description = "admin password for VM"
}

variable "prefix" {
  description = "The prefix which should be used for all resources in this example"
}

variable "resourceGroupName" {
  description = "Name of already created resource group in Azure"
  default = "test-resources"
}

variable "packerImageName" {
  description = "Image name from packer"
  default = "myPackerImage"
}

variable "vmInstances" {
  description = " Number of virtual machine's instances to be created"
  type = number
  default = 2
}

variable "tagsKey" {
  description = "tags key for resources"
  default = "udacity"
}

variable "tagsValue" {
  description = "tags value for resources"
  default = "test"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
}