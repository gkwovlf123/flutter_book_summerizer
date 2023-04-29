import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../Image/ImageUtils.dart';
import '../OCR/OCRUtils.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';


class PDFUtils {
  static List<String> filePath = [];
  static bool isLoading = true;
  static List<Uint8List> images = [];
  static List<String> ocrText = [];
  static List<String> filename = [];
  String pdfName = '';


  Future<void> createDoc(String? name, String path, String text, String url) async { //firebase create
    FirebaseFirestore.instance.collection('pdfs').add({
      'PDFname': name,
      'PDFpath': path,
      'PDFimgUrl': url,
      'Create time': Timestamp.now(),
      'Deviceid': await getDeviceId(),
      'OCRtext': text,
    });
  }

  Future<File> convertImagesToPDF(String title, List<Uint8List> images) async { //List<Uint8List>를 PDF로 변환
    final pdf = pw.Document();
    for (final image in images) {
      final img = pw.MemoryImage(image);
      pdf.addPage(pw.Page(build: (pw.Context context) {
        return pw.Center(child: pw.Image(img));
      }));
    }
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/$title.pdf';
    return File(filePath).writeAsBytes(await pdf.save());
  }

  Future<String?> getDeviceId() async { //디바이스 uid 가져오는 함수
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String? id = '';
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      id = androidInfo.androidId;
      return id;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      id = iosInfo.identifierForVendor;
      return id;
    }
    return null;
  }

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
      pdfName = result.names.last.toString();
      images = await convertPDFtoImages(file.path);
      ocrText = await performOCR(images!);

      Map<String, List<String>> data = {
        'ocrText': ocrText,
      };
      String jsonString = jsonEncode(data); //ocr텍스트 json 변환

      File pdfFile = await convertImagesToPDF(pdfName, images); //List<Uint8List> 타입 images를 File타입으로 변환

      final ref = FirebaseStorage.instance.ref().child('$pdfName');
      TaskSnapshot snapshot = await ref.putFile(pdfFile); //pdf명으로 파일 업로드
      final url = await ref.getDownloadURL(); //url 변수에 업로드한 파일의 다운로드 url을 할당

      createDoc(pdfName, file.path, jsonString, url); //pdf이름, 경로, 변환된 텍스트, 다운로드 url, 등록 시간을 firebase에 업로드

      print("파일이름 : " + result.names.last.toString());

    }
    else if (result == null) {
      isLoading = false;
    }
  }
}