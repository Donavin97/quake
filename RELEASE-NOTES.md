# Release Notes

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - Recent Updates (TBD)

### Added

#### Earthquake Search Feature
- New search bar in the earthquake list screen
- Real-time filtering by place name, magnitude, or earthquake ID
- Empty state UI when no results match
- Proper cleanup of TextEditingController to prevent memory leaks

#### Statistics Screen
- New dedicated statistics screen accessible from the home menu
- **Summary Card**: Total events, average/max/min magnitude, average depth, date range
- **Magnitude Distribution**: Interactive pie chart visualization showing breakdown by category:
  - Micro (<2.0)
  - Minor (2.0-3.9)
  - Light (4.0-4.9)
  - Moderate (5.0-5.9)
  - Strong (6.0-6.9)
  - Major (7.0-7.9)
  - Great (8.0+)
- **Depth Analysis**: Shallow (<70km), Intermediate (70-300km), Deep (300km+)
- **Time Distribution**: Last hour, past 24 hours, past week, older
- **Most Active Regions**: Top 5 regions by earthquake count

#### Enhanced Notification Sounds
- Different notification sounds based on earthquake magnitude:
  - **Standard sound** (`earthquake.wav`): Used for earthquakes below magnitude 6.0
  - **Large earthquake sound** (`earthquake-large.wav`): Used for earthquakes magnitude 6.0 and above
- Implemented in both the Flutter app (`background_service.dart`) and Firebase Cloud Functions (`functions/index.js`)
- Resource protection ensured via `keep.xml` to prevent sound files from being stripped during release build

### Changed
- Pie chart implemented using `fl_chart` package for magnitude distribution visualization
- Replaced static progress bars with interactive color-coded pie chart

### Dependencies
- Added `fl_chart: ^0.69.0` for chart visualizations
- Added `analyzer: ^6.4.0` for static analysis

### Accessibility Improvements
- Fixed TalkBack crash in notification profile detail screen by using final TextEditingControllers with inline initialization (ensures controllers exist before build calls)
- Added autofillHints to notification profile detail screen name field
- Added autofillHints to profile screen email and password fields (AutofillHints.email, AutofillHints.newPassword, AutofillHints.password)
- Added autofillHints to setup screen authentication form fields
- Added semantic label to Google logo in setup screen for screen readers
- Added semanticFormatterCallback to intensity slider in "Did you feel it?" dialog for better screen reader support
- Added Semantics widget to earthquake provider dropdown in settings screen
- Added tooltips to password visibility toggle buttons
- Improved keyboard types for latitude/longitude fields (TextInputType.numberWithOptions)

### Bug Fixes
- Fixed crash in notification profile detail screen with improved validation
- Fixed slider validation for NaN and infinite values
- Fixed day picker to use dialog-based selection
- Fixed navigation service import path

---

## Previous Releases

### [0.x.x] - Earlier Versions
See git history for details on earlier releases.