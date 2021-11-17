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

    # DATABASE_URI=postgres://<username>:<password>@<database-ip>:<database_port>/<databasename>
    # DATABASE_URI="postgres://scaleway08@efrei-devops.com:Efrei!2021@195.154.70.55:12045/rdb"

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