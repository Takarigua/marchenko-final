terraform {
  required_version = ">= 1.5.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.162.0"
    }
  }
}

# Читаем секреты из yaml
locals {
  secrets = yamldecode(file("${path.module}/../secrets/terraform.yaml"))
}

provider "yandex" {
  cloud_id  = local.secrets.cloud_id
  folder_id = local.secrets.folder_id
  token     = local.secrets.yc_token
}

# Сервисный аккаунт для Terraform
resource "yandex_iam_service_account" "tf-sa" {
  name        = "${local.secrets.project_name}-tf-sa"
  description = "Service account for Terraform state management"
}

# Назначаем права этому аккаунту (например, editor на каталог)
resource "yandex_resourcemanager_folder_iam_member" "tf-sa-editor" {
  folder_id = local.secrets.folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.tf-sa.id}"
}

# Генерируем статический ключ доступа (для Object Storage)
resource "yandex_iam_service_account_static_access_key" "tf-sa-static-key" {
  service_account_id = yandex_iam_service_account.tf-sa.id
  description        = "Static key for Terraform backend"
}

# Создаём бакет для хранения стейта
resource "yandex_storage_bucket" "tfstate" {
  access_key = yandex_iam_service_account_static_access_key.tf-sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.tf-sa-static-key.secret_key

  bucket = "${local.secrets.project_name}-tfstate"
  acl    = "private"

  anonymous_access_flags {
    read = false
    list = false
  }
}
