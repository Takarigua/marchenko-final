## Этап 1. Bootstrap (хранилище состояния Terraform)
- Создал сервисный аккаунт для Terraform и сгенерировал S3-ключи.
- Поднял S3-бакет `marchenko-final-tfstate` в Object Storage под Terraform state.
- Выдал IAM-права на бакет. Теперь `terraform apply/destroy` идут без ручных шагов, стейт хранится централизованно.

## Этап 2. Базовая инфраструктура (infra)
- Создал VPC и три подсети в зонах `ru-central1-a/b/d`.
- Настроил security group с базовыми правилами (22/80/443/6443 + полный egress).
- Состояние Terraform вынес в Object Storage (S3 backend). Зафиксировал outputs: `network_id`, `subnet_ids[]`, `security_group_id`.

## Этап 3. Kubernetes на своих ВМ (self-hosted)
- Поднял 3 ВМ (1 master + 2 worker) в разных зонах (`a/b/d`) через Terraform.
  Все ноды **preemptible**, **20% vCPU**, диски 20 ГБ — эконом-профиль.
- Автоматически сгенерировал Ansible-инвентарь для Kubespray (использую `access_ip` = приватный адрес).
- Развернул кластер через Kubespray (containerd, Calico, CoreDNS, etcd/kubeadm).
- Получил kubeconfig для локального доступа (сертификат apiserver включает публичный IP мастера).
- Проверка:
kubectl get nodes -o wide
kubectl get pods -A
