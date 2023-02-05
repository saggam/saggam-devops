output "web-instance-ip" {
  value = google_compute_instance.web-instance.network_interface.0.access_config.0.assigned_nat_ip
}