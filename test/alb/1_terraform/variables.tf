variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "rare-karma-480813-i3"
}

variable "region" {
  description = "GCP Region for Cloud Run"
  type        = string
  default     = "asia-southeast1"
}

variable "cloudrun_service_name" {
  description = "Name of the Cloud Run service"
  type        = string
  default     = "app-service"
}

variable "container_image" {
  description = "Container image for Cloud Run"
  type        = string
  default     = "gcr.io/cloudrun/hello"
}

variable "ssl_domains" {
  description = "Domains for SSL certificate"
  type        = list(string)
  default     = ["test.nhameo.site"]
}

variable "alert_email" {
  description = "Email address for alert notifications"
  type        = string
  default     = "baonguyen.aws@gmail.com"
}
