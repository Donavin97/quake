// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'DepremTakip';

  @override
  String get mapTab => 'Harita';

  @override
  String get listTab => 'Liste';

  @override
  String get statsTab => 'İstatistik';

  @override
  String get settingsTab => 'Ayarlar';

  @override
  String get magnitude => 'Büyüklük';

  @override
  String get depth => 'Derinlik';

  @override
  String get distance => 'Uzaklık';

  @override
  String get time => 'Zaman';

  @override
  String get source => 'Kaynak';

  @override
  String get feltRadius => 'Hissedilen Yarıçap';

  @override
  String get plateBoundaries => 'Levha Sınırları';

  @override
  String get faultLines => 'Fay Hatları';

  @override
  String get showFeltRadius => 'Etki Alanını Göster';

  @override
  String get theoreticalFeltRadius => 'Teorik Hissetme Yarıçapı';

  @override
  String get didYouFeelIt => 'Siz de Hissettiniz mi?';

  @override
  String get viewFeltReports => 'Hissedenlerin Haritası';

  @override
  String get seismograph => 'Sismograf';

  @override
  String get share => 'Paylaş';

  @override
  String get retry => 'Tekrar Dene';

  @override
  String get loading => 'Yükleniyor...';

  @override
  String get noData => 'Deprem verisi bulunamadı';

  @override
  String get offlineMode =>
      'Çevrimdışı veriler gösteriliyor. Bağlantıyı kontrol edin.';

  @override
  String get searchPlace => 'Yer ara...';

  @override
  String get searchArchive => 'Küresel geçmişte ara...';

  @override
  String get archiveToggle => 'Küresel Arşiv';

  @override
  String get noArchiveData =>
      'Aramanızla eşleşen arşivlenmiş deprem bulunamadı.';

  @override
  String get searchLoading => 'Küresel arşiv aranıyor...';

  @override
  String get profile => 'Profil';

  @override
  String get signOut => 'Çıkış Yap';

  @override
  String get signIn => 'Giriş Yap';

  @override
  String get authRequired => 'Kimlik Doğrulama Gerekli';

  @override
  String get authRequiredMessage =>
      'Ayarlara erişmek ve değiştirmek için lütfen giriş yapın.';

  @override
  String get safetyTab => 'Güvenlik';

  @override
  String get duringQuake => 'Deprem Anında';

  @override
  String get dropCoverHold => 'Çök, Kapan, Tutun!';

  @override
  String get dropDesc => 'Dizlerinizin üzerine ÇÖKÜN.';

  @override
  String get coverDesc =>
      'Başınızı ve boynunuzu kollarınızla KAPATIN. Sağlam bir masanın altına sığının.';

  @override
  String get holdDesc => 'Sarsıntı durana kadar sığınağınıza TUTUNUN.';

  @override
  String get afterQuake => 'Depremden Sonra';

  @override
  String get checkInjuries => 'Yaralanmaları Kontrol Edin';

  @override
  String get checkGas => 'Gaz, Su ve Elektriği Kontrol Edin';

  @override
  String get bePreparedAftershocks =>
      'Artçı Sarsıntılara Karşı Hazırlıklı Olun';

  @override
  String get emergencyKit => 'Güvenlik Seti Listesi';

  @override
  String get kitWater => 'Su (kişi başı günlük 4 litre)';

  @override
  String get kitFood => 'Bozulmayan Gıdalar';

  @override
  String get kitFlashlight => 'El feneri ve yedek piller';

  @override
  String get kitFirstAid => 'İlk Yardım Çantası';

  @override
  String get emergencyContacts => 'Acil Durum İletişim';

  @override
  String get callEmergency => '112\'yi Ara (Acil Yardım)';

  @override
  String near(String place) {
    return '$place Yakınında';
  }

  @override
  String distanceFromYou(String distance) {
    return 'Sizden uzaklığı: $distance km';
  }
}
