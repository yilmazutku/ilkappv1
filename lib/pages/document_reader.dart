import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:io';

class DocumentReader {
  late Map<String, List<String>> subtitles;

  DocumentReader() {
    subtitles = {
      'Subtitle 1': [],
      'Subtitle 2': [],
      'Subtitle 3': [],
      'Subtitle 4': [],
    };
  }  String extractedText = "";
  Future<void> readPdfFile(Uint8List fileBytes) async {
    final PdfDocument document = PdfDocument(inputBytes: fileBytes);

    final textExtractor = PdfTextExtractor(document);
    // for (int i = 0; i < document.pages.count; i++) {
    //   final text = textExtractor.extractText(startPageIndex: i, endPageIndex: i);
    //   _extractSubtitles(text);
    // }
    for (int i = 0; i < document.pages.count; i++) {
      final text = textExtractor.extractText(startPageIndex: i, endPageIndex: i);
      extractedText += text + "\n";
    }
    print(getRawText());
    document.dispose(); // Dispose of the document after processing
  }
  void _extractSubtitles(String text) {
    // Split the text by lines using a more consistent regex to avoid splitting meaningful content
    final lines = text.split(RegExp(r'\r\n|\r|\n')).map((line) => line.trim()).where((line) => line.isNotEmpty).toList();

    String? currentSubtitle;

    for (var line in lines) {
      // Detect subtitles based on the exact keys
      if (subtitles.containsKey(line)) {
        currentSubtitle = line;
      } else if (currentSubtitle != null) {
        subtitles[currentSubtitle]!.add(line);
      }
    }

    print(subtitles);
  }
  String getRawText() {
    return extractedText;
  }
}
