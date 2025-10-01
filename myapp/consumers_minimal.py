"""
Minimal consumers.py for Railway deployment - WebSocket functionality disabled
"""
import json
import re

def sanitize_username(username):
    """Sanitize username for WebSocket group names by removing special characters"""
    # Remove or replace special characters that cause WebSocket group name validation errors
    sanitized = re.sub(r'[^a-zA-Z0-9_-]', '_', username)
    return sanitized

# WebSocket consumers disabled for Railway deployment
# All WebSocket functionality has been removed to ensure fast deployment
