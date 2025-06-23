# Firebase Setup Guide for FarmiculturAPP

This guide will help you set up Firebase for your FarmiculturAPP project.

## Prerequisites

- A Firebase project (cropvision-73fde)
- Xcode 13.0 or later
- iOS 15.0 or later

## Step 1: Firebase Console Setup

1. **Go to Firebase Console**
   - Visit [https://console.firebase.google.com/](https://console.firebase.google.com/)
   - Sign in with your Google account

2. **Select Your Project**
   - Choose the project: `cropvision-73fde`

3. **Add iOS App**
   - Click the iOS icon (+ Add app)
   - Enter your Bundle ID (e.g., `com.yourcompany.FarmiculturAPP`)
   - Enter App nickname: `FarmiculturAPP`
   - Click "Register app"

4. **Download Configuration File**
   - Download the `GoogleService-Info.plist` file
   - **Important**: Keep this file secure and never commit it to version control

## Step 2: Xcode Setup

1. **Add Firebase SDK**
   - In Xcode, go to File → Add Package Dependencies
   - Enter URL: `https://github.com/firebase/firebase-ios-sdk`
   - Select the following packages:
     - FirebaseAuth
     - FirebaseFirestore
     - FirebaseFirestoreSwift

2. **Add Configuration File**
   - Drag the downloaded `GoogleService-Info.plist` into your Xcode project
   - Make sure it's added to your main app target
   - **Replace** the placeholder file in the project

3. **Update Bundle Identifier**
   - In Xcode, select your project
   - Go to the target settings
   - Update the Bundle Identifier to match what you registered in Firebase

## Step 3: Firebase Console Configuration

1. **Enable Authentication**
   - In Firebase Console, go to Authentication → Sign-in method
   - Enable "Email/Password" authentication
   - Optionally enable other methods (Google, Apple, etc.)

2. **Set up Firestore Database**
   - Go to Firestore Database → Create database
   - Choose "Start in test mode" for development
   - Select a location close to your users
   - **Important**: Update security rules for production

3. **Firestore Security Rules**
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       // Users can only access their own data
       match /users/{userId} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
         
         // Users can manage their own crops
         match /crops/{cropId} {
           allow read, write: if request.auth != null && request.auth.uid == userId;
         }
       }
     }
   }
   ```

## Step 4: Test the Setup

1. **Build and Run**
   - Clean build folder (Product → Clean Build Folder)
   - Build and run the app

2. **Test Authentication**
   - Try creating a new account
   - Try signing in with existing credentials
   - Check Firebase Console to see if users are created

3. **Test Firestore**
   - Create a new crop in the app
   - Check Firestore Console to see if data is saved
   - Verify the data structure matches your models

## Data Structure

The app will create the following Firestore structure:

```
users/
  {userId}/
    crops/
      {cropId}/
        - id: string
        - userId: string
        - type: string
        - name: string
        - isActive: boolean
        - sections: array
        - beds: array
        - activities: array
        - observations: array
        - ... (other crop fields)
```

## Troubleshooting

### Common Issues

1. **"Firebase not configured" error**
   - Make sure `GoogleService-Info.plist` is added to the project
   - Verify the Bundle ID matches Firebase registration

2. **Authentication errors**
   - Check if Email/Password auth is enabled in Firebase Console
   - Verify the user exists in Firebase Console

3. **Firestore permission errors**
   - Check Firestore security rules
   - Ensure the user is authenticated before accessing data

4. **Build errors**
   - Clean build folder and rebuild
   - Check that all Firebase packages are properly added

### Security Best Practices

1. **Never commit `GoogleService-Info.plist` to version control**
2. **Use proper Firestore security rules in production**
3. **Implement proper error handling in the app**
4. **Consider implementing offline persistence for better UX**

## Next Steps

Once Firebase is set up:

1. **Test all functionality** with real Firebase data
2. **Implement offline support** using Firestore offline persistence
3. **Add push notifications** for harvest reminders
4. **Set up analytics** to track app usage
5. **Configure crash reporting** for better debugging

## Support

If you encounter issues:

1. Check the [Firebase iOS documentation](https://firebase.google.com/docs/ios/setup)
2. Review [Firebase iOS GitHub repository](https://github.com/firebase/firebase-ios-sdk)
3. Check Firebase Console for error logs
4. Verify your Firebase project settings 