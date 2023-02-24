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
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "tfe" {
}

provider "github" {
  owner = var.github_organisation
}

provider "azuread" {
}
