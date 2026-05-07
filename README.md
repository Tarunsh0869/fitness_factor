# Fitness Factor - Geo-Attendance Tracking App

A Flutter-based gym attendance tracking application with automatic geofencing check-in/check-out, Firebase integration, and Aadhaar-based member registration.

## Features

- **Auto Geo-Attendance**: Automatic check-in/check-out based on GPS geofencing
- **Manual Attendance Logging**: Log workouts manually with workout type, notes, and custom times
- **Real-time Session Tracking**: Live timer for active gym sessions
- **Exit Confirmation**: FCM push notifications when members leave the gym
- **Aadhaar Verification**: Secure member registration with Verhoeff checksum validation
- **Session History**: View past workout sessions with duration and details
- **Settings**: View member and gym information

## Tech Stack

- **Flutter** (SDK ^3.11.4)
- **Firebase**:
  - Firestore (database)
  - Firebase Auth (authentication)
  - Firebase Cloud Messaging (push notifications)
- **Geolocator** (geofencing)
- **RxDart** (reactive streams)

## Project Structure

```
lib/
├── models/
│   ├── attendance_record.dart    # Attendance session model
│   └── member.dart                # Member model
├── screens/
│   ├── attendance_form_screen.dart  # Manual attendance logging
│   ├── home_screen.dart             # Main dashboard
│   ├── login_screen.dart            # Phone-based login
│   ├── register_screen.dart         # New member registration
│   ├── seed_screen.dart             # Initial Firestore setup
│   └── settings_screen.dart         # App settings
├── services/
│   ├── attendance_service.dart   # Firestore attendance operations
│   ├── firebase_service.dart     # FCM setup and streams
│   └── geo_service.dart          # Geofencing logic
├── widgets/
│   └── exit_confirmation_sheet.dart  # Exit confirmation modal
├── firebase_options.dart         # Firebase config (auto-generated)
└── main.dart                     # App entry point
```

## Prerequisites

1. **Flutter SDK** (^3.11.4)
2. **Android Studio** or **VS Code** with Flutter extensions
3. **Firebase Project** with:
   - Firestore enabled
   - Firebase Cloud Messaging enabled
   - Android app registered
4. **Google Services JSON**: `android/app/google-services.json`

## Setup Instructions

### 1. Clone and Install Dependencies

```bash
cd f:\desktop_3-9-26\AVALON_smart\fitness_factor\fitness_factor
flutter pub get
```

### 2. Firebase Configuration

#### a. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project: "Fitness Factor"
3. Enable **Firestore Database** (start in test mode)
4. Enable **Firebase Cloud Messaging**

#### b. Register Android App
1. In Firebase Console → Project Settings → Add Android App
2. Package name: `com.example.fitness_factor`
3. Download `google-services.json`
4. Place it in: `android/app/google-services.json`

#### c. Generate Firebase Options
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure --project=your-firebase-project-id
```

This will generate/update `lib/firebase_options.dart`.

### 3. Android Permissions

Already configured in `android/app/src/main/AndroidManifest.xml`:
- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`
- `ACCESS_BACKGROUND_LOCATION`
- `FOREGROUND_SERVICE`
- `INTERNET`
- `RECEIVE_BOOT_COMPLETED`

### 4. Firestore Security Rules

Set these rules in Firebase Console → Firestore → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /gyms/{gymId} {
      allow read: if true;
      allow write: if false;
    }
    match /members/{memberId} {
      allow read: if true;
      allow create: if true;
      allow update: if request.auth != null;
    }
    match /attendance/{sessionId} {
      allow read, write: if true;
    }
    match /exit_requests/{requestId} {
      allow read, write: if true;
    }
  }
}
```

## Running the App

### Debug Mode (Development)

```bash
# Connect Android device or start emulator
flutter devices

# Run the app
flutter run
```

### Release Mode (Production)

```bash
flutter run --release
```

### Build APK

```bash
# Build release APK
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Build App Bundle (for Play Store)

```bash
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

## First Run Setup

On first launch, the app will:
1. Check if `gym_001` exists in Firestore
2. If not, show **SeedScreen** to create:
   - Gym: `gym_001` (Fitness Factor HQ)
   - Test Member: `member_001` (phone: `+60123456789`)
3. Redirect to **LoginScreen**

### Test Login Credentials
- **Phone**: `+60123456789`
- **Member**: Test Member

## Usage

### 1. Login
- Enter registered phone number
- App fetches member data from Firestore

### 2. Auto Check-in
- Grant location permissions
- Walk within 50m of gym coordinates
- App auto-checks you in

### 3. Manual Attendance
- Tap **"Log Attendance"** FAB
- Select workout type (Cardio, Weights, etc.)
- Set check-in/check-out times
- Add notes

### 4. Auto Check-out
- Walk outside gym geofence
- App sends FCM notification
- Confirm exit or deny (if still inside)
- Auto-checkout after 5 minutes if no response

### 5. Manual Check-out
- Tap **"Check Out Now"** button on session card

## Configuration

### Gym Coordinates
Edit in `lib/screens/seed_screen.dart`:
```dart
'latitude': 3.1390,    // Your gym latitude
'longitude': 101.6869, // Your gym longitude
'radiusMeters': 50,    // Geofence radius
```

### Geofence Settings
Edit in `lib/services/geo_service.dart`:
```dart
distanceFilter: 10,  // Update every 10 meters
debounceTime: Duration(minutes: 2),  // 2-min debounce
```

### Auto-Checkout Timer
Edit in `lib/screens/home_screen.dart`:
```dart
Timer(const Duration(minutes: 5), _doCheckout);  // 5-min delay
```

## Firestore Collections

### `gyms`
```json
{
  "gym_001": {
    "name": "Fitness Factor HQ",
    "latitude": 3.1390,
    "longitude": 101.6869,
    "radiusMeters": 50
  }
}
```

### `members`
```json
{
  "member_001": {
    "name": "Ahmad bin Ali",
    "phone": "+60123456789",
    "emergencyContact": "+60123456780",
    "membershipType": "Basic",
    "gender": "Male",
    "dateOfBirth": "1990-01-01T00:00:00.000",
    "gymId": "gym_001",
    "fcmToken": "...",
    "aadhaarNumber": "123456789012",
    "aadhaarName": "Ahmad bin Ali",
    "active": true,
    "createdAt": "2024-01-01T00:00:00.000Z"
  }
}
```

### `attendance`
```json
{
  "session_001": {
    "memberId": "member_001",
    "gymId": "gym_001",
    "checkedIn": "2024-01-01T08:00:00.000Z",
    "checkedOut": "2024-01-01T09:30:00.000Z",
    "source": "auto",  // or "manual"
    "workoutType": "Cardio",
    "notes": "Great session!"
  }
}
```

### `exit_requests`
```json
{
  "request_001": {
    "memberId": "member_001",
    "requestedAt": "2024-01-01T09:00:00.000Z",
    "handled": false
  }
}
```

## FCM Push Notifications

To trigger exit confirmation:
```json
{
  "to": "<member_fcm_token>",
  "data": {
    "action": "exit_confirmation"
  }
}
```

## Troubleshooting

### Location Permission Denied
- Go to Settings → Apps → Fitness Factor → Permissions
- Enable Location → Allow all the time

### Firebase Connection Failed
- Verify `google-services.json` is in `android/app/`
- Check Firebase project is active
- Run `flutter clean && flutter pub get`

### Geofence Not Working
- Ensure GPS is enabled
- Check location permissions granted
- Verify gym coordinates are correct
- Test with smaller radius (e.g., 100m)

### Build Errors
```bash
# Clean build cache
flutter clean

# Get dependencies
flutter pub get

# Rebuild
flutter run
```

## Development Notes

- **Minimum SDK**: Android 21 (Lollipop)
- **Target SDK**: Latest Flutter default
- **Compile SDK**: Latest Flutter default
- **Java Version**: 17

## License

Private project - All rights reserved

## Support

For issues or questions, contact the development team.

---

**Built with ❤️ using Flutter**
