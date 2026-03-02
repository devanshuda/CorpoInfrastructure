/*** The following variables are defined for Terraform modules and configurations  ***/

// Define the Subscription ID variable
variable "subscription_id" {
  description = "The Subscription ID for the Azure resources."
  type        = string
}

// Define a map variable for multiple Resource Groups
variable "resource_groups" {
  description = "A map of Resource Groups to create."
  type = map(object({
    rg_name  = string
    location = string
  }))
}

// Define a map variable for multiple Network Security Groups
variable "network_security_groups" {    
  description = "A map of Network Security Groups to create."
  type = map(object({
    nsg_name = string
    rg_key   = string   // Key to reference the Resource Group in resource_groups map  
    })) 
}