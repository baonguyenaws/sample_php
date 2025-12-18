FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt ./

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the latency simulator script
COPY latency_simulator.py ./

# Make script executable
RUN chmod +x latency_simulator.py

# Set environment variables
ENV PYTHONUNBUFFERED=1

# Run latency simulator
CMD ["python3", "latency_simulator.py"]
