// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'RastreadorSismos';

  @override
  String get mapTab => 'Mapa';

  @override
  String get listTab => 'Lista';

  @override
  String get statsTab => 'Estadísticas';

  @override
  String get settingsTab => 'Ajustes';

  @override
  String get magnitude => 'Magnitud';

  @override
  String get depth => 'Profundidad';

  @override
  String get distance => 'Distancia';

  @override
  String get time => 'Hora';

  @override
  String get source => 'Fuente';

  @override
  String get feltRadius => 'Radio Sentido';

  @override
  String get plateBoundaries => 'Límites de Placas';

  @override
  String get faultLines => 'Líneas de Falla';

  @override
  String get showFeltRadius => 'Mostrar Radio Sentido';

  @override
  String get theoreticalFeltRadius => 'Radio Teórico Sentido';

  @override
  String get didYouFeelIt => '¿Lo sentiste?';

  @override
  String get viewFeltReports => 'Ver Reportes';

  @override
  String get seismograph => 'Sismógrafo';

  @override
  String get share => 'Compartir';

  @override
  String get retry => 'Reintentar';

  @override
  String get loading => 'Cargando...';

  @override
  String get noData => 'No hay datos de terremotos disponibles';

  @override
  String get offlineMode =>
      'Mostrando datos fuera de línea. Compruebe la conexión.';

  @override
  String get searchPlace => 'Buscar por lugar...';

  @override
  String get searchArchive => 'Buscar en el historial global...';

  @override
  String get archiveToggle => 'Archivo Global';

  @override
  String get noArchiveData =>
      'No se encontraron terremotos archivados que coincidan con su búsqueda.';

  @override
  String get searchLoading => 'Buscando en el archivo global...';

  @override
  String get profile => 'Perfil';

  @override
  String get signOut => 'Cerrar Sesión';

  @override
  String get signIn => 'Iniciar Sesión';

  @override
  String get authRequired => 'Autenticación Requerida';

  @override
  String get authRequiredMessage =>
      'Inicie sesión para acceder y modificar los ajustes.';

  @override
  String get safetyTab => 'Seguridad';

  @override
  String get duringQuake => 'Durante un Terremoto';

  @override
  String get dropCoverHold => '¡Agáchate, Cúbrete y Sujétate!';

  @override
  String get dropDesc => 'AGÁCHATE sobre tus manos y rodillas.';

  @override
  String get coverDesc =>
      'CÚBRETE la cabeza y el cuello con tus brazos. Busca refugio bajo una mesa resistente.';

  @override
  String get holdDesc =>
      'SUJÉTATE a tu refugio hasta que el temblor se detenga.';

  @override
  String get afterQuake => 'Después de un Terremoto';

  @override
  String get checkInjuries => 'Comprobar Lesiones';

  @override
  String get checkGas => 'Revisar Gas, Agua y Electricidad';

  @override
  String get bePreparedAftershocks => 'Prepárate para las Réplicas';

  @override
  String get emergencyKit => 'Lista del Kit de Emergencia';

  @override
  String get kitWater => 'Agua (4 litros por persona al día)';

  @override
  String get kitFood => 'Alimentos no Perecederos';

  @override
  String get kitFlashlight => 'Linterna y pilas de repuesto';

  @override
  String get kitFirstAid => 'Botiquín de Primeros Auxilios';

  @override
  String get emergencyContacts => 'Contactos de Emergencia';

  @override
  String get callEmergency => 'Llamar al 911 (Emergencias)';

  @override
  String near(String place) {
    return 'Cerca de $place';
  }

  @override
  String distanceFromYou(String distance) {
    return 'Distancia desde ti: $distance km';
  }
}
