# 🌐 Deployment Guide - PinIt Landing Page

## Prerequisites

- Node.js installed
- Landing page built and tested locally
- Production backend URL ready

---

## Option 1: Vercel (Recommended ⭐)

### Why Vercel?
- ✅ Free for personal projects
- ✅ Automatic builds on git push
- ✅ Custom domains
- ✅ SSL certificates included
- ✅ Edge network (fast worldwide)

### Steps:

1. **Install Vercel CLI**
   ```bash
   npm install -g vercel
   ```

2. **Deploy**
   ```bash
   cd web_landing
   vercel
   ```

3. **Follow the prompts:**
   - Link to existing project? `N`
   - Project name? `pinit-landing` (or your choice)
   - Directory? `./` (current directory)
   - Build Command? (default is fine)
   - Output Directory? (default is fine)

4. **Set Environment Variable**
   - Go to Vercel dashboard
   - Select your project
   - Go to Settings → Environment Variables
   - Add: `VITE_API_URL` = `https://pinit-backend-production.up.railway.app`

5. **Redeploy**
   ```bash
   vercel --prod
   ```

6. **Update Backend CORS**
   
   Add your Vercel URL to Django `settings.py`:
   ```python
   CORS_ALLOWED_ORIGINS = [
       "http://localhost:3000",
       "https://your-project.vercel.app",  # Add this
       "https://pinit-backend-production.up.railway.app",
   ]
   
   CSRF_TRUSTED_ORIGINS = [
       'https://pinit-backend-production.up.railway.app',
       'https://your-project.vercel.app',  # Add this
   ]
   ```

7. **Done!** Your site is live at `https://your-project.vercel.app`

---

## Option 2: Netlify

### Why Netlify?
- ✅ Free for personal projects
- ✅ Simple drag-and-drop
- ✅ Custom domains
- ✅ SSL included

### Steps:

1. **Build the project**
   ```bash
   cd web_landing
   npm run build
   ```

2. **Deploy via Web UI**
   - Go to https://app.netlify.com
   - Drag and drop the `dist` folder
   - Or click "Add new site" → "Deploy manually"

3. **Set Environment Variable**
   - Go to Site settings
   - Build & deploy → Environment
   - Add: `VITE_API_URL` = `https://pinit-backend-production.up.railway.app`

4. **Trigger Redeploy**
   - Go to Deploys
   - Click "Trigger deploy"

5. **Update Backend CORS**
   
   Add your Netlify URL to Django `settings.py`:
   ```python
   CORS_ALLOWED_ORIGINS = [
       "http://localhost:3000",
       "https://your-site.netlify.app",  # Add this
       "https://pinit-backend-production.up.railway.app",
   ]
   
   CSRF_TRUSTED_ORIGINS = [
       'https://pinit-backend-production.up.railway.app',
       'https://your-site.netlify.app',  # Add this
   ]
   ```

6. **Done!** Your site is live at `https://your-site.netlify.app`

### Alternative: GitHub Auto-Deploy

1. Push code to GitHub
2. Connect Netlify to your GitHub repo
3. Set build settings:
   - Build command: `npm run build`
   - Publish directory: `dist`
   - Base directory: `web_landing`

---

## Option 3: Railway

### Why Railway?
- ✅ Great for full-stack projects
- ✅ Can host both frontend and backend
- ✅ Good for Node.js apps

### Steps:

1. **Create Railway Project**
   - Go to https://railway.app
   - Click "New Project"
   - Choose "Deploy from GitHub repo"

2. **Configure**
   - Root directory: `web_landing`
   - Railway auto-detects Vite

3. **Set Environment Variable**
   - Add variable: `VITE_API_URL` = `https://pinit-backend-production.up.railway.app`

4. **Deploy**
   - Railway automatically builds and deploys

5. **Update Backend CORS**
   
   Add your Railway URL to Django `settings.py`:
   ```python
   CORS_ALLOWED_ORIGINS = [
       "http://localhost:3000",
       "https://your-project.railway.app",  # Add this
       "https://pinit-backend-production.up.railway.app",
   ]
   
   CSRF_TRUSTED_ORIGINS = [
       'https://pinit-backend-production.up.railway.app',
       'https://your-project.railway.app',  # Add this
   ]
   ```

6. **Done!** Your site is live at `https://your-project.railway.app`

---

## Option 4: Custom Server (VPS/DigitalOcean/AWS)

### Steps:

1. **Build the project**
   ```bash
   npm run build
   ```

2. **Upload `dist` folder to your server**

3. **Configure Nginx** (example):
   ```nginx
   server {
       listen 80;
       server_name your-domain.com;
       root /var/www/pinit-landing/dist;
       index index.html;

       location / {
           try_files $uri $uri/ /index.html;
       }
   }
   ```

4. **Set up SSL** (Let's Encrypt):
   ```bash
   certbot --nginx -d your-domain.com
   ```

5. **Update Backend CORS** with your domain

---

## Custom Domain Setup

### Vercel
1. Go to project settings
2. Domains → Add domain
3. Follow DNS configuration instructions

### Netlify
1. Go to site settings
2. Domain management → Add custom domain
3. Update DNS records

---

## Post-Deployment Checklist

- ✅ Site loads without errors
- ✅ Can sign up new users
- ✅ Can log in
- ✅ Dashboard loads correctly
- ✅ No CORS errors in console
- ✅ SSL certificate is active (HTTPS)
- ✅ Mobile responsive
- ✅ Images load correctly

---

## Backend Configuration

**Important:** After deploying, you MUST update your Django backend's CORS settings!

### Edit `StudyCon/settings.py`:

```python
# Add your production domain(s)
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",  # Keep for local dev
    "https://your-production-domain.com",  # Add this
    "https://pinit-backend-production.up.railway.app",
]

CSRF_TRUSTED_ORIGINS = [
    'https://pinit-backend-production.up.railway.app',
    'https://your-production-domain.com',  # Add this
]

# Also update ALLOWED_HOSTS if needed
ALLOWED_HOSTS = [
    'pinit-backend-production.up.railway.app',
    'localhost',
    '127.0.0.1',
]
```

### Redeploy Backend:
```bash
git add .
git commit -m "Add CORS for landing page"
git push
```

Railway will automatically redeploy your backend.

---

## Monitoring & Analytics

### Add Google Analytics (Optional)

1. Get your GA tracking ID
2. Add to `index.html`:
   ```html
   <script async src="https://www.googletagmanager.com/gtag/js?id=GA_MEASUREMENT_ID"></script>
   <script>
     window.dataLayer = window.dataLayer || [];
     function gtag(){dataLayer.push(arguments);}
     gtag('js', new Date());
     gtag('config', 'GA_MEASUREMENT_ID');
   </script>
   ```

---

## Troubleshooting

### Site not loading?
- Check build logs
- Verify environment variables are set
- Check if domain DNS is configured

### API not working?
- Verify `VITE_API_URL` is correct
- Check backend CORS settings
- Check browser console for errors

### 404 on refresh?
- Configure routing for SPA:
  - **Vercel:** Add `vercel.json`:
    ```json
    {
      "rewrites": [{ "source": "/(.*)", "destination": "/index.html" }]
    }
    ```
  - **Netlify:** Add `_redirects` in `public`:
    ```
    /*    /index.html   200
    ```

---

## Best Practices

1. **Environment Variables**
   - Use different API URLs for dev/staging/prod
   - Never commit `.env` files

2. **SEO**
   - Add meta tags in `index.html`
   - Add sitemap.xml
   - Add robots.txt

3. **Performance**
   - Enable gzip compression
   - Use CDN (Vercel/Netlify do this automatically)
   - Optimize images

4. **Security**
   - Always use HTTPS
   - Keep dependencies updated
   - Set proper CORS origins

---

## Need Help?

- Vercel Docs: https://vercel.com/docs
- Netlify Docs: https://docs.netlify.com
- Railway Docs: https://docs.railway.app

---

**Ready to share your PinIt landing page with the world!** 🚀


