# Quick Start Guide - Latency Simulator (Local Testing)

## 🚀 Giới thiệu

Script này giả lập độ trễ (latency) khi chạy image. Độ trễ được truyền qua biến môi trường `LATENCY_MS` (tính bằng milliseconds).

## 📋 Cấu hình độ trễ có sẵn

- **50ms** - Độ trễ thấp (mạng nội bộ)
- **100ms** - Độ trễ trung bình (mặc định)
- **200ms** - Độ trễ cao (mạng internet)
- **500ms** - Độ trễ rất cao (kết nối chậm)

## 🎯 Option 1: Test Local - Single Container

```bash
# Mặc định 100ms
docker compose up -d
curl http://localhost:8080/health
docker logs -f latency-test

# Thay đổi độ trễ (sửa docker-compose.yml)
# environment:
#   - LATENCY_MS=200  # Đơn vị: milliseconds

docker compose down
docker compose up -d
```

## 🎯 Option 2: Test Local - Nhiều Containers Cùng Lúc

```bash
# Build image một lần
docker compose build --no-cache

# Start nhiều containers với độ trễ khác nhau
docker compose -f docker-compose-50ms.yml up -d   # Port 8050
docker compose -f docker-compose-200ms.yml up -d  # Port 8200
docker compose -f docker-compose-500ms.yml up -d  # Port 8500

# Kiểm tra
curl http://localhost:8050/health    # 50ms latency
curl http://localhost:8200/health    # 200ms latency
curl http://localhost:8500/health    # 500ms latency

# Cleanup
docker compose -f docker-compose-50ms.yml down
docker compose -f docker-compose-200ms.yml down
docker compose -f docker-compose-500ms.yml down
```

## 🧪 Test Endpoints

### Health Check (Web UI)
```bash
curl http://localhost:8080/health
# Hoặc mở trình duyệt: http://localhost:8080
```

### API Test (JSON Response)
```bash
curl http://localhost:8080/api/test
```

### Test với ab (Apache Bench)
```bash
# Cài đặt ab nếu chưa có
# macOS: brew install httpd
# Ubuntu: sudo apt-get install apache2-utils

# Test với 100 requests, 10 concurrent
ab -n 100 -c 10 http://localhost:8080/health

# Test API endpoint
ab -n 100 -c 10 http://localhost:8080/api/test
```

### Test với wrk
```bash
# Cài đặt wrk
# macOS: brew install wrk

# Test 30 giây, 10 connections, 2 threads
wrk -t2 -c10 -d30s http://localhost:8080/health
```

## 📊 Monitoring

```bash
# Xem logs real-time
docker logs -f latency-test

# Xem stats
docker stats latency-test

# Kiểm tra container
docker ps | grep latency
```

## 🔧 Custom Latency

Bạn có thể tạo độ trễ tùy chỉnh:

```bash
# Ví dụ: 350ms latency
docker run -d \
  --name latency-custom \
  -p 8350:8080 \
  -e LATENCY_MS=350 \
  -e PORT=8080 \
  latency-simulator:latest
```

## 📝 Files

- `latency_simulator.py` - Script chính giả lập độ trễ
- `Dockerfile` - Container definition
- `docker-compose.yml` - Default config (100ms)
- `docker-compose-50ms.yml` - 50ms latency
- `docker-compose-200ms.yml` - 200ms latency
- `docker-compose-500ms.yml` - 500ms latency

## 💡 Đặc điểm

- ✅ Độ trễ cấu hình qua biến môi trường `LATENCY_MS`
- ✅ Variance ±10% để mô phỏng realistic hơn
- ✅ Web UI hiển thị thông tin real-time
- ✅ JSON API endpoint cho automation testing
- ✅ Auto-refresh mỗi 5 giây
- ✅ Lightweight - chỉ dùng Python standard library

## 🚀 Next Steps

Sau khi test local thành công, xem file `QUICK_START_CLOUD_RUN.md` để deploy lên GCP Cloud Run.
