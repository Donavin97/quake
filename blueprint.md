# Project Blueprint

## Overview

This project is a Flutter application that tracks earthquakes and sends notifications to users.

## Features

*   **Earthquake Tracking:** The application will display a list of recent earthquakes.
*   **Notifications:** The application will send push notifications to users when a new earthquake is detected.
*   **Settings:** Users will be able to customize the application's settings, such as the minimum magnitude of earthquakes to be displayed.

## Plan

1.  **Generate `firebase_options.dart`:** Run `flutterfire configure` to generate the `firebase_options.dart` file.
2.  **Fix `notification_service.dart`:** Fix the errors in `lib/notification_service.dart`.
3.  **Clean up logging:** Replace the `print` statements in `lib/firebase_api.dart` with `developer.log`.
4.  **Run `flutter analyze`:** Run `flutter analyze` to check for any remaining errors.
