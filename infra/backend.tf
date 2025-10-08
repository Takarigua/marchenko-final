terraform {
  backend "s3" {
    endpoints = { s3 = "https://storage.yandexcloud.net" }

    bucket = "marchenko-final-tfstate"
    region = "ru-central1"
    key    = "infra/terraform.tfstate"

    profile                     = "yc-marchenko"
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
  }
}
