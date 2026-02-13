import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/earthquake.dart';
import '../models/time_window.dart';
import '../providers/settings_provider.dart';

class UsgsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Earthquake>> getEarthquakesStream(SettingsProvider settings) {
    Query query = _firestore
        .collection('earthquakes')
        .where('source', isEqualTo: EarthquakeSource.usgs.name.toUpperCase());

    final minMagnitude = settings.minMagnitude;
    query = query.where('magnitude', isGreaterThanOrEqualTo: minMagnitude);

    final timeWindow = settings.timeWindow;
    if (timeWindow != TimeWindow.all) {
      final now = DateTime.now();
      final startTime = now.subtract(timeWindow.duration);
      query = query.where('time', isGreaterThanOrEqualTo: startTime);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Earthquake.fromFirestore(doc)).toList();
    });
  }
}
