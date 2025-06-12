 
//____________________(NGINX-1)____________________________________
resource "yandex_compute_instance" "nginx1" {
  name = "nginx1"
  platform_id = "standard-v3"
  zone = "ru-central1-a"
  hostname = "nginx1"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  scheduling_policy {
    preemptible = false
  }

  boot_disk {
    initialize_params {
      image_id = "fd8s4a9mnca2bmgol2r8"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = false
    ip_address = "10.8.1.11"
    security_group_ids = [yandex_vpc_security_group.nginx-sg.id]
  }

  
  metadata = {
    user-data = "${file("./conf.txt")}      - ${var.private_key}"
  }
    
}

//_____________________(NGINX-2)__________________________________
resource "yandex_compute_instance" "nginx2" {
  name = "nginx2"
  platform_id = "standard-v3"
  zone = "ru-central1-b"
  hostname = "nginx2"

  resources {
    cores = 2
    memory = 2
    core_fraction = 20
  }

  scheduling_policy {
    preemptible = false
  }

  boot_disk {
    initialize_params {
      image_id = "fd8s4a9mnca2bmgol2r8"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-2.id
    nat       = false
    ip_address = "10.8.2.22"
    security_group_ids = [yandex_vpc_security_group.nginx-sg.id]
  }

  
  metadata = {
    user-data = "${file("./conf.txt")}      - ${var.private_key}"
  }
    
}

//______________________(ZABBIX)__________________________________
resource "yandex_compute_instance" "zabbix" {
  name = "zabbix"
  platform_id = "standard-v3"
  zone = "ru-central1-d"
  hostname = "zabbix"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  scheduling_policy {
    preemptible = false
  }

  boot_disk {
    initialize_params {
      image_id = "fd8s4a9mnca2bmgol2r8"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-3.id
    nat       = true
    ip_address = "10.8.3.33"
    security_group_ids = [yandex_vpc_security_group.zabbix-sg.id]
  }

  
  metadata = {
    user-data = "${file("./conf.txt")}      - ${var.private_key}"
  }
   
  
}

//______________________(ELASTICSEARCH)______________________________
resource "yandex_compute_instance" "elastic" {
  name = "elastic"
  platform_id = "standard-v3"
  zone = "ru-central1-d"
  hostname = "elastic"

  resources {
    cores  = 2
    memory = 4
    core_fraction = 20
  }

  scheduling_policy {
    preemptible = false
  }

  boot_disk {
    initialize_params {
      image_id = "fd8s4a9mnca2bmgol2r8"
      size = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-4.id
    nat       = false
    ip_address = "10.8.4.44"
    security_group_ids = [yandex_vpc_security_group.elastic-sg.id]
  }

  
  metadata = {
    user-data = "${file("./conf.txt")}      - ${var.private_key}"
  }
   
  
}

//_________________________(KIBANA)_____________________________________
resource "yandex_compute_instance" "kibana" {
  name = "kibana"
  platform_id = "standard-v3"
  zone = "ru-central1-d"
  hostname = "kibana"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  scheduling_policy {
    preemptible = false
  }

  boot_disk {
    initialize_params {
      image_id = "fd8s4a9mnca2bmgol2r8"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-3.id
    nat       = true
    ip_address = "10.8.3.34"
    security_group_ids = [yandex_vpc_security_group.kibana-sg.id]
  }

  
  metadata = {
    user-data = "${file("./conf.txt")}      - ${var.private_key}"
  }
   
}

//______________________(BASTION)________________________________________
resource "yandex_compute_instance" "bastion" {
  name = "bastion"
  platform_id = "standard-v3"
  zone = "ru-central1-d"
  hostname = "bastion"

  resources {
    cores  = 2
    memory = 1
    core_fraction = 20
  }
  

  scheduling_policy {
    preemptible = false
  }

  boot_disk {
    initialize_params {
      image_id = "fd8s4a9mnca2bmgol2r8"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-3.id
    nat       = true
    ip_address = "10.8.33.33"
    security_group_ids = [yandex_vpc_security_group.bastion-sg.id]
    
  }

  metadata = {
    user-data = "${file("./conf.txt")}      - ${var.private_key}"
 
#    ssh-authorized-keys 
 #   user-data = "travitskii: ${var.private_key}"
    
  
      
  }
   
}



//_________________________TARGET_GROUP___________________________________________
resource "yandex_alb_target_group" "ngx-target-group" {
  name      = "ngx-target-group"

  target {
    subnet_id = "${yandex_vpc_subnet.subnet-1.id}"
    ip_address   = "${yandex_compute_instance.nginx1.network_interface.0.ip_address}"
  }

  target {
    subnet_id = "${yandex_vpc_subnet.subnet-2.id}"
    ip_address   = "${yandex_compute_instance.nginx2.network_interface.0.ip_address}"
  }
}

//______________________BACKEND_GROUP__________________________________________________
resource "yandex_alb_backend_group" "nginx-backend-group" {
  name      = "nginx-backend-group"

  http_backend {
    name = "backend-1"
    weight = 1
    port = 80
    target_group_ids = [yandex_alb_target_group.ngx-target-group.id]
    
    load_balancing_config {
      panic_threshold = 0
    }    
    healthcheck {
      timeout = "2s"
      interval = "35s"
      healthy_threshold    = 2
      unhealthy_threshold  = 2 
      healthcheck_port     = 80
      http_healthcheck {
        path  = "/"
      }
    }
  }
}

//_______________________HTTP-ROUTER_________________________________________
resource "yandex_alb_http_router" "nginx-router" {
  name      = "nginx-router"
}

//______________________ВИРТУАЛЬНЫЙ__ХОСТ____________________________________
resource "yandex_alb_virtual_host" "ngx-virtual-host" {
  name                    = "ngx-virtual-host"
  http_router_id          = yandex_alb_http_router.nginx-router.id
  route {
    name                  = "nginx-route"
    http_route {
      http_match {
        path {
          prefix = "/"
        }
      }
      http_route_action {
        backend_group_id  = yandex_alb_backend_group.nginx-backend-group.id
      }
    }
  }
}    

//________________________Балансер_____________________________________________
resource "yandex_alb_load_balancer" "nginx-balancer" {
name        = "nginx-balancer"
  network_id  = yandex_vpc_network.network-1.id

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.subnet-1.id 
    }
    location {
      zone_id   = "ru-central1-b"
      subnet_id = yandex_vpc_subnet.subnet-2.id 
    }
#   location {
#      zone_id   = "ru-central1-d"
#      subnet_id = yandex_vpc_subnet.subnet-3.id 
#    }
  
  }

  listener {
    name = "my-listener"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [ 80 ]
    }    
    http {
      handler {
        http_router_id = yandex_alb_http_router.nginx-router.id
      }
    }
  }
}  


//_____________РАСПИСАНИЕ СНИМКОВ ДИСКОВ ВМ__________________________________________
resource "yandex_compute_snapshot_schedule" "daily" {
  name = "daily"

  schedule_policy {
    expression = "00 17 ? * *"
  }

  retention_period = "168h"

  disk_ids = [yandex_compute_instance.nginx1.boot_disk.0.disk_id, yandex_compute_instance.nginx2.boot_disk.0.disk_id, yandex_compute_instance.zabbix.boot_disk.0.disk_id, yandex_compute_instance.elastic.boot_disk.0.disk_id, yandex_compute_instance.kibana.boot_disk.0.disk_id, yandex_compute_instance.bastion.boot_disk.0.disk_id]
}



resource "local_file" "ansible-inventory" {
  content  = <<-EOT
    [Bastion]   
    bastion.ru-central1.internal
    
    [web] 
    nginx1.ru-central1.internal  
    nginx2.ru-central1.internal  

    [Zabbix]  
    zabbix.ru-central1.internal         
     

    [Elasticsearch]    
    elastic.ru-central1.internal          
     

    [Kibana]   
    kibana.ru-central1.internal   
           
    
    [all:vars]
    ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand="ssh -p 22 -W %h:%p -q travitskii@${yandex_compute_instance.bastion.network_interface.0.nat_ip_address}"'
    EOT
  filename = "/home/travitskii/Diplom_finih/ansible/inventory.ini"
}



 
