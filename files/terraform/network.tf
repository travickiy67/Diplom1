//_______________ ГРУППЫ БЕЗОПАСНОСТИ________________
//_________________БАСТИОН________________________
resource "yandex_vpc_security_group" "bastion-sg" {
  name        = "bastion-sg"
  description = "access via ssh"
  network_id  = "${yandex_vpc_network.network-1.id}"  
  ingress {
      protocol          = "TCP"
      description       = "ssh-in"
      port              = 22
      v4_cidr_blocks = ["0.0.0.0/0"]
  }
 ingress {
    protocol       = "ICMP"
    description    = "allow ping"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol       = "TCP"
    description    = "zabbix in"
    port           = "10050"
    v4_cidr_blocks = ["10.8.3.0/24"] 
  }
  egress {
      protocol          = "ANY"
      description       = "any for basion to out"
      from_port         = 0
      to_port           = 65535
      v4_cidr_blocks = ["0.0.0.0/0"]
    }
}



//________________nginx_____________________
resource "yandex_vpc_security_group" "nginx-sg" {
  name        = "nginx-sg"
  description = "rules for nginx"
  network_id  = "${yandex_vpc_network.network-1.id}"  

  ingress {
    protocol       = "TCP"
    description    = "HTTP in"
    port           = "80"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "ssh in"
    port           = "22"
    v4_cidr_blocks = ["10.8.33.0/24"] 
  }

  ingress {
    protocol       = "TCP"
    description    = "zabbix in"
    port           = "10050"
    v4_cidr_blocks = ["10.8.3.0/24"] 
  }

  ingress {
    protocol       = "ICMP"
    description    = "allow ping"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "Health checks from NLB"
    protocol = "TCP"
    predefined_target = "loadbalancer_healthchecks" 
  }

  
  egress {
    description    = "ANY"
    protocol       = "ANY"
    from_port         = 0
    to_port           = 65535
    v4_cidr_blocks = ["0.0.0.0/0"] 
  }
}

//__________________ZABBIX_server_____________________
resource "yandex_vpc_security_group" "zabbix-sg" {
  name        = "zabbix-sg"
  description = "rules for zabbix"
  network_id  = "${yandex_vpc_network.network-1.id}"  

  ingress {
    protocol       = "TCP"
    description    = "HTTP in"
    port           = "80"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "HTTP in"
    port           = "3000"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    protocol       = "TCP"
    description    = "ssh in"
    port           = "22"
    v4_cidr_blocks = ["10.8.33.0/24"] 
  }
  
  

  ingress {
    protocol       = "TCP"
    description    = "zabbix in"
    port           = "10051"
    v4_cidr_blocks = ["10.8.1.0/24", "10.8.2.0/24", "10.8.3.0/24", "10.8.4.0/24", "10.8.33.0/24"]
 
  }

  
  egress {
    description    = "ANY"
    protocol       = "ANY"
    from_port         = 0
    to_port           = 65535
    v4_cidr_blocks = ["0.0.0.0/0"] 
  }
}

//____________ELASTIC__________________
resource "yandex_vpc_security_group" "elastic-sg" {
  name        = "elastic-sg"
  description = "rules for elastic"
  network_id  = "${yandex_vpc_network.network-1.id}"  


  ingress {
    protocol       = "TCP"
    description    = "ssh in"
    port           = "22"
    v4_cidr_blocks = ["10.8.33.0/24"] 
  }

  ingress {
    protocol       = "TCP"
    description    = "zabbix in"
    port           = "10050"
    v4_cidr_blocks = ["10.8.3.0/24"] 
  }

  ingress {
    protocol       = "TCP"
    description    = "elastic agent in"
    port           = "9200"
    v4_cidr_blocks = ["10.8.1.0/24", "10.8.2.0/24", "10.8.3.0/24"] 
#    v4_cidr_blocks = ["0.0.0.0/0"]
  }
 
  
  egress {
    description    = "ANY"
    protocol       = "ANY"
    from_port         = 0
    to_port           = 65535
    v4_cidr_blocks = ["0.0.0.0/0"] 
  }
}

# //___________________KIBANA______________________
resource "yandex_vpc_security_group" "kibana-sg" {
  name        = "kibana-sg"
  description = "rules for kibana"
  network_id  = "${yandex_vpc_network.network-1.id}"  

  ingress {
    protocol       = "TCP"
    description    = "kibana interface"
    port           = "5601"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  
  ingress {
    protocol       = "TCP"
    description    = "ssh in"
    port           = "22"
    v4_cidr_blocks = ["10.8.33.0/24"] 
  }

  ingress {
    protocol       = "TCP"
    description    = "zabbix in"
    port           = "10050"
    v4_cidr_blocks = ["10.8.3.0/24"] 
  }

  
  egress {
    description    = "ANY"
    protocol       = "ANY"
    from_port         = 0
    to_port           = 65535
    v4_cidr_blocks = ["0.0.0.0/0"] 
  }
}

//_______________ШЛЮЗ И ТАБЛИЦА МАРШРУТИЗАЦИИ__________________________
resource "yandex_vpc_gateway" "nginx1-2_elastic_gateway" {
  name = "nginx-elastic-gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "nginx1-2_elastic" {
  name       = "nginx-elastic-route-table"
  network_id = yandex_vpc_network.network-1.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nginx1-2_elastic_gateway.id
  }
}



//__________________________СЕТЬ_______________________________________
resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

//_________________________ПОДСЕТЬ-1____________________________________
resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["10.8.1.0/24"]
  route_table_id = yandex_vpc_route_table.nginx1-2_elastic.id
}

//_________________________ПОДСЕТЬ-2____________________________________
resource "yandex_vpc_subnet" "subnet-2" {
  name           = "subnet2"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["10.8.2.0/24"]
  route_table_id = yandex_vpc_route_table.nginx1-2_elastic.id
}

//_________________________ПОДСЕТЬ-3____________________________________
resource "yandex_vpc_subnet" "subnet-3" {
  name           = "subnet3"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["10.8.3.0/24", "10.8.33.0/24"]
}

//_________________________ПОДСЕТЬ-4____________________________________
resource "yandex_vpc_subnet" "subnet-4" {
  name           = "subnet4"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["10.8.4.0/24"]
  route_table_id = yandex_vpc_route_table.nginx1-2_elastic.id
}
