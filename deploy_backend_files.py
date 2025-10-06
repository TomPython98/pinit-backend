#!/usr/bin/env python3
"""
Script to copy essential backend files for image upload system
"""

import os
import shutil
from pathlib import Path

def copy_backend_files():
    """Copy essential backend files to a deployment directory"""
    
    # Create deployment directory
    deploy_dir = Path("backend_deployment")
    deploy_dir.mkdir(exist_ok=True)
    
    # Files to copy
    files_to_copy = [
        "myapp/models.py",
        "myapp/views.py", 
        "myapp/urls.py",
        "StudyCon/settings.py",
        "StudyCon/urls.py",
        "requirements.txt"
    ]
    
    print("🚀 Copying backend files for image upload system...")
    
    for file_path in files_to_copy:
        src = Path(file_path)
        if src.exists():
            # Create directory structure
            dst = deploy_dir / file_path
            dst.parent.mkdir(parents=True, exist_ok=True)
            
            # Copy file
            shutil.copy2(src, dst)
            print(f"✅ Copied: {file_path}")
        else:
            print(f"❌ Not found: {file_path}")
    
    print(f"\n📁 Files copied to: {deploy_dir.absolute()}")
    print("\n📋 Next steps:")
    print("1. Go to https://github.com/TomPython98/pinit-backend")
    print("2. Upload these files to the repository")
    print("3. The server should redeploy automatically")
    
    # List the copied files
    print(f"\n📄 Copied files:")
    for root, dirs, files in os.walk(deploy_dir):
        for file in files:
            rel_path = os.path.relpath(os.path.join(root, file), deploy_dir)
            print(f"   - {rel_path}")

if __name__ == "__main__":
    copy_backend_files()
