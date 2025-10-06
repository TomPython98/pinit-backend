#!/usr/bin/env python3
"""
Test R2 Credentials
"""
import boto3
from botocore.exceptions import ClientError

def test_r2_credentials():
    """Test the R2 credentials"""
    
    # Your credentials
    access_key = '4f368c0bf5f06c10e8381b85f946ff1f'
    secret_key = 'RD1oPR2xgAp8Eo5ZaUSdcLkSH-ZQi4ArnlupEH4F'
    account_id = 'da76c95301856b7cd9fee0a8f758097a'
    bucket_name = 'pinit-images'
    endpoint_url = f'https://{account_id}.r2.cloudflarestorage.com'
    
    print(f"Testing R2 credentials...")
    print(f"Access Key: {access_key}")
    print(f"Secret Key: {secret_key[:10]}...")
    print(f"Account ID: {account_id}")
    print(f"Bucket: {bucket_name}")
    print(f"Endpoint: {endpoint_url}")
    print()
    
    try:
        # Create S3 client
        s3_client = boto3.client(
            's3',
            endpoint_url=endpoint_url,
            aws_access_key_id=access_key,
            aws_secret_access_key=secret_key,
            region_name='auto'
        )
        
        print("🔍 Testing connection...")
        
        # Test 1: List buckets
        try:
            response = s3_client.list_buckets()
            buckets = [bucket['Name'] for bucket in response['Buckets']]
            print(f"✅ Successfully connected! Available buckets: {buckets}")
            
            if bucket_name in buckets:
                print(f"✅ Bucket '{bucket_name}' found!")
            else:
                print(f"❌ Bucket '{bucket_name}' not found")
                return False
                
        except ClientError as e:
            print(f"❌ List buckets failed: {e}")
            return False
        
        # Test 2: Try to upload a test file
        try:
            print("📤 Testing file upload...")
            test_content = b"Hello from PinIt App R2 test!"
            s3_client.put_object(
                Bucket=bucket_name,
                Key='test/connection-test.txt',
                Body=test_content,
                ContentType='text/plain'
            )
            print("✅ Test file uploaded successfully!")
            
            # Test 3: Try to download the file
            print("📥 Testing file download...")
            response = s3_client.get_object(Bucket=bucket_name, Key='test/connection-test.txt')
            downloaded_content = response['Body'].read()
            if downloaded_content == test_content:
                print("✅ Test file downloaded successfully!")
            else:
                print("❌ Downloaded content doesn't match")
                return False
            
            # Test 4: Get the public URL
            print("🔗 Testing public URL...")
            public_url = f"https://{account_id}.r2.cloudflarestorage.com/{bucket_name}/test/connection-test.txt"
            print(f"Public URL: {public_url}")
            
            # Clean up
            s3_client.delete_object(Bucket=bucket_name, Key='test/connection-test.txt')
            print("🧹 Test file cleaned up")
            
            return True
            
        except ClientError as e:
            print(f"❌ Upload/download test failed: {e}")
            return False
            
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return False

if __name__ == "__main__":
    print("🚀 Testing Cloudflare R2 Credentials")
    print("=" * 50)
    
    success = test_r2_credentials()
    
    if success:
        print("\n🎉 R2 credentials are working! Images will be stored in R2.")
    else:
        print("\n❌ R2 credentials failed. You may need to get S3-compatible credentials.")
        print("Go to Cloudflare Dashboard → R2 → Manage R2 API tokens → Create S3 API token")
