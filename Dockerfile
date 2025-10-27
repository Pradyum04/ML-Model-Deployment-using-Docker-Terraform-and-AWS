# Base image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy app code and model
COPY app /app/app
COPY model /app/model

# Install dependencies
RUN pip install --upgrade pip
RUN pip install -r app/requirements.txt

# Expose the port Flask will run on
EXPOSE 5000

# Set environment variables (optional)
ENV FLASK_APP=app/app.py
ENV FLASK_RUN_HOST=0.0.0.0
ENV FLASK_ENV=production

# Run the Flask app
CMD ["python", "app/app.py"]
