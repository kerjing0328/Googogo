import 'dart:async';
import 'package:flutter_compass/flutter_compass.dart';

class CompassService {
  static StreamSubscription<CompassEvent>? listenToCompass(void Function(double? heading) onData) {
    return FlutterCompass.events?.listen((event) {
      onData(event.heading);
    });
  }
}