# QuakeTrack - Release Notes

## Version 1.1.0

### 📡 Seismograph Improvements
- **Audio Sonification**: Listen to seismic data as audio with play/pause, seek, and progress tracking
  - **Auto-reset**: Player automatically stops and reverts to position 0 when playback completes
- **Enhanced Share Caption**: Felt reports map now shares with engaging captions including magnitude, location, felt reports count, and app promotion
- **Multi-provider Fallback**: 12 FDSN providers (IRIS, EMSC, GFZ, INGV, LMU, BGR, NIED, SCEDC, NCEDC, ORFEUS, USP, AUSP) ensure maximum data coverage
- **Station Fallback**: Automatically tries up to 10 nearby stations if closest has no data
- **Earthquake Marker**: Red dashed line marks the event time at 60 seconds
- Enhanced station info: name, distance, elevation, location, channel (BHZ/HHZ/SHZ)
- Fixed IRIS dataselect API with proper format=mseed and nodata=404 parameters
- **Scrollable View**: Entire seismograph screen is now scrollable
- **Simplified Loading**: Shows clean spinner with status text instead of detailed progress
- **Customizable Vibration Settings**: Adjust success and error vibration duration (10-300ms) and intensity (1-3 pulses) in settings
- **Haptic Feedback**: Device vibrates once on successful data, twice on failure or mock data
- **Fixed Vibration**: Switched to Vibration package for reliable haptic feedback on Android (fixes devices that wouldn't vibrate properly)
- **Fade-in Animation**: Smooth 500ms ease-in animation when data loads

### 🔔 Enhanced Notifications
- Different notification sounds based on magnitude (6.0+ uses large earthquake alert)
- Distance displayed in notification body (within 100km)
- Time-ago formatting ("5 minutes ago", "2 hours ago")

### 🌍 Timezone-Aware Quiet Hours
- Set your local timezone for accurate quiet hours scheduling
- Auto-detects device timezone on profile creation

### ↕️ Pull to Refresh
- Pull down on earthquake list to refresh data manually

### ♿ Accessibility
- Better screen reader support throughout the app
- Audio player buttons (play/pause, stop, seek bar) labeled with tooltips in the seismograph screen

### 🛡️ Crash-Resistant Improvements
- Added lifecycle observers to all major screens (detail, felt reports, home, map, notification profiles)
- App now reloads ads, felt reports, and map data when returning from background
- Added mounted checks before using context after async operations throughout the app
- Fixed duplicate mounted checks that could cause issues

### 🔘 Play Button Logic
- Play button now always restarts from beginning when pressed (seeks to start before playing)
- Player auto-resets to position 0 when playback completes
- Haptic feedback now uses success/error patterns instead of light/medium/heavy

### 🐛 Bug Fixes
- Fixed TalkBack crashes with screen reader-compatible text fields
- Fixed notification filtering to respect personal filter settings
- Fixed subscription updates when filter criteria change

### 🛡️ Privacy Policy Crash Fix
- Fixed app crash when navigating to privacy policy and returning to the app
- Added lifecycle observer to settings screen to properly handle app resume from external URLs
- Settings now reload automatically when returning from privacy policy link

### 🔧 Code Quality
- Replaced deprecated `withOpacity()` with `withValues(alpha:)`
- Added const constructors for better performance
- Fixed deprecated DropdownButtonFormField `value` parameter warning
- Removed unused imports and variables
- Fixed IconButton semanticLabel parameter (not valid for IconButton)
- Added timezone package back as explicit dependency
- Fixed async context usage in seismograph screen
- Removed redundant argument values in vibration settings

---

For support or feedback, please visit our website or contact us through the app.
