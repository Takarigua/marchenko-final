output "network_id" {
  value = yandex_vpc_network.this.id
}

output "subnet_ids" {
  value = [
    yandex_vpc_subnet.a.id,
    yandex_vpc_subnet.b.id,
    yandex_vpc_subnet.d.id
  ]
}

output "security_group_id" {
  value = yandex_vpc_security_group.this.id
}
