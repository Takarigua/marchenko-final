# Быстрый запуск/проверка

## Bootstrap
* cd ~/marchenko-final/bootstrap
* terraform init
* terraform apply -auto-approve

## Infra (S3 backend)
* cd ~/marchenko-final/infra
* terraform init -reconfigure
* terraform apply -auto-approve
* terraform output

## Self-managed K8s VMs
* cd ~/marchenko-final/selfk8s
* terraform init -reconfigure
* terraform apply -auto-approve
* terraform output public_ips
* terraform output private_ips

## Kubespray (инвентарь уже готов Terraform'ом)
* cd ~/kubespray
* cp ~/marchenko-final/selfk8s/inventory/hosts.yaml inventory/netology/hosts.yaml

ansible-playbook -i inventory/netology/hosts.yaml cluster.yml -b -v \
  --private-key=~/marchenko-final/secrets/vm-key

## kubeconfig локально
* mkdir -p ~/.kube
* cp inventory/netology/artifacts/admin.conf ~/.kube/config
  * если admin.conf указывает на внутренний IP — заменить на публичный:
  * cd ~/marchenko-final/selfk8s
sed -i -E "s#server: https?://[0-9.]+:6443#server: https://$CP1_PUBLIC:6443#g" ~/.kube/config

- проверка
kubectl get nodes -o wide
kubectl get pods -A
