#!/bin/bash

# Simple startup script for Railway
echo "🚀 Starting PinIt Backend..."

# Run migrations
echo "📊 Running database migrations..."
python manage.py migrate --noinput

# Collect static files
echo "📁 Collecting static files..."
python manage.py collectstatic --noinput

# Start the server
echo "🌐 Starting Gunicorn server..."
exec gunicorn StudyCon.wsgi --log-file - --bind 0.0.0.0:$PORT
