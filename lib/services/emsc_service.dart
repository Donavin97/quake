
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/earthquake.dart';

class EmscService {
  static const String _baseUrl =
      'https://www.emsc-csem.org/service/fdsnws/event/1/query';

  Future<List<Earthquake>> fetchEarthquakes() async {
    final response = await http.get(Uri.parse('$_baseUrl?format=json'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final features = data['features'] as List;
      return features.map((e) => Earthquake.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load earthquakes');
    }
  }
}
