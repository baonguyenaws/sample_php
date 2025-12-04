# Quick Start Guide - CPU Load Generator (Cloud Run)

## 🚀 Deploy to Google Cloud Run

### Prerequisites

```bash
# Login to gcloud
gcloud auth login

# Set project
gcloud config set project my-project-sample

# Enable required APIs
gcloud services enable run.googleapis.com
gcloud services enable cloudbuild.googleapis.com
```

## 📦 Step 1: Build & Push Docker Image to Docker Hub

```bash
# Login to Docker Hub
docker login -u baonv

docker build -t docker.io/baonv/cpu-load-generator:latest .
docker tag docker.io/baonv/cpu-load-generator:latest docker.io/baonv/cpu-load-generator:latest

# Push lên Docker Hub
docker push docker.io/baonv/cpu-load-generator:latest
docker push docker.io/baonv/cpu-load-generator:latest

# Verify
docker images | grep cpu-load-generator
```

## ☁️ Step 2: Deploy to Cloud Run

### Option 1: Deploy Single Service (85% CPU)

```bash
gcloud run deploy cpu-load-service \
  --image docker.io/docker.io/baonv/cpu-load-generator:latest \
  --region asia-southeast1 \
  --set-env-vars CPU_TARGET=85,STARTUP_DELAY=10 \
  --timeout 300 \
  --max-instances 1 \
  --min-instances 0 \
  --cpu 1 \
  --memory 512Mi \
  --port 8080 \
  --no-cpu-throttling \
  --cpu-boost \
  --allow-unauthenticated

# Test
SERVICE_URL=$(gcloud run services describe cpu-load-service \
  --region asia-southeast1 \
  --format 'value(status.url)')
echo "Service URL: $SERVICE_URL"
curl $SERVICE_URL/health

# Cleanup
gcloud run services delete cpu-load-service \
  --region asia-southeast1 \
  --quiet
```

### Option 2: Deploy 3 Services (75%, 85%, 99%)

```bash
# Deploy 75% CPU
gcloud run deploy cpu-load-75 \
  --image docker.io/baonv/cpu-load-generator:latest \
  --region asia-southeast1 \
  --set-env-vars CPU_TARGET=75,STARTUP_DELAY=10 \
  --timeout 300 \
  --max-instances 1 \
  --min-instances 0 \
  --cpu 1 \
  --memory 512Mi \
  --port 8080 \
  --no-cpu-throttling \
  --cpu-boost \
  --allow-unauthenticated

# Deploy 85% CPU
gcloud run deploy cpu-load-85 \
  --image docker.io/baonv/cpu-load-generator:latest \
  --region asia-southeast1 \
  --set-env-vars CPU_TARGET=85,STARTUP_DELAY=10 \
  --timeout 300 \
  --max-instances 1 \
  --min-instances 0 \
  --cpu 1 \
  --memory 512Mi \
  --port 8080 \
  --no-cpu-throttling \
  --cpu-boost \
  --allow-unauthenticated

# Deploy 99% CPU
gcloud run deploy cpu-load-99 \
  --image docker.io/baonv/cpu-load-generator:latest \
  --region asia-southeast1 \
  --set-env-vars CPU_TARGET=99,STARTUP_DELAY=10 \
  --timeout 300 \
  --max-instances 1 \
  --min-instances 0 \
  --cpu 1 \
  --memory 512Mi \
  --port 8080 \
  --no-cpu-throttling \
  --cpu-boost \
  --allow-unauthenticated

# Test all services
URL_75=$(gcloud run services describe cpu-load-75 --region asia-southeast1 --format 'value(status.url)')
URL_85=$(gcloud run services describe cpu-load-85 --region asia-southeast1 --format 'value(status.url)')
URL_99=$(gcloud run services describe cpu-load-99 --region asia-southeast1 --format 'value(status.url)')

echo "Testing CPU 75%: $URL_75"
curl $URL_75/health

echo "Testing CPU 85%: $URL_85"
curl $URL_85/health

echo "Testing CPU 99%: $URL_99"
curl $URL_99/health

# Cleanup all
gcloud run services delete cpu-load-75 --region asia-southeast1 --quiet
gcloud run services delete cpu-load-85 --region asia-southeast1 --quiet
gcloud run services delete cpu-load-99 --region asia-southeast1 --quiet
```

