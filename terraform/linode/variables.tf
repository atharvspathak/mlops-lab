variable "linode_token" {
  description = "Linode API token"
  sensitive   = true
}

variable "region" {
  description = "Linode region"
  default     = "in-bom-2"  # Mumbai — closest to Pune
}

variable "project" {
  description = "Project name"
  default     = "mlops-lab"
}

variable "root_password" {
  description = "Root password for VM"
  sensitive   = true
}

variable "dockerhub_username" {
  description = "DockerHub username"
  default     = ""
}
