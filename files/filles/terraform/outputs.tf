output "external_ip_addres_load_balancer" {
  value = yandex_alb_load_balancer.nginx-balancer.listener.0.endpoint.0.address.0.external_ipv4_address
}
output "external_ip_address_vm_6_BASTION" {
  value = yandex_compute_instance.bastion.network_interface.0.nat_ip_address

}
output "kibana" {
  value = yandex_compute_instance.kibana.network_interface.0.nat_ip_address
}

output "zabbix" {
  value = yandex_compute_instance.zabbix.network_interface.0.nat_ip_address
}
