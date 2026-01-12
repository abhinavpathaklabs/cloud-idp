variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type    = string
  default = "cloud-idp"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "allowed_cidr" {
  description = "Your IP/CIDR allowed to access Jenkins (8080) and SSH (22). Example: 1.2.3.4/32"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key content for EC2 access (optional but recommended)."
  type        = string
}

variable "jenkins_instance_type" {
  type    = string
  default = "t3.small"
}

variable "jenkins_policy_arn" {
  type    = string
  default = "arn:aws:iam::aws:policy/AdministratorAccess"
}

variable "eks_version" {
  type    = string
  default = "1.33"
}

variable "tf_state_bucket" {
  type = string
}

variable "tf_lock_table" {
  type = string
}

variable "repo_url" {
  type        = string
  description = "Git repo URL Jenkins should use to load Jenkinsfiles/helm charts (this repo)."
}

variable "repo_branch" {
  type        = string
  description = "Git branch Jenkins should use to load Jenkinsfiles/helm charts."
  default     = "main"
}
