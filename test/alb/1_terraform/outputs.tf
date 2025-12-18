output "project_id" {
  description = "GCP Project ID"
  value       = var.project_id
}

output "region" {
  description = "GCP Region"
  value       = var.region
}

output "cloudrun_service_name" {
  description = "Name of the Cloud Run service"
  value       = google_cloud_run_service.app.name
}

output "alb_ip_address" {
  description = "IP address of the Application Load Balancer"
  value       = google_compute_global_address.alb_ip.address
}

output "cloudrun_service_url" {
  description = "URL of the Cloud Run service"
  value       = google_cloud_run_service.app.status[0].url
}

output "alb_url" {
  description = "ALB URL (requires DNS setup)"
  value       = "https://${var.ssl_domains[0]}"
}

output "backend_service_name" {
  description = "Name of the backend service"
  value       = google_compute_backend_service.cloudrun_backend.name
}

output "alert_policy_name" {
  description = "Name of the alert policy"
  value       = google_monitoring_alert_policy.high_latency_alert.display_name
}
