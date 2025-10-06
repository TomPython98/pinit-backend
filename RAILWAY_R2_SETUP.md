# Railway R2 Setup for PinIt App

## Your R2 Configuration
- **Account ID**: `da76c95301856b7cd9fee0a8f758097a`
- **Bucket Name**: `pinit-images`
- **Endpoint**: `https://da76c95301856b7cd9fee0a8f758097a.r2.cloudflarestorage.com`

## Step 1: Get API Credentials
1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Navigate to **R2 Object Storage** → **Manage R2 API tokens**
3. Click **Create API token**
4. Name: `pinit-backend`
5. Permissions: **Object Read & Write**
6. Bucket: Select `pinit-images`
7. Click **Create API token**
8. **SAVE** the Access Key ID and Secret Access Key

## Step 2: Add Environment Variables to Railway
Go to your Railway project dashboard and add these environment variables:

```
CLOUDFLARE_R2_ACCESS_KEY_ID=your_access_key_here
CLOUDFLARE_R2_SECRET_ACCESS_KEY=your_secret_key_here
CLOUDFLARE_R2_BUCKET_NAME=pinit-images
CLOUDFLARE_ACCOUNT_ID=da76c95301856b7cd9fee0a8f758097a
CLOUDFLARE_R2_CUSTOM_DOMAIN=da76c95301856b7cd9fee0a8f758097a.r2.cloudflarestorage.com
```

## Step 3: Test the Setup
After adding the environment variables, Railway will automatically redeploy. You can test by:

1. Uploading an image in your app
2. The image should now be stored in R2 and served via CDN URLs
3. Check the image URLs - they should start with `https://da76c95301856b7cd9fee0a8f758097a.r2.cloudflarestorage.com/`

## Benefits
- ✅ Images stored in Cloudflare R2 (not local filesystem)
- ✅ Served via CDN for fast loading worldwide
- ✅ Free tier: 10GB storage, 1M requests/month
- ✅ Reliable and scalable
