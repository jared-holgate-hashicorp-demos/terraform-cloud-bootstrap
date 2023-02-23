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
  features {}
}

provider "tfe" {
}

provider "github" {
  owner = var.github_organisation
}

provider "azuread" {
}
