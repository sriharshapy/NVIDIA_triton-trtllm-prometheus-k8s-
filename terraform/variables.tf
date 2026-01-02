variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP Zone (must support H100)"
  type        = string
  default     = "us-central1-a"
}

variable "instance_name" {
  description = "Name of the GCP instance"
  type        = string
  default     = "qwen3-8b-h100"
}

variable "image" {
  description = "GCE image to use (should have CUDA and drivers)"
  type        = string
  default     = "projects/nvidia-ngc-public/global/images/nvidia-tensorrt-llm-release-v0-12-0"
}

variable "disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 200
}

