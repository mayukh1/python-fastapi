#FROM python:3.9-slim
FROM s390x/python:3.9-slim

# Set working directory
WORKDIR /app
USER root
# Install dependencies
COPY requirement.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install python-multipart
# Copy app code
COPY authentication authentication

# Expose port
EXPOSE 8000

# Run the app
CMD ["uvicorn", "authentication.main:app", "--host", "0.0.0.0", "--port", "8000"]
