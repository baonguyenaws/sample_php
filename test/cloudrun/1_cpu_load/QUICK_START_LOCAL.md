# Quick Start Guide - CPU Load Generator (Local Testing)

## 🚀 3 Mức CPU Support: 75%, 85%, 99%

### Option 1: Test Local - Single Container

```bash
# Default 75%
docker compose up -d
curl http://localhost:8080/health
docker stats cpu-load-test

# Custom target (edit docker-compose.yml)
# environment:
#   - CPU_TARGET=75  # Options: 75, 85, 95, 100 (percentage of memory to consume)

docker compose down
docker compose up -d
```

## 📝 Files

- `cpu_load.py` - Core CPU load generator
- `cpu_load_with_http.py` - HTTP server wrapper (used by Dockerfile)
- `Dockerfile` - Container definition
- `docker-compose.yml` - Default config (75%)
