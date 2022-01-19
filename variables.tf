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
    vcs_integrated : bool
    github_repo_team_access : list(string)
  }))
  default = [
    {
      name = "demo-one"
      environments = [
        {
          name                        = "dev"
          reviewers_users             = []
          reviewers_teams             = []
          create_azure_resource_group = true
        },
        {
          name                        = "test"
          reviewers_users             = ["jaredfholgate"]
          reviewers_teams             = []
          create_azure_resource_group = true
        },
        {
          name                        = "prod"
          reviewers_users             = []
          reviewers_teams             = ["tester_team"]
          create_azure_resource_group = true
        }
      ]
      create_github_repo      = true
      vcs_integrated          = false
      github_repo_team_access = ["tester_team"]
    },
    {
      name = "demo-two"
      environments = [
        {
          name                        = "dev"
          reviewers_users             = []
          reviewers_teams             = []
          create_azure_resource_group = true
        },
        {
          name                        = "test"
          reviewers_users             = ["jaredfholgate"]
          reviewers_teams             = []
          create_azure_resource_group = true
        },
        {
          name                        = "prod"
          reviewers_users             = []
          reviewers_teams             = ["tester_team"]
          create_azure_resource_group = true
        }
      ]
      create_github_repo      = true
      vcs_integrated          = true
      github_repo_team_access = ["tester_team"]
    }
  ]
}

variable "prefix" {
  type    = string
  default = "jared-holgate"
}

variable "github_token" {
  type    = string
  default = ""
}