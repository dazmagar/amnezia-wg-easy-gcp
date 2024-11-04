variable "user" {
  type = string
}

variable "privatekeypath" {
  type = string
}

variable "instance_ip" {}

variable "wg_host" {
  type = string
}

variable "wg_password" {
  type = string
}

variable "enable_wg_configs" {
  type    = bool
  default = false
}
