FROM python:3.13-slim

WORKDIR /app

# Install system dependencies including PostgreSQL development libraries
RUN apt-get update && apt-get install -y \
    gcc \
    postgresql-client \
    libpq-dev \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements_production.txt .
RUN pip install --no-cache-dir -r requirements_production.txt

# Copy project
COPY . .

# Collect static files
RUN python manage.py collectstatic --noinput

# Expose port
EXPOSE 8080

# Run migrations and start server
CMD ["sh", "-c", "python manage.py migrate && gunicorn StudyCon.wsgi --log-file - --bind 0.0.0.0:8080"]
