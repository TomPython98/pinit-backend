#!/usr/bin/env python3
"""
Test R2 Connection Script
This script tests if the R2 connection is working properly.
"""

import os
import boto3
from botocore.exceptions import ClientError

def test_r2_connection():
    """Test R2 connection with the provided credentials"""
    
    # Your R2 configuration
    access_key = os.getenv('CLOUDFLARE_R2_ACCESS_KEY_ID')
    secret_key = os.getenv('CLOUDFLARE_R2_SECRET_ACCESS_KEY')
    bucket_name = 'pinit-images'
    account_id = 'da76c95301856b7cd9fee0a8f758097a'
    
    if not access_key or not secret_key:
        print("❌ R2 credentials not found in environment variables")
        print("Please set CLOUDFLARE_R2_ACCESS_KEY_ID and CLOUDFLARE_R2_SECRET_ACCESS_KEY")
        return False
    
    print("🔍 Testing R2 connection...")
    print(f"Account ID: {account_id}")
    print(f"Bucket: {bucket_name}")
    print(f"Endpoint: https://{account_id}.r2.cloudflarestorage.com")
    
    try:
        # Create S3 client for R2
        s3_client = boto3.client(
            's3',
            endpoint_url=f'https://{account_id}.r2.cloudflarestorage.com',
            aws_access_key_id=access_key,
            aws_secret_access_key=secret_key,
            region_name='auto'
        )
        
        # Test connection by listing buckets
        print("📋 Listing buckets...")
        response = s3_client.list_buckets()
        buckets = [bucket['Name'] for bucket in response['Buckets']]
        
        print(f"Available buckets: {buckets}")
        
        if bucket_name in buckets:
            print(f"✅ Successfully connected to R2!")
            print(f"✅ Bucket '{bucket_name}' found")
            
            # Test uploading a small file
            print("📤 Testing file upload...")
            test_content = b"Hello from PinIt App!"
            s3_client.put_object(
                Bucket=bucket_name,
                Key='test/connection-test.txt',
                Body=test_content,
                ContentType='text/plain'
            )
            print("✅ Test file uploaded successfully!")
            
            # Test downloading the file
            print("📥 Testing file download...")
            response = s3_client.get_object(Bucket=bucket_name, Key='test/connection-test.txt')
            downloaded_content = response['Body'].read()
            if downloaded_content == test_content:
                print("✅ Test file downloaded successfully!")
            else:
                print("❌ Downloaded content doesn't match uploaded content")
                return False
            
            # Clean up test file
            s3_client.delete_object(Bucket=bucket_name, Key='test/connection-test.txt')
            print("🧹 Test file cleaned up")
            
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
    print("🚀 Testing Cloudflare R2 Connection for PinIt App")
    print("=" * 50)
    
    success = test_r2_connection()
    
    if success:
        print("\n🎉 R2 is ready! Your images will be stored in Cloudflare R2.")
        print("You can now upload images in your app and they'll be served via CDN.")
    else:
        print("\n❌ R2 setup failed. Please check your credentials and try again.")
