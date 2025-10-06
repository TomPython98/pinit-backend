"""
Custom Cloudflare R2 Storage Backend using API Token
"""
import requests
import json
import os
from django.core.files.storage import Storage
from django.conf import settings
from django.utils.deconstruct import deconstructible
from django.core.files.base import ContentFile
import mimetypes

@deconstructible
class CloudflareR2Storage(Storage):
    """
    Custom storage backend for Cloudflare R2 using API token
    """
    
    def __init__(self, account_id=None, bucket_name=None, api_token=None):
        self.account_id = account_id or os.getenv('CLOUDFLARE_ACCOUNT_ID', 'da76c95301856b7cd9fee0a8f758097a')
        self.bucket_name = bucket_name or os.getenv('CLOUDFLARE_R2_BUCKET_NAME', 'pinit-images')
        self.api_token = api_token or os.getenv('CLOUDFLARE_R2_API_TOKEN')
        self.base_url = f"https://api.cloudflare.com/client/v4/accounts/{self.account_id}/r2/buckets/{self.bucket_name}"
    
    def _get_headers(self):
        """Get headers for Cloudflare API requests"""
        return {
            'Authorization': f'Bearer {self.api_token}',
            'Content-Type': 'application/json'
        }
    
    def _get_object_url(self, name):
        """Get the public URL for an object"""
        return f"https://{self.account_id}.r2.cloudflarestorage.com/{self.bucket_name}/{name}"
    
    def _open(self, name, mode='rb'):
        """Open a file for reading"""
        try:
            url = f"{self.base_url}/objects/{name}"
            headers = self._get_headers()
            
            response = requests.get(url, headers=headers)
            response.raise_for_status()
            
            return ContentFile(response.content)
        except Exception as e:
            raise FileNotFoundError(f"Could not open file {name}: {e}")
    
    def _save(self, name, content):
        """Save a file to R2"""
        try:
            url = f"{self.base_url}/objects/{name}"
            headers = {
                'Authorization': f'Bearer {self.api_token}',
                'Content-Type': mimetypes.guess_type(name)[0] or 'application/octet-stream'
            }
            
            # Read content
            if hasattr(content, 'read'):
                file_data = content.read()
            else:
                file_data = content
            
            response = requests.put(url, data=file_data, headers=headers)
            response.raise_for_status()
            
            return name
        except Exception as e:
            raise Exception(f"Could not save file {name}: {e}")
    
    def delete(self, name):
        """Delete a file from R2"""
        try:
            url = f"{self.base_url}/objects/{name}"
            headers = self._get_headers()
            
            response = requests.delete(url, headers=headers)
            response.raise_for_status()
        except Exception as e:
            raise Exception(f"Could not delete file {name}: {e}")
    
    def exists(self, name):
        """Check if a file exists in R2"""
        try:
            url = f"{self.base_url}/objects/{name}"
            headers = self._get_headers()
            
            response = requests.head(url, headers=headers)
            return response.status_code == 200
        except:
            return False
    
    def url(self, name):
        """Get the public URL for a file"""
        return self._get_object_url(name)
    
    def size(self, name):
        """Get the size of a file"""
        try:
            url = f"{self.base_url}/objects/{name}"
            headers = self._get_headers()
            
            response = requests.head(url, headers=headers)
            response.raise_for_status()
            
            return int(response.headers.get('Content-Length', 0))
        except:
            return 0
    
    def get_valid_name(self, name):
        """Get a valid name for the file"""
        return name
    
    def get_available_name(self, name, max_length=None):
        """Get an available name for the file"""
        return name
