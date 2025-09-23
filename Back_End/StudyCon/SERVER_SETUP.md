# Django Server Setup Guide

## Overview
This Django project requires a virtual environment to run properly due to macOS system restrictions on installing Python packages globally.

## Prerequisites
- Python 3.x installed (we used Python 3.13)
- Terminal access

## Setup Steps

### 1. Create Virtual Environment
```bash
cd /Users/tombesinger/Desktop/Real_App/Back_End/StudyCon
python3 -m venv venv
```

### 2. Activate Virtual Environment
```bash
source venv/bin/activate
```

### 3. Install Dependencies
```bash
python -m pip install -r requirements.txt
```

### 4. Start Django Server
```bash
cd StudyCon
source ../venv/bin/activate
python manage.py runserver 0.0.0.0:8000
```

## Important Notes

### Virtual Environment is Required
- **Always activate the virtual environment before running the server**
- The command `source ../venv/bin/activate` activates the virtual environment
- Without this, you'll get: `ImportError: Couldn't import Django`

### Server Access
- Server runs on: `http://localhost:8000`
- Also accessible on: `http://0.0.0.0:8000`
- Admin interface: `http://localhost:8000/admin/`

### Project Structure
```
Back_End/StudyCon/
├── venv/                    # Virtual environment (created)
├── requirements.txt         # Dependencies (created)
├── StudyCon/               # Django project directory
│   ├── manage.py           # Django management script
│   ├── StudyCon/           # Django settings
│   └── myapp/              # Django app
```

### Dependencies Installed
- Django==5.1.6
- daphne==4.0.0 (ASGI server)
- channels==4.0.0 (WebSocket support)
- djangorestframework==3.15.2
- django-cors-headers==4.3.1
- django-push-notifications==3.0.0

## Quick Start Command
```bash
cd /Users/tombesinger/Desktop/Real_App/Back_End/StudyCon/StudyCon
source ../venv/bin/activate
python manage.py runserver 0.0.0.0:8000
```

## Troubleshooting

### "command not found: python"
- Use `python3` instead of `python` if Python 3 is not aliased

### "Couldn't import Django"
- Make sure virtual environment is activated: `source ../venv/bin/activate`
- Check if dependencies are installed: `pip list | grep Django`

### "externally-managed-environment"
- This is why we need the virtual environment - macOS prevents global package installation

## Server Status
When running successfully, you should see:
```
Watching for file changes with StatReloader
```

This indicates the server is running and monitoring for code changes.
