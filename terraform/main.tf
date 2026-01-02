terraform {
  required_version = ">= 1.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Service account for the instance
resource "google_service_account" "trt_llm_sa" {
  account_id   = "trt-llm-sa"
  display_name = "TRT-LLM Service Account"
}

resource "google_project_iam_member" "trt_llm_sa_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.trt_llm_sa.email}"
}

# H100 GPU instance
resource "google_compute_instance" "h100_instance" {
  name         = var.instance_name
  machine_type = "a3-highgpu-1g"  # H100 1g instance type
  zone         = var.zone
  
  # Ensure service account is created before instance
  depends_on = [google_service_account.trt_llm_sa]

  boot_disk {
    initialize_params {
      image = var.image
      size  = var.disk_size
      type  = "pd-ssd"
    }
  }

  network_interface {
    network = "default"
    access_config {
      # Ephemeral public IP
    }
  }

  service_account {
    email  = google_service_account.trt_llm_sa.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = file("${path.module}/startup_script.sh")

  scheduling {
    on_host_maintenance = "TERMINATE"
    automatic_restart   = false
  }

  labels = {
    purpose = "trt-llm-inference"
    model   = "qwen3-8b"
  }

  guest_accelerator {
    type  = "nvidia-h100-1g"
    count = 1
  }
}

# Firewall rule for Triton ports
resource "google_compute_firewall" "triton_http" {
  name    = "triton-http-${var.instance_name}"
  network = "default"
  
  # Firewall rules can be created independently

  allow {
    protocol = "tcp"
    ports    = ["8000"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["triton-server"]
}

resource "google_compute_firewall" "triton_grpc" {
  name    = "triton-grpc-${var.instance_name}"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8001"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["triton-server"]
}

resource "google_compute_firewall" "triton_metrics" {
  name    = "triton-metrics-${var.instance_name}"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8002"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["triton-server"]
}

# Outputs
output "instance_name" {
  value       = google_compute_instance.h100_instance.name
  description = "Name of the GCP instance"
}

output "instance_ip" {
  value       = google_compute_instance.h100_instance.network_interface[0].access_config[0].nat_ip
  description = "Public IP address of the instance"
}

output "instance_zone" {
  value       = google_compute_instance.h100_instance.zone
  description = "Zone of the instance"
}

