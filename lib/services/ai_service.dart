import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiService {
  static Future<Map<String, dynamic>> analyzeImage(File imageFile) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
      );
      final imageBytes = await imageFile.readAsBytes();

      final prompt = TextPart(
        "Analyze this image. First, VALIDATE if this image is taken on an outdoor walkway, sidewalk, pavement, or pedestrian path. "
        "Reject if: it is indoors (bedroom, office, room), inside a car, selfies, or completely unrelated objects. "
        "If rejected, set 'is_valid_path' to false and explain why. "
        "If valid, classify the damage. "
        "Return valid JSON only: "
        "{"
        "'is_valid_path': boolean,"
        "'rejection_reason': 'reason if false',"
        "'damage_type': 'hole' | 'hazards' | 'obstacle' | 'narrow' | 'crack' | 'other' | 'no path' ,"
        "'severity': (1-10 integer),"
        "'short_desc': 'very concise description with potential hazards'"
        "}",
      );

      final response = await model.generateContent([
        Content.multi([prompt, DataPart('image/jpeg', imageBytes)]),
      ]);

      String text = response.text
              ?.replaceAll('```json', '')
              .replaceAll('```', '')
              .trim() ?? "{}";
      return jsonDecode(text);
    } catch (e) {
      return {"is_valid_path": false, "rejection_reason": "AI Analysis Failed: $e"};
    }
  }
}