#!/usr/bin/env python3
"""
Test R2 upload directly using boto3
"""
import boto3
from botocore.exceptions import ClientError
import os

# R2 credentials
access_key = '7a4467aff561cea6f89a877a6ad9fc58'
secret_key = '5e6345fc231451d46694d10e90e8e1d85d9110a27f0860019a47b4eb005705b8'
endpoint_url = 'https://da76c95301856b7cd9fee0a8f758097a.r2.cloudflarestorage.com'
bucket_name = 'pinit-images'

def test_r2_upload():
    try:
        # Create S3 client
        s3_client = boto3.client(
            's3',
            aws_access_key_id=access_key,
            aws_secret_access_key=secret_key,
            endpoint_url=endpoint_url
        )
        
        print('Testing R2 connection...')
        
        # Test connection by listing bucket contents
        try:
            response = s3_client.list_objects_v2(Bucket=bucket_name)
            print(f'✅ Bucket exists! Objects count: {response.get("KeyCount", 0)}')
        except ClientError as e:
            print(f'❌ Bucket access error: {e}')
            return False
        
        # Create a test file
        test_content = b'This is a test file for R2 upload - direct test'
        
        # Upload test file
        print('Uploading test file...')
        s3_client.put_object(
            Bucket=bucket_name,
            Key='test-direct-upload.txt',
            Body=test_content,
            ContentType='text/plain'
        )
        print('✅ Upload successful!')
        
        # Test public URL
        public_url = f'https://pub-3df36a2ba44f4af9a779dc24cb9097a8.r2.dev/pinit-images/test-direct-upload.txt'
        print(f'Public URL: {public_url}')
        
        # Test if we can access the file
        import requests
        try:
            response = requests.get(public_url)
            if response.status_code == 200:
                print('✅ Public URL accessible!')
                print(f'Content: {response.text}')
            else:
                print(f'❌ Public URL not accessible: {response.status_code}')
        except Exception as e:
            print(f'❌ Error accessing public URL: {e}')
        
        return True
        
    except ClientError as e:
        print(f'❌ R2 Error: {e}')
        return False
    except Exception as e:
        print(f'❌ General Error: {e}')
        return False

if __name__ == "__main__":
    test_r2_upload()
