# Latency Simulator

Công cụ giả lập độ trễ (latency) khi chạy container, hỗ trợ cấu hình linh hoạt qua biến môi trường.

## ✨ Tính năng

- ✅ Cấu hình độ trễ qua biến môi trường `LATENCY_MS` (milliseconds)
- ✅ Variance ±10% để mô phỏng realistic hơn
- ✅ Web UI hiển thị thông tin real-time với auto-refresh
- ✅ JSON API endpoint cho automation testing
- ✅ Hỗ trợ HTTP GET và POST requests
- ✅ Lightweight - chỉ dùng Python standard library
- ✅ Health check endpoint cho Cloud Run
- ✅ Sẵn sàng deploy lên Google Cloud Run

## 🚀 Quick Start

### Local Testing

```bash
# Clone repo và cd vào thư mục
cd 9_test/cloudrun/3_latency

# Build và run với Docker Compose (100ms latency)
docker compose up -d

# Kiểm tra
curl http://localhost:8080/health
curl http://localhost:8080/api/test

# Xem logs
docker logs -f latency-test

# Dọn dẹp
docker compose down
```

### Test nhiều độ trễ cùng lúc

```bash
# Build image
docker compose build

# Start nhiều containers
docker compose -f docker-compose-50ms.yml up -d   # Port 8050
docker compose -f docker-compose-200ms.yml up -d  # Port 8200
docker compose -f docker-compose-500ms.yml up -d  # Port 8500

# Test
curl http://localhost:8050/api/test   # 50ms
curl http://localhost:8200/api/test   # 200ms
curl http://localhost:8500/api/test   # 500ms
```

## 📊 Endpoints

### Health Check (Web UI)
```
GET http://localhost:8080/health
GET http://localhost:8080/
```

Response: HTML page với thông tin real-time

### API Test (JSON)
```
GET http://localhost:8080/api/test
POST http://localhost:8080/api/test
```

Response:
```json
{
    "status": "ok",
    "target_latency_ms": 100,
    "actual_response_time_ms": 105.23,
    "timestamp": "2025-12-13T10:30:45.123456"
}
```

## 🔧 Cấu hình

### Biến môi trường

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `LATENCY_MS` | Độ trễ mục tiêu (milliseconds) | `100` | `50`, `200`, `500` |
| `PORT` | Port của HTTP server | `8080` | `8080` |

### Docker Compose

```yaml
environment:
  - LATENCY_MS=100  # Thay đổi giá trị này
  - PORT=8080
```

### Custom Latency

```bash
docker run -d \
  --name latency-custom \
  -p 8350:8080 \
  -e LATENCY_MS=350 \
  -e PORT=8080 \
  latency-simulator:latest
```

## 🌐 Deploy to Cloud Run

### Quick Deploy

```bash
# Set project
export PROJECT_ID="your-project-id"
gcloud config set project $PROJECT_ID

# Deploy với 100ms latency
./deploy-cloudrun.sh 100

# Hoặc deploy nhiều versions
./deploy-all-cloud-run.sh
```

### Manual Deploy

```bash
gcloud run deploy latency-simulator \
  --source . \
  --region asia-southeast1 \
  --platform managed \
  --allow-unauthenticated \
  --set-env-vars LATENCY_MS=100 \
  --memory 256Mi \
  --cpu 1
```

Chi tiết xem [QUICK_START_CLOUD_RUN.md](QUICK_START_CLOUD_RUN.md)

## 🧪 Load Testing

### Apache Bench
```bash
ab -n 1000 -c 50 http://localhost:8080/health
```

### wrk
```bash
wrk -t4 -c100 -d60s http://localhost:8080/health
```

## 📁 File Structure

```
3_latency/
├── latency_simulator.py          # Script chính
├── Dockerfile                     # Container definition
├── requirements.txt               # Python dependencies (empty - no external deps)
├── docker-compose.yml             # Default (100ms)
├── docker-compose-50ms.yml        # 50ms config
├── docker-compose-200ms.yml       # 200ms config
├── docker-compose-500ms.yml       # 500ms config
├── deploy-cloudrun.sh            # Deploy script cho Cloud Run
├── deploy-all-cloud-run.sh        # Deploy nhiều versions
├── QUICK_START_LOCAL.md           # Hướng dẫn test local
├── QUICK_START_CLOUD_RUN.md       # Hướng dẫn deploy Cloud Run
└── README.md                      # File này
```

## 💡 Use Cases

1. **Testing API latency**: Giả lập độ trễ của external APIs
2. **Network simulation**: Mô phỏng các điều kiện mạng khác nhau
3. **Performance testing**: Kiểm tra ứng dụng với độ trễ cao
4. **Timeout testing**: Test timeout handling của client
5. **Load balancer testing**: Test với nhiều backends có latency khác nhau

## 📈 Monitoring

```bash
# Docker logs
docker logs -f latency-test

# Docker stats
docker stats latency-test

# Cloud Run logs
gcloud run services logs read latency-simulator --region asia-southeast1
```

## 🗑️ Cleanup

### Local
```bash
docker compose down
docker compose -f docker-compose-50ms.yml down
docker compose -f docker-compose-200ms.yml down
docker compose -f docker-compose-500ms.yml down
```

### Cloud Run
```bash
gcloud run services delete latency-simulator --region asia-southeast1 --quiet
```

## 🤝 Contributing

Mọi đóng góp đều được hoan nghênh! 

## 📄 License

MIT License
