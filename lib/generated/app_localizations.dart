import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('tr')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'QuakeTrack'**
  String get appTitle;

  /// No description provided for @mapTab.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapTab;

  /// No description provided for @listTab.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get listTab;

  /// No description provided for @statsTab.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get statsTab;

  /// No description provided for @settingsTab.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTab;

  /// No description provided for @magnitude.
  ///
  /// In en, this message translates to:
  /// **'Magnitude'**
  String get magnitude;

  /// No description provided for @depth.
  ///
  /// In en, this message translates to:
  /// **'Depth'**
  String get depth;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @feltRadius.
  ///
  /// In en, this message translates to:
  /// **'Felt Radius'**
  String get feltRadius;

  /// No description provided for @plateBoundaries.
  ///
  /// In en, this message translates to:
  /// **'Plate Boundaries'**
  String get plateBoundaries;

  /// No description provided for @faultLines.
  ///
  /// In en, this message translates to:
  /// **'Fault Lines'**
  String get faultLines;

  /// No description provided for @showFeltRadius.
  ///
  /// In en, this message translates to:
  /// **'Show Felt Radius'**
  String get showFeltRadius;

  /// No description provided for @theoreticalFeltRadius.
  ///
  /// In en, this message translates to:
  /// **'Theoretical Felt Radius'**
  String get theoreticalFeltRadius;

  /// No description provided for @didYouFeelIt.
  ///
  /// In en, this message translates to:
  /// **'Did You Feel It?'**
  String get didYouFeelIt;

  /// No description provided for @viewFeltReports.
  ///
  /// In en, this message translates to:
  /// **'View Felt Reports'**
  String get viewFeltReports;

  /// No description provided for @seismograph.
  ///
  /// In en, this message translates to:
  /// **'Seismograph'**
  String get seismograph;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No earthquake data available'**
  String get noData;

  /// No description provided for @offlineMode.
  ///
  /// In en, this message translates to:
  /// **'Showing offline data. Check connection.'**
  String get offlineMode;

  /// No description provided for @searchPlace.
  ///
  /// In en, this message translates to:
  /// **'Search by place...'**
  String get searchPlace;

  /// No description provided for @searchArchive.
  ///
  /// In en, this message translates to:
  /// **'Search global history...'**
  String get searchArchive;

  /// No description provided for @archiveToggle.
  ///
  /// In en, this message translates to:
  /// **'Global Archive'**
  String get archiveToggle;

  /// No description provided for @noArchiveData.
  ///
  /// In en, this message translates to:
  /// **'No archived earthquakes found matching your search.'**
  String get noArchiveData;

  /// No description provided for @searchLoading.
  ///
  /// In en, this message translates to:
  /// **'Searching global archive...'**
  String get searchLoading;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @authRequired.
  ///
  /// In en, this message translates to:
  /// **'Authentication Required'**
  String get authRequired;

  /// No description provided for @authRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to access and modify settings.'**
  String get authRequiredMessage;

  /// No description provided for @safetyTab.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get safetyTab;

  /// No description provided for @duringQuake.
  ///
  /// In en, this message translates to:
  /// **'During an Earthquake'**
  String get duringQuake;

  /// No description provided for @dropCoverHold.
  ///
  /// In en, this message translates to:
  /// **'Drop, Cover, and Hold On!'**
  String get dropCoverHold;

  /// No description provided for @dropDesc.
  ///
  /// In en, this message translates to:
  /// **'DROP down onto your hands and knees.'**
  String get dropDesc;

  /// No description provided for @coverDesc.
  ///
  /// In en, this message translates to:
  /// **'COVER your head and neck with your arms. Seek shelter under a sturdy table.'**
  String get coverDesc;

  /// No description provided for @holdDesc.
  ///
  /// In en, this message translates to:
  /// **'HOLD ON to your shelter until the shaking stops.'**
  String get holdDesc;

  /// No description provided for @afterQuake.
  ///
  /// In en, this message translates to:
  /// **'After an Earthquake'**
  String get afterQuake;

  /// No description provided for @checkInjuries.
  ///
  /// In en, this message translates to:
  /// **'Check for Injuries'**
  String get checkInjuries;

  /// No description provided for @checkGas.
  ///
  /// In en, this message translates to:
  /// **'Check Gas, Water, and Electricity'**
  String get checkGas;

  /// No description provided for @bePreparedAftershocks.
  ///
  /// In en, this message translates to:
  /// **'Be Prepared for Aftershocks'**
  String get bePreparedAftershocks;

  /// No description provided for @emergencyKit.
  ///
  /// In en, this message translates to:
  /// **'Safety Kit Checklist'**
  String get emergencyKit;

  /// No description provided for @kitWater.
  ///
  /// In en, this message translates to:
  /// **'Water (one gallon per person per day)'**
  String get kitWater;

  /// No description provided for @kitFood.
  ///
  /// In en, this message translates to:
  /// **'Non-perishable Food'**
  String get kitFood;

  /// No description provided for @kitFlashlight.
  ///
  /// In en, this message translates to:
  /// **'Flashlight and extra batteries'**
  String get kitFlashlight;

  /// No description provided for @kitFirstAid.
  ///
  /// In en, this message translates to:
  /// **'First Aid Kit'**
  String get kitFirstAid;

  /// No description provided for @emergencyContacts.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contacts'**
  String get emergencyContacts;

  /// No description provided for @callEmergency.
  ///
  /// In en, this message translates to:
  /// **'Call 911 (Local Emergency)'**
  String get callEmergency;

  /// No description provided for @near.
  ///
  /// In en, this message translates to:
  /// **'Near {place}'**
  String near(String place);

  /// No description provided for @distanceFromYou.
  ///
  /// In en, this message translates to:
  /// **'Distance from you: {distance} km'**
  String distanceFromYou(String distance);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
