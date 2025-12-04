FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install build dependencies for psutil
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    gcc \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the memory load scripts
COPY memory_load.py mem_load_with_http.py ./

# Make scripts executable
RUN chmod +x memory_load.py mem_load_with_http.py

# Set environment variables
ENV PYTHONUNBUFFERED=1

# Run HTTP-enabled version for Cloud Run compatibility
CMD ["python3", "mem_load_with_http.py"]
