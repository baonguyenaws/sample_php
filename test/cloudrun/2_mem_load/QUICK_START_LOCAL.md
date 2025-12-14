# Quick Start Guide - Memory Load Generator (Local Testing)

## 🚀 3 Mức Memory Support: 75%, 85%, 99%

### Test Local - Single Container

```bash
# Default 75%
docker compose up -d
curl http://localhost:8080/health
docker stats memory-load-test

# Custom target (edit docker-compose.yml)
# environment:
#   - MEMORY_TARGET=75  # Options: 75, 85, 95, 100 (percentage of memory to consume)

docker compose down
docker compose up -d
```

## 📝 Files

- `memory_load.py` - Core Memory load generator
- `mem_load_with_http.py` - HTTP server wrapper (used by Dockerfile)
- `Dockerfile` - Container definition
- `docker-compose.yml` - Default config (75%)
