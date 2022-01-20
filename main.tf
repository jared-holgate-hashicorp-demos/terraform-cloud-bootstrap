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
  #token = var.github_token
}

provider "azuread" {
}

locals {
  organization = "jaredfholgate-hashicorp"

  github_repositories = [for workspace in var.workspaces : workspace if workspace.create_github_repo]

  flattened_workspaces = flatten([for workspace in var.workspaces : [
    for environment in workspace.environments : {
      name               = "${var.prefix}-${workspace.name}-${environment.name}"
      workspace_name     = "${var.prefix}-${workspace.name}"
      environment        = environment
      create_github_repo = workspace.create_github_repo
      vcs_integrated     = workspace.vcs_integrated
    }
    ]
  ])

  gitub_team_access = flatten([for repo in local.github_repositories : [
    for team in repo.github_repo_team_access : {
      team_name = team
      repo_name = "${var.prefix}-${repo.name}"
    }]
  ])
  github_environments   = [for workspace in local.flattened_workspaces : workspace if workspace.create_github_repo]
  github_users          = distinct(flatten([for env in local.github_environments : env.environment.reviewers_users]))
  github_teams          = distinct(concat(flatten([for env in local.github_environments : env.environment.reviewers_teams]), flatten([for repo in local.github_repositories : repo.github_repo_team_access])))
  azure_resource_groups = [for workspace in local.flattened_workspaces : workspace if workspace.environment.create_azure_resource_group]
}