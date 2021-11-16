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
  node_type      = "DB-DEV-S"
  engine         = "PostgreSQL-12"
  is_ha_cluster  = true
  # disable_backup = true
  # user_name      = "user"
  # password       = "password"
}