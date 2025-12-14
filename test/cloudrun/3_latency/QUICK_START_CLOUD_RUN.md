# Quick Start Guide - Latency Simulator (Cloud Run Deployment)

## 🚀 Deploy lên Google Cloud Run

### Prerequisites
```bash
# Đăng nhập GCP
gcloud auth login

# Set project
export PROJECT_ID="your-project-id"
gcloud config set project $PROJECT_ID

# Enable APIs
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com
```

### Option 1: Deploy với gcloud CLI

```bash
# Set biến
export REGION="asia-southeast1"
export SERVICE_NAME="latency-simulator"
export LATENCY_MS=100  # Thay đổi độ trễ tại đây

# Deploy
gcloud run deploy $SERVICE_NAME \
  --source . \
  --region $REGION \
  --platform managed \
  --allow-unauthenticated \
  --set-env-vars LATENCY_MS=$LATENCY_MS \
  --memory 256Mi \
  --cpu 1 \
  --min-instances 0 \
  --max-instances 10
```

### Option 2: Build & Push Docker Image

```bash
# Set biến
export PROJECT_ID="your-project-id"
export REGION="asia-southeast1"
export SERVICE_NAME="latency-simulator"
export IMAGE_NAME="gcr.io/$PROJECT_ID/$SERVICE_NAME"

# Build image
docker build -t $IMAGE_NAME .

# Push to GCR
docker push $IMAGE_NAME

# Deploy to Cloud Run
gcloud run deploy $SERVICE_NAME \
  --image $IMAGE_NAME \
  --region $REGION \
  --platform managed \
  --allow-unauthenticated \
  --set-env-vars LATENCY_MS=100 \
  --memory 256Mi \
  --cpu 1
```

### Option 3: Deploy nhiều versions với độ trễ khác nhau

```bash
export PROJECT_ID="your-project-id"
export REGION="asia-southeast1"

# Deploy version 50ms
gcloud run deploy latency-50ms \
  --source . \
  --region $REGION \
  --platform managed \
  --allow-unauthenticated \
  --set-env-vars LATENCY_MS=50 \
  --memory 256Mi \
  --cpu 1

# Deploy version 200ms
gcloud run deploy latency-200ms \
  --source . \
  --region $REGION \
  --platform managed \
  --allow-unauthenticated \
  --set-env-vars LATENCY_MS=200 \
  --memory 256Mi \
  --cpu 1

# Deploy version 500ms
gcloud run deploy latency-500ms \
  --source . \
  --region $REGION \
  --platform managed \
  --allow-unauthenticated \
  --set-env-vars LATENCY_MS=500 \
  --memory 256Mi \
  --cpu 1
```

## 📊 Kiểm tra Service

```bash
# Get service URL
gcloud run services describe $SERVICE_NAME \
  --region $REGION \
  --format 'value(status.url)'

# Test health check
curl $(gcloud run services describe $SERVICE_NAME \
  --region $REGION \
  --format 'value(status.url)')/health

# Test API endpoint
curl $(gcloud run services describe $SERVICE_NAME \
  --region $REGION \
  --format 'value(status.url)')/api/test
```

## 🔧 Update Environment Variables

```bash
# Update độ trễ
gcloud run services update $SERVICE_NAME \
  --region $REGION \
  --set-env-vars LATENCY_MS=300
```

## 📈 Monitoring & Logs

```bash
# View logs
gcloud run services logs read $SERVICE_NAME \
  --region $REGION \
  --limit 50

# Stream logs
gcloud run services logs tail $SERVICE_NAME \
  --region $REGION

# View metrics in Cloud Console
echo "https://console.cloud.google.com/run/detail/$REGION/$SERVICE_NAME/metrics?project=$PROJECT_ID"
```

## 🧪 Load Testing trên Cloud Run

### Sử dụng Apache Bench
```bash
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME \
  --region $REGION \
  --format 'value(status.url)')

ab -n 1000 -c 50 $SERVICE_URL/health
```

### Sử dụng wrk
```bash
wrk -t4 -c100 -d60s $SERVICE_URL/health
```

## 🗑️ Cleanup

```bash
# Delete service
gcloud run services delete $SERVICE_NAME \
  --region $REGION \
  --quiet

# Delete multiple services
gcloud run services delete latency-50ms --region $REGION --quiet
gcloud run services delete latency-200ms --region $REGION --quiet
gcloud run services delete latency-500ms --region $REGION --quiet

# Delete images
gcloud container images delete gcr.io/$PROJECT_ID/$SERVICE_NAME --quiet
```

## 💡 Tips

1. **Auto-scaling**: Cloud Run tự động scale based on requests
2. **Cold start**: First request có thể chậm hơn
3. **Cost optimization**: Sử dụng `--min-instances 0` để tránh chi phí khi không dùng
4. **Monitoring**: Sử dụng Cloud Monitoring để theo dõi latency thực tế
5. **Load testing**: Test với traffic cao để verify độ trễ ổn định

## 📋 Useful Commands

```bash
# List all Cloud Run services
gcloud run services list --region $REGION

# Describe service
gcloud run services describe $SERVICE_NAME --region $REGION

# Get service URL
gcloud run services describe $SERVICE_NAME \
  --region $REGION \
  --format 'value(status.url)'

# View revisions
gcloud run revisions list --service $SERVICE_NAME --region $REGION
```
