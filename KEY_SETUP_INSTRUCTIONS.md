# App Signing Setup Instructions

## Creating the key.properties File

Before building a release version of the app, you need to create a `key.properties` file in the root directory of your project (same level as `pubspec.yaml`).

### Step 1: Generate a Signing Key

Run this command in your terminal:

```bash
keytool -genkey -v -keystore focus-flow-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias focus-flow-key
```

This will create a keystore file named `focus-flow-release-key.jks`.

### Step 2: Create key.properties File

Create a file named `key.properties` in the project root with the following content:

```properties
storePassword=your_keystore_password
keyPassword=your_key_password
keyAlias=focus-flow-key
storeFile=../focus-flow-release-key.jks
```

Replace:
- `your_keystore_password` with the keystore password you chose
- `your_key_password` with the key password you chose
- Ensure the path to your keystore file is correct

### Step 3: Security Notes

**Important:** 
- Never commit the `key.properties` file to version control
- Keep your keystore file secure and backed up
- The `key.properties` file is already added to `.gitignore`

### Step 4: Build Release APK/AAB

```bash
# For APK
flutter build apk --release

# For App Bundle (recommended for Play Store)
flutter build appbundle --release
```

The build system will automatically use your signing configuration for release builds.

## Troubleshooting

If you encounter signing errors:

1. Verify the paths in `key.properties` are correct
2. Ensure the keystore file exists in the specified location
3. Check that passwords match what you used when creating the keystore
4. Make sure the `key.properties` file is in the project root directory

## Additional Security

For additional security in CI/CD environments, consider:

1. Using environment variables instead of the properties file
2. Encrypting the keystore file
3. Using Google Play App Signing (recommended)

---

**Note:** This signing setup is required for publishing to the Google Play Store. The debug configuration is only suitable for development and testing.