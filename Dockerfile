# Dockerfile for CenErg Flask API
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy requirements and install dependencies
COPY server/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY server /app

# Expose port (default to 5000)
EXPOSE 5000

# Start the Gunicorn server
CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:5000"]
