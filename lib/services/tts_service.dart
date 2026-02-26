import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();

  TtsService() {
    _init();
  }

  Future<void> _init() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
  }

  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}