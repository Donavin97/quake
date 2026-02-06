
# Project Blueprint: Earthquake Tracker App

## Overview

This document outlines the plan for creating a mobile application to track recent earthquakes using data from the U.S. Geological Survey (USGS). The app will provide a list of earthquakes and allow users to see more details about each event.

## Design and Features

### Visual Design

*   **Theme:** A modern, data-focused theme will be implemented using Material 3 principles. It will support both light and dark modes.
*   **Typography:** Custom fonts will be used via the `google_fonts` package to enhance readability and visual appeal.
*   **Layout:** A clean, list-based layout will be used for the main screen. A separate screen will show detailed information for a selected earthquake.
*   **Iconography:** Material Design icons will be used to represent actions and information, such as magnitude and location.

### Features

*   **Earthquake Data:** Fetch and display real-time earthquake data from the USGS API.
*   **List View:** Show a list of recent earthquakes, including magnitude, location, and time.
*   **Detail View:** Allow users to tap on an earthquake to see more details, such as coordinates and depth.
*   **State Management:** Use the `provider` package to manage application state, including the theme and the earthquake data.
*   **Networking:** Use the `http` package to make API requests to the USGS service.
*   **Error Handling:** Implement graceful error handling for network issues.

## Current Plan

### 1. Project Setup
*   Update the `blueprint.md` file.
*   Add the `http`, `provider`, and `google_fonts` packages to `pubspec.yaml`.
*   Run `flutter pub get` to install dependencies.

### 2. Data Layer
*   Create a data model (`Earthquake`) to represent the earthquake data from the USGS JSON feed.
*   Create a service class (`UsgsService`) to handle fetching and parsing the earthquake data using the `http` package.

### 3. State Management
*   Create a `ThemeProvider` class to manage the app's theme (light/dark mode).
*   Create an `EarthquakeProvider` class that uses the `UsgsService` to fetch earthquakes and manages the list of earthquakes for the UI.

### 4. UI Implementation
*   **`main.dart`**: Set up the main application widget, including the `ChangeNotifierProvider` for both `ThemeProvider` and `EarthquakeProvider`.
*   **`screens/`**: Create separate files for the home screen (earthquake list) and the detail screen.
*   **`widgets/`**: Create reusable widgets, such as a custom list item for displaying earthquake information.
*   Implement the main list view on the home screen.
*   Implement the theme toggle in the `AppBar`.
*   Implement navigation to the detail screen.

### 5. Code Quality and Validation
*   Run `dart format .` to format the code.
*   Run `flutter analyze` to check for errors and warnings.
*   Run `flutter test` to ensure core functionality is working as expected.
