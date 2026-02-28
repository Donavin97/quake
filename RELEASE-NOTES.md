# QuakeTrack - Release Notes

## Version 1.1.0 - What's New in This Version

### 🚀 New Features

**Earthquake Search**
- Search earthquakes by place name, magnitude, or earthquake ID
- Real-time filtering as you type

**Statistics Screen**
- View earthquake statistics including total events, average magnitude, and date ranges
- Interactive pie chart showing magnitude distribution (Micro, Minor, Light, Moderate, Strong, Major, Great)
- Depth analysis (Shallow, Intermediate, Deep)
- Most active regions

**Enhanced Notifications**
- Different notification sounds based on earthquake magnitude
- Large earthquake sound (6.0+) for significant events

### 🐛 Bug Fixes

- **Fixed TalkBack crashes**: Improved accessibility support - the app no longer crashes when using screen readers with text fields
- **Fixed notification filtering**: Notifications now respect your personal filter settings - you'll only get alerts for earthquakes that match your criteria (magnitude threshold, location radius, etc.)
- **Fixed subscription updates**: Filter changes now properly update notification subscriptions

### ♿ Accessibility Improvements

- Better screen reader support throughout the app
- Improved keyboard and input field accessibility
- Semantic labels for interactive elements

### 🔧 Code Quality

- Fixed deprecated API usage: replaced `withOpacity()` with `withValues(alpha:)` in seismograph screen
- Removed redundant default arguments for cleaner code
- Added const constructors where appropriate for better performance

### 📡 Seismograph Improvements

- Enhanced station information display: shows station name, distance, elevation, and site location
- Added channel information (BHZ, HHZ, SHZ) to waveform data display
- Better error handling for IRIS API requests with retry logic
- Improved timeout handling and user-friendly error messages
- Added nodata=404 parameter to station queries for cleaner error handling

---

For support or feedback, please visit our website or contact us through the app.
