# Use official Python image
#FROM registry.access.redhat.com/rhel8/python-39
#FROM registry.access.redhat.com/ubi9/python-39:1-90
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Install dependencies
COPY requirement.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy app code
COPY authentication authentication

# Expose port
EXPOSE 8000

# Run the app
CMD ["uvicorn", "authentication.main:app", "--host", "0.0.0.0", "--port", "8000"]
