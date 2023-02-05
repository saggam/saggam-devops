# VM Instance creation

resource "google_compute_instance" "web-instance" {
  name         = "web-instance"
  machine_type = "n1-standard-1"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = "default"
  }
}

# Kubernetes cluster creation

resource "google_container_cluster" "k8s-cluster" {
  name     = "k8s-cluster"
  location = "us-central1"

  initial_node_count = 3

  node_config {
    machine_type = "n1-standard-2"
    disk_size_gb = 100
  }
}

# CloudSQl creation.

resource "google_sql_database_instance" "cloud-sql-instance" {
  name                 = "cloud-sql-instance"
  database_version     = "MYSQL_5_7"
  region               = "us-central1"
  tier                 = "db-f1-micro"
  storage_type         = "PD_SSD"
  storage_auto_increase = false
  storage_size         = 10

  root_password = "mysecretpassword"
}


