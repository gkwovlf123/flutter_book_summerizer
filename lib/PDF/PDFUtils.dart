import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import '../Image/ImageUtils.dart';
import '../OCR/OCRUtils.dart';
import 'package:intl/intl.dart';


class PDFUtils {
  static List<String> filePath = [];
  static bool isLoading = true;
  static List<Uint8List> images = [];
  static List<String> ocrText = [];
  static List<String> filename = [];

  Future<void> PDFpicker() async {
    //use file picker select PDF
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      File file = File(result.files.single.path!);

      isLoading = false;
      filePath.add(file.path);
      filename.add(result.names.last.toString());



      print("파일이름 : " + result.names.last.toString());
    }
    else if (result == null) {
      isLoading = false;
    }

  }
}