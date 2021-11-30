data "azurerm_client_config" "current" {
}

data "azurerm_subscription" "current" {
}

resource "azurerm_resource_group" "application" {
  for_each = { for rg in local.azure_resource_groups : rg.name => rg }
  name     = each.key
  location = "UK South"
}

resource "azurerm_role_assignment" "application" {
  for_each             = { for rg in local.azure_resource_groups : rg.name => rg }
  scope                = azurerm_resource_group.application[each.key].id
  role_definition_name = "Owner"
  principal_id         = azuread_service_principal.application[each.key].object_id
}