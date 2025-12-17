#!/bin/bash

# Deploy Auto-Failover Monitor Service to Cloud Run
# Usage: ./deploy.sh
# Note: This script builds the image and deploys the service with Cloud Scheduler

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ID="rare-karma-480813-i3"
REGION="asia-northeast2"
SERVICE_ACCOUNT="1088946422308-compute@developer.gserviceaccount.com"
IAM_ROLE="roles/compute.loadBalancerAdmin"
REPO_NAME="auto-failover-monitor"
SERVICE_NAME="auto-failover-monitor"
IMAGE_NAME="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${SERVICE_NAME}"
CPU="1"
MEMORY="768Mi"
MIN_INSTANCES="1"
MAX_INSTANCES="2"
JOB_NAME="auto-failover-monitor-job"
SCHEDULE="*/1 * * * *"  # Every 1 minute


echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}🚀 Deploying Auto-Failover Monitor to Cloud Run${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo "  Project ID:     $PROJECT_ID"
echo "  Region:         $REGION"
echo "  Service Name:   $SERVICE_NAME"
echo "  Image:          $IMAGE_NAME"
echo "  Memory:         $MEMORY"
echo "  CPU:            $CPU"
echo "  Min Instances:  $MIN_INSTANCES"
echo "  Max Instances:  $MAX_INSTANCES"
echo "  Scheduler:      $SCHEDULE"
echo ""

# Confirm
read -p "Continue with deployment? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Deployment cancelled${NC}"
    exit 1
fi

# Step 1: Check env.yaml file
echo ""
echo -e "${YELLOW}Step 1: Checking env.yaml file...${NC}"
if [ ! -f env.yaml ]; then
    echo -e "${RED}   ✗ Error: env.yaml not found!${NC}"
    echo -e "${YELLOW}   Please create env.yaml from env.example.yaml${NC}"
    echo "     cp env.example.yaml env.yaml"
    exit 1
else
    echo -e "${GREEN}   ✓ env.yaml file found${NC}"
fi

# Step 2: Configure Docker authentication
echo ""
echo -e "${YELLOW}Step 2: Configuring Docker authentication for Artifact Registry...${NC}"
gcloud auth configure-docker ${REGION}-docker.pkg.dev --quiet
echo -e "${GREEN}   ✓ Docker authentication configured${NC}"

# Step 3: Create Artifact Registry repository if not exists
echo ""
echo -e "${YELLOW}Step 3: Checking Artifact Registry repository...${NC}"
if gcloud artifacts repositories describe ${REPO_NAME} \
  --location=${REGION} \
  --project=${PROJECT_ID} &>/dev/null; then
    echo -e "${GREEN}   ✓ Repository already exists${NC}"
else
    echo -e "${YELLOW}   Creating new repository...${NC}"
    gcloud artifacts repositories create ${REPO_NAME} \
      --repository-format=docker \
      --location=${REGION} \
      --project=${PROJECT_ID} \
      --description="Docker repository for ${SERVICE_NAME}" \
      --quiet
    echo -e "${GREEN}   ✓ Repository created successfully${NC}"
fi

# Step 4: Build Docker image
echo ""
echo -e "${YELLOW}Step 4: Building Docker image for linux/amd64...${NC}"
docker build --platform linux/amd64 -t ${IMAGE_NAME} .
echo -e "${GREEN}   ✓ Image built successfully${NC}"

# Step 5: Push image to Artifact Registry
echo ""
echo -e "${YELLOW}Step 5: Pushing image to Artifact Registry...${NC}"
docker push ${IMAGE_NAME}
echo -e "${GREEN}   ✓ Image pushed successfully${NC}"

# Step 6: Deploy to Cloud Run
echo ""
echo -e "${YELLOW}Step 6: Deploying to Cloud Run...${NC}"
gcloud run deploy ${SERVICE_NAME} \
  --image ${IMAGE_NAME} \
  --platform managed \
  --project ${PROJECT_ID} \
  --region ${REGION} \
  --cpu ${CPU} \
  --memory ${MEMORY} \
  --min-instances ${MIN_INSTANCES} \
  --max-instances ${MAX_INSTANCES} \
  --env-vars-file env.yaml \
  --allow-unauthenticated \
  --timeout 300

echo -e "${GREEN}   ✓ Service deployed successfully${NC}"

# Step 7: Grant IAM permissions
echo ""
echo -e "${YELLOW}Step 7: Granting Load Balancer Admin role...${NC}"
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="${IAM_ROLE}" \
  --condition=None \
  --quiet
echo -e "${GREEN}   ✓ IAM role granted${NC}"

# Step 8: Get service URL
echo ""
echo -e "${YELLOW}Step 8: Getting service information...${NC}"
SERVICE_URL=$(gcloud run services describe ${SERVICE_NAME} \
  --region ${REGION} \
  --project ${PROJECT_ID} \
  --format 'value(status.url)')
STATUS_URL="${SERVICE_URL}/status"
MONITOR_URL="${SERVICE_URL}/monitor"

echo -e "${GREEN}   ✓ Service URL retrieved${NC}"

# Step 9: Configure Cloud Scheduler
echo ""
echo -e "${YELLOW}Step 9: Configuring Cloud Scheduler job...${NC}"

# Enable Cloud Scheduler API if not enabled
gcloud services enable cloudscheduler.googleapis.com --project=${PROJECT_ID} --quiet 2>/dev/null || true
echo -e "${GREEN}   ✓ Cloud Scheduler API enabled${NC}"

if gcloud scheduler jobs describe ${JOB_NAME} --location=${REGION} --project=${PROJECT_ID} &>/dev/null; then
    echo -e "${YELLOW}   Scheduler job already exists. Updating...${NC}"
    gcloud scheduler jobs update http ${JOB_NAME} \
      --location ${REGION} \
      --schedule "${SCHEDULE}" \
      --uri "${MONITOR_URL}" \
      --http-method GET \
      --project ${PROJECT_ID} \
      --quiet
    echo -e "${GREEN}   ✓ Scheduler job updated${NC}"
else
    echo -e "${YELLOW}   Creating new scheduler job...${NC}"
    gcloud scheduler jobs create http ${JOB_NAME} \
      --location ${REGION} \
      --schedule "${SCHEDULE}" \
      --uri "${MONITOR_URL}" \
      --http-method GET \
      --project ${PROJECT_ID} \
      --quiet
    echo -e "${GREEN}   ✓ Scheduler job created${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Service Information${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "  Project ID:     $PROJECT_ID"
echo "  Region:         $REGION"
echo "  Service Name:   $SERVICE_NAME"
echo "  Service URL:    $SERVICE_URL"
echo "  Status URL:     $STATUS_URL"
echo "  Monitor URL:    $MONITOR_URL"
echo "  Scheduler Job:  $JOB_NAME"
echo "  Schedule:       $SCHEDULE (every 1 minute)"
echo ""
echo -e "${YELLOW}Quick Test:${NC}"
echo "  curl $SERVICE_URL"
echo "  curl $STATUS_URL | jq"
echo "  curl $MONITOR_URL | jq"
echo ""
echo -e "${YELLOW}View Logs:${NC}"
echo "  gcloud run services logs read $SERVICE_NAME --region $REGION --project $PROJECT_ID --limit 50"
echo ""
echo -e "${YELLOW}Stream Logs:${NC}"
echo "  gcloud run services logs tail $SERVICE_NAME --region $REGION --project $PROJECT_ID"
echo ""
echo -e "${YELLOW}Describe Service:${NC}"
echo "  gcloud run services describe $SERVICE_NAME --region $REGION --project $PROJECT_ID"
echo ""
echo -e "${YELLOW}View Scheduler Jobs:${NC}"
echo "  gcloud scheduler jobs list --location $REGION --project $PROJECT_ID"
echo ""
echo -e "${YELLOW}View Metrics:${NC}"
echo "  https://console.cloud.google.com/run/detail/$REGION/$SERVICE_NAME/metrics?project=$PROJECT_ID"
echo ""
echo -e "${YELLOW}Delete Service:${NC}"
echo "  gcloud run services delete $SERVICE_NAME --region $REGION --project $PROJECT_ID --quiet"
echo "  gcloud scheduler jobs delete $JOB_NAME --location $REGION --project $PROJECT_ID --quiet"
echo ""

# Wait for service to be fully ready
echo -e "${YELLOW}Waiting 10 seconds for service to be fully ready...${NC}"
sleep 10

# Test the service
echo -e "${YELLOW}Testing service...${NC}"
response=$(curl -s -w "\n%{http_code}" $STATUS_URL 2>/dev/null || echo "\nERROR")
http_code=$(echo "$response" | tail -n1)

if [ "$http_code" == "200" ]; then
    echo -e "${GREEN}✓ Service is responding correctly${NC}"
    echo -e "${GREEN}  HTTP Status: $http_code${NC}"
    echo ""
    echo -e "${GREEN}Response:${NC}"
    curl -s $STATUS_URL | jq
else
    echo -e "${RED}✗ Service returned HTTP $http_code${NC}"
    echo -e "${YELLOW}  Note: Service may need a few moments to fully start${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"