terraform {
  required_version = ">= 1.5.0"
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.162.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4.0"
    }
  }
}

locals {
  secrets = yamldecode(file("${path.module}/../secrets/terraform.yaml"))
}

provider "yandex" {
  cloud_id  = local.secrets.cloud_id
  folder_id = local.secrets.folder_id
  token     = local.secrets.yc_token
}

# --- Тянем сеть/подсети/SG из infra ---
data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    endpoints = { s3 = "https://storage.yandexcloud.net" }
    bucket    = "marchenko-final-tfstate"
    region    = "ru-central1"
    key       = "infra/terraform.tfstate"

    profile                     = "yc-marchenko"
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
  }
}

locals {
  network_id = data.terraform_remote_state.infra.outputs.network_id
  subnet_ids = tolist(data.terraform_remote_state.infra.outputs.subnet_ids)    # [a, b, d]
  infra_sg   = data.terraform_remote_state.infra.outputs.security_group_id
  zones      = ["ru-central1-a", "ru-central1-b", "ru-central1-d"]
  project    = local.secrets.project_name

  # В 'd' нет standard-v1 — используем v3
  platform_per_zone = {
    "ru-central1-a" = "standard-v1"
    "ru-central1-b" = "standard-v1"
    "ru-central1-d" = "standard-v3"
  }
}

# --- SG для полного внутреннего трафика кластера + общий egress ---
resource "yandex_vpc_security_group" "k8s_internal" {
  name       = "${local.project}-selfk8s-internal"
  network_id = local.network_id

  egress {
    protocol       = "ANY"
    description    = "Allow all egress"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol          = "ANY"
    description       = "All traffic within SG"
    predefined_target = "self_security_group"
  }
}

# --- Базовый образ Ubuntu 22.04 LTS ---
data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

# --- 3 узла: 1 control-plane + 2 worker ---
locals {
  nodes = {
    cp1 = { zone = local.zones[0], subnet_id = local.subnet_ids[0], role = "cp"     }
    w1  = { zone = local.zones[1], subnet_id = local.subnet_ids[1], role = "worker" }
    w2  = { zone = local.zones[2], subnet_id = local.subnet_ids[2], role = "worker" }
  }
}

resource "yandex_compute_instance" "k8s" {
  for_each    = local.nodes
  name        = "${local.project}-${each.key}"
  platform_id = local.platform_per_zone[each.value.zone]
  zone        = each.value.zone

  resources {
    cores         = var.node_cores
    core_fraction = var.node_core_fraction
    memory        = each.value.role == "cp" ? var.cp_memory_gb : var.node_memory_gb
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = var.disk_gb
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = each.value.subnet_id
    nat                = true
    security_group_ids = [
      local.infra_sg,                             # 22/80/443/6443 из infra
      yandex_vpc_security_group.k8s_internal.id   # полный внутренний трафик
    ]
  }

  scheduling_policy {
    preemptible = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("${path.module}/../secrets/vm-key.pub")}"
  }
}

# --- Inventory для Kubespray (hosts.yaml) ---
locals {
  inv_cp1_pub = yandex_compute_instance.k8s["cp1"].network_interface[0].nat_ip_address
  inv_cp1_int = yandex_compute_instance.k8s["cp1"].network_interface[0].ip_address
  inv_w1_pub  = yandex_compute_instance.k8s["w1"].network_interface[0].nat_ip_address
  inv_w1_int  = yandex_compute_instance.k8s["w1"].network_interface[0].ip_address
  inv_w2_pub  = yandex_compute_instance.k8s["w2"].network_interface[0].nat_ip_address
  inv_w2_int  = yandex_compute_instance.k8s["w2"].network_interface[0].ip_address
}

resource "local_file" "kubespray_inventory" {
  filename = "${path.module}/inventory/hosts.yaml"
  content  = templatefile("${path.module}/templates/hosts.yaml.tmpl", {
    cp1_pub = local.inv_cp1_pub
    cp1_int = local.inv_cp1_int
    w1_pub  = local.inv_w1_pub
    w1_int  = local.inv_w1_int
    w2_pub  = local.inv_w2_pub
    w2_int  = local.inv_w2_int
  })
}

# --- Переменные размеров ---
variable "node_cores" {
  type    = number
  default = 2
}

variable "node_core_fraction" {
  type    = number
  default = 20
}

variable "cp_memory_gb" {
  type    = number
  default = 4
}

variable "node_memory_gb" {
  type    = number
  default = 2
}

variable "disk_gb" {
  type    = number
  default = 20
}

# --- Outputs ---
output "public_ips" {
  value = {
    cp1 = local.inv_cp1_pub
    w1  = local.inv_w1_pub
    w2  = local.inv_w2_pub
  }
}

output "private_ips" {
  value = {
    cp1 = local.inv_cp1_int
    w1  = local.inv_w1_int
    w2  = local.inv_w2_int
  }
}
