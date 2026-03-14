// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'QuakeTrack';

  @override
  String get mapTab => 'Map';

  @override
  String get listTab => 'List';

  @override
  String get statsTab => 'Stats';

  @override
  String get settingsTab => 'Settings';

  @override
  String get magnitude => 'Magnitude';

  @override
  String get depth => 'Depth';

  @override
  String get distance => 'Distance';

  @override
  String get time => 'Time';

  @override
  String get source => 'Source';

  @override
  String get feltRadius => 'Felt Radius';

  @override
  String get plateBoundaries => 'Plate Boundaries';

  @override
  String get faultLines => 'Fault Lines';

  @override
  String get showFeltRadius => 'Show Felt Radius';

  @override
  String get theoreticalFeltRadius => 'Theoretical Felt Radius';

  @override
  String get didYouFeelIt => 'Did You Feel It?';

  @override
  String get viewFeltReports => 'View Felt Reports';

  @override
  String get seismograph => 'Seismograph';

  @override
  String get share => 'Share';

  @override
  String get retry => 'Retry';

  @override
  String get loading => 'Loading...';

  @override
  String get noData => 'No earthquake data available';

  @override
  String get offlineMode => 'Showing offline data. Check connection.';

  @override
  String get searchPlace => 'Search by place...';

  @override
  String get searchArchive => 'Search global history...';

  @override
  String get archiveToggle => 'Global Archive';

  @override
  String get noArchiveData =>
      'No archived earthquakes found matching your search.';

  @override
  String get searchLoading => 'Searching global archive...';

  @override
  String get profile => 'Profile';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signIn => 'Sign In';

  @override
  String get authRequired => 'Authentication Required';

  @override
  String get authRequiredMessage =>
      'Please sign in to access and modify settings.';

  @override
  String get safetyTab => 'Safety';

  @override
  String get duringQuake => 'During an Earthquake';

  @override
  String get dropCoverHold => 'Drop, Cover, and Hold On!';

  @override
  String get dropDesc => 'DROP down onto your hands and knees.';

  @override
  String get coverDesc =>
      'COVER your head and neck with your arms. Seek shelter under a sturdy table.';

  @override
  String get holdDesc => 'HOLD ON to your shelter until the shaking stops.';

  @override
  String get afterQuake => 'After an Earthquake';

  @override
  String get checkInjuries => 'Check for Injuries';

  @override
  String get checkGas => 'Check Gas, Water, and Electricity';

  @override
  String get bePreparedAftershocks => 'Be Prepared for Aftershocks';

  @override
  String get emergencyKit => 'Safety Kit Checklist';

  @override
  String get kitWater => 'Water (one gallon per person per day)';

  @override
  String get kitFood => 'Non-perishable Food';

  @override
  String get kitFlashlight => 'Flashlight and extra batteries';

  @override
  String get kitFirstAid => 'First Aid Kit';

  @override
  String get emergencyContacts => 'Emergency Contacts';

  @override
  String get callEmergency => 'Call 911 (Local Emergency)';

  @override
  String near(String place) {
    return 'Near $place';
  }

  @override
  String distanceFromYou(String distance) {
    return 'Distance from you: $distance km';
  }
}
