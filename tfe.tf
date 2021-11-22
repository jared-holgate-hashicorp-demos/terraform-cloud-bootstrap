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