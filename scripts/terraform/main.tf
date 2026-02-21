
/*-----------------------
Local Variables
------------------------*/
locals {
  subscription_id = {
    "corpo-dev"  = var.corpodev_sub_id
    "corpo-mgmt" = var.corpomgmt_sub_id 
    "corpo-prod" = var.corpoprod_sub_id
  }[terraform.workspace]
}

/*-----------------------
Resource Groups Module
------------------------*/
module "rg" {
  source      = "./modules/rg"

  for_each = var.resource_groups
  rg_name     = each.value.rg_name
  location    = each.value.location
}

/*------------------------------
Network Security Group Module
-------------------------------*/
module "nsg" {
  source = "./modules/nsg"

  for_each = var.network_security_groups
  nsg_name          = each.value.nsg_name
  rg_name           = module.rg[each.value.rg_key].rg_name
  location          = module.rg[each.value.rg_key].rg_location

}