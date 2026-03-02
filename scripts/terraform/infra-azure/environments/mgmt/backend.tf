/*
Azure RM backend for storing Terraform state remotely.
Replace the placeholder values below or supply them at init time with
`terraform init -backend-config="key=value"`.
*/

terraform {
	backend "azurerm" {
		# Replace these values or pass them via -backend-config during `terraform init`
		resource_group_name  = var.rg_name
		storage_account_name = var.storage_account_name
		container_name       = var.container_name
		key                  = "CorpoInfrastructure/scripts/terraform/terraform.tfstate"

		# Optional: tenant/subscription if you want to pin them here.
		# It's often better to pass sensitive values via -backend-config or env vars.
		# tenant_id       = "<TENANT_ID>"
		# subscription_id = "<SUBSCRIPTION_ID>"
	}
}

