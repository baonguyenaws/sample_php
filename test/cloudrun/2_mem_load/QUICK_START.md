# Quick Start Guide - Memory Load Generator

## 📚 Documentation

This guide has been split into two parts for better organization:

### 🖥️ Local Development & Testing
👉 **[QUICK_START_LOCAL.md](QUICK_START_LOCAL.md)**
- Run with Docker Compose
- Test single or multiple containers
- Monitor memory usage locally

### ☁️ Google Cloud Run Deployment
👉 **[QUICK_START_CLOUD_RUN.md](QUICK_START_CLOUD_RUN.md)**
- Build & push to GCR
- Deploy to Cloud Run
- Monitor production workloads

---

## 🚀 Quick Links

**Want to test locally?** → Go to [QUICK_START_LOCAL.md](QUICK_START_LOCAL.md)

**Ready to deploy to Cloud Run?** → Go to [QUICK_START_CLOUD_RUN.md](QUICK_START_CLOUD_RUN.md)

---

## 📊 Supported Memory Targets

| Target | Description | Use Case |
|--------|-------------|----------|
| 75% | Moderate memory usage | Normal workloads |
| 85% | High memory usage | Stress testing |
| 99% | Maximum memory usage | Extreme scenarios |

| MEMORY_TARGET | Expected Memory Usage | Container Name | Port (Local) |
|---------------|----------------------|----------------|--------------|
| 75% | ~384 MB of 512 MB | memory-load-75 | 8175 |
| 85% | ~435 MB of 512 MB | memory-load-85 | 8185 |
| 99% | ~507 MB of 512 MB | memory-load-99 | 8199 |

## 💡 Quick Tips

- ✅ Test local trước khi deploy lên Cloud Run
- ✅ Set `MEMORY_TARGET` qua environment variable
- ✅ Port 8080 cho HTTP server (Cloud Run requirement)
- ✅ Tăng memory limit nếu muốn test với memory lớn hơn
- ✅ Nhớ cleanup resources sau khi test!

## 📝 Files

- `memory_load.py` - Core memory load generator
- `mem_load_with_http.py` - HTTP server wrapper (used by Dockerfile)
- `docker-compose.yml` - Default config (75%)
- `docker-compose-75.yml` - 75% Memory config
- `docker-compose-85.yml` - 85% Memory config
- `docker-compose-99.yml` - 99% Memory config
- `README.md` - Full documentation
