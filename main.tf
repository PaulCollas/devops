terraform {
  required_providers {
    scaleway = {
      source = "scaleway/scaleway"
    }
  }
  required_version = ">= 0.13"
}

provider "scaleway" {
  access_key = "SCW5X569PRAJ6Q3X1EKT"
  secret_key = "8b005a8a-635e-4372-9a86-1967b204a73c"
  project_id = "785298d6-80d8-442d-9dda-1831e3bb5020"
}

resource "scaleway_rdb_instance" "main" {
  name           = "devops-rdb"
  node_type      = "db-dev-s"
  engine         = "PostgreSQL-12"
  is_ha_cluster  = true
  user_name      = "TotoToto50"
  password       = "PAssWord;50"
}

resource "scaleway_instance_ip" "public_ip" {
  count = 2
}

resource "scaleway_instance_server" "web" {

  count = 2

  type = "DEV1-S"
  image = "ubuntu_focal"
  ip_id = scaleway_instance_ip.public_ip[count.index].id
  
  user_data = {
    DATABASE_URI= "postgres://${scaleway_rdb_instance.main.user_name}:${scaleway_rdb_instance.main.password}@51.159.10.108:41352/rdb"
  }

  provisioner "remote-exec" {

    inline=[
      "sudo apt -y update",
      "sudo apt install -y docker.io",
      "docker run -d --name app -e DATABASE_URI=\"$(scw-userdata DATABASE_URI)\" -p 80:8080 --restart=always rg.fr-par.scw.cloud/efrei-devops/app:latest"
    ]

    connection {
      type  = "ssh"
      user  = "root"
      private_key=file(pathexpand("~/.ssh/id_rsa"))
      host=self.public_ip
    } 

  }
}


resource "scaleway_lb_ip" "ip" {
}

resource "scaleway_lb" "base" {
  ip_id  = scaleway_lb_ip.ip.id
  zone = "fr-par-1"
  type   = "LB-S"
}

resource "scaleway_lb_backend" "backend01" {
  lb_id            = scaleway_lb.base.id
  name             = "backend01"
  forward_protocol = "http"
  forward_port     = "80"

  server_ips = [ for o in scaleway_instance_ip.public_ip : o.address ]
  
}

resource "scaleway_lb_frontend" "frontend01" {
  lb_id        = scaleway_lb.base.id
  backend_id   = scaleway_lb_backend.backend01.id
  name         = "frontend01"
  inbound_port = "80"
}