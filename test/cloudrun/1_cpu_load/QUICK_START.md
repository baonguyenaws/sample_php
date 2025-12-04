# Quick Start Guide - CPU Load Generator

## 🚀 3 Mức CPU Support: 75%, 85%, 99%

## 📚 Choose Your Guide

### 🏠 [Local Testing Guide](./QUICK_START_LOCAL.md)
Hướng dẫn test local với Docker và Docker Compose
- Single container hoặc multiple containers
- Monitor CPU usage với `docker stats`
- Troubleshooting local issues

### ☁️ [Cloud Run Deployment Guide](./QUICK_START_CLOUD_RUN.md)
Hướng dẫn deploy lên Google Cloud Run
- Build & push Docker image lên Docker Hub
- Deploy single hoặc multiple services
- Monitor & debug trên Cloud Run
- Quick deploy script

---

## 📖 Quick Reference

### Option 1: Test Local - Single Container

---

## 📖 Quick Reference

### Local Testing

```bash
# Single container
docker compose up -d
curl http://localhost:8080/health
docker stats cpu-load-test
docker compose down
```

### Cloud Run Deployment

```bash
# Build & push to Docker Hub
docker build -t docker.io/baonv/cpu-load-generator:v1.0 .
docker push docker.io/baonv/cpu-load-generator:v1.0

# Deploy to Cloud Run
gcloud run deploy cpu-load-service \
  --image docker.io/baonv/cpu-load-generator:v1.0 \
  --region asia-southeast1 \
  --set-env-vars CPU_TARGET=85,STARTUP_DELAY=5 \
  --timeout 300 --max-instances 1 \
  --cpu 1 --memory 512Mi \
  --allow-unauthenticated

# Test
SERVICE_URL=$(gcloud run services describe cpu-load-service --region asia-southeast1 --format 'value(status.url)')
curl $SERVICE_URL/health
```

## 📊 Supported CPU Targets

| CPU_TARGET | Expected CPU Usage | Container Name | Port (Local) |
|------------|-------------------|----------------|--------------|
| 75% | ~75% of 1 core | cpu-load-75 | 8075 |
| 85% | ~85% of 1 core | cpu-load-85 | 8085 |
| 99% | ~99% of 1 core | cpu-load-99 | 8099 |

## 📝 Files

- `cpu_load.py` - Core CPU load generator
- `cpu_load_with_http.py` - HTTP server wrapper (used by Dockerfile)
- `Dockerfile` - Container definition
- `docker-compose*.yml` - Docker Compose configs
- `QUICK_START_LOCAL.md` - Local testing guide
- `QUICK_START_CLOUD_RUN.md` - Cloud Run deployment guide  
- `docker-compose-99.yml` - 99% CPU config
- `README.md` - Full documentation
