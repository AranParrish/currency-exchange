FROM python:3.12-slim

WORKDIR /app

# Copy requirements.txt into the image
COPY requirements.txt requirements.txt

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy your source code
COPY src/ src/

# Optional: set environment variable
ENV ce_bucket="currency-exchange-bucket"

# Default command (runs your extractor)
CMD ["python", "src/ce_extract_lambda.py"]