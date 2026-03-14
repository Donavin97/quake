# QuakeTrack Release Notes

## v1.5.0 (Current)
- **State Management & Model Overhaul**: Migrated the entire application state to Riverpod with full code generation (@riverpod). Adopted `Freezed` for all state and core models, ensuring absolute data integrity and perfect immutability.
- **UI Customization**: Added new accessibility settings to scale map buttons and earthquake markers, allowing users to personalize their interface density.
- **Background Seismograph**: Re-engineered the Community Seismograph to run as a persistent background service. It now monitors for seismic activity even when the app is closed or the screen is off.
- **Stabilization & Audio**: Added a 30-second "settle time" when connecting to a charger to prevent false detections and an audible signal when recording starts.
- **"Did You Feel It?" Map Upgrades**: Improved felt report maps with full zoom/pan interactivity and geographically locked info boxes that stay pinned to the earthquake epicenter.
- **Performance Optimization**: Implemented selective rebuilding using `.select()` across all major screens and added `RepaintBoundary` isolation for complex rendering layers.
- **Architectural Refinement**: Replaced the legacy service locator with a centralized provider-based dependency injection system.
- **Build Stability**: Ensured critical audio assets are protected from resource shrinking for consistent alert behavior in production builds.
- **Version Update**: App version bumped to 1.5.0+24.

## v1.4.9
- **Hardened Device Security**: Enhanced the "One Account per Device" logic with hardware-level identification to prevent account collisions.
- **Account Recovery Tools**: Added a dedicated "Unlink Device" feature to allow users to reclaim second-hand devices for their own accounts.
- **Improved Authentication**: Fixed synchronization issues between device IDs and email addresses with case-insensitive validation.
- **Firebase Auth Standards**: Added mandatory email verification for new accounts and hardened login flows against enumeration.
- **Hardware Resilience**: Implemented safety timeouts for GPS requests to prevent the app from hanging on poor location locks.
- **Notification Reliability**: Implemented a dual-lock system that immediately mutes local notifications and deletes the cloud messaging token when disabled.
- **Map Performance**: Re-engineered marker rendering for perfectly smooth scrolling and seamless panning across the globe.
- **Persistent State**: Tabs now stay active in the background, keeping your map position and list filters exactly where you left them.
- **Privacy & Stability**: Hardened the Privacy Policy viewer with error handling and a seamless in-app transition for better stability.
