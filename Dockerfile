# Dockerfile for CenErg Flask API
FROM python:3.11-slim

# Install OS dependencies for psycopg2
RUN apt-get update && apt-get install -y build-essential libpq-dev && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements and install dependencies
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . /app

# Expose port (default to 5000)
EXPOSE 5000

# Start the Gunicorn server
CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:5000"]
