# StudyCon Deployment & Setup Guide

## 🚀 Quick Start

### Prerequisites
- Python 3.13+
- Xcode 15+ (for iOS development)
- Git
- pip package manager

### 1. Clone Repository
```bash
git clone <repository-url>
cd Real_App
```

### 2. Backend Setup
```bash
cd Back_End/StudyCon

# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate  # On macOS/Linux
# or
venv\Scripts\activate     # On Windows

# Install dependencies
pip install -r requirements.txt

# Run database migrations
python manage.py migrate

# Create superuser (optional)
python manage.py createsuperuser

# Start development server
python manage.py runserver 0.0.0.0:8000
```

### 3. Frontend Setup
```bash
cd Front_End/Fibbling_BackUp

# Open in Xcode
open Fibbling.xcodeproj

# Or use command line
xcodebuild -project Fibbling.xcodeproj -scheme Fibbling build
```

## 🐍 Virtual Environment Setup

### Creating Virtual Environment
```bash
# Navigate to backend directory
cd Back_End/StudyCon

# Create virtual environment
python3 -m venv venv

# Verify Python version
python --version  # Should be 3.13+
```

### Activating Virtual Environment
```bash
# macOS/Linux
source venv/bin/activate

# Windows
venv\Scripts\activate

# Verify activation
which python  # Should point to venv/bin/python
```

### Installing Dependencies
```bash
# Upgrade pip
pip install --upgrade pip

# Install from requirements.txt
pip install -r requirements.txt

# Verify installation
pip list
```

### Virtual Environment Files
```
venv/
├── bin/
│   ├── activate              # Activation script
│   ├── python                # Python interpreter
│   ├── pip                   # Package installer
│   ├── django-admin          # Django management
│   └── daphne                # ASGI server
├── lib/
│   └── python3.13/
│       └── site-packages/    # Installed packages
└── pyvenv.cfg                # Environment config
```

## 🗄️ Database Setup

### SQLite (Development)
```bash
# Default SQLite database
python manage.py migrate

# Check database
ls -la db.sqlite3

# Access database shell
python manage.py dbshell
```

### PostgreSQL (Production)
```bash
# Install PostgreSQL
# macOS
brew install postgresql
brew services start postgresql

# Ubuntu/Debian
sudo apt-get install postgresql postgresql-contrib

# Create database
sudo -u postgres psql
CREATE DATABASE studycon_prod;
CREATE USER studycon_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE studycon_prod TO studycon_user;
\q
```

### Database Configuration
```python
# settings.py for production
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'studycon_prod',
        'USER': 'studycon_user',
        'PASSWORD': 'your_password',
        'HOST': 'localhost',
        'PORT': '5432',
    }
}
```

## 🌐 Server Configuration

### Development Server
```bash
# Start Django development server
python manage.py runserver 0.0.0.0:8000

# Server accessible at:
# http://localhost:8000
# http://127.0.0.1:8000
# http://0.0.0.0:8000
```

### Production Server (Gunicorn + Nginx)
```bash
# Install Gunicorn
pip install gunicorn

# Install Nginx
# macOS
brew install nginx

# Ubuntu/Debian
sudo apt-get install nginx

# Start Gunicorn
gunicorn StudyCon.wsgi:application --bind 0.0.0.0:8000 --workers 3

# Configure Nginx
sudo nano /etc/nginx/sites-available/studycon
```

### Nginx Configuration
```nginx
server {
    listen 80;
    server_name yourdomain.com;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /static/ {
        alias /path/to/static/files/;
    }

    location /media/ {
        alias /path/to/media/files/;
    }
}
```

### ASGI Server (WebSockets)
```bash
# Install Daphne
pip install daphne

# Run ASGI server
daphne -b 0.0.0.0 -p 8000 StudyCon.asgi:application

# Or with Gunicorn + Uvicorn
pip install uvicorn[standard]
gunicorn StudyCon.asgi:application -w 4 -k uvicorn.workers.UvicornWorker
```

## 📱 iOS App Configuration

### Xcode Project Setup
```bash
# Open project in Xcode
open Fibbling.xcodeproj

# Or build from command line
xcodebuild -project Fibbling.xcodeproj -scheme Fibbling -configuration Debug build
```

### iOS Simulator
```bash
# List available simulators
xcrun simctl list devices

# Boot simulator
xcrun simctl boot "iPhone 15 Pro"

# Install app on simulator
xcrun simctl install booted /path/to/app.app
```

### iOS Device Deployment
1. **Developer Account**: Sign up for Apple Developer Program
2. **Certificates**: Create development/distribution certificates
3. **Provisioning Profiles**: Create profiles for your app
4. **Code Signing**: Configure in Xcode project settings

### Build Configurations
```swift
// Debug configuration
#if DEBUG
    let baseURL = "http://localhost:8000/api"
#else
    let baseURL = "https://yourdomain.com/api"
#endif
```

## 🔧 Environment Configuration

### Django Settings
```python
# settings.py
import os
from pathlib import Path

# Build paths
BASE_DIR = Path(__file__).resolve().parent.parent

# Security settings
SECRET_KEY = os.environ.get('SECRET_KEY', 'your-secret-key')
DEBUG = os.environ.get('DEBUG', 'False').lower() == 'true'
ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', 'localhost,127.0.0.1').split(',')

# Database
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('DB_NAME', 'studycon'),
        'USER': os.environ.get('DB_USER', 'postgres'),
        'PASSWORD': os.environ.get('DB_PASSWORD', ''),
        'HOST': os.environ.get('DB_HOST', 'localhost'),
        'PORT': os.environ.get('DB_PORT', '5432'),
    }
}

# CORS settings
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "https://yourdomain.com",
]

# WebSocket settings
CHANNEL_LAYERS = {
    "default": {
        "BACKEND": "channels_redis.core.RedisChannelLayer",
        "CONFIG": {
            "hosts": [("127.0.0.1", 6379)],
        },
    },
}
```

### Environment Variables
```bash
# .env file
SECRET_KEY=your-super-secret-key-here
DEBUG=False
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com
DB_NAME=studycon_prod
DB_USER=studycon_user
DB_PASSWORD=your-db-password
DB_HOST=localhost
DB_PORT=5432
REDIS_URL=redis://localhost:6379/0
```

## 🐳 Docker Deployment

### Dockerfile
```dockerfile
FROM python:3.13-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy project
COPY . .

# Run migrations and start server
CMD ["sh", "-c", "python manage.py migrate && python manage.py runserver 0.0.0.0:8000"]
```

### Docker Compose
```yaml
version: '3.8'

services:
  db:
    image: postgres:15
    environment:
      POSTGRES_DB: studycon
      POSTGRES_USER: studycon_user
      POSTGRES_PASSWORD: your_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  web:
    build: .
    command: python manage.py runserver 0.0.0.0:8000
    volumes:
      - .:/app
    ports:
      - "8000:8000"
    depends_on:
      - db
      - redis
    environment:
      - DEBUG=False
      - DB_HOST=db
      - REDIS_URL=redis://redis:6379/0

volumes:
  postgres_data:
```

### Docker Commands
```bash
# Build and run
docker-compose up --build

# Run in background
docker-compose up -d

# View logs
docker-compose logs -f web

# Stop services
docker-compose down
```

## ☁️ Cloud Deployment

### Heroku Deployment
```bash
# Install Heroku CLI
# macOS
brew install heroku/brew/heroku

# Login to Heroku
heroku login

# Create app
heroku create studycon-app

# Set environment variables
heroku config:set SECRET_KEY=your-secret-key
heroku config:set DEBUG=False
heroku config:set ALLOWED_HOSTS=studycon-app.herokuapp.com

# Add PostgreSQL addon
heroku addons:create heroku-postgresql:hobby-dev

# Deploy
git push heroku main

# Run migrations
heroku run python manage.py migrate
```

### AWS Deployment
```bash
# Install AWS CLI
pip install awscli

# Configure AWS
aws configure

# Create Elastic Beanstalk application
eb init studycon-app

# Create environment
eb create production

# Deploy
eb deploy
```

### DigitalOcean App Platform
```yaml
# .do/app.yaml
name: studycon-app
services:
- name: web
  source_dir: Back_End/StudyCon
  github:
    repo: your-username/studycon
    branch: main
  run_command: python manage.py runserver 0.0.0.0:8080
  environment_slug: python
  instance_count: 1
  instance_size_slug: basic-xxs
  envs:
  - key: DEBUG
    value: "False"
  - key: SECRET_KEY
    value: your-secret-key
databases:
- name: studycon-db
  engine: PG
  version: "13"
```

## 🔒 Security Configuration

### Production Security Checklist
- [ ] Set `DEBUG=False`
- [ ] Use secure `SECRET_KEY`
- [ ] Configure `ALLOWED_HOSTS`
- [ ] Enable HTTPS
- [ ] Set secure database passwords
- [ ] Configure CORS properly
- [ ] Use environment variables for secrets
- [ ] Enable Django security middleware
- [ ] Set secure cookie settings

### HTTPS Configuration
```python
# settings.py
SECURE_SSL_REDIRECT = True
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
SECURE_CONTENT_TYPE_NOSNIFF = True
SECURE_BROWSER_XSS_FILTER = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
```

### Firewall Configuration
```bash
# UFW (Ubuntu)
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# iptables
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -j DROP
```

## 📊 Monitoring & Logging

### Django Logging Configuration
```python
# settings.py
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {process:d} {thread:d} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'file': {
            'level': 'INFO',
            'class': 'logging.FileHandler',
            'filename': 'django.log',
            'formatter': 'verbose',
        },
        'console': {
            'level': 'DEBUG',
            'class': 'logging.StreamHandler',
            'formatter': 'verbose',
        },
    },
    'root': {
        'handlers': ['console', 'file'],
        'level': 'INFO',
    },
}
```

### Performance Monitoring
```bash
# Install monitoring tools
pip install django-debug-toolbar
pip install django-silk

# Add to INSTALLED_APPS
INSTALLED_APPS = [
    'debug_toolbar',
    'silk',
    # ... other apps
]
```

## 🔄 CI/CD Pipeline

### GitHub Actions
```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Set up Python
      uses: actions/setup-python@v2
      with:
        python-version: 3.13
    - name: Install dependencies
      run: |
        pip install -r Back_End/StudyCon/requirements.txt
    - name: Run tests
      run: |
        cd Back_End/StudyCon
        python manage.py test

  deploy:
    needs: test
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Deploy to Heroku
      uses: akhileshns/heroku-deploy@v3.12.12
      with:
        heroku_api_key: ${{secrets.HEROKU_API_KEY}}
        heroku_app_name: "studycon-app"
        heroku_email: "your-email@example.com"
```

## 🚨 Troubleshooting

### Common Issues

#### Backend Issues
```bash
# Database connection error
python manage.py dbshell

# Migration issues
python manage.py migrate --fake-initial

# Static files not loading
python manage.py collectstatic

# WebSocket connection issues
# Check Redis is running
redis-cli ping
```

#### Frontend Issues
```bash
# Xcode build errors
# Clean build folder
Product → Clean Build Folder

# Simulator issues
# Reset simulator
xcrun simctl erase all

# Code signing issues
# Check certificates in Keychain Access
```

#### Network Issues
```bash
# Check server is running
curl http://localhost:8000/api/get_all_users/

# Check CORS configuration
# Verify ALLOWED_HOSTS in settings.py

# Check firewall
sudo ufw status
```

### Debug Commands
```bash
# Django shell
python manage.py shell

# Check migrations
python manage.py showmigrations

# Check installed packages
pip list

# Check Python path
python -c "import sys; print(sys.path)"
```

## 📞 Support

### Getting Help
1. Check this documentation
2. Review error logs
3. Check Django console output
4. Verify network connectivity
5. Check Xcode console for iOS errors

### Useful Commands
```bash
# Backend
python manage.py runserver 0.0.0.0:8000
python manage.py migrate
python manage.py collectstatic
python manage.py shell

# Frontend
xcodebuild -project Fibbling.xcodeproj -scheme Fibbling build
xcrun simctl list devices
xcrun simctl boot "iPhone 15 Pro"

# System
ps aux | grep python
lsof -i :8000
netstat -an | grep 8000
```

---

**Last Updated**: January 2025
**Deployment Version**: 1.0.0

