
# Project Blueprint

## Overview

This document outlines the architecture, features, and design of the Flutter application. It serves as a single source of truth for the project's implementation details.

## Current Features

* **FCM Push Notifications:** The application is configured to receive Firebase Cloud Messaging (FCM) push notifications.
* **FCM Token Management:** The application saves the device's FCM token to a "fcm_tokens" collection in Firestore to enable targeted push notifications.

## Design

The application follows a standard Flutter project structure. The core business logic is separated from the UI, and the UI is composed of reusable widgets.

## Plan for Current Request

The user requested to store the FCM token in Firebase. The following steps were taken:

1. **Add `cloud_firestore` dependency:** The `cloud_firestore` package was added to `pubspec.yaml` to enable interaction with Firestore.
2. **Update `firebase_api.dart`:**
    - An instance of `FirebaseFirestore` was created.
    - The `initNotifications` function was updated to call a new `_saveTokenToFirestore` function.
    - The `_saveTokenToFirestore` function saves the FCM token to a "fcm_tokens" collection in Firestore.
