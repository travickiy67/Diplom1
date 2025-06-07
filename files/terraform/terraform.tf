terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">=0.14"
}

provider "yandex" {
  token     = "*********************************************"
  cloud_id  = "*************************"
  folder_id = "***********************"

}
