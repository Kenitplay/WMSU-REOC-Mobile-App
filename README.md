# WMSU REOC Portal

[![Flutter Version](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-lightgrey.svg)]()

A dedicated mobile application for the **Western Mindanao State University (WMSU) Research Ethics Oversight Committee (REOC)**. This platform digitizes the ethical review workflow, ensuring transparency and efficiency in university research management.

---

## 📱 About the App

The **WMSU REOC App** is a centralized portal designed to streamline the communication between university researchers and the ethics committee. By moving away from manual paper trails, the app ensures that research proposals are reviewed, tracked, and approved in a timely and secure manner.



### Key Features
* **Digital Submission:** Researchers can upload proposals and required ethics documents directly from their devices.
* **Real-time Tracking:** Stay updated with the current status of your application (e.g., Pending, Under Review, Approved, or Revisions Required).
* **Feedback Loop:** Receive direct comments and guidance from the REOC reviewers.
* **Institution-wide Standards:** Ensures all research adheres to the ethical guidelines set by WMSU and national research bodies.

---

## 🚀 Getting Started

Follow these instructions to get a copy of the project up and running on your local machine for development and testing.

### Prerequisites
* **Flutter SDK:** [Install Flutter](https://docs.flutter.dev/get-started/install)
* **Dart SDK:** Included with Flutter
* **IDE:** VS Code or Android Studio with Flutter/Dart plugins installed.
* **Git:** To clone the repository.

### Installation

1.  **Clone the Repository:**
    ```bash
    git clone [https://github.com/your-username/wmsu-reoc-app.git](https://github.com/your-username/wmsu-reoc-app.git)
    cd wmsu-reoc-app
    ```

2.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Setup Environment (Optional):**
    If your app uses Firebase or an API, ensure your `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) files are placed in the correct directories.

4.  **Launch the App:**
    Connect a device or start an emulator and run:
    ```bash
    flutter run
    ```

---

## 🛠 Building the Application

To create a release build for distribution:

### Android
Generate an APK:
```bash
flutter build apk --release