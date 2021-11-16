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
  # user_name      = "scaleway08@efrei-devops.com"
  # password       = "Efrei!2021"
}

resource "scaleway_instance_ip" "public_ip" {}

resource "scaleway_instance_server" "web" {
  type = "DEV1-S"
  image = "ubuntu_focal"
  ip_id = scaleway_instance_ip.public_ip.id
  
  user_data = {
    # DATABASE_URI= "postgres://${scaleway_rdb_instance.main.user_name}:${scaleway_rdb_instance.main.password}@51.159.10.108:4698/rdb"
    DATABASE_URI= "postgres://scaleway08@efrei-devops.com:Efrei!2021@51.15.209.207:9794/rdb"

  }
}