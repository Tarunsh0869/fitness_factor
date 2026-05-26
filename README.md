# Fitness Factor

A Flutter + .NET 8 gym attendance app with Firebase and geofencing.

---

## Project Structure

```
fitness_factor/          ← Flutter mobile app
fitness_factor_api/      ← .NET 8 REST API backend
```

---

## Prerequisites

| Tool | Version |
|------|---------|
| Flutter SDK | ≥ 3.11.4 |
| Dart SDK | ≥ 3.11.4 |
| .NET SDK | 8.0 |
| SQL Server | 2019+ (or SQL Server Express) |
| Firebase project | with Firestore + FCM enabled |

---

## 1 — Backend Setup (`fitness_factor_api/`)

### 1.1 Configure appsettings

Copy the example and fill in your values:

```bash
cp fitness_factor_api/appsettings.example.json fitness_factor_api/appsettings.json
```

Edit `appsettings.json`:
- `ConnectionStrings:DefaultConnection` → your SQL Server connection string
- `Jwt:Key` → any random string ≥ 32 characters
- `Firebase:ServiceAccountPath` → path to your Firebase service account JSON

### 1.2 Add Firebase service account

Download your Firebase service account key from:
> Firebase Console → Project Settings → Service Accounts → Generate new private key

Save it as `fitness_factor_api/firebase-service-account.json`

### 1.3 Run the API

```bash
cd fitness_factor_api
dotnet restore
dotnet run
```

The API starts at `http://0.0.0.0:5001`  
Swagger UI: `http://localhost:5001/swagger`

> The database and tables are created automatically on first run via EF Core migrations.

---

## 2 — Flutter App Setup (`fitness_factor/`)

### 2.1 Firebase config

Place your Firebase config files:
- `android/app/google-services.json` — from Firebase Console → Android app
- `lib/firebase_options.dart` — generated via `flutterfire configure`

### 2.2 Install dependencies

```bash
cd fitness_factor
flutter pub get
```

### 2.3 Set API base URL

In `lib/services/attendance_service.dart`, update the base URL to point to your running API:
- Android emulator: `http://10.0.2.2:5001`
- Physical device: `http://<your-machine-ip>:5001`

### 2.4 Run the app

```bash
flutter run
```

---

## 3 — Database

The schema is managed by EF Core migrations in `fitness_factor_api/Migrations/`.  
Running `dotnet run` applies all pending migrations automatically.

Tables created:
- `Gyms` — gym locations with geofence radius
- `Members` — registered members
- `Attendances` — check-in/check-out records

A default gym (`Fitness Factor`) is seeded on first run.

---

## 4 — Environment Files (not committed)

| File | Where to get it |
|------|----------------|
| `fitness_factor_api/appsettings.json` | Copy from `appsettings.example.json` and fill in |
| `fitness_factor_api/firebase-service-account.json` | Firebase Console → Service Accounts |
| `fitness_factor/android/app/google-services.json` | Firebase Console → Android app |
| `fitness_factor/lib/firebase_options.dart` | Run `flutterfire configure` |
