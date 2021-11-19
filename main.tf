variable "workspaces" {
  type = list(object({
      name = string
      environments : list(object({
        name : string
        reviewers_users : list(string)
        reviewers_teams : list(string)
        create_azure_resource_group : bool
      }))
      
      create_github_repo : bool
  }))
  default = [
    {
      name = "demo_one"
      environments = [
        {
          name = "dev"
          reviewers_users = []
          reviewers_teams = []
          create_azure_resource_group = true
        },
        {
          name = "test"
          reviewers_users = ["jaredfholgate"]
          reviewers_teams = []
          create_azure_resource_group = true
        },
        {
          name = "prod"
          reviewers_users = []
          reviewers_teams = ["tester_team"]
          create_azure_resource_group = true
        }
      ]
      create_github_repo = true
    }
  ]
}

variable "prefix" {
    type = string
    default = "jared-holgate"
}

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    tfe = {
    }
    github = {
      source = "integrations/github"
    }
    azuread = {
    }
  }

  backend "remote" {
    organization = "jaredfholgate-hashicorp"

    workspaces {
      name = "bootstrap"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "tfe" {
}

provider "github" {
}

provider "azuread" {
}

locals {
  organization = "jaredfholgate-hashicorp"

  github_repositories = [ for workspace in var.workspaces : workspace if workspace.create_github_repo ]

  flattened_workspaces = flatten([ for workspace in var.workspaces : [
      for environment in workspace.environments : {
          name = "${var.prefix}-${workspace.name}-${environment.name}"
          workspace_name = "${var.prefix}-${workspace.name}"
          environment = environment
          create_github_repo = workspace.create_github_repo
        }
     ]
  ])

  github_environments = [ for workspace in local.flattened_workspaces : workspace if workspace.create_github_repo ]
  github_users = flatten([ for env in local.github_environments : env.environment.reviewers_users ])
  github_teams = flatten([ for env in local.github_environments : env.environment.reviewers_teams ])
  azure_resource_groups = [ for workspace in local.flattened_workspaces : workspace if workspace.environment.create_azure_resource_group ]
}

data "azurerm_client_config" "current" {
}

resource "tfe_workspace" "application" {
  for_each     = { for workspace in local.flattened_workspaces : workspace.name => workspace }
  name         = each.key
  organization = local.organization
  description  = "Demonstration ${each.key}"
}

resource "tfe_team" "application" {
  for_each     = { for workspace in local.flattened_workspaces : workspace.name => workspace }
  name         = each.key
  organization = local.organization
}

resource "tfe_team_access" "application" {
  for_each     = { for workspace in local.flattened_workspaces : workspace.name => workspace }
  access       = "write"
  team_id      = tfe_team.application[each.key].id
  workspace_id = tfe_workspace.application[each.key].id
}

resource "tfe_team_token" "application" {
  for_each = { for workspace in local.flattened_workspaces : workspace.name => workspace }
  team_id  = tfe_team.application[each.key].id
}

resource "tfe_variable" "client_secret" {
  for_each     = { for rg in local.azure_resource_groups : rg.name => rg }
  key          = "ARM_CLIENT_SECRET"
  value        = azuread_service_principal_password.application[each.key].value
  category     = "env"
  workspace_id = tfe_workspace.application[each.key].id
  description  = "The Azure Service Principal Client Secret"
  sensitive    = true
}

resource "tfe_variable" "client_id" {
  for_each     = { for rg in local.azure_resource_groups : rg.name => rg }
  key          = "ARM_CLIENT_ID"
  value        = azuread_application.application[each.key].application_id
  category     = "env"
  workspace_id = tfe_workspace.application[each.key].id
  description  = "The Azure Service Principal Client Id"
  sensitive    = true
}

resource "tfe_variable" "tenant_id" {
  for_each     = { for rg in local.azure_resource_groups : rg.name => rg }
  key          = "ARM_TENANT_ID"
  value        = data.azurerm_client_config.current.tenant_id
  category     = "env"
  workspace_id = tfe_workspace.application[each.key].id
  description  = "The Azure Tenant Id"
  sensitive    = true
}

resource "tfe_variable" "subscription_id" {
  for_each     = { for rg in local.azure_resource_groups : rg.name => rg }
  key          = "ARM_SUBSCRIPTION_ID"
  value        = data.azurerm_client_config.current.subscription_id
  category     = "env"
  workspace_id = tfe_workspace.application[each.key].id
  description  = "The Azure Subcription Id"
  sensitive    = true
}

resource "tfe_variable" "client_secret_for_unseal" {
  for_each     = { for rg in local.azure_resource_groups : rg.name => rg }
  key          = "TF_VAR_client_secret_for_unseal"
  value        = azuread_service_principal_password.application[each.key].value
  category     = "env"
  workspace_id = tfe_workspace.application[each.key].id
  description  = "The Azure Client Secret required for unsealing Vault"
  sensitive    = true
}

resource "tfe_variable" "skip_provider_registration" {
  for_each     = { for rg in local.azure_resource_groups : rg.name => rg }
  key          = "ARM_SKIP_PROVIDER_REGISTRATION"
  value        = "true"
  category     = "env"
  workspace_id = tfe_workspace.application[each.key].id
  description  = "Tell the Azure provider to skip provider registration on the subscription"
  sensitive    = false
}

data "github_user" "current" {
    for_each = { for reviewer_user in local.github_users : reviewer_user => reviewer_user}
    username = each.key
}

data "github_team" "current" {
    for_each = { for reviewer_team in local.github_teams : reviewer_team => reviewer_team}
    slug = each.key
}

resource "github_repository" "application" {
  for_each = { for repo in local.github_repositories : "${var.prefix}-${repo.name}" => repo }
  name        = each.key
  description = "Demonstration ${each.key}"

  visibility = "private"
}

resource "github_repository_environment" "application" {
  for_each    = { for env in local.github_environments : env.name => env }
  repository  = each.key
  environment = each.value.environment.name

  reviewers {
    users = [ for reviewer_user in each.value.environment.reviewers_users : data.github_user.current[reviewer_user] ]
    teams = [ for reviewer_team in each.value.environment.reviewers_teams : data.github_team.current[reviewer_team] ]
  }
}

resource "github_actions_environment_secret" "terraform_api_token" {
  for_each    = { for env in local.github_environments : env.name => env }
  repository  = each.key
  environment     = github_repository_environment.application[each.key].environment
  secret_name     = "TF_API_TOKEN"
  plaintext_value = tfe_team_token.application[each.key].token
}

resource "azurerm_resource_group" "application" {
  for_each = { for rg in local.azure_resource_groups : rg.name => rg }
  name     = each.key
  location = "UK South"
}

resource "azuread_application" "application" {
  for_each     = { for rg in local.azure_resource_groups : rg.name => rg }
  display_name = each.key
}

resource "azuread_service_principal" "application" {
  for_each       = { for rg in local.azure_resource_groups : rg.name => rg }
  application_id = azuread_application.application[each.key].application_id
}

resource "azuread_service_principal_password" "application" {
  for_each             = { for rg in local.azure_resource_groups : rg.name => rg }
  service_principal_id = azuread_service_principal.application[each.key].object_id
}

data "azurerm_subscription" "current" {
}

resource "azurerm_role_assignment" "application" {
  for_each             = { for rg in local.azure_resource_groups : rg.name => rg }
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Owner"
  principal_id         = azuread_service_principal.application[each.key].object_id
}