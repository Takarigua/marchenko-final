terraform {
  required_version = ">= 1.5.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.162.0"
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

# --- VPC ---
resource "yandex_vpc_network" "this" {
  name = "${local.secrets.project_name}-network"
}

# --- Subnets ---
resource "yandex_vpc_subnet" "a" {
  name           = "${local.secrets.project_name}-subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.this.id
  v4_cidr_blocks = ["10.10.1.0/24"]
}

resource "yandex_vpc_subnet" "b" {
  name           = "${local.secrets.project_name}-subnet-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.this.id
  v4_cidr_blocks = ["10.10.2.0/24"]
}

resource "yandex_vpc_subnet" "d" {
  name           = "${local.secrets.project_name}-subnet-d"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.this.id
  v4_cidr_blocks = ["10.10.3.0/24"]
}

# --- Security group ---
resource "yandex_vpc_security_group" "this" {
  name       = "${local.secrets.project_name}-sg"
  network_id = yandex_vpc_network.this.id

  # outbound: всё наружу разрешено
  egress {
    protocol       = "ANY"
    description    = "Allow all egress"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # inbound: SSH
  ingress {
    protocol       = "TCP"
    description    = "SSH"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # inbound: Kubernetes API
  ingress {
    protocol       = "TCP"
    description    = "Kubernetes API"
    port           = 6443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # inbound: HTTP/HTTPS (на будущее для ingress/grafana)
  ingress {
    protocol       = "TCP"
    description    = "HTTP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "HTTPS"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
