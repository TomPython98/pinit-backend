# PinIt Build Notes Documentation

## Overview
This document provides comprehensive build configuration, requirements, and deployment instructions for the PinIt application across all platforms.

## Backend Build Configuration

### Django Backend Requirements

#### Python Version
- **Python**: 3.11+
- **Django**: 4.2+
- **Django REST Framework**: 3.14+

#### Core Dependencies (`requirements.txt`)
```
Django==4.2.7
djangorestframework==3.14.0
django-cors-headers==4.3.1
daphne==4.0.0
channels==4.0.0
django-push-notifications==3.0.0
whitenoise==6.6.0
gunicorn==21.2.0
```

#### Development Dependencies
```
pytest==7.4.3
pytest-django==4.7.0
coverage==7.3.2
black==23.9.1
flake8==6.1.0
```

#### Build Configuration Files
- `runtime.txt`: Python version specification
- `Procfile`: Process configuration for Railway deployment
- `railway.json`: Railway-specific configuration
- `docker-compose.yml`: Local development with Docker

### Backend Build Process

#### Local Development Setup
```bash
# 1. Clone repository
git clone <repository-url>
cd PinItApp

# 2. Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Run migrations
python manage.py migrate

# 5. Create superuser
python manage.py createsuperuser

# 6. Start development server
python manage.py runserver
```

#### Production Deployment (Railway)
```bash
# 1. Install Railway CLI
npm install -g @railway/cli

# 2. Login to Railway
railway login

# 3. Link project
railway link

# 4. Deploy
railway up
```

#### Environment Variables
```bash
# Required Environment Variables
SECRET_KEY=your-secret-key
DEBUG=False
ALLOWED_HOSTS=*
DATABASE_URL=sqlite:///db.sqlite3

# Optional Environment Variables
CORS_ALLOW_ALL_ORIGINS=True
PUSH_NOTIFICATIONS_SETTINGS={"APNS_CERTIFICATE": "/path/to/cert.pem"}
```

## iOS Build Configuration

### Xcode Requirements
- **Xcode**: 15.0+
- **iOS Deployment Target**: 15.0+
- **Swift**: 5.9+

### iOS Dependencies

#### Package Dependencies (Swift Package Manager)
```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/mapbox/mapbox-maps-ios", from: "11.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.0.0")
]
```

#### CocoaPods Dependencies (if used)
```ruby
# Podfile
platform :ios, '15.0'
use_frameworks!

target 'Fibbling' do
  pod 'MapboxMaps', '~> 11.0'
  pod 'Alamofire', '~> 5.8'
  pod 'SwiftyJSON', '~> 5.0'
end
```

### iOS Build Process

#### Development Build
```bash
# 1. Open Xcode project
open Fibbling.xcodeproj

# 2. Select development team
# 3. Configure signing & capabilities
# 4. Build and run (Cmd+R)
```

#### Archive Build (App Store)
```bash
# 1. Select "Any iOS Device" as target
# 2. Product → Archive
# 3. Distribute App → App Store Connect
# 4. Upload to App Store
```

#### TestFlight Build
```bash
# 1. Archive build
# 2. Distribute App → TestFlight
# 3. Upload for testing
```

### iOS Configuration Files

#### Info.plist Configuration
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>PinIt needs location access to find nearby study events</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>PinIt needs location access to find nearby study events</string>
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.pinit.app</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>pinit</string>
        </array>
    </dict>
</array>
```

#### Entitlements Configuration
```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:pin-it.net</string>
</array>
<key>aps-environment</key>
<string>production</string>
```

## Android Build Configuration

### Android Studio Requirements
- **Android Studio**: Hedgehog 2023.1.1+
- **Gradle**: 8.4+
- **Kotlin**: 1.9.20+
- **Compile SDK**: 35
- **Target SDK**: 35
- **Min SDK**: 24

### Android Dependencies

#### Gradle Configuration (`build.gradle.kts`)
```kotlin
android {
    namespace = "com.example.pinit"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.example.pinit"
        minSdk = 24
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildFeatures {
        compose = true
    }
}
```

#### Dependencies (`build.gradle.kts`)
```kotlin
dependencies {
    // Core Android
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime.ktx)
    implementation(libs.androidx.activity.compose)
    
    // Compose BOM
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.ui)
    implementation(libs.androidx.ui.graphics)
    implementation(libs.androidx.ui.tooling.preview)
    implementation(libs.androidx.material3)
    
    // Extended Material Icons
    implementation("androidx.compose.material:material-icons-extended:1.6.1")
    
    // ViewModel Compose
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.7.0")
    
    // Mapbox
    implementation("com.mapbox.maps:android:11.0.0")
    
    // Network
    implementation("com.squareup.retrofit2:retrofit:2.9.0")
    implementation("com.squareup.retrofit2:converter-gson:2.9.0")
    implementation("com.google.code.gson:gson:2.10.1")
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    implementation("com.squareup.okhttp3:logging-interceptor:4.12.0")
    
    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3")
    
    // JSON Processing
    implementation("org.json:json:20240303")
    
    // Core Library Desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    
    // Testing
    testImplementation(libs.junit)
    androidTestImplementation(libs.androidx.junit)
    androidTestImplementation(libs.androidx.espresso.core)
    androidTestImplementation(platform(libs.androidx.compose.bom))
    androidTestImplementation(libs.androidx.ui.test.junit4)
    debugImplementation(libs.androidx.ui.tooling)
    debugImplementation(libs.androidx.ui.test.manifest)
}
```

### Android Build Process

#### Development Build
```bash
# 1. Open Android Studio
# 2. Open project from PinIt_Android directory
# 3. Sync Gradle files
# 4. Run on device/emulator (Shift+F10)
```

#### Debug APK Build
```bash
# Command line build
./gradlew assembleDebug

# Output: app/build/outputs/apk/debug/app-debug.apk
```

#### Release APK Build
```bash
# 1. Generate signing key
keytool -genkey -v -keystore pinit-release-key.keystore -alias pinit -keyalg RSA -keysize 2048 -validity 10000

# 2. Configure signing in build.gradle
android {
    signingConfigs {
        release {
            storeFile file('pinit-release-key.keystore')
            storePassword 'your-store-password'
            keyAlias 'pinit'
            keyPassword 'your-key-password'
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            isMinifyEnabled = true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}

# 3. Build release APK
./gradlew assembleRelease

# Output: app/build/outputs/apk/release/app-release.apk
```

#### AAB Build (Google Play Store)
```bash
# Build Android App Bundle
./gradlew bundleRelease

# Output: app/build/outputs/bundle/release/app-release.aab
```

### Android Configuration Files

#### AndroidManifest.xml
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    
    <application
        android:allowBackup="true"
        android:dataExtractionRules="@xml/data_extraction_rules"
        android:fullBackupContent="@xml/backup_rules"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:supportsRtl="true"
        android:theme="@style/Theme.PinIt"
        android:usesCleartextTraffic="true">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:label="@string/app_name"
            android:theme="@style/Theme.PinIt">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

#### ProGuard Rules (`proguard-rules.pro`)
```proguard
# Retrofit
-dontwarn retrofit2.**
-keep class retrofit2.** { *; }
-keepattributes Signature
-keepattributes Exceptions

# Gson
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Mapbox
-keep class com.mapbox.** { *; }
-dontwarn com.mapbox.**

# Keep data classes
-keep class com.example.pinit.models.** { *; }
```

## Build Environment Setup

### Required Tools

#### Backend Development
- Python 3.11+
- pip
- virtualenv
- Git
- Railway CLI (for deployment)

#### iOS Development
- macOS (required for iOS development)
- Xcode 15.0+
- iOS Simulator
- Apple Developer Account (for App Store)
- CocoaPods (if using Pod dependencies)

#### Android Development
- Android Studio Hedgehog 2023.1.1+
- Android SDK (API 24-35)
- Java 11+
- Gradle 8.4+
- Android Emulator or physical device

### Environment Variables

#### Backend Environment
```bash
# .env file for local development
SECRET_KEY=your-secret-key-here
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1
DATABASE_URL=sqlite:///db.sqlite3
CORS_ALLOW_ALL_ORIGINS=True
```

#### iOS Environment
```bash
# Xcode Build Settings
API_BASE_URL=https://pinit-backend-production.up.railway.app/api
MAPBOX_ACCESS_TOKEN=your-mapbox-token
```

#### Android Environment
```bash
# gradle.properties
MAPBOX_ACCESS_TOKEN=your-mapbox-token
API_BASE_URL=https://pinit-backend-production.up.railway.app/api
```

## Build Scripts

### Backend Build Scripts

#### Quick Deploy Script (`quick_deploy.py`)
```python
#!/usr/bin/env python3
import subprocess
import sys

def deploy():
    print("🚀 Starting PinIt deployment...")
    
    # Run migrations
    subprocess.run(["python", "manage.py", "migrate"], check=True)
    
    # Collect static files
    subprocess.run(["python", "manage.py", "collectstatic", "--noinput"], check=True)
    
    # Run tests
    subprocess.run(["python", "-m", "pytest"], check=True)
    
    print("✅ Deployment completed successfully!")

if __name__ == "__main__":
    deploy()
```

#### Railway Deploy Script (`go_live.sh`)
```bash
#!/bin/bash
echo "🚀 Deploying PinIt to Railway..."

# Install Railway CLI if not installed
if ! command -v railway &> /dev/null; then
    npm install -g @railway/cli
fi

# Login to Railway
railway login

# Deploy
railway up

echo "✅ Deployment completed!"
```

### iOS Build Scripts

#### Build Script (`build_ios.sh`)
```bash
#!/bin/bash
echo "📱 Building iOS app..."

# Clean build folder
xcodebuild clean -workspace Fibbling.xcworkspace -scheme Fibbling

# Build for simulator
xcodebuild build -workspace Fibbling.xcworkspace -scheme Fibbling -destination 'platform=iOS Simulator,name=iPhone 15'

# Archive for App Store
xcodebuild archive -workspace Fibbling.xcworkspace -scheme Fibbling -archivePath build/Fibbling.xcarchive

echo "✅ iOS build completed!"
```

### Android Build Scripts

#### Build Script (`build_android.sh`)
```bash
#!/bin/bash
echo "🤖 Building Android app..."

# Clean project
./gradlew clean

# Build debug APK
./gradlew assembleDebug

# Build release APK
./gradlew assembleRelease

# Build AAB for Play Store
./gradlew bundleRelease

echo "✅ Android build completed!"
```

## Testing Configuration

### Backend Testing
```bash
# Run all tests
python -m pytest

# Run with coverage
python -m pytest --cov=myapp

# Run specific test file
python -m pytest tests/test_views.py
```

### iOS Testing
```bash
# Run unit tests
xcodebuild test -workspace Fibbling.xcworkspace -scheme Fibbling -destination 'platform=iOS Simulator,name=iPhone 15'

# Run UI tests
xcodebuild test -workspace Fibbling.xcworkspace -scheme FibblingUITests -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Android Testing
```bash
# Run unit tests
./gradlew test

# Run instrumented tests
./gradlew connectedAndroidTest

# Run all tests
./gradlew check
```

## Deployment Checklist

### Backend Deployment
- [ ] Environment variables configured
- [ ] Database migrations applied
- [ ] Static files collected
- [ ] Tests passing
- [ ] Railway deployment successful
- [ ] Health check endpoint responding

### iOS Deployment
- [ ] Code signing configured
- [ ] App Store Connect setup
- [ ] TestFlight testing completed
- [ ] App Store review submitted
- [ ] Push notification certificates configured

### Android Deployment
- [ ] Release keystore generated
- [ ] ProGuard rules configured
- [ ] Google Play Console setup
- [ ] Internal testing completed
- [ ] Production release published

## Troubleshooting

### Common Build Issues

#### Backend Issues
- **Migration errors**: Run `python manage.py migrate --fake-initial`
- **Static files**: Ensure `whitenoise` is configured
- **CORS errors**: Check `CORS_ALLOW_ALL_ORIGINS` setting

#### iOS Issues
- **Code signing**: Verify Apple Developer account and certificates
- **Mapbox errors**: Check access token configuration
- **Build errors**: Clean build folder and rebuild

#### Android Issues
- **Gradle sync**: Check internet connection and proxy settings
- **Build errors**: Clean project and sync Gradle files
- **Mapbox errors**: Verify access token in `gradle.properties`

### Performance Optimization

#### Backend Optimization
- Enable database query optimization
- Implement Redis caching
- Use CDN for static files
- Optimize database indexes

#### Frontend Optimization
- Enable code splitting
- Optimize image assets
- Implement lazy loading
- Use ProGuard/R8 for Android

This build documentation provides comprehensive instructions for building and deploying the PinIt application across all platforms.

