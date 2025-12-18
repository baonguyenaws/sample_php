#!/bin/bash

# Script to verify alert policy and check metrics

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}🔍 Verifying Alert Policy & Metrics${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Get project ID from terraform
cd 1_terraform 2>/dev/null || { echo -e "${RED}❌ Must run from /alb directory${NC}"; exit 1; }

PROJECT_ID=$(terraform output -raw project_id 2>/dev/null)

if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}❌ Cannot get project ID from terraform outputs${NC}"
    exit 1
fi

cd ..

echo -e "${YELLOW}Project ID: $PROJECT_ID${NC}"
echo ""

# Get alert policy name
echo -e "${BLUE}📋 Fetching Alert Policy...${NC}"
ALERT_POLICY=$(timeout 10 gcloud alpha monitoring policies list \
    --project=$PROJECT_ID \
    --filter="displayName:'High Latency Alert - ALB to Cloud Run'" \
    --format="value(name)" 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$ALERT_POLICY" ]; then
    echo -e "${YELLOW}⚠️  Cannot fetch alert policy details (command timed out or failed)${NC}"
    echo "Trying alternative method..."
    
    # Try without alpha
    ALERT_POLICY=$(timeout 10 gcloud monitoring policies list \
        --project=$PROJECT_ID \
        --filter="displayName:'High Latency Alert - ALB to Cloud Run'" \
        --format="value(name)" 2>/dev/null)
    
    if [ -z "$ALERT_POLICY" ]; then
        echo -e "${RED}❌ Alert policy not found!${NC}"
        echo "Make sure you have run: cd 1_terraform && terraform apply"
        echo ""
        echo "You can check manually in console:"
        echo "  https://console.cloud.google.com/monitoring/alerting/policies?project=$PROJECT_ID"
        exit 1
    fi
fi

echo -e "${GREEN}✅ Alert Policy found${NC}"
echo "   Name: $ALERT_POLICY"
echo ""

# Check alert policy details
echo -e "${BLUE}📊 Alert Policy Status:${NC}"
timeout 10 gcloud alpha monitoring policies describe $ALERT_POLICY \
    --project=$PROJECT_ID \
    --format="table(displayName, enabled, conditions[].displayName, conditions[].conditionThreshold.thresholdValue)" 2>/dev/null || \
    echo -e "${YELLOW}Unable to fetch details (use web console)${NC}"
echo ""

# Check for active incidents
echo -e "${YELLOW}Skipping incident check (can be slow)${NC}"
echo "Check incidents manually in console (see link below)"      --project=$PROJECT_ID 2>/dev/null || true
fi
echo ""

# Check recent metrics
echo -e "${BLUE}📈 Recent Backend Latency Metrics (last 10 minutes):${NC}"
METRICS=$(gcloud monitoring time-series list \
    --project=$PROJECT_ID \
    --filter='metric.type="loadbalancing.googleapis.com/https/backend_latencies"' \
    --format="table(resource.labels.url_map_name, metric.type)" \
    --limit=5 2>/dev/null)

if [ -z "$METRICS" ]; then
    echo -e "${YELLOW}⚠️  No metrics available yet${NC}"
    echo "   Metrics may take 2-5 minutes to appear after sending requests"
    echo ""
    echo "   If you just ran test-load.sh, please wait and try again"
else
    echo "$METRICS"
    echo ""
    echo -e "${GREEN}✅ Metrics are being collected${NC}"
fi
echo ""

# Check notification channels
echo -e "${BLUE}📧 Notification Channels:${NC}"
gcloud alpha monitoring channels list \
    --project=$PROJECT_ID \
    --filter="type=email" \
    --format="table(displayName, labels.email_address, enabled)" 2>/dev/null || echo "No email channels found"
echo ""

# Summary and next steps
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}📝 Summary & Next Steps${NC}"
echo -e "${GREEN}========================================${NC}"
timeout 10 gcloud alpha monitoring channels list \
    --project=$PROJECT_ID \
    --filter="type=email" \
    --format="table(displayName, labels.email_address, enabled)" 2>/dev/null || \
    echo -e "${YELLOW}Cannot fetch channels (use web console)${NC}
    echo ""
    echo "What to do:"
    echo "  1. Make sure you have run: ./update-latency.sh 4000"
    echo "  2. Generate traffic: ./test-load.sh yourdomain.com"
    echo "  3. Wait 2-5 minutes for metrics to appear"
    echo "  4. Run this script again: ./verify-alert.sh"
else
    echo -e "${GREEN}Status: Metrics are being collected${NC}"
    echo ""
    echo "What to check:"
    echo "  1. Wait 3-6 minutes after sending traffic"
    echo "  2. Check if alert has triggered (incidents appear above)"
    echo "  3. Check your email (may take 5-10 minutes)"
    echo "  4. Alert will auto-close after 30 minutes if condition clears"
fi

echo ""
echo -e "${BLUE}🌐 Web Console Links:${NC}"
echo "  Metrics Explorer:"
echo "    https://console.cloud.google.com/monitoring/metrics-explorer?project=$PROJECT_ID"
echo ""
echo "  Alert Policies:"
echo "    https://console.cloud.google.com/monitoring/alerting/policies?project=$PROJECT_ID"
echo ""
echo "  Load Balancing Monitoring:"
echo "    https://console.cloud.google.com/net-services/loadbalancing/list/loadBalancers?project=$PROJECT_ID"
echo ""

# Detailed metrics query
echo -e "${BLUE}💡 To see detailed latency metrics, run:${NC}"
echo '  gcloud monitoring time-series list \'
echo '    --project='$PROJECT_ID' \'
echo '    --filter='"'"'metric.type="loadbalancing.googleapis.com/https/backend_latencies"'"'"' \'
echo '    --format="json" | jq '"'"'.[] | {url_map: .resource.labels.url_map_name, mean: .points[].value.distributionValue.mean}'"'"
echo ""
