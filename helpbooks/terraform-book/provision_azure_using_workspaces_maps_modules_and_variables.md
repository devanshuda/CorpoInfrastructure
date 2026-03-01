# Terraform Concepts Guide
## CorpoInfrastructure Project

This document provides a comprehensive overview of Terraform concepts and patterns implemented in the CorpoInfrastructure project. It serves as a reference guide for understanding Infrastructure as Code (IaC) principles and their application to Azure resource management.

---

## Table of Contents

1. [Introduction to Terraform](#introduction-to-terraform)
2. [Core Concepts](#core-concepts)
3. [Project Architecture](#project-architecture)
4. [Terraform Blocks & Syntax](#terraform-blocks--syntax)
5. [Modules](#modules)
6. [State Management](#state-management)
7. [Workspaces](#workspaces)
8. [Variables & Locals](#variables--locals)
9. [Project-Specific Patterns](#project-specific-patterns)
10. [Best Practices](#best-practices)

---

## Introduction to Terraform

### What is Terraform?

Terraform is an **Infrastructure as Code (IaC)** tool developed by HashiCorp that enables you to define, provision, and manage cloud infrastructure through code. Instead of manually configuring resources through cloud provider consoles, you write declarative configuration files that describe your desired infrastructure state.

### Key Benefits

- **Reproducibility**: Infrastructure is version-controlled and can be recreated identically
- **Scalability**: Easily manage hundreds or thousands of resources
- **Maintainability**: Changes are tracked, reviewed, and auditable
- **Multi-Cloud**: Supports AWS, Azure, GCP, and 1000+ providers through a unified syntax
- **Modularity**: Reusable components across projects

### Declarative vs Imperative

Terraform uses a **declarative approach**: you describe *what* infrastructure you want, not *how* to create it. Terraform determines the steps needed to reach that desired state.

```hcl
# Declarative: You declare the desired state
resource "azurerm_resource_group" "example" {
  name     = "rg-example"
  location = "eastus"
}
# Terraform figures out: create, update, or delete this resource
```

---

## Core Concepts

### 1. Resources

**Resources** are the fundamental building blocks of infrastructure. They represent cloud objects like virtual machines, storage accounts, networks, etc.

```hcl
resource "azurerm_resource_group" "rg" {
  name     = "rg-example"
  location = "eastus"
}
```

**Components:**
- `azurerm_resource_group`: Resource type (provider + resource)
- `rg`: Local resource name (for internal reference)
- `name`, `location`: Arguments (provider-specific properties)

### 2. Providers

**Providers** are plugins that Terraform uses to manage resources on cloud platforms. Each provider has its own resource types and data sources.

```hcl
provider "azurerm" {
  subscription_id = local.subscription_id
  features {}
}
```

**In this project:**
- Provider: `azurerm` (Azure Resource Manager)
- Configuration: Subscription ID from locals
- Features: Empty object (uses provider defaults)

### 3. State File

The **state file** (`terraform.tfstate`) is Terraform's source of truth. It records every resource Terraform manages, their IDs, and current properties.

**Why it matters:**
- Terraform compares desired config (code) vs actual state (state file) to determine changes
- Without it, Terraform doesn't know which resources it created
- Must be secured, backed up, and typically stored remotely

### 4. Backend

A **backend** is where Terraform stores the state file. Backends enable:
- **Remote state**: Share state across team members
- **Locking**: Prevent concurrent modifications
- **Versioning**: Track state history

**In this project:**
- Configured for Azure Storage (commented out in `backend.tf`)
- Must be enabled before production use

### 5. Plan & Apply

Terraform follows a predictable workflow:

```
terraform plan   → Shows proposed changes (dry run)
terraform apply  → Executes changes to infrastructure
```

The plan phase is crucial for safety—you see exactly what will change before applying.

---

## Project Architecture

### Multi-Environment Setup

The Azure Infra Automation with Terraform Workspace project architecture demonstrates **Terraform Workspaces** to manage multiple environments:

```
env-dev    → Development environment
env-staging   → Staging environment
env-prod   → Production environment
```

Each environment:
- Has its own Terraform state file (isolated from other environments)
- Uses separate Azure subscriptions (organization best practice)
- Pulls configuration from dedicated `.tfvars` files (environment-specific values)

### Directory Structure

```
terraform/
├── main.tf                         # Root module: composes modules
├── variables.tf                    # Input variables
├── providers.tf                    # Azure provider config
├── backend.tf                      # State backend config
├── env_dev_values.tfvars          # Dev environment values
├── env_staging_values.tfvars      # Staging environment values
├── env_prod_values.tfvars         # Prod environment values
│
├── modules/
│   ├── base_resources/            # Core resource module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── output.tf
│   │
│   └── network_resources/         # Network resource module
│       ├── main.tf
│       ├── variables.tf
│       └── output.tf
│
└── environment/
    ├── dev/                       # Dev-specific configs
    ├── staging/                   # Staging-specific configs
    └── prod/                      # Prod-specific configs
```

### Workspace-Dependent Configuration

This architecture uses Terraform's `terraform.workspace` to dynamically select environment-specific values:

```hcl
locals {
  subscription_id = {
    "env-dev"    = var.subscription_id_dev
    "env-staging" = var.subscription_id_staging
    "env-prod"   = var.subscription_id_prod
  }[terraform.workspace]
}
```

This pattern allows:
- Single codebase for all environments
- Environment-specific subscriptions
- Consistent resource naming and configuration

---

## Terraform Blocks & Syntax

### HCL Syntax Overview

Terraform uses **HCL (HashiCorp Configuration Language)**, which is readable and intuitive:

```hcl
# Block syntax: block_type "name" { ... }
resource "azurerm_resource_group" "rg" {
  # Argument = value
  name     = "my-rg"
  location = "eastus"
}

# Data source: fetch existing resources
data "azurerm_client_config" "current" {}

# Locals: computed values
locals {
  environment = terraform.workspace
}

# Outputs: return values from modules
output "resource_group_id" {
  value = azurerm_resource_group.rg.id
}
```

### Key Terraform Blocks

| Block | Purpose | Example |
|-------|---------|---------|
| `resource` | Define cloud infrastructure | `resource "azurerm_resource_group" "rg"` |
| `variable` | Input variables | `variable "location" { type = string }` |
| `output` | Return values | `output "id" { value = resource.x.id }` |
| `local` | Computed local values | `locals { name = "${var.prefix}-rg" }` |
| `module` | Reusable components | `module "rg" { source = "./modules/rg" }` |
| `provider` | Cloud provider config | `provider "azurerm" { }` |
| `terraform` | Terraform settings | `terraform { required_version = ">= 1.0" }` |
| `data` | Reference existing resources | `data "azurerm_client_config"` |

---

## Modules

### What are Modules?

**Modules** are reusable, self-contained packages of Terraform configuration. They allow you to:
- Encapsulate complexity
- Promote DRY (Don't Repeat Yourself) principles
- Create reusable components across projects
- Establish clear interfaces (inputs/outputs)

### Module Structure

A module is simply a directory with Terraform files:

```
modules/rg/
├── main.tf           # Resource definitions
├── variables.tf      # Input variables
└── output.tf         # Output values
```

### Using Modules

```hcl
module "rg" {
  source = "./modules/rg"     # Path to module
  
  rg_name = "my-resource-group"
  location = "eastus"
}
```

### Module Calls with `for_each`

The CorpoInfrastructure project uses `for_each` to create multiple instances of modules:

```hcl
module "rg" {
  source      = "./modules/rg"
  
  for_each = var.resource_groups
  rg_name  = each.value.rg_name
  location = each.value.location
}
```

**How it works:**
- `for_each` iterates over a map variable
- `each.key`: Map key (e.g., "rg-cc-01")
- `each.value`: Map value (e.g., object with rg_name and location)
- Creates one module instance per map entry

### Benefits of Modules in This Project

- **Single Source of Truth**: Resource Group logic defined once
- **Consistency**: All RGs created the same way
- **Scalability**: Add new resources by updating `.tfvars` without code changes
- **Testability**: Modules can be tested independently

---

## State Management

### State File Basics

The state file is a JSON file mapping configuration to real resources:

```json
{
  "resources": [
    {
      "type": "azurerm_resource_group",
      "name": "rg",
      "instances": [
        {
          "attributes": {
            "id": "/subscriptions/xxx/resourceGroups/rg-example",
            "name": "rg-example",
            "location": "eastus"
          }
        }
      ]
    }
  ]
}
```

### Why Remote State?

**Local state problems:**
- Not shared across team members
- No built-in backup
- No locking (concurrent changes cause corruption)
- Credentials exposed in plaintext

**Remote state (Azure Storage) provides:**
- Shared access: Team collaboration
- Encryption: Credentials protected
- Locking: Prevents concurrent modifications
- Versioning: Historical snapshots
- Availability: Centralized storage

### Workspace State Isolation

```
terraform.tfstate.d/
├── env-dev/
│   └── terraform.tfstate         # Dev environment state
├── env-staging/
│   └── terraform.tfstate         # Staging environment state
└── env-prod/
    └── terraform.tfstate         # Prod environment state
```

Each workspace maintains its own isolated state file, preventing changes in one environment from affecting others. This is crucial for production safety.

### State Security Best Practices

⚠️ **IMPORTANT**: Never commit `.tfstate` files to version control!

1. Add to `.gitignore`:
   ```
   *.tfstate
   *.tfstate.*
   ```

2. Use remote backends (not local file storage)

3. Enable encryption at rest (Azure Storage encryption)

4. Restrict access using IAM/RBAC

5. Enable state locking to prevent concurrent modifications

---

## Workspaces

### What are Workspaces?

**Workspaces** are separate state storage environments within the same configuration. They allow you to:
- Manage multiple environments with one codebase
- Keep state files isolated
- Reuse the same code for dev, test, prod, etc.

### Default vs Additional Workspaces

```bash
terraform workspace list
# Output:
# default
# env-dev
# env-staging
# env-prod
```

### Switching Workspaces

```bash
# Select a workspace
terraform workspace select env-dev

# The state file used changes:
# terraform.tfstate.d/env-dev/terraform.tfstate
```

### Workspace Usage Pattern

This approach demonstrates how workspaces can dynamically select environment-specific values:

```hcl
provider "azurerm" {
  subscription_id = local.subscription_id  # Uses terraform.workspace
  features {}
}

locals {
  subscription_id = {
    "env-dev"    = var.subscription_id_dev
    "env-staging" = var.subscription_id_staging
    "env-prod"   = var.subscription_id_prod
  }[terraform.workspace]
}
```

### Workspace-Based Workflow

```bash
# Deploy to dev
terraform workspace select env-dev
terraform apply -var-file=env_dev_values.tfvars

# Deploy to prod (same code, different state and subscription)
terraform workspace select env-prod
terraform apply -var-file=env_prod_values.tfvars
```

### Advantages in This Project

✅ Single source of truth for all environments  
✅ Identical resource naming conventions across environments  
✅ Easy to promote changes from dev → mgmt → prod  
✅ Clear separation of state files  
✅ Reduced code duplication  

---

## Variables & Locals

### Variables (Inputs)

**Variables** are input parameters that make configurations flexible and reusable:

```hcl
variable "subscription_id_dev" {
  description = "The Development Subscription ID"
  type        = string
  sensitive   = true         # Prevents output in logs
}

variable "resources_to_create" {
  description = "A map of resources to create"
  type = map(object({
    resource_name = string
    location      = string
  }))
}
```

### Variable Sources (Priority Order)

Variables can be set from multiple sources (last one wins):

1. **Command line**: `terraform apply -var="location=eastus"`
2. **Environment variables**: `TF_VAR_location=eastus`
3. **`.tfvars` files**: `terraform apply -var-file=dev.tfvars`
4. **Auto `.tfvars` files**: `prod.auto.tfvars` (auto-loaded)
5. **Variable defaults**: `variable "x" { default = "value" }`

### Variable Types

```hcl
# Primitive types
variable "region" { type = string }
variable "instance_count" { type = number }
variable "enable_logging" { type = bool }

# Complex types
variable "tags" { type = map(string) }
variable "instances" { type = list(string) }
variable "config" { 
  type = object({
    name  = string
    count = number
  })
}
```

### Locals (Computed Values)

**Locals** are like variables but computed within the configuration. They cannot be overridden from outside:

```hcl
locals {
  # Select appropriate value based on current workspace
  subscription_id = {
    "env-dev"    = var.subscription_id_dev
    "env-staging" = var.subscription_id_staging
    "env-prod"   = var.subscription_id_prod
  }[terraform.workspace]
  
  # Compute common tags for all resources
  common_tags = {
    Environment = terraform.workspace
    ManagedBy   = "Terraform"
    CreatedDate = timestamp()
  }
}
```

### Key Differences

| Feature | Variables | Locals |
|---------|-----------|--------|
| Source | External inputs | Computed internally |
| Override | Yes (via -var, tfvars) | No |
| Use Case | Configuration | Computed values |
| Sensitive Data | Can mark as sensitive | N/A |

### In This Type of Project

**Variables** define flexible inputs:
```hcl
variable "resources_to_create" {
  # Can change per environment via .tfvars
}
```

**Locals** compute environment-specific values:
```hcl
locals {
  subscription_id = { ... }[terraform.workspace]
  # Selected based on current workspace
}
```

---

## Project-Specific Patterns

### Pattern 1: Multi-Subscription Architecture

**Goal**: Manage separate Azure subscriptions for different environments

**Concept**: Use workspace-based lookup to select the correct subscription ID at runtime.

**Implementation Pattern**:
```hcl
# Input subscription IDs for each environment (stored securely via environment variables or tfvars)
variable "subscription_id_dev" { 
  type = string
  sensitive = true 
}
variable "subscription_id_prod" { 
  type = string
  sensitive = true 
}

# Select appropriate subscription based on current workspace
locals {
  subscription_id = {
    "env-dev"  = var.subscription_id_dev
    "env-prod" = var.subscription_id_prod
  }[terraform.workspace]
}

# Provider uses selected subscription
provider "azurerm" {
  subscription_id = local.subscription_id
  features {}
}
```

**Concept Benefits**:
- **Environment Isolation**: Each environment operates independently with separate state and subscriptions
- **Safety**: Prevents accidental changes to prod from dev deployment
- **Security**: Follows principle of least privilege by limiting scope per subscription
- **Auditability**: Resource changes tracked per environment

### Pattern 2: Declarative Resource Creation with Maps

**Goal**: Define infrastructure inventory in data files (`.tfvars`) rather than hardcoding in Terraform code

**Concept**: Use maps and `for_each` to iterate over resources defined in variables, enabling adding/removing infrastructure through configuration files only.

**Implementation Pattern**:
```hcl
# variables.tf - Define the shape of resources
variable "infrastructure_components" {
  type = map(object({
    component_name = string
    region         = string
  }))
  description = "Map of infrastructure components to create"
}

# main.tf - Create resources dynamically based on variable
module "components" {
  for_each = var.infrastructure_components
  source   = "./modules/component"
  
  name   = each.value.component_name
  region = each.value.region
}

# env_prod_values.tfvars - Define actual resources
infrastructure_components = {
  "component-1" = {
    component_name = "primary-component"
    region         = "us-east-1"
  }
  "component-2" = {
    component_name = "secondary-component"
    region         = "us-west-2"
  }
}
```

**Concept Benefits**:
- **Separation of Concerns**: Infrastructure definitions (what) separate from module logic (how)
- **Configuration-Driven**: Add/remove resources by updating variables, not code
- **Inventory**: `.tfvars` files act as infrastructure inventory
- **Flexibility**: Same code works for different resource configurations across environments
- **Reference Pattern**: Keys in maps enable cross-module relationships (e.g., resource B references resource A by key)

### Pattern 3: Cross-Module References Using Keys

**Goal**: Create loose coupling between modules by referencing resources via keys rather than hardcoding dependencies

**Concept**: Store a key/reference in one resource's configuration, then use that key to look up another resource's output.

**Implementation Pattern**:
```hcl
# Module A: creates parent resources
module "parent_resources" {
  for_each = var.parent_configs
  source   = "./modules/parent"
  name     = each.value.name
}

# Module B: child resources that need to reference parents
variable "child_configs" {
  type = map(object({
    child_name  = string
    parent_key  = string  # Reference to parent_configs key
  }))
}

module "child_resources" {
  for_each = var.child_configs
  source   = "./modules/child"
  
  name           = each.value.child_name
  parent_id      = module.parent_resources[each.value.parent_key].resource_id
  parent_name    = module.parent_resources[each.value.parent_key].resource_name
}
```

**Concept Benefits**:
- **Loose Coupling**: Modules don't hardcode relationships; relationships defined in configuration
- **Flexibility**: Easy to compose different combinations of resources
- **Maintainability**: Changes to parent don't require module code updates
- **Scalability**: Add new resource combinations by extending configuration maps

### Pattern 4: Environment-Specific Configurations

**Goal**: Use a single Terraform codebase across multiple environments with environment-specific variable values

**Concept**: Separate code from configuration by maintaining environment-specific `.tfvars` files while keeping infrastructure definitions generic.

**Implementation Pattern**:
```
terraform/
├── main.tf (shared - universal)
├── variables.tf (shared - universal)
├── env_dev_values.tfvars (dev-specific values)
├── env_staging_values.tfvars (staging-specific values)
└── env_prod_values.tfvars (prod-specific values)
```

**Deployment Workflow**:
```bash
# Deploy same code to different environments
terraform workspace select env-dev
terraform apply -var-file=env_dev_values.tfvars

terraform workspace select env-prod
terraform apply -var-file=env_prod_values.tfvars
```

**Concept Benefits**:
- **DRY Principle**: Single codebase reduces duplication
- **Consistency**: Same logic applied to all environments
- **Promotion**: Changes tested in dev, promoted to prod without code rewrites
- **Version Control**: Code and environment-specific configs tracked together
- **Flexibility**: Override any variable per environment via `.tfvars`

---

## Best Practices

### 1. State Management

✅ **DO:**
- Use remote backends in production (Azure Storage, Terraform Cloud)
- Enable state locking
- Enable encryption at rest
- Restrict access with RBAC
- Keep sensitive data in variables marked as `sensitive = true`

❌ **DON'T:**
- Commit `.tfstate` files to version control
- Store state locally in production
- Share state files manually
- Expose credentials in `.tf` files

### 2. Code Organization

✅ **DO:**
- Organize by modules (each module = one logical component)
- Keep root module (`main.tf`) focused on composition
- Use meaningful names: `azurerm_resource_group.app_rg` not `azurerm_resource_group.x`
- Separate inputs (variables.tf) from definitions (main.tf) from outputs (output.tf)

❌ **DON'T:**
- Put everything in one giant `main.tf`
- Create modules for every single resource
- Use cryptic variable names

### 3. Variables & Configurations

✅ **DO:**
- Mark sensitive variables: `sensitive = true`
- Provide descriptions for all variables
- Use complex types (objects, maps) for related configuration
- Store values in `.tfvars` files, not hardcoded
- Version control `.tfvars` files (remove sensitive values)

❌ **DON'T:**
- Put credentials in code
- Use `default` for sensitive values
- Hardcode environment-specific values in `.tf` files

### 4. Documentation

✅ **DO:**
- Add comments explaining complex logic
- Document module purposes
- Keep a README explaining deployment process
- Document variable purposes with descriptions

❌ **DON'T:**
- Leave code without context
- Assume others understand implicit logic

### 5. Workflow

✅ **DO:**
- Always run `terraform plan` before `terraform apply`
- Review plan output carefully
- Use workspaces to isolate environments
- Test changes in dev/test before prod
- Tag resources for cost tracking and organization

❌ **DON'T:**
- Skip the plan phase
- Apply directly without review
- Use the same workspace for multiple environments
- Manually change infrastructure (causes drift)

### 6. Reusability

✅ **DO:**
- Extract common patterns into modules
- Use `for_each` for repetitive resources
- Make modules configurable via variables
- Create a module library for org-wide use

❌ **DON'T:**
- Copy-paste configuration
- Create modules that only work for one specific use case
- Over-engineer modules (YAGNI principle)

### 7. Troubleshooting

**State Drift** (reality ≠ configuration):
```bash
terraform refresh  # Update state from actual resources
terraform plan     # See drift
terraform apply    # Reconcile
```

**Lock Files**:
```bash
terraform force-unlock <lock_id>  # Use cautiously
```

**Plan Inspection**:
```bash
terraform plan -out=tfplan  # Save plan
terraform show tfplan       # Inspect plan details
```

---

## Common Commands Reference

```bash
# Initialization (run once)
terraform init -backend-config="key=value"

# Select environment
terraform workspace select corpo-dev

# Planning & Execution
terraform plan -var-file=dev_values.tfvars
terraform apply -var-file=dev_values.tfvars
terraform destroy -var-file=dev_values.tfvars

# State Management
terraform state list
terraform state show azurerm_resource_group.rg
terraform state rm azurerm_resource_group.rg
terraform refresh

# Workspace Management
terraform workspace new corpo-dev
terraform workspace select corpo-dev
terraform workspace list
terraform workspace delete corpo-dev

# Formatting & Validation
terraform fmt -recursive
terraform validate

# Debugging
terraform plan -out=tfplan
terraform show tfplan
export TF_LOG=DEBUG
```

---

## Conclusion

Key Terraform concepts demonstrated in this type of project:

- **Workspace Management**: Separate state and subscriptions for environment isolation
- **Modular Architecture**: Reusable modules with clear input/output contracts
- **Declarative Configuration**: Infrastructure defined as data (maps) rather than code
- **Dynamic Resource Creation**: `for_each` enables scaling resources without code changes
- **Environment Abstraction**: Single codebase adapted to multiple environments via variables
- **Security Patterns**: Sensitive data marked and managed separately from code

By mastering these patterns, you can build scalable, maintainable infrastructure that grows with your organization while maintaining safety and consistency across environments.

---

## Additional Resources

- [Terraform Official Documentation](https://www.terraform.io/docs)
- [Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices)
- [HCL Syntax Reference](https://www.terraform.io/docs/language)

---

**Last Updated**: 2nd March 2026  
**Content**: Terraform Concepts & Patterns Guide
**Author**: Devanshu Agarwal using Github Copilot