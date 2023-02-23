data "tfe_oauth_client" "application" {
  for_each = { for repo in local.github_repositories : "${var.prefix}-${repo.name}" => repo }
  organization     = var.terraform_organisation
  name             = var.oauth_tokens[each.value.name]
}

resource "tfe_workspace" "application" {
  for_each       = { for workspace in local.environments : workspace.name => workspace }
  name           = each.key
  organization   = var.terraform_organisation
  description    = "Demonstration ${each.key}"
  queue_all_runs = false

  dynamic "vcs_repo" {
    for_each = each.value.vcs_integrated ? [each.value.application_name] : []
    content {
      identifier     = github_repository.application[vcs_repo.value].full_name
      oauth_token_id = tfe_oauth_client.application[vcs_repo.value].oauth_token_id
    }
  }
}

resource "tfe_team" "users" {
  for_each     = { for team in local.config.teams : "${var.prefix}-${team.name}" => team }
  name         = each.key
  organization = var.terraform_organisation
}

data "tfe_organization_membership" "users" {
  for_each     = { for user in distinct(flatten(local.config.teams[*].members)) : user => user }
  organization = var.terraform_organisation
  email        = each.key
}

resource "tfe_team_organization_member" "users" {
  for_each                   = { for team_membership in local.terraform_team_members : "${team_membership.team_name}-${team_membership.member}" => team_membership }
  team_id                    = tfe_team.users[each.value.team_name].id
  organization_membership_id = data.tfe_organization_membership.users[each.value.member].id
}

resource "tfe_team_access" "users" {
  for_each = { for workspace_permission in local.terraform_workspace_team_permissions : "${workspace_permission.workspace_name}-${workspace_permission.team_name}" => workspace_permission }
  permissions {
    runs              = each.value.permissions.permissions.runs
    variables         = each.value.permissions.permissions.variables
    state_versions    = each.value.permissions.permissions.state_versions
    sentinel_mocks    = each.value.permissions.permissions.sentinel_mocks
    workspace_locking = each.value.permissions.permissions.workspace_locking
    run_tasks         = each.value.permissions.permissions.run_tasks
  }
  team_id      = tfe_team.users[each.value.team_name].id
  workspace_id = tfe_workspace.application[each.value.workspace_name].id
}

resource "tfe_team" "application" {
  for_each     = { for workspace in local.environments : workspace.name => workspace }
  name         = "${each.key}-apikey"
  organization = var.terraform_organisation
}

resource "tfe_team_access" "application" {
  for_each     = { for workspace in local.environments : workspace.name => workspace }
  access       = "write"
  team_id      = tfe_team.application[each.key].id
  workspace_id = tfe_workspace.application[each.key].id
}

resource "tfe_team_token" "application" {
  for_each = { for workspace in local.environments : workspace.name => workspace }
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

resource "tfe_variable" "skip_provider_registration" {
  for_each     = { for rg in local.azure_resource_groups : rg.name => rg }
  key          = "ARM_SKIP_PROVIDER_REGISTRATION"
  value        = "true"
  category     = "env"
  workspace_id = tfe_workspace.application[each.key].id
  description  = "Tell the Azure provider to skip provider registration on the subscription"
  sensitive    = false
}
