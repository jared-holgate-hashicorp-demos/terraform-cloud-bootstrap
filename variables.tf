variable "prefix" {
  type    = string
  default = "jared-holgate"
}

variable "terraform_organisation" {
  type    = string
  default = "jaredfholgate-hashicorp"
}

variable "github_organisation" {
  type    = string
  default = "jared-holgate-hashicorp-demos"
}

variable "github_token" {
  type      = string
  default   = ""
  sensitive = true
}

variable "configs" {
  type    = list(string)
  default = ["demo-one", "demo-two"]
}