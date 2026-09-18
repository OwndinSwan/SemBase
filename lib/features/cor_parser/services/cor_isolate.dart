import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/parsed_cor.dart';
import 'cor_matcher.dart';

/// Service that executes PDF parsing and text decoding in a dedicated background Isolate
class CorIsolateService {
  /// Parses PDF bytes on a background isolate to prevent UI frame drops
  static Future<ParsedCorData> parsePdfBytes(Uint8List bytes) async {
    return await compute(_extractAndParsePdfIsolate, bytes);
  }

  /// Top-level function executed on background Isolate
  static ParsedCorData _extractAndParsePdfIsolate(Uint8List pdfBytes) {
    try {
      final PdfDocument document = PdfDocument(inputBytes: pdfBytes);
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      final String extractedText = extractor.extractText();
      document.dispose();

      return CorMatcher.parseCorText(extractedText);
    } catch (e) {
      // In case PDF decoding encounters corrupted stream, return empty structure or fallback
      debugPrint('Isolate PDF decoding error: $e');
      return CorMatcher.parseCorText('');
    }
  }

  /// Parses raw text string directly (e.g. from clipboard paste) in background isolate
  static Future<ParsedCorData> parseRawText(String text) async {
    return await compute(_parseTextIsolate, text);
  }

  static ParsedCorData _parseTextIsolate(String text) {
    return CorMatcher.parseCorText(text);
  }
}
