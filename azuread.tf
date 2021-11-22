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