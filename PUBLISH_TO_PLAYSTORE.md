# Publishing Your Flutter App to Google Play Store

This guide walks you through the process of publishing your Flutter habit tracker app to the Google Play Store.

## Prerequisites

Before you begin, ensure you have:

- A [Google Play Developer Account](https://play.google/console/signup) ($25 one-time fee)
- Flutter SDK installed and configured
- Your app ready for release (version bump in `pubspec.yaml`)

---

## Step 1: Update App Version

Before building, update the version in your [`pubspec.yaml`](pubspec.yaml):

```yaml
version: 1.0.0+1  # Change to your desired version
```

---

## Step 2: Build a Release APK/AAB

### Option A: Build App Bundle (Recommended)

App Bundles are smaller and optimized for Google Play's delivery:

```bash
flutter build appbundle --release
```

The output will be at: `build/app/outputs/flutter-apk/app-release.apk` (or `.aab`)

### Option B: Build APK

```bash
flutter build apk --release
```

---

## Step 3: Sign Your App

For release, you need a signing key. If you don't have one:

### Generate a Keystore

```bash
keytool -genkey -v -keystore your-app-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias your-app-alias
```

### Configure Signing in `android/app/build.gradle`

```groovy
android {
    signingConfigs {
        release {
            storeFile file("your-app-keystore.jks")
            storePassword "your-store-password"
            keyAlias "your-key-alias"
            keyPassword "your-key-password"
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

> **Security Tip:** Never commit your keystore file to version control. Add it to `.gitignore`.

---

## Step 4: Create Google Play Console Listing

1. Go to [Google Play Console](https://play.google.com/console)
2. Click **Create App**
3. Fill in:
   - **App name**: Your app's display name
   - **Default language**: English (en)
   - **App type**: Android App

---

## Step 5: Complete App Content

Answer the **App Content** questions:

- **Privacy Policy**: Required if app handles personal data
- **Target Audience**: Select age groups
- **App Categories**: Select appropriate categories
- **Tags**: Add relevant tags

---

## Step 6: Upload Your App

1. Go to **Release > Production** in Play Console
2. Click **Create New Release**
3. Upload your `.aab` or `.apk` file
4. Add release notes
5. Click **Save** and then **Review Release**

---

## Step 7: Fill App Listing Details

Navigate to **Store Presence** and fill:

### Main Store Listing
- **Title** (short - 30 chars max)
- **Short Description** (80 chars max)
- **Full Description** (4000 chars max)
- **Screenshots**: At least 2 screenshots (phone + 7" tablet recommended)
- **Feature Graphic**: 1024 x 512 PNG
- **Phone Screenshots**: 1080 x 1920 PNG (at least 2)
- **App Icon**: 512 x 512 PNG

### Pricing & Distribution
- Set as **Free** or **Paid**
- Select countries/regions

---

## Step 8: Review and Publish

1. Go to **Release > Production**
2. Ensure status shows "Ready to send for review"
3. Click **Send for Review**

**Typical review time:** 1-7 days (usually 24-48 hours)

---

## Post-Publishing

After approval:

- Track downloads and ratings in Play Console
- Respond to user reviews
- Push updates using the same signing key
- Monitor crashes via **Quality > Android Vitals**

---

## Useful Commands Summary

```bash
# Build release APK
flutter build apk --release

# Build release App Bundle
flutter build appbundle --release

# Build with specific keystore
flutter build apk --release --keystore=path/to/keystore.jks --key-alias=alias
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| App rejected for privacy policy | Add a valid privacy policy URL in App Content |
| Signing issues | Ensure you're using the same keystore for updates |
| APK too large | Use App Bundle, enable R8 minification |
| Target SDK too old | Update `android/app/build.gradle` minSdkVersion |

---

## Resources

- [Google Play Console](https://play.google.com/console)
- [Flutter Build & Release Docs](https://flutter.dev/docs/deployment/android)
- [Google Play App Signing](https://developer.android.com/studio/publish/app-signing)
- [App Bundle Explained](https://developer.android.com/guide/app-bundle)

---

*Last updated: 2026-02-21*
