terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.34.0"
    }
  }
}

variable "project_id" {
  type        = string
  description = "The GCP project ID to deploy resources into."
}

variable "tunnel_id" {
  type        = string
  description = "The Cloudflare tunnel ID."
}

variable "cloudflare_token" {
  type        = string
  description = "The Cloudflare token."
  sensitive   = true
}

variable "domain" {
  type        = string
  description = "The domain to expose n8n on."
}

resource "google_secret_manager_secret" "cloudflare_token" {
  project   = var.project_id
  secret_id = "cloudflare-token"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "cloudflare_token_version" {
  secret      = google_secret_manager_secret.cloudflare_token.id
  secret_data = var.cloudflare_token
}

resource "google_project_iam_member" "secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_compute_instance.free_tier_vm.service_account[0].email}"
}

resource "google_compute_instance" "free_tier_vm" {
  project      = var.project_id
  machine_type = "e2-micro"
  zone         = "us-central1-a"
  name         = "free-vm"
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  network_interface {
    network = "default"
    access_config {}
  }
  metadata = {
    startup-script = templatefile("${path.module}/startup-script.sh", {
      secret_id = google_secret_manager_secret.cloudflare_token.secret_id
      domain    = var.domain
      tunnel_id = var.tunnel_id
    })
  }
  service_account {
    scopes = ["cloud-platform"]
  }
}