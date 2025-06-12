variable "private_key" {
  type = string
  description = "Путь к вашему локальному приватный SSH-ключу"
  default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOYspe8XbSYQTqZ5Hz0euSC3zwD0nRVGqEou/T4tGNXn travitskii@ubuntu22"
  sensitive = true
}

variable "cloud_id" {
  type    = string
  default = "b1gronbt07tj612mes6j"
}

variable "folder_id" {
  type    = string
  default = "b1gluqrau3c21a35g0kp"
}
