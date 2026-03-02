/*
  variables_comment_block.tf

  Purpose:
  - Example comment block for `variables.tf` explaining workspace and
      subscription handling, variable overrides, backend notes and security.

  How to use:
  - Copy this comment block to the top of `variables.tf` or include it as
    a separate file in your repo for reference.
  - Prefer workspace-specific tfvars (e.g., `dev.tfvars`) or environment
    variables (`TF_VAR_subscription_id`) for per-environment values.

  Recommended patterns:
  - Use Terraform workspaces for environment separation and map values by
    workspace:

      locals {
        subscription_ids = {
          dev  = "<dev-sub-id>"
          prod = "<prod-sub-id>"
        }
      }

      # then consume with:
      # subscription_id = local.subscription_ids[terraform.workspace]

  - Alternatively, keep a `subscriptions.tfvars` (not committed if it contains
    sensitive values) and pass it with `-var-file` during CI/CD runs.

  Backend note:
  - Initialize the remote backend with the correct backend config:

      terraform init \
        -backend-config="resource_group_name=rg-terraform-state" \
        -backend-config="storage_account_name=tfstatecorpo2026" \
        -backend-config="container_name=tfstate" \
        -backend-config="key=CorpoInfrastructure/scripts/terraform/terraform.tfstate"

  Security:
  - Do NOT commit credentials, secrets, or subscription keys into source control.
    Use the CI/CD secret store, environment variables, or Azure Managed Identities.
*/
