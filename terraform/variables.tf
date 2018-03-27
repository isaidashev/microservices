variable key {
  description = "Json credentials file GCP"
  default     = "credentials.json"
}

variable project {
  description = "Project"
  default     = "testing-gitlab-198014"
}

variable region {
  description = "Region"
  default     = "europe-west1"
}

variable instance_name {
  default = "gitlabci"
}

variable public_key_path {
  description = "Path to the public key used for ssh access"
  default     = "~/.ssh/appuser.pub"
}

variable "app-disk-image" {
  description = "Disk image for reddit app"
  default     = "ubuntu-1604-lts"
}

variable zone {
  description = "Zone"
  default     = "europe-west1-d"
}
