import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Extracts text from an image file (photo of notes).
  Future<String> extractTextFromImage(File image) async {
    final input = InputImage.fromFile(image);
    final result = await _recognizer.processImage(input);
    return result.text;
  }

  Future<void> dispose() async {
    await _recognizer.close();
  }
}
