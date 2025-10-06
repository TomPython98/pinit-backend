#!/usr/bin/env python3
"""
Deploy image upload fixes to production
"""

import os
import subprocess
import sys

def deploy_to_production():
    """Deploy the image upload fixes to production"""
    
    print("🚀 Deploying image upload fixes to production...")
    
    # Change to backend deployment directory
    os.chdir('/Users/tombesinger/Desktop/PinItApp/backend_deployment')
    
    try:
        # Copy updated files
        print("📁 Copying updated files...")
        subprocess.run(['cp', '../myapp/models.py', 'myapp/models.py'], check=True)
        subprocess.run(['cp', '../StudyCon/urls.py', 'StudyCon/urls.py'], check=True)
        
        # Deploy to Railway
        print("🚂 Deploying to Railway...")
        subprocess.run(['railway', 'deploy'], check=True)
        
        print("✅ Image upload fixes deployed successfully!")
        print("🔧 Fixed issues:")
        print("  - Removed broken unique constraint")
        print("  - Added proper partial unique constraint")
        print("  - Fixed media file serving in production")
        print("🔗 Images should now be accessible at: https://pinit-backend-production.up.railway.app/media/...")
        
    except subprocess.CalledProcessError as e:
        print(f"❌ Deployment failed: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    deploy_to_production()
