terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.34.0"
    }
  }
}

resource "google_compute_instance" "free_tier_vm" {
  project      = var.project_id
  machine_type = "e2-micro"
  zone         = "us-central1-a"
  name         = "my-first-vm"
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  network_interface {
    network = "default"
    access_config {}
  }
  tags = ["http-server"]
  metadata = {
    startup-script = file("${path.module}/startup-script.sh")
  }
}

resource "google_compute_firewall" "allow_http" {
  project = var.project_id
  name    = "allow-http-ingress"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  target_tags = ["http-server"]
  source_ranges = ["0.0.0.0/0"]
}

variable "project_id" {
  type        = string
  description = "The GCP project ID to deploy resources into."
}

output "vm_external_ip" {
  description = "The external IP address of the web server VM."
  value       = google_compute_instance.free_tier_vm.network_interface[0].access_config[0].nat_ip
}