# ALB + Cloud Run + Alert Policy - Complete Workflow

Hướng dẫn từ A-Z để tạo ALB kết nối Cloud Run và test Alert Policy khi latency > 3 giây.

## 📋 Tổng quan

- **1_terraform/** - Terraform code để tạo ALB, Cloud Run, NEG và Alert Policy
- **2_latency/** - Latency simulator app để test
- **deploy-test-app.sh** - Script deploy app từ 2_latency lên Cloud Run
- **update-latency.sh** - Script update latency của Cloud Run service

---

## 🚀 Workflow Hoàn chỉnh

### **Bước 1: Setup Terraform variables**

```bash
cd 1_terraform

# Tạo file terraform.tfvars từ example
cp terraform.tfvars.example terraform.tfvars

# Edit file với thông tin của bạn
vi terraform.tfvars
```

**Cần điền:**
- `project_id` - GCP project ID
- `region` - Region (vd: us-central1, asia-northeast1)
- `cloudrun_service_name` - Tên service (vd: latency-test)
- `ssl_domains` - Domain của bạn (vd: ["example.com"])
- `alert_email` - Email nhận alert

### **Bước 2: Tạo infrastructure với Terraform**

```bash
# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Apply configuration
terraform apply
```

**Lưu ý:** SSL certificate có thể mất 15-60 phút để provision sau khi setup DNS.

### **Bước 3: Setup DNS**

```bash
# Lấy IP của ALB
terraform output alb_ip_address
```

Tạo DNS A record trỏ domain của bạn đến IP này.

### **Bước 4: Deploy test application**

```bash
cd ..  # Quay về thư mục alb/

# Deploy latency simulator lên Cloud Run
chmod +x deploy-test-app.sh
./deploy-test-app.sh
```

Script này sẽ deploy code từ `2_latency/` lên Cloud Run service.

### **Bước 5: Test bình thường (không trigger alert)**

```bash
# Lấy service URL
cd 1_terraform
SERVICE_URL=$(terraform output -raw cloudrun_service_url)

# Test với latency mặc định (100ms - không trigger alert)
curl $SERVICE_URL/health
curl $SERVICE_URL/api/test
```

### **Bước 6: Update latency để trigger alert**

```bash
cd ..  # Quay về alb/

# Set latency = 4 seconds (> 3s threshold)
chmod +x update-latency.sh
./update-latency.sh 4000
```

### **Bước 7: Generate traffic để trigger alert**

```bash
cd 1_terraform

# Generate load
chmod +x test-load.sh
./test-load.sh yourdomain.com

# Hoặc dùng IP nếu chưa setup DNS
./test-load.sh $(terraform output -raw alb_ip_address)
```

**Script sẽ:**
- Gửi 1200 requests trong 2 phút
- 5% requests có latency > 3 giây
- 95th percentile > 3s → trigger alert

### **Bước 8: Verify alert đã trigger**

```bash
# Wait 2-5 phút rồi check
chmod +x verify-alert.sh
./verify-alert.sh
```

**Hoặc check thủ công trong Console:**
- Metrics: https://console.cloud.google.com/monitoring/metrics-explorer
- Alerts: https://console.cloud.google.com/monitoring/alerting/policies
- Check email: Notification sẽ đến trong 5-10 phút

### **Bước 9: Reset về bình thường**

```bash
cd ..  # Quay về alb/

# Reset latency về 100ms
./update-latency.sh 100
```

Alert sẽ tự động close sau 30 phút nếu không còn vi phạm.

---

## 📝 Quick Commands Reference

```bash
# === Setup ===
cd 1_terraform
terraform init
terraform apply

# === Deploy App ===
cd ../
./deploy-test-app.sh

# === Test Alert ===
./update-latency.sh 4000                    # Set high latency
cd 1_terraform
./test-load.sh yourdomain.com               # Generate traffic
./verify-alert.sh                           # Check alert

# === Reset ===
cd ../
./update-latency.sh 100                     # Reset to normal

# === Cleanup ===
cd 1_terraform
terraform destroy
```

---

## 🔍 Monitoring & Debugging

### Check metrics từ CLI

```bash
cd 1_terraform
PROJECT_ID=$(terraform output -raw project_id)

# Backend latency metrics
gcloud monitoring time-series list \
  --project=$PROJECT_ID \
  --filter='metric.type="loadbalancing.googleapis.com/https/backend_latencies"'

# Alert policy status
gcloud alpha monitoring policies list \
  --project=$PROJECT_ID \
  --filter="displayName:'High Latency Alert - ALB to Cloud Run'"
```

### Check Cloud Run logs

```bash
SERVICE_NAME=$(terraform output -raw cloudrun_service_name)
REGION=$(terraform output -raw region)

gcloud run services logs read $SERVICE_NAME \
  --region=$REGION \
  --project=$PROJECT_ID \
  --limit=50
```

### Check ALB backend health

```bash
# List backend services
gcloud compute backend-services list --global

# Check backend health
BACKEND_NAME=$(terraform output -raw backend_service_name)
gcloud compute backend-services get-health $BACKEND_NAME --global
```

---

## ⏱️ Timeline

- **0-15 min**: Terraform apply (resources creation)
- **15-60 min**: SSL certificate provisioning (nếu dùng managed cert)
- **2-5 min**: Deploy app lên Cloud Run
- **0-2 min**: Generate traffic
- **2-5 min**: Metrics xuất hiện
- **3-6 min**: Alert trigger
- **5-10 min**: Email notification
- **30 min**: Alert auto-close

---

## 🎯 Tips

1. **Nếu chưa setup DNS**: Có thể test bằng IP nhưng cần bỏ qua SSL validation
   ```bash
   curl -k "https://ALB_IP/health"
   ```

2. **Test nhanh alert**: Update latency cao → gửi ít requests → check ngay
   ```bash
   ./update-latency.sh 5000
   curl "https://yourdomain.com/health" (repeat 10-20 lần)
   ```

3. **Monitor real-time**: Dùng Cloud Console để xem metrics real-time thay vì CLI

4. **Email không đến**: Check spam folder và verify email address trong terraform.tfvars

---

## 📚 Tài liệu chi tiết

- [1_terraform/README.md](1_terraform/README.md) - Chi tiết Terraform configuration
- [1_terraform/TEST_GUIDE.md](1_terraform/TEST_GUIDE.md) - Hướng dẫn test chi tiết
- [2_latency/README.md](2_latency/README.md) - Latency simulator documentation

---

## 🧹 Cleanup

```bash
cd 1_terraform
terraform destroy
```

**Lưu ý**: Xóa DNS record thủ công nếu đã tạo.
