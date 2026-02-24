# QuakeTrack

QuakeTrack is a mobile application that provides real-time information about earthquakes happening worldwide. The app is designed to keep you informed about recent seismic activities, allowing you to view details and receive timely notifications.

## Features

-   **Real-time Earthquake Data:** Fetches and displays up-to-date earthquake data from the USGS, EMSC, and SEC APIs.
-   **Up-to-Date Database Reflection:** Earthquake events removed from source APIs (e.g., FDSNWS) are promptly reflected in the app's local database.
-   **Interactive Map View:** Visualizes earthquakes on an interactive map, allowing users to explore seismic events in different regions.
-   **Dynamic Earthquake List:** Displays a list of recent earthquakes with the ability to sort and dynamically filter based on user-selected notification profiles.
-   **Detailed Earthquake Information:** Provides comprehensive details for each earthquake, including magnitude, location, time, and depth.
-   **Advanced Notification Profiles:**
    *   **Multiple User-Defined Filters:** Create and manage multiple personalized notification profiles, each with its own specific location (latitude, longitude, radius), minimum magnitude, quiet hours settings, emergency thresholds, and override options.
    *   **Comprehensive Alerting:** Receive notifications for *all* earthquake events that match the criteria of *any* of your defined notification profiles.
    *   **Informative Notification Body:** Notification messages are dynamically constructed to indicate which specific profiles (e.g., "Home," "Work") were triggered by an earthquake.
    *   **Breakthrough Do Not Disturb (Android):** Critical notifications are configured to potentially bypass Android's Do Not Disturb mode for urgent alerts.
-   **Improved Permission Handling:**
    *   **Sequential Request Flow:** Location permissions are requested first, followed by notification permissions, after user sign-in and navigation to the home screen.
    *   **Proactive Status Feedback:** The app proactively checks permission status. If permissions are already granted (e.g., implicitly on Android), the user is informed via in-app feedback (e.g., SnackBar). If permanently denied, the user is guided to system settings.
-   **Personalized "Felt" Reports:** Allows users to report if they've felt an earthquake, creating a user-generated "felt intensity" map.
-   **Customizable Global Settings:** Control app-wide settings like theme (system, light, dark), time window for data display, and preferred earthquake data provider.
-   **User-friendly Interface:** Offers a clean and intuitive user interface for easy navigation and a seamless user experience.
-   **Banner Advertisements:** Integrated banner advertisements to help cover server and usage costs.

## Getting Started
