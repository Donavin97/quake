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
        final earthquake = Earthquake(
          id: quakeData['unid'],
          magnitude: double.parse(quakeData['mag']),
          place: quakeData['flynn_region'],
          time: DateTime.parse(quakeData['time']),
          latitude: double.parse(quakeData['lat']),
          longitude: double.parse(quakeData['lon']),
          depth: double.parse(quakeData['depth']),
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
