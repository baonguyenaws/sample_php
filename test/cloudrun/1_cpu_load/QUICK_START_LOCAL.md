# Quick Start Guide - CPU Load Generator (Local Testing)

## 🚀 3 Mức CPU Support: 75%, 85%, 99%

### Option 1: Test Local - Single Container

```bash
# Default 85%
docker compose up -d
curl http://localhost:8080/health
docker stats cpu-load-test

# Custom target (edit docker-compose.yml)
# environment:
#   - CPU_TARGET=75  # hoặc 85, 99

docker compose down
docker compose up -d
```

### Option 2: Test Local - 3 Containers Cùng Lúc

```bash
# Build image một lần
docker compose build --no-cache

# Start cả 3 containers
docker compose -f docker-compose-75.yml up -d  # Port 8075
docker compose -f docker-compose-85.yml up -d  # Port 8085
docker compose -f docker-compose-99.yml up -d  # Port 8099

# Test health check
curl http://localhost:8075/health
curl http://localhost:8085/health
curl http://localhost:8099/health

# Monitor CPU usage
docker stats cpu-load-75 cpu-load-85 cpu-load-99

# Cleanup
docker compose -f docker-compose-75.yml down
docker compose -f docker-compose-85.yml down
docker compose -f docker-compose-99.yml down
```

### Option 3: Test Dockerfile trực tiếp

```bash
# Build image
docker build -t cpu-load-test:local .

# Run single container với custom config
docker run -d \
  --name cpu-test-85 \
  -p 8080:8080 \
  -e CPU_TARGET=85 \
  -e STARTUP_DELAY=2 \
  cpu-load-test:local

# Test health check
curl http://localhost:8080/health

# Monitor
docker stats cpu-test-85

# Cleanup
docker stop cpu-test-85
docker rm cpu-test-85
```

### Option 4: Test 3 containers với custom ports

```bash
# Build image một lần
docker build -t cpu-load-test:local .

# Run 3 containers
docker run -d --name cpu-test-75 -p 8075:8080 -e CPU_TARGET=75 cpu-load-test:local
docker run -d --name cpu-test-85 -p 8085:8080 -e CPU_TARGET=85 cpu-load-test:local
docker run -d --name cpu-test-99 -p 8099:8080 -e CPU_TARGET=99 cpu-load-test:local

# Test all
curl http://localhost:8075/health
curl http://localhost:8085/health
curl http://localhost:8099/health

# Monitor all
docker stats cpu-test-75 cpu-test-85 cpu-test-99

# Cleanup all
docker stop cpu-test-75 cpu-test-85 cpu-test-99
docker rm cpu-test-75 cpu-test-85 cpu-test-99
```

## 📊 Expected Results

| CPU_TARGET | Expected CPU Usage | Container Name | Port (Local) |
|------------|-------------------|----------------|--------------|
| 75% | ~75% of 1 core | cpu-load-75 | 8075 |
| 85% | ~85% of 1 core | cpu-load-85 | 8085 |
| 99% | ~99% of 1 core | cpu-load-99 | 8099 |

## 💡 Quick Tips

- ✅ Sử dụng `docker stats` để monitor CPU usage real-time
- ✅ Set `CPU_TARGET` qua environment variable (75, 85, hoặc 99)
- ✅ Port 8080 bên trong container, map ra port khác nếu cần
- ✅ `STARTUP_DELAY` mặc định là 5s, có thể giảm xuống 2s cho local test
- ✅ Nhớ cleanup containers sau khi test!

## 🔧 Troubleshooting Local

### Container không start

```bash
# Check logs
docker logs cpu-test-85

# Check nếu port đã được sử dụng
lsof -i :8080
netstat -tuln | grep 8080
```

### CPU usage không đúng target

```bash
# Kiểm tra container có CPU limit không
docker inspect cpu-test-85 | grep -A 5 "CpuQuota"

# Check logs để xem configuration
docker logs cpu-test-85 | head -20
```

### Test health check

```bash
# Verbose curl
curl -v http://localhost:8080/health

# Watch continuously
watch -n 1 'curl -s http://localhost:8080/health'
```

## 📝 Files

- `cpu_load.py` - Core CPU load generator
- `cpu_load_with_http.py` - HTTP server wrapper (used by Dockerfile)
- `Dockerfile` - Container definition
- `docker-compose.yml` - Default config (85%)
- `docker-compose-75.yml` - 75% CPU config
- `docker-compose-85.yml` - 85% CPU config
- `docker-compose-99.yml` - 99% CPU config

## 🎯 Next Steps

Sau khi test local thành công, xem file `QUICK_START_CLOUD_RUN.md` để deploy lên GCP Cloud Run.
