# Android Build Notes

## Build Configuration

### Gradle Version
- **Gradle**: 8.0
- **Android Gradle Plugin**: 8.1.0
- **Kotlin**: 1.9.10

### SDK Versions
- **Compile SDK**: 35
- **Target SDK**: 35
- **Min SDK**: 24
- **Build Tools**: 34.0.0

### Java Version
- **Source Compatibility**: Java 11
- **Target Compatibility**: Java 11
- **Core Library Desugaring**: Enabled

## Dependencies

### Core Android
```kotlin
implementation("androidx.core:core-ktx:1.12.0")
implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")
implementation("androidx.activity:activity-compose:1.8.2")
```

### Jetpack Compose
```kotlin
implementation(platform("androidx.compose:compose-bom:2024.02.00"))
implementation("androidx.compose.ui:ui")
implementation("androidx.compose.ui:ui-graphics")
implementation("androidx.compose.ui:ui-tooling-preview")
implementation("androidx.compose.material3:material3")
implementation("androidx.compose.material:material-icons-extended:1.6.1")
implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.7.0")
```

### Network
```kotlin
implementation("com.squareup.retrofit2:retrofit:2.9.0")
implementation("com.squareup.retrofit2:converter-gson:2.9.0")
implementation("com.google.code.gson:gson:2.10.1")
implementation("com.squareup.okhttp3:okhttp:4.12.0")
implementation("com.squareup.okhttp3:logging-interceptor:4.12.0")
```

### Maps
```kotlin
implementation("com.mapbox.maps:android:11.0.0")
```

### Coroutines
```kotlin
implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3")
```

### Utilities
```kotlin
implementation("org.json:json:20240303")
coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
```

### Testing
```kotlin
testImplementation("junit:junit:4.13.2")
androidTestImplementation("androidx.test.ext:junit:1.1.5")
androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
androidTestImplementation(platform("androidx.compose:compose-bom:2024.02.00"))
androidTestImplementation("androidx.compose.ui:ui-test-junit4")
debugImplementation("androidx.compose.ui:ui-tooling")
debugImplementation("androidx.compose.ui:ui-test-manifest")
```

## Build Types

### Debug
```kotlin
buildTypes {
    debug {
        isDebuggable = true
        isMinifyEnabled = false
        applicationIdSuffix = ".debug"
        versionNameSuffix = "-debug"
    }
}
```

### Release
```kotlin
buildTypes {
    release {
        isMinifyEnabled = false
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
    }
}
```

## Required Build Steps

### 1. Prerequisites
- **Android Studio**: Arctic Fox or later
- **JDK**: 11 or later
- **Android SDK**: API 24-35
- **NDK**: Not required

### 2. Environment Setup
```bash
# Set JAVA_HOME
export JAVA_HOME=/path/to/jdk11

# Set ANDROID_HOME
export ANDROID_HOME=/path/to/android-sdk

# Add to PATH
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
```

### 3. Build Commands
```bash
# Clean build
./gradlew clean

# Build debug APK
./gradlew assembleDebug

# Build release APK
./gradlew assembleRelease

# Run tests
./gradlew test

# Run connected tests
./gradlew connectedAndroidTest
```

### 4. IDE Setup
1. Open project in Android Studio
2. Sync Gradle files
3. Install required SDK platforms
4. Configure signing for release builds

## Configuration Files

### build.gradle.kts (App Level)
```kotlin
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
}

android {
    namespace = "com.example.pinit"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.example.pinit"
        minSdk = 24
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
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

### build.gradle.kts (Project Level)
```kotlin
plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.kotlin.android) apply false
    alias(libs.plugins.kotlin.compose) apply false
}
```

### gradle.properties
```properties
# Project-wide Gradle settings
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
org.gradle.parallel=true
org.gradle.caching=true
org.gradle.configureondemand=true

# AndroidX package structure
android.useAndroidX=true
android.enableJetifier=true

# Compose
android.enableComposeCompiler=true
```

## Permissions

### AndroidManifest.xml
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Network permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    
    <!-- Location permissions -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    
    <!-- Camera permissions (for profile pictures) -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    
    <application
        android:allowBackup="true"
        android:dataExtractionRules="@xml/data_extraction_rules"
        android:fullBackupContent="@xml/backup_rules"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:supportsRtl="true"
        android:theme="@style/Theme.PinIt"
        android:usesCleartextTraffic="true"
        android:networkSecurityConfig="@xml/network_security_config">
        
        <!-- Mapbox configuration -->
        <meta-data
            android:name="com.mapbox.maps.MapboxMapOptions.EnableMultipleRendererMode"
            android:value="true" />
        <meta-data
            android:name="com.mapbox.token"
            android:value="pk.eyJ1IjoidG9tYmVzaSIsImEiOiJjbTdwNDdvbXAwY3I3MmtzYmZ3dzVtaGJrIn0.yiXVdzVGYjTucLPZPa0hjw" />
            
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:label="@string/app_name"
            android:theme="@style/Theme.PinIt"
            android:windowSoftInputMode="adjustResize">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

## ProGuard Rules

### proguard-rules.pro
```proguard
# Add project specific ProGuard rules here
-keep class com.example.pinit.models.** { *; }
-keep class com.example.pinit.network.** { *; }

# Gson
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Retrofit
-keepattributes Signature, InnerClasses, EnclosingMethod
-keepattributes RuntimeVisibleAnnotations, RuntimeVisibleParameterAnnotations
-keepclassmembers,allowshrinking,allowobfuscation interface * {
    @retrofit2.http.* <methods>;
}
-dontwarn org.codehaus.mojo.animal_sniffer.IgnoreJRERequirement
-dontwarn javax.annotation.**
-dontwarn kotlin.Unit
-dontwarn retrofit2.KotlinExtensions
-dontwarn retrofit2.KotlinExtensions$*

# OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# Mapbox
-keep class com.mapbox.** { *; }
-dontwarn com.mapbox.**
```

## Network Security

### network_security_config.xml
```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">localhost</domain>
        <domain includeSubdomains="true">10.0.2.2</domain>
        <domain includeSubdomains="true">127.0.0.1</domain>
    </domain-config>
    
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system"/>
        </trust-anchors>
    </base-config>
</network-security-config>
```

## Build Variants

### Debug Variant
- **Debuggable**: true
- **Minify**: false
- **Suffix**: .debug
- **Version**: -debug

### Release Variant
- **Debuggable**: false
- **Minify**: false (can be enabled)
- **Suffix**: none
- **Version**: production

## Signing Configuration

### debug.keystore
- **Location**: ~/.android/debug.keystore
- **Password**: android
- **Key Alias**: androiddebugkey
- **Key Password**: android

### Release Signing
```kotlin
android {
    signingConfigs {
        release {
            storeFile file("release.keystore")
            storePassword "password"
            keyAlias "key"
            keyPassword "password"
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

## Common Build Issues

### 1. Gradle Sync Issues
```bash
# Clean and rebuild
./gradlew clean
./gradlew build
```

### 2. SDK Issues
- Ensure correct SDK versions are installed
- Check Android Studio SDK Manager
- Verify environment variables

### 3. Dependency Conflicts
```bash
# Check dependency tree
./gradlew app:dependencies

# Resolve conflicts
./gradlew app:dependencyInsight --dependency <dependency-name>
```

### 4. Compose Issues
- Ensure Compose compiler is enabled
- Check Kotlin version compatibility
- Verify Compose BOM version

### 5. Mapbox Issues
- Verify access token is correct
- Check network permissions
- Ensure Mapbox SDK is properly initialized

## Performance Optimization

### 1. Build Performance
```properties
# gradle.properties
org.gradle.jvmargs=-Xmx4096m -Dfile.encoding=UTF-8
org.gradle.parallel=true
org.gradle.caching=true
org.gradle.configureondemand=true
```

### 2. App Performance
- Enable R8 for release builds
- Use ProGuard rules for obfuscation
- Optimize images and resources
- Enable vector drawables

### 3. Memory Optimization
- Use appropriate image formats
- Implement proper lifecycle management
- Avoid memory leaks in ViewModels
- Use lazy loading for large lists

## Testing Configuration

### Unit Tests
```kotlin
// test/java/com/example/pinit/
class EventRepositoryTest {
    @Test
    fun `test get events for user`() {
        // Test implementation
    }
}
```

### Instrumented Tests
```kotlin
// androidTest/java/com/example/pinit/
@RunWith(AndroidJUnit4::class)
class MainActivityTest {
    @Test
    fun testEventCreation() {
        // UI test implementation
    }
}
```

## Deployment

### Debug APK
```bash
./gradlew assembleDebug
# Output: app/build/outputs/apk/debug/app-debug.apk
```

### Release APK
```bash
./gradlew assembleRelease
# Output: app/build/outputs/apk/release/app-release.apk
```

### AAB (Android App Bundle)
```bash
./gradlew bundleRelease
# Output: app/build/outputs/bundle/release/app-release.aab
```

## CI/CD Integration

### GitHub Actions
```yaml
name: Android CI
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Set up JDK 11
      uses: actions/setup-java@v2
      with:
        java-version: '11'
        distribution: 'adopt'
    - name: Grant execute permission for gradlew
      run: chmod +x gradlew
    - name: Build with Gradle
      run: ./gradlew build
```

## Troubleshooting

### Common Issues
1. **Gradle sync failed**: Check internet connection and proxy settings
2. **SDK not found**: Verify ANDROID_HOME environment variable
3. **Build failed**: Check error logs and dependency versions
4. **App crashes**: Check logs and verify permissions
5. **Map not loading**: Verify Mapbox token and network permissions

### Debug Commands
```bash
# Check Gradle version
./gradlew --version

# Check dependencies
./gradlew app:dependencies

# Run with debug info
./gradlew build --info

# Check for lint issues
./gradlew lint
```

