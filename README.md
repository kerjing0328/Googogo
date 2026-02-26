# AidCess: AI Pedestrian Damage Reporting & Smart Route Assistant

<img width="1920" height="1080" alt="Googogo" src="https://github.com/user-attachments/assets/c19c31d7-9b2d-427a-a3d7-ea385e5ce24b" />

## 📋 Repository Overview
* **Project Name:** Googogo
* **Focus:** AI-driven accessibility, smart city civic reporting and pedestrian navigation.
* **Status:** MVP Prototype

### 👥 Team Intro
* Ng Ker Jing
* Ng Shi Hong

---

## 🚀 Project Overview

### Problem Statement
Urban pedestrian infrastructure in Malaysia is frequently inaccessible to persons with disabilities (OKU), the elderly, and visually impaired users due to damaged sidewalks, missing ramps, and obstructions. Existing navigation applications prioritize distance over accessibility, and the process of reporting infrastructure damage to authorities is often slow and fragmented. This leads to unsafe routes, reduced mobility independence, and delayed urban maintenance.

### Solution
Googogo is a crowdsourced, AI-powered pedestrian navigation and civic reporting platform. It transforms street-level images into actionable accessibility intelligence, enabling accessibility-aware navigation while directly connecting citizen-reported issues to relevant local authorities.

### 🌏 Sustainable Development Goals (SDG) Alignment
This project aligns with the following UN SDGs:

* **SDG 11: Sustainable Cities and Communities**
    * Improves safety and inclusivity of pedestrian infrastructure.
    * Enables data-driven urban maintenance and planning.
* **SDG 10: Reduced Inequalities**
    * Empowers OKU and visually impaired users with independent navigation.
    * Reduces mobility barriers caused by poor infrastructure.

---

## ✨ Key Features

* **AI-Powered Damage Detection:** Uses Computer Vision to detect and assess the severity of sidewalk issues (cracks, obstructions, missing ramps).
* **Accessibility-First Navigation:** Generates accessibility scores for pedestrian routes and prioritizes safety over distance.
* **Voice Guidance:** Provides AI-powered verbal descriptions of route conditions for visually impaired users.
* **Automated Civic Reporting:** Automatically identifies the responsible local authority based on location and generates structured reports.
* **Crowdsourcing & Gamification:** Encourages volunteers to capture data through a gamified interface to sustain participation.

---

## 🛠 Technologies Overview

Googogo is powered by a robust stack of Google technologies to ensure scalable performance, real-time data synchronization, and advanced AI capabilities across our architecture:

<img width="1920" height="1080" alt="technical" src="https://github.com/user-attachments/assets/b1c6edb1-fb5f-4fc1-8255-4952a1952053" />

* **Flutter (Dart):** Powers the cross-platform frontend for both the Volunteer Mobile App (Android/iOS) and the Authority Web Dashboard.
* **Google Gemini (2.5 Flash):** Acts as the core of our Data Ingestion Pipeline. It analyzes user-uploaded photos to verify valid outdoor images, classify the specific type of infrastructure damage, and automatically assign a severity score.
* **Google Maps Platform (Accessible Navigation Pipeline):**
  * **Places API:** Provides real-time autocomplete suggestions for pedestrian destinations.
  * **Directions API:** Fetches accurate pedestrian routes for evaluation.
  * **Maps SDK:** Renders the interactive visual map for navigation and hazard plotting.
* **Firebase Suite (Backend):**
  * **Authentication:** Manages secure sign-ins for pedestrians and urban planners.
  * **Firestore Database:** Handles metadata persistence for issue reports and fetches real-time "barrier" data to calculate route accessibility scores.
  * **Cloud Storage:** Securely hosts the uploaded images of infrastructure damage.

*(Additional Flutter libraries include `image_picker`, `geolocator`, `geocoding`, and `flutter_tts` for voice guidance).*

---

## ⚙️ Implementation & System Architecture

<img width="1920" height="1080" alt="userflow" src="https://github.com/user-attachments/assets/d8120244-1bfc-418b-b3a5-a464c3383b3f" />

### 1. Volunteer Damage Reporting Flow
Volunteers capture images of sidewalks using the mobile app. The AI analyzes the image to detect damage categories and severity (1-10). The user confirms the AI output, and the data is stored in Firestore with GPS location and timestamps.

### 2. Autority Monitoring Flow
The system identifies the local authority (PBT) based on the report's geolocation. A structured report—containing the geo-tagged image, damage category, and severity score—is automatically sent via API or email to the authority's dashboard. The system tracks the status from "Submitted" to "Resolved".

### 3. Pedestrian Navigation Flow
When a user enters a destination and selects their mobility mode, the app fetches standard routes. These routes are then ranked by their calculated accessibility score, and the safest route is recommended with optional AI voice guidance.

---

## 🚧 Challenges Faced

* **Image Quality Variability:** Ensuring accurate AI detection across different lighting and camera qualities.
* **Volunteer Engagement:** Sustaining long-term participation from crowdsourced data collectors.
* **Privacy:** Avoiding the capture of identifiable individuals in public infrastructure photos.

---

## 🔮 Future Roadmap

* **Maintenance Priority Analytics:** developing logic to help authorities prioritize repairs based on severity and usage.
* **City-Wide Heatmaps:** Visualizing accessibility levels across entire districts.
* **Predictive Maintenance:** Using historical data to alert authorities before infrastructure becomes critical.

---

## ⚙️ Installation & Setup

To optimize performance and security, this project utilizes a single Flutter codebase with two distinct entry points. This separates our **Volunteer Mobile App** from our **Authority Web Dashboard**.

### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (Version 3.x or higher)
* Android Studio or Xcode (for running the mobile emulator)
* Google Chrome (required for testing the web dashboard)
* Git

**1. Clone the repository**
```bash
git clone https://github.com/kerjing0328/Googogo.git
cd googogo
```

**2. Install dependencies**
```bash
flutter pub get
```

**3. Configure Environment Variables**
This project uses a `.env` file to securely manage API keys for Gemini, Google Maps and Firebase App Check. Create a file named `.env` in the root directory of the project and add the following keys:

```env
# Google Maps & Gemini
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
GEMINI_API_KEY=your_gemini_api_key

# Firebase Web
FIREBASE_WEB_API_KEY=your_firebase_web_api_key
FIREBASE_WEB_APP_ID=your_firebase_web_app_id
FIREBASE_WEB_MESSAGING_SENDER_ID=your_firebase_web_sender_id
FIREBASE_WEB_PROJECT_ID=your_firebase_web_project_id
FIREBASE_WEB_AUTH_DOMAIN=your_firebase_web_auth_domain
FIREBASE_WEB_STORAGE_BUCKET=your_firebase_web_storage_bucket
FIREBASE_WEB_MEASUREMENT_ID=your_firebase_web_measurement_id

# Firebase Android
FIREBASE_ANDROID_API_KEY=your_firebase_android_api_key
FIREBASE_ANDROID_APP_ID=your_firebase_android_app_id

# Firebase iOS
FIREBASE_IOS_API_KEY=your_firebase_ios_api_key
FIREBASE_IOS_APP_ID=your_firebase_ios_app_id
FIREBASE_IOS_BUNDLE_ID=your_firebase_ios_bundle_id
```

**4. Firebase Configuration**
The `firebase_options.dart` file is already included in this repository. Ensure your local environment is authorized if you are swapping to a custom Firebase testing instance.

## 🚀 Running the Applications

### 📱 1. Running the Volunteer App (Mobile)
This app is designed for Android/iOS users to navigate and report damages.
**To run on an emulator or connected mobile device:**
```bash
flutter run -t lib/main_mobile.dart
```

### 💻 2. Running the Authority Dashboard (Web)
This dashboard is built for authorities to monitor incoming civic reports. It bypasses the mobile authentication wrapper for direct access and injects the required web-specific mapping scripts.

**To run on Google Chrome:**
```bash
flutter run -d chrome -t lib/main_web.dart
```
---

## 📦 Building for Production

To compile release versions of the platforms:

**Build Android APK:**
```bash
flutter build apk -t lib/main_mobile.dart
```

**Build Web Release:**
```bash
flutter build web -t lib/main_web.dart
```


