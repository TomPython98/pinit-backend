from django.core.files.storage import Storage
from django.conf import settings
import boto3
from botocore.exceptions import ClientError
import os

class R2Storage(Storage):
    """
    Custom storage class for Cloudflare R2
    """
    
    def __init__(self):
        self.bucket_name = settings.AWS_STORAGE_BUCKET_NAME
        self.custom_domain = 'pub-3df36a2ba44f4af9a779dc24cb9097a8.r2.dev'
        
        # Initialize S3 client for R2
        self.s3_client = boto3.client(
            's3',
            endpoint_url=settings.AWS_S3_ENDPOINT_URL,
            aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
            aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
            region_name=settings.AWS_S3_REGION_NAME
        )
    
    def _open(self, name, mode='rb'):
        """Open file for reading"""
        try:
            response = self.s3_client.get_object(Bucket=self.bucket_name, Key=name)
            return response['Body']
        except ClientError as e:
            raise FileNotFoundError(f"File {name} not found: {e}")
    
    def _save(self, name, content):
        """Save file to R2"""
        try:
            # Reset file pointer to beginning
            content.seek(0)
            
            # Upload to R2
            self.s3_client.put_object(
                Bucket=self.bucket_name,
                Key=name,
                Body=content.read(),
                ContentType=getattr(content, 'content_type', 'application/octet-stream'),
                ACL='public-read'
            )
            return name
        except ClientError as e:
            raise Exception(f"Failed to save file {name}: {e}")
    
    def delete(self, name):
        """Delete file from R2"""
        try:
            self.s3_client.delete_object(Bucket=self.bucket_name, Key=name)
        except ClientError as e:
            raise Exception(f"Failed to delete file {name}: {e}")
    
    def exists(self, name):
        """Check if file exists in R2"""
        try:
            self.s3_client.head_object(Bucket=self.bucket_name, Key=name)
            return True
        except ClientError:
            return False
    
    def listdir(self, path):
        """List directory contents"""
        try:
            response = self.s3_client.list_objects_v2(
                Bucket=self.bucket_name,
                Prefix=path.rstrip('/') + '/' if path else '',
                Delimiter='/'
            )
            
            dirs = []
            files = []
            
            # Get directories
            for prefix in response.get('CommonPrefixes', []):
                dirs.append(prefix['Prefix'].rstrip('/').split('/')[-1])
            
            # Get files
            for obj in response.get('Contents', []):
                if obj['Key'] != path.rstrip('/') + '/':
                    files.append(obj['Key'].split('/')[-1])
            
            return dirs, files
        except ClientError as e:
            raise Exception(f"Failed to list directory {path}: {e}")
    
    def size(self, name):
        """Get file size"""
        try:
            response = self.s3_client.head_object(Bucket=self.bucket_name, Key=name)
            return response['ContentLength']
        except ClientError as e:
            raise Exception(f"Failed to get size of {name}: {e}")
    
    def url(self, name):
        """Get public URL for file"""
        if self.custom_domain:
            return f"https://{self.custom_domain}/{name}"
        else:
            return f"https://{self.bucket_name}.{settings.AWS_S3_ENDPOINT_URL.replace('https://', '')}/{name}"
    
    def get_available_name(self, name, max_length=None):
        """Get available name if file exists"""
        if not self.exists(name):
            return name
        
        # Generate unique name
        name, ext = os.path.splitext(name)
        counter = 1
        while True:
            new_name = f"{name}_{counter}{ext}"
            if not self.exists(new_name):
                return new_name
            counter += 1