# Real-Time Multi-User Map Tracker (Flutter + Mapbox + Firestore)

A functional prototype for a real-time location tracking application. This project demonstrates how to broadcast a device's GPS coordinates to a cloud database and synchronize multiple users' positions on a shared Mapbox interface.

## 🚀 Key Features

* **Live Location Broadcasting:** Automatically streams the user's GPS coordinates to Firebase Firestore whenever they move (minimum 2-meter filter).
* **Real-Time Synchronization:** Uses Firestore snapshots to listen for updates from all active users and renders them instantly.
* **Mapbox Integration:** High-performance vector map rendering using the `mapbox_maps_flutter` SDK.
* **Batch Marker Rendering:** Optimized rendering logic using `CircleAnnotationManager.createMulti()` to handle multiple users without performance drops.
* **Persistent Identity:** Generates and stores a unique UUID and a random 2-character avatar locally using `SharedPreferences`.
* **Smart Navigation:** Includes a "Fly-to" camera function to smoothly center the map on the current user.

## 🛠️ Tech Stack

* **Frontend Framework:** Flutter
* **Map Provider:** Mapbox Maps SDK for Flutter
* **Database:** Cloud Firestore
* **Geolocation:** Geolocator
* **Storage:** Shared Preferences
* **Utilities:** `uuid`, `geotypes`, `dart:async`.

---

## 📋 Prerequisites

To get this prototype running, you need to configure the following external services:

1.  **Mapbox Access Token:**
    * Obtain a Public Access Token from your [Mapbox Account](https://account.mapbox.com/).
    * Configure your secret token in your project's `gradle.properties` (Android) and `Info.plist` (iOS).

2.  **Firebase Setup:**
    * Create a Firebase project.
    * Register your Android/iOS apps and download the `google-services.json` and `GoogleService-Info.plist`.
    * Enable **Cloud Firestore** and set the security rules to allow read/write access for testing.

3.  **Database Structure:**
    * The app expects a collection named `usersLocations`.

---

## ⚙️ Core Logic Overview

The application follows a reactive architecture divided into three main processes:



### 1. Initialization (`getInitData`)
When the app launches, it checks for a local `userId`. If it's a first-time run, it generates a unique identifier and a random avatar string (e.g., "XY"). This ensures that even without an authentication system, users are uniquely represented in the database.

### 2. Broadcasting (`startListeningGeolocationChanges`)
The app uses a `PositionStream` from the `geolocator` package.
* **Filter:** It only triggers an update if the user moves more than 2 meters.
* **Persistence:** The coordinates are sent to Firestore using `doc(userId).set(..., SetOptions(merge: true))`.

### 3. Rendering (`setupMarkersListener`)
This is the most critical part of the UI. The app subscribes to the `usersLocations` collection:
* **Snapshot Listener:** Every time any user's document changes in Firestore, the listener triggers.
* **Marker Management:** It clears existing annotations and rebuilds a list of `CircleAnnotationOptions`.
* **Optimization:** Instead of adding markers one by one, it uses `createMulti()` to push all markers to the Mapbox engine in a single batch, ensuring 60fps performance.

---

## 📂 Project Structure

```text
lib/
├── helpers/
│   ├── location_helper.dart           # Permission handling and position fetching
│   └── shared_preferences_helper.dart # Local storage for UserID and Avatars
├── screens/
│   └── mapbox_screen.dart             # Main Map UI and Real-time logic
└── main.dart                          # Application entry point