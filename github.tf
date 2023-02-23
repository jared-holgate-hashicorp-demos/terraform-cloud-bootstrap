data "github_user" "current" {
  for_each = { for reviewer_user in local.github_users : reviewer_user => reviewer_user }
  username = each.key
}

data "github_team" "current" {
  for_each = { for reviewer_team in local.github_teams : reviewer_team => reviewer_team }
  slug     = each.key
}

resource "github_repository" "application" {
  for_each    = { for repo in local.github_repositories : "${var.prefix}-${repo.name}" => repo }
  name        = each.key
  description = "Demonstration ${each.key}"

  visibility         = "public"
  gitignore_template = "Terraform"

  template {
    owner      = each.value.github_repository.template.organisation
    repository = each.value.github_repository.template.repository
  }
}

resource "github_team_repository" "application" {
  for_each   = { for access in local.gitub_team_access : "${access.repo_name}-${access.team_name}" => access }
  team_id    = data.github_team.current[each.value.team_name].id
  repository = github_repository.application[each.value.repo_name].name
  permission = each.value.permission
}

resource "github_repository_environment" "application" {
  depends_on = [
    github_team_repository.application
  ]
  for_each    = { for env in local.github_environments : env.name => env }
  repository  = github_repository.application[each.value.application_name].name
  environment = each.value.environment.name

  reviewers {
    users = [for reviewer_user in each.value.environment.github_environment.reviewers_users : data.github_user.current[reviewer_user].id]
    teams = [for reviewer_team in each.value.environment.github_environment.reviewers_teams : data.github_team.current[reviewer_team].id]
  }
}

resource "github_actions_environment_secret" "terraform_api_token" {
  for_each        = { for env in local.github_environments : env.name => env }
  repository      = github_repository.application[each.value.application_name].name
  environment     = github_repository_environment.application[each.key].environment
  secret_name     = "TF_API_TOKEN"
  plaintext_value = tfe_team_token.application[each.key].token
}

resource "github_actions_environment_secret" "terraform_name" {
  for_each        = { for env in local.github_environments : env.name => env }
  repository      = github_repository.application[each.value.application_name].name
  environment     = github_repository_environment.application[each.key].environment
  secret_name     = "TF_NAME"
  plaintext_value = "${github_repository.application[each.value.application_name].name}-each.key}"
}
