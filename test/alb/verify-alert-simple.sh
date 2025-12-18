#!/bin/bash

# Simple script to verify alert policy status without slow gcloud commands

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}🔍 Alert Policy Verification${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Get info from terraform
cd 1_terraform 2>/dev/null || { echo -e "${RED}❌ Must run from /alb directory${NC}"; exit 1; }

PROJECT_ID=$(terraform output -raw project_id 2>/dev/null)
REGION=$(terraform output -raw region 2>/dev/null)
SERVICE_NAME=$(terraform output -raw cloudrun_service_name 2>/dev/null)
ALB_IP=$(terraform output -raw alb_ip_address 2>/dev/null)

cd ..

echo -e "${BLUE}Configuration:${NC}"
echo "  Project:  $PROJECT_ID"
echo "  Region:   $REGION"  
echo "  Service:  $SERVICE_NAME"
echo "  ALB IP:   $ALB_IP"
echo ""

# Check Cloud Run service
echo -e "${BLUE}☁️  Cloud Run Service Status:${NC}"
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME \
    --region=$REGION \
    --project=$PROJECT_ID \
    --format="value(status.url)" 2>/dev/null)

if [ -z "$SERVICE_URL" ]; then
    echo -e "${RED}❌ Cannot get service URL${NC}"
else
    echo -e "${GREEN}✅ Service running: $SERVICE_URL${NC}"
    
    # Test service endpoint
    echo ""
    echo -e "${BLUE}Testing /health endpoint...${NC}"
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$SERVICE_URL/health" 2>/dev/null)
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo -e "${GREEN}✅ Service responding (HTTP $HTTP_CODE)${NC}"
    else
        echo -e "${YELLOW}⚠️  Service response: HTTP $HTTP_CODE${NC}"
    fi
fi
echo ""

# Check current latency setting
echo -e "${BLUE}⏱️  Current Latency Configuration:${NC}"
LATENCY=$(gcloud run services describe $SERVICE_NAME \
    --region=$REGION \
    --project=$PROJECT_ID \
    --format="value(spec.template.spec.containers[0].env[?(@.name=='LATENCY_MS')].value)" 2>/dev/null)

if [ -z "$LATENCY" ]; then
    echo -e "${YELLOW}⚠️  LATENCY_MS not set (using default)${NC}"
else
    echo "  LATENCY_MS: ${LATENCY}ms ($(echo "scale=1; $LATENCY/1000" | bc)s)"
    
    if [ "$LATENCY" -gt 3000 ]; then
        echo -e "${RED}  ⚠️  High latency! This will trigger alert${NC}"
    else
        echo -e "${GREEN}  ✓ Normal latency${NC}"
    fi
fi
echo ""

# Alert Policy Info
echo -e "${BLUE}🚨 Alert Policy:${NC}"
echo "  Name: High Latency Alert - ALB to Cloud Run"
echo "  Metric: loadbalancing.googleapis.com/https/backend_latencies"
echo "  Condition: 95th percentile > 3000ms (3 seconds)"
echo "  Window: 60 seconds"
echo "  Email: baonguyen.aws@gmail.com"
echo ""

# Web Console Links
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}🌐 Web Console (for real-time data)${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Metrics Explorer:"
echo "  https://console.cloud.google.com/monitoring/metrics-explorer?project=$PROJECT_ID"
echo ""
echo "Alert Policies:"
echo "  https://console.cloud.google.com/monitoring/alerting/policies?project=$PROJECT_ID"
echo ""
echo "Cloud Run Service:"
echo "  https://console.cloud.google.com/run/detail/$REGION/$SERVICE_NAME/metrics?project=$PROJECT_ID"
echo ""
echo "Load Balancer:"
echo "  https://console.cloud.google.com/net-services/loadbalancing/list/loadBalancers?project=$PROJECT_ID"
echo ""

# Workflow
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}📝 Test Alert Workflow${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "1. Set high latency (>3s):"
echo "   ./update-latency.sh 4000"
echo ""
echo "2. Generate traffic:"
echo "   ./test-load.sh test.nhameo.site"
echo "   # or"
echo "   ./test-load.sh $ALB_IP"
echo ""
echo "3. Monitor (wait 2-5 minutes):"
echo "   - Check Metrics Explorer (link above)"
echo "   - Look for backend_latencies metric"
echo ""
echo "4. Alert triggers (3-6 minutes):"
echo "   - Check Alert Policies (link above)"
echo "   - Email notification (5-10 minutes)"
echo ""
echo "5. Reset to normal:"
echo "   ./update-latency.sh 100"
echo ""
