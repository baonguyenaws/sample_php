FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy the CPU load scripts
COPY cpu_load.py cpu_load_with_http.py ./

# Make scripts executable
RUN chmod +x cpu_load.py cpu_load_with_http.py

# Set environment variables
ENV PYTHONUNBUFFERED=1

# Run HTTP-enabled version for Cloud Run compatibility
CMD ["python3", "cpu_load_with_http.py"]
