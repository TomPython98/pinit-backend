# Cloudflare R2 Setup for PinIt App

## Step 1: Create Cloudflare R2 Bucket

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Navigate to **R2 Object Storage**
3. Click **Create bucket**
4. Name: `pinit-images` (or your preferred name)
5. Location: Choose closest to your users
6. Click **Create bucket**

## Step 2: Get API Credentials

1. In R2 dashboard, go to **Manage R2 API tokens**
2. Click **Create API token**
3. Name: `pinit-backend`
4. Permissions: **Object Read & Write**
5. Bucket: Select your `pinit-images` bucket
6. Click **Create API token**
7. **SAVE** the Access Key ID and Secret Access Key

## Step 3: Configure Custom Domain (Optional but Recommended)

1. In your R2 bucket, go to **Settings** → **Custom Domains**
2. Add a custom domain like `images.pinit-app.com`
3. Follow DNS setup instructions
4. This gives you a CDN URL instead of the default R2 URL

## Step 4: Set Environment Variables

Add these to your Railway deployment environment variables:

```
R2_ACCESS_KEY_ID=your_access_key_here
R2_SECRET_ACCESS_KEY=your_secret_key_here
R2_BUCKET_NAME=pinit-images
R2_ENDPOINT_URL=https://your-account-id.r2.cloudflarestorage.com
R2_CUSTOM_DOMAIN=images.pinit-app.com
```

## Step 5: Test the Setup

After deployment, test by uploading an image and checking if it's accessible via the public URL.

## Benefits of R2

- **Free tier**: 10GB storage, 1M requests/month
- **Fast CDN**: Images load quickly worldwide
- **S3-compatible**: Works with django-storages
- **Reliable**: Cloudflare's infrastructure
- **Cost-effective**: Much cheaper than other cloud storage
