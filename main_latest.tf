# VPC creation
resource "google_compute_network" "custom-vpc_network" {
  project                 = "my-project-name"
  name                    = "custom-vpc-network"
  auto_create_subnetworks = false
  
}

output "custom_vpc" {
  value = google_compute_network.custom-vpc_network.id
}

# Subnet Creation
resource "google_compute_subnetwork" "subnetwork" {
  name          = "subnetwork"
  ip_cidr_range = "10.2.0.0/16"
  region        = "us-central1"
  network       = google_compute_network.custom-vpc_network.id
  private_ip_google_access = true
}


# Firewall creation

resource "google_compute_firewall" "firewall" {
  name    = "three-tier-firewall"
  network = google_compute_network.custom-vpc_network.id

  allow {
    protocol = "icmp"
  }

  source_ranges = ["ip_address_range"]

  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "1000-2000"]
  }

  source_tags = ["web"]
}

# Instance creation

resource "google_service_account" "default" {
  account_id   = "service_account_id"
  display_name = "Service Account"
}

resource "google_compute_instance" "vm_instance" {
  name         = "vm-insatnce-1"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  tags = ["foo", "bar"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size = 20
    }
  }

  network_interface {
    network = google_compute_network.custom-vpc_network.id
    subnet = google_compute_subnetwork.subnetwork.id

    lifecycle {
    ignore_changes = [attached_disk]
  }

}

# Attach disk

resource "google_compute_disk" "disk-1" {
  name  = "disk-1"
  type  = "pd-ssd"
  zone  = "us-central1-a"
  size = 100
}

resource "google_compute_attached_disk" "disk-att" {
  disk     = google_compute_disk.disk-1.id
  instance = google_compute_instance.vm_instance.id
}



# Cloud SQl instance

resource "google_sql_database_instance" "mysql_instance" {
  name             = "mysql_instance"
  database_version = "MYSQL_5_7"
  region           = "us-central1"

  settings {
    tier = "db-f1-micro"
  }
}

resource "google_sql_user" "myuser" {
  name = "hari"
  password = "test"
  instance = google_sql_database_instance.mysql_instance.id
}


# GKE cluster

resource "google_container_cluster" "gke_cluster" {
  name     = "gke_cluster"
  location = "us-central1"
  initial_node_count       = 3
  network = google_compute_network.custom-vpc_network.id
  subnet = google_compute_subnetwork.subnetwork.id
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "my-node-pool"
  location   = "us-central1"
  cluster    = google_container_cluster.primary.name
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "e2-medium"
    service_account = google_service_account.default.email
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

# Load balancer details
# This health check is used to monitor the health of the instances in the target pool.

resource "google_compute_http_health_check" "lb_health_check" {
  name               = "my-lb-health-check"
  request_path       = "/"
  port               = 80
  check_interval_sec = 1
  timeout_sec        = 1
}

# GCP target pool is created 
resource "google_compute_target_pool" "lb_target_pool" {
  name       = "my-lb-target-pool"

  instances  = [google_compute_instance.vm_instance.id]
  health_checks = [google_compute_http_health_check.lb_health_check.self_link]
}

#GCP forwarding rule creation. This forwarding rule routes incoming traffic to the target pool.
resource "google_compute_forwarding_rule" "lb_forwarding_rule" {
  name       = "my-lb-forwarding-rule"
  target     = google_compute_target_pool.lb_target_pool.self_link
  port_range = "80"
  IP_protocol = "TCP"
}