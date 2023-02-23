variable "prefix" {
  type    = string
  default = "tf-lz"
}

variable "terraform_organisation" {
  type    = string
  default = "jared-holgate-microsoft"
}

variable "github_organisation" {
  type    = string
  default = "jared-holgate-hashicorp-demos"
}

variable "oauth_tokens" {
  type = map(string)
  sensitive = true
}

variable "configs" {
  type    = list(string)
  default = ["demo-one", "demo-two"]
}
