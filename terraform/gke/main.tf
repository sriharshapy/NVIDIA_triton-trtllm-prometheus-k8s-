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

# GKE Cluster
resource "google_container_cluster" "trt_llm_cluster" {
  name     = var.cluster_name
  location = var.zone

  # Enable required APIs before creating cluster
  depends_on = [
    google_project_service.container,
    google_project_service.compute,
  ]

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = var.network
  subnetwork = var.subnetwork

  # Enable required features
  enable_shielded_nodes = true
  enable_legacy_abac    = false

  # Network policy
  network_policy {
    enabled = true
  }

  # Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Addons
  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  # Logging and monitoring
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  # Maintenance
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }

  # Resource labels
  resource_labels = {
    purpose = "trt-llm-inference"
    model   = "qwen3-8b"
  }
}

# Node pool for A100 GPUs
resource "google_container_node_pool" "a100_pool" {
  name     = "a100-node-pool"
  location = var.zone
  cluster  = google_container_cluster.trt_llm_cluster.name

  # Use initial_node_count when autoscaling is enabled
  initial_node_count = var.node_count

  # Ensure cluster is created before node pool
  depends_on = [
    google_container_cluster.trt_llm_cluster,
    google_service_account.gke_sa,
  ]

  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count # Restricted to 1 for single A100 GPU deployment
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type    = "a2-highgpu-1g" # A100 40GB instance
    disk_size_gb    = 200
    disk_type       = "pd-ssd"
    service_account = google_service_account.gke_sa.email
    
    # Use spot instances for cost savings (60-80% discount)
    spot = true

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    # GPU configuration
    guest_accelerator {
      type  = "nvidia-tesla-a100"
      count = 1
    }

    # Labels for node selection
    labels = {
      accelerator = "nvidia-tesla-a100"
      pool        = "a100"
    }

    # Taints for GPU nodes
    taint {
      key    = "nvidia.com/gpu"
      value  = "true"
      effect = "NO_SCHEDULE"
    }

    # Enable GKE Sandbox if needed
    # sandbox_config {
    #   sandbox_type = "gvisor"
    # }

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }
}

# CPU Node pool for OpenWebUI and other non-GPU workloads
resource "google_container_node_pool" "cpu_pool" {
  name     = "cpu-node-pool"
  location = var.zone
  cluster  = google_container_cluster.trt_llm_cluster.name

  initial_node_count = 1 # Start with 1 CPU node for Prometheus and OpenWebUI

  autoscaling {
    min_node_count = 1 # Keep 1 node for Prometheus and OpenWebUI
    max_node_count = 1 # Limit to 1 CPU node (cheap instances)
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type    = "e2-standard-2" # 2 vCPU, 8GB RAM - enough for OpenWebUI (1 CPU) + Prometheus (1 CPU)
    disk_size_gb    = 30
    disk_type       = "pd-standard"
    service_account = google_service_account.gke_sa.email

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    # Labels for node selection
    labels = {
      accelerator   = "cpu"
      pool          = "cpu"
      workload-type = "cpu"
    }

    # Taints for CPU nodes (optional - to ensure only non-GPU workloads)
    taint {
      key    = "workload-type"
      value  = "cpu"
      effect = "NO_SCHEDULE"
    }

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }

  depends_on = [
    google_container_cluster.trt_llm_cluster,
    google_service_account.gke_sa,
  ]
}

# Service account for GKE
resource "google_service_account" "gke_sa" {
  account_id   = "gke-trillm-sa"
  display_name = "GKE TRT-LLM Service Account"
}

resource "google_project_iam_member" "gke_sa_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}

resource "google_project_iam_member" "gke_sa_monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}

resource "google_project_iam_member" "gke_sa_monitoring_viewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}

# Enable required APIs
resource "google_project_service" "container" {
  project = var.project_id
  service = "container.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "compute" {
  project = var.project_id
  service = "compute.googleapis.com"

  disable_on_destroy = false
}

# Outputs
output "cluster_name" {
  value       = google_container_cluster.trt_llm_cluster.name
  description = "GKE cluster name"
}

output "cluster_endpoint" {
  value       = google_container_cluster.trt_llm_cluster.endpoint
  description = "GKE cluster endpoint"
}

output "cluster_location" {
  value       = google_container_cluster.trt_llm_cluster.location
  description = "GKE cluster location"
}

output "cluster_ca_certificate" {
  # CA certificate is available via master_auth
  # For clusters with Workload Identity, master_auth may be limited but CA cert is still available
  value       = try(google_container_cluster.trt_llm_cluster.master_auth[0].cluster_ca_certificate, "")
  description = "GKE cluster CA certificate"
  sensitive   = true
}

output "get_credentials_command" {
  value       = "gcloud container clusters get-credentials ${google_container_cluster.trt_llm_cluster.name} --zone ${var.zone} --project ${var.project_id}"
  description = "Command to get GKE credentials"
}

