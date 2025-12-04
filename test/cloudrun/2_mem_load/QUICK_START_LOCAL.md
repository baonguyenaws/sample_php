# Quick Start Guide - Memory Load Generator (Local)

## 🚀 Test Local với Docker Compose

### Option 1: Single Container (Default 75%)

```bash
# Start container
docker compose up -d

# Check health
curl http://localhost:8080/health

# Monitor memory usage
docker stats memory-load-test

# Cleanup
docker compose down
```

### Option 2: Custom Memory Target

Edit `docker-compose.yml`:
```yaml
environment:
  - MEMORY_TARGET=85  # Change to 75, 85, or 99
```

Then:
```bash
docker compose down
docker compose up -d
```

### Option 3: Run 3 Containers Simultaneously (75%, 85%, 99%)

```bash
# Build image once
docker compose build --no-cache

# Start all 3 containers
docker compose -f docker-compose-75.yml up -d  # Port 8175
docker compose -f docker-compose-85.yml up -d  # Port 8185
docker compose -f docker-compose-99.yml up -d  # Port 8199

# Test health checks
curl http://localhost:8175/health
curl http://localhost:8185/health
curl http://localhost:8199/health

# Monitor all containers
docker stats memory-load-75 memory-load-85 memory-load-99

# Cleanup
docker compose -f docker-compose-75.yml down
docker compose -f docker-compose-85.yml down
docker compose -f docker-compose-99.yml down
```

## 📊 Expected Results

| Container | MEMORY_TARGET | Memory Limit | Expected Usage | Port |
|-----------|---------------|--------------|----------------|------|
| memory-load-75 | 75% | 512MB | ~384MB | 8175 |
| memory-load-85 | 85% | 512MB | ~435MB | 8185 |
| memory-load-99 | 99% | 512MB | ~507MB | 8199 |

## 💡 Tips

- Memory allocation happens gradually
- Use `docker stats` to monitor real-time usage
- Health check endpoint: `/health` or `/`
- Logs: `docker logs <container-name>`

## 🔙 Cloud Run Deployment

See `QUICK_START_CLOUD_RUN.md` for deploying to Google Cloud Run.
