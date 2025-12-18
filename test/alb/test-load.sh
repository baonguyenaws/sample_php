#!/bin/bash

# Script to generate load and trigger alert policy
# This script sends requests with high latency to trigger the alert

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
DOMAIN=${1:-""}
REQUESTS_PER_SECOND=10
DURATION_MINUTES=2

if [ -z "$DOMAIN" ]; then
    echo -e "${RED}❌ Error: Domain or IP required${NC}"
    echo ""
    echo "Usage: $0 <DOMAIN_OR_IP>"
    echo ""
    echo "Examples:"
    echo "  $0 yourdomain.com"
    echo "  $0 34.120.45.67"
    echo ""
    echo "Or get ALB IP from terraform:"
    echo "  cd 1_terraform && terraform output -raw alb_ip_address"
    exit 1
fi

# Get Cloud Run service URL from terraform for direct backend testing
cd 1_terraform 2>/dev/null || true
SERVICE_URL=$(terraform output -raw cloudrun_service_url 2>/dev/null || echo "")
cd .. 2>/dev/null || true

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}🚀 Starting Load Test${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo "  Target:         $DOMAIN"
echo "  Rate:           $REQUESTS_PER_SECOND req/s"
echo "  Duration:       $DURATION_MINUTES minutes"
if [ ! -z "$SERVICE_URL" ]; then
    echo "  Backend URL:    $SERVICE_URL"
fi
echo ""

# Calculate total requests
TOTAL_SECONDS=$((DURATION_MINUTES * 60))
TOTAL_REQUESTS=$((REQUESTS_PER_SECOND * TOTAL_SECONDS))

echo -e "${BLUE}📊 Test plan:${NC}"
echo "  Total requests: $TOTAL_REQUESTS"
echo "  Expected to trigger alert when 95th percentile > 3s"
echo ""

# Determine protocol and URL
if [[ $DOMAIN =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    # It's an IP address
    BASE_URL="https://$DOMAIN"
    INSECURE_FLAG="--insecure"
    echo -e "${YELLOW}⚠️  Using IP address - SSL validation disabled${NC}"
else
    # It's a domain
    BASE_URL="https://$DOMAIN"
    INSECURE_FLAG=""
fi

echo ""
echo -e "${BLUE}🔄 Sending requests...${NC}"
echo ""

counter=0
success_count=0
error_count=0
start_time=$(date +%s)

# Function to send request
send_request() {
    local endpoint=$1
    local type=$2
    
    if curl -s -o /dev/null -w "%{http_code}" \
        "${BASE_URL}${endpoint}" \
        -H "Host: $DOMAIN" \
        $INSECURE_FLAG \
        --connect-timeout 10 \
        --max-time 30 2>/dev/null | grep -q "200"; then
        ((success_count++))
    else
        ((error_count++))
    fi
}

# Send requests
while [ $counter -lt $TOTAL_REQUESTS ]; do
    # All requests go to /health endpoint
    # The backend latency is controlled by LATENCY_MS env var set earlier
    send_request "/health" "test" &
    
    ((counter++))
    
    # Print progress every 50 requests
    if [ $((counter % 50)) -eq 0 ]; then
        elapsed=$(($(date +%s) - start_time))
        echo -e "${BLUE}Progress: $counter/$TOTAL_REQUESTS requests (${elapsed}s elapsed, $success_count success, $error_count errors)${NC}"
    fi
    
    # Control request rate (requests per second)
    sleep $(echo "scale=3; 1/$REQUESTS_PER_SECOND" | bc)
done

# Wait for all background requests to complete
echo ""
echo -e "${YELLOW}Waiting for all requests to complete...${NC}"
wait

total_time=$(($(date +%s) - start_time))

echo ""
echo -e "${GREEN}✅ Load test completed!${NC}"
echo ""
echo -e "${BLUE}📈 Summary:${NC}"
echo "  Total requests:   $TOTAL_REQUESTS"
echo "  Successful:       $success_count"
echo "  Errors:           $error_count"
echo "  Duration:         ${total_time}s"
echo "  Actual rate:      $(echo "scale=2; $TOTAL_REQUESTS/$total_time" | bc) req/s"
echo ""
echo -e "${YELLOW}🔍 Next steps:${NC}"
echo "  1. Wait 2-5 minutes for metrics to appear in Cloud Monitoring"
echo "  2. Alert should trigger within 3-6 minutes if latency > 3s"
echo "  3. Email notification within 5-10 minutes"
echo ""
echo -e "${BLUE}Check status with:${NC}"
echo "  cd 1_terraform && ./verify-alert.sh"
echo ""
echo -e "${BLUE}View in Console:${NC}"
echo "  Metrics: https://console.cloud.google.com/monitoring/metrics-explorer"
echo "  Alerts:  https://console.cloud.google.com/monitoring/alerting/policies"
