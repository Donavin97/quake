import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import '../models/earthquake.dart'; // Assuming Earthquake model is defined here

class WebSocketService {
  final String _emscWebSocketUrl = 'wss://www.seismicportal.eu/standing_order/websocket';
  WebSocketChannel? _channel;
  final BehaviorSubject<Earthquake> _earthquakeSubject = BehaviorSubject<Earthquake>();

  Stream<Earthquake> get earthquakeStream => _earthquakeSubject.stream;

  WebSocketService() {
    _connect();
  }

  void _connect() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_emscWebSocketUrl));
      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onDone: () {
          debugPrint('WebSocket disconnected. Reconnecting...');
          _reconnect();
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _reconnect();
        },
      );
      debugPrint('WebSocket connected to $_emscWebSocketUrl');
    } catch (e) {
      debugPrint('Failed to connect to WebSocket: $e');
      _reconnect();
    }
  }

  void _reconnect() {
    _channel?.sink.close();
    Future.delayed(const Duration(seconds: 5), () {
      _connect();
    });
  }

  void _handleMessage(dynamic message) {
    try {
      final Map<String, dynamic> data = jsonDecode(message);
      if (data['event'] == 'quake') {
        final quakeData = data['data'];

        double parseDouble(dynamic value) {
          if (value == null) return 0.0;
          if (value is num) return value.toDouble();
          if (value is String) return double.tryParse(value) ?? 0.0;
          return 0.0;
        }

        final earthquake = Earthquake(
          id: quakeData['unid'],
          magnitude: parseDouble(quakeData['mag']),
          place: quakeData['flynn_region'],
          time: DateTime.parse(quakeData['time']),
          latitude: parseDouble(quakeData['lat']),
          longitude: parseDouble(quakeData['lon']),
          depth: parseDouble(quakeData['depth']),
          source: EarthquakeSource.emsc,
          provider: 'EMSC',
        );
        _earthquakeSubject.add(earthquake);
      }
    } catch (e) {
      debugPrint('Error parsing WebSocket message: $e\nMessage: $message');
    }
  }

  void dispose() {
    _channel?.sink.close();
    _earthquakeSubject.close();
  }
}
