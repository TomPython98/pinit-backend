#!/usr/bin/env python3
"""
Cloudflare R2 Setup Script for PinIt App
This script helps you set up Cloudflare R2 for image storage.
"""

import os
import requests
import json

def setup_r2_instructions():
    """Print step-by-step instructions for setting up R2"""
    print("🚀 Cloudflare R2 Setup for PinIt App")
    print("=" * 50)
    print()
    print("Step 1: Create Cloudflare R2 Bucket")
    print("1. Go to https://dash.cloudflare.com/")
    print("2. Navigate to R2 Object Storage")
    print("3. Click 'Create bucket'")
    print("4. Name: 'pinit-images' (or your preferred name)")
    print("5. Location: Choose closest to your users")
    print("6. Click 'Create bucket'")
    print()
    print("Step 2: Get API Credentials")
    print("1. In R2 dashboard, go to 'Manage R2 API tokens'")
    print("2. Click 'Create API token'")
    print("3. Name: 'pinit-backend'")
    print("4. Permissions: 'Object Read & Write'")
    print("5. Bucket: Select your 'pinit-images' bucket")
    print("6. Click 'Create API token'")
    print("7. SAVE the Access Key ID and Secret Access Key")
    print()
    print("Step 3: Get Your Account ID")
    print("1. In Cloudflare dashboard, look at the right sidebar")
    print("2. Find 'Account ID' under 'API' section")
    print("3. Copy this Account ID")
    print()
    print("Step 4: Set Environment Variables in Railway")
    print("Go to your Railway project dashboard and add these environment variables:")
    print()
    print("CLOUDFLARE_R2_ACCESS_KEY_ID=your_access_key_here")
    print("CLOUDFLARE_R2_SECRET_ACCESS_KEY=your_secret_key_here")
    print("CLOUDFLARE_R2_BUCKET_NAME=pinit-images")
    print("CLOUDFLARE_ACCOUNT_ID=your_account_id_here")
    print("CLOUDFLARE_R2_CUSTOM_DOMAIN=images.pinit-app.com (optional)")
    print()
    print("Step 5: Deploy")
    print("After setting the environment variables, deploy the code:")
    print("1. Run: python3 deploy_backend_files.py")
    print("2. Commit and push to GitHub")
    print("3. Railway will automatically redeploy")
    print()
    print("Benefits of R2:")
    print("✅ Free tier: 10GB storage, 1M requests/month")
    print("✅ Fast CDN: Images load quickly worldwide")
    print("✅ S3-compatible: Works with django-storages")
    print("✅ Reliable: Cloudflare's infrastructure")
    print("✅ Cost-effective: Much cheaper than other cloud storage")

def test_r2_connection():
    """Test R2 connection if credentials are provided"""
    access_key = os.getenv('CLOUDFLARE_R2_ACCESS_KEY_ID')
    secret_key = os.getenv('CLOUDFLARE_R2_SECRET_ACCESS_KEY')
    bucket_name = os.getenv('CLOUDFLARE_R2_BUCKET_NAME')
    account_id = os.getenv('CLOUDFLARE_ACCOUNT_ID')
    
    if not all([access_key, secret_key, bucket_name, account_id]):
        print("❌ R2 credentials not found in environment variables")
        print("Please set the environment variables first")
        return False
    
    print("🔍 Testing R2 connection...")
    
    try:
        import boto3
        from botocore.exceptions import ClientError
        
        # Create S3 client for R2
        s3_client = boto3.client(
            's3',
            endpoint_url=f'https://{account_id}.r2.cloudflarestorage.com',
            aws_access_key_id=access_key,
            aws_secret_access_key=secret_key,
            region_name='auto'
        )
        
        # Test connection by listing buckets
        response = s3_client.list_buckets()
        buckets = [bucket['Name'] for bucket in response['Buckets']]
        
        if bucket_name in buckets:
            print(f"✅ Successfully connected to R2!")
            print(f"✅ Bucket '{bucket_name}' found")
            return True
        else:
            print(f"❌ Bucket '{bucket_name}' not found")
            print(f"Available buckets: {buckets}")
            return False
            
    except ImportError:
        print("❌ boto3 not installed. Run: pip install boto3")
        return False
    except ClientError as e:
        print(f"❌ R2 connection failed: {e}")
        return False
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return False

if __name__ == "__main__":
    setup_r2_instructions()
    print()
    test_r2_connection()
