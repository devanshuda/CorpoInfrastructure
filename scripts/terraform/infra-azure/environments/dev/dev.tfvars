/************************************************************************************
Terraform TFVARS File:
This file contains variable definitions for Terraform configurations.
************************************************************************************/

// Resource Groups values
resource_groups = {
  "rg-cc-01" = {
    rg_name  = "rg-cc-dev-01"
    location = "eastus"
  }
  "rg-cc-02" = {
    rg_name  = "rg-cc-dev-02"
    location = "eastus2"
  }    
}

// Network Security Groups values
network_security_groups = {
  "nsg-cc-01" = {
    nsg_name = "nsg-cc-dev-01"
    rg_key   = "rg-cc-01"   // Reference to the Resource Group key in resource_groups map
  }
  "nsg-cc-02" = {
    nsg_name = "nsg-cc-dev-02"
    rg_key   = "rg-cc-02"   // Reference to the Resource Group key in resource_groups map
  }    
}