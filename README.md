# Googogo: AI-Powered Accessible Navigation & Civic Reporting

## 📋 Repository Overview
**Project Name:** Googogo
**Focus:** AI-driven accessibility, smart city civic reporting and pedestrian navigation.
**Status:** MVP Prototype

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

### Google Technologies
* **Gemini API:** Used for analyzing sidewalk images to detect damage categories (cracks, uneven surfaces) and assign severity scores.
* **Google Maps SDK:** Fetches base pedestrian routes which are then re-ranked based on accessibility data.
* **Firebase Ecosystem:**
    * **Authentication:** Role-based access control.
    * **Firestore:** Database for storing damage reports and accessibility scores.
    * **Cloud Storage:** Hosting user-uploaded images.
    * **Cloud Functions:** Backend processing and automation.

### Frontend & UI
* **Framework:** Flutter (Android & iOS).
* **Accessibility UI:** Features large text support and voice interaction capabilities.

---

## ⚙️ Implementation & System Architecture

### 1. Volunteer Damage Reporting Flow
Volunteers capture images of sidewalks using the mobile app. The AI analyzes the image to detect damage categories and severity (1-10). The user confirms the AI output, and the data is stored in Firestore with GPS location and timestamps.

### 2. Automated Authority Reporting Flow
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

## 📥 Installation & Setup

*(Note: Please ensure you have the Flutter SDK and a Firebase project set up).*

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/your-username/googogo.git](https://github.com/your-username/googogo.git)
    cd googogo
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Configure Firebase:**
    * Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) to the respective directories.

4.  **Environment Variables:**
    * Create a `.env` file and add your Gemini API Key and Google Maps API Key.

5.  **Run the app:**
    ```bash
    flutter run
    ```
