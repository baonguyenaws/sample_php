terraform {
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
}

# Cloud Run service
resource "google_cloud_run_service" "app" {
  name     = var.cloudrun_service_name
  location = var.region

  template {
    spec {
      containers {
        image = var.container_image
        
        resources {
          limits = {
            cpu    = "1000m"
            memory = "512Mi"
          }
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# Allow unauthenticated access to Cloud Run
resource "google_cloud_run_service_iam_member" "public_access" {
  service  = google_cloud_run_service.app.name
  location = google_cloud_run_service.app.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Regional Network Endpoint Group for Cloud Run
resource "google_compute_region_network_endpoint_group" "cloudrun_neg" {
  name                  = "${var.cloudrun_service_name}-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  
  cloud_run {
    service = google_cloud_run_service.app.name
  }
}

# Backend service for ALB
resource "google_compute_backend_service" "cloudrun_backend" {
  name                  = "${var.cloudrun_service_name}-backend"
  protocol              = "HTTPS"
  timeout_sec           = 30
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_region_network_endpoint_group.cloudrun_neg.id
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

# URL Map
resource "google_compute_url_map" "alb" {
  name            = "${var.cloudrun_service_name}-alb"
  default_service = google_compute_backend_service.cloudrun_backend.id
}

# HTTPS Proxy
resource "google_compute_target_https_proxy" "alb_proxy" {
  name             = "${var.cloudrun_service_name}-https-proxy"
  url_map          = google_compute_url_map.alb.id
  ssl_certificates = [google_compute_managed_ssl_certificate.alb_cert.id]
}

# HTTP Proxy (same backend, no redirect)
resource "google_compute_target_http_proxy" "alb_http_proxy" {
  name    = "${var.cloudrun_service_name}-http-proxy"
  url_map = google_compute_url_map.alb.id
}

# SSL Certificate
resource "google_compute_managed_ssl_certificate" "alb_cert" {
  name = "${var.cloudrun_service_name}-cert"

  managed {
    domains = var.ssl_domains
  }
}

# Global Forwarding Rule for HTTPS (443)
resource "google_compute_global_forwarding_rule" "alb_https" {
  name                  = "${var.cloudrun_service_name}-https-forwarding-rule"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_target_https_proxy.alb_proxy.id
  ip_address            = google_compute_global_address.alb_ip.id
}

# Global Forwarding Rule for HTTP (80)
resource "google_compute_global_forwarding_rule" "alb_http" {
  name                  = "${var.cloudrun_service_name}-http-forwarding-rule"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "80"
  target                = google_compute_target_http_proxy.alb_http_proxy.id
  ip_address            = google_compute_global_address.alb_ip.id
}

# Static IP for ALB
resource "google_compute_global_address" "alb_ip" {
  name = "${var.cloudrun_service_name}-ip"
}

# Notification channel for alerts (email)
resource "google_monitoring_notification_channel" "email" {
  display_name = "Email Notification Channel"
  type         = "email"
  
  labels = {
    email_address = var.alert_email
  }
}

# Alert policy for high latency
resource "google_monitoring_alert_policy" "high_latency_alert" {
  display_name = "High Latency Alert - ALB to Cloud Run"
  combiner     = "OR"
  
  conditions {
    display_name = "2% of requests have latency > 3s"
    
    condition_threshold {
      filter          = "resource.type=\"https_lb_rule\" AND resource.labels.url_map_name=\"${google_compute_url_map.alb.name}\" AND metric.type=\"loadbalancing.googleapis.com/https/backend_latencies\""
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = 3000  # 3 seconds in milliseconds
      
      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_DELTA"
        cross_series_reducer = "REDUCE_PERCENTILE_95"
        group_by_fields      = ["resource.url_map_name"]
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]

  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    content   = "Alert triggered when 2% of requests from ALB to Cloud Run have latency greater than 3 seconds in a 1-minute window."
    mime_type = "text/markdown"
  }
}
