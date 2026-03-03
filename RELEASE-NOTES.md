# QuakeTrack - Release Notes

## Version 1.1.0

### 🌍 Timezone-Aware Quiet Hours
- Set your local timezone for accurate quiet hours scheduling
- Auto-detects device timezone on profile creation

### 📡 Seismograph Improvements
- **Audio Sonification**: Listen to seismic data as audio with play/pause, seek, and progress tracking
- **Multi-provider Fallback**: 12 FDSN providers (IRIS, EMSC, GFZ, INGV, LMU, BGR, NIED, SCEDC, NCEDC, ORFEUS, USP, AUSP) ensure maximum data coverage
- **Station Fallback**: Automatically tries up to 10 nearby stations if closest has no data
- **Earthquake Marker**: Red dashed line marks event time at 60 seconds
- Enhanced station info: name, distance, elevation, location, channel (BHZ/HHZ/SHZ)
- Fixed IRIS dataselect API with proper format=mseed and nodata=404 parameters
- **Scrollable View**: Entire seismograph screen is now scrollable
- **Simplified Loading**: Shows clean spinner with status text instead of detailed progress
- **Haptic Feedback**: Device vibrates once on successful data, twice on failure or mock data
- **Fade-in Animation**: Smooth 500ms ease-in animation when data loads

### 🔔 Enhanced Notifications
- Different notification sounds based on magnitude (6.0+ uses large earthquake sound)
- Distance displayed in notification body (within 100km)
- Time-ago formatting ("5 minutes ago", "2 hours ago")

### 🐛 Bug Fixes
- Fixed TalkBack crashes with screen reader-compatible text fields
- Fixed notification filtering to respect personal filter settings
- Fixed subscription updates when filter criteria change

### ♿ Accessibility
- Better screen reader support throughout the app
- Audio player buttons (play/pause, stop, seek bar) labeled with tooltips in seismograph screen

### 🔧 Code Quality
- Replaced deprecated `withOpacity()` with `withValues(alpha:)`
- Added const constructors for better performance
- Fixed deprecated DropdownButtonFormField `value` to use `initialValue`
- Removed unused imports and variables
- Fixed IconButton semanticLabel parameter (not valid for IconButton)
- Fixed haptic feedback to use Vibration package for reliable Android vibration
- Added timezone package back as explicit dependency

---

For support or feedback, please visit our website or contact us through the app.
