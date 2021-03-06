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
  token = var.github_token
  owner = var.github_organisation
}

provider "azuread" {
}