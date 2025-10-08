output "tf_sa_id" {
  value = yandex_iam_service_account.tf-sa.id
}

output "tf_sa_access_key" {
  value = yandex_iam_service_account_static_access_key.tf-sa-static-key.access_key
}

output "tf_sa_secret_key" {
  value     = yandex_iam_service_account_static_access_key.tf-sa-static-key.secret_key
  sensitive = true
}

output "bucket" {
  value = yandex_storage_bucket.tfstate.bucket
}
