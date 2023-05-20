import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../Image/ImageUtils.dart';
import '../OCR/OCRUtils.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

import '../server/serverUtils.dart';


var date = DateTime.now();
class PDFUtils {
  List<String> filePath = [];
  List<Uint8List> images = [];
  List<String> ocrText = [];
  List<String> filename = [];
  late Uint8List img;
  String pdfName = '';
  String now = DateFormat('yyyy-MM-dd HH:mm').format(date);
  Server server = Server();

  Future<void> createDoc(String? name, String path, String url, String imgurl, String jsonurl, String sumjsonurl) async { //firebase create
    FirebaseFirestore.instance.collection('pdfs').add({
      'PDFname': name,
      'PDFpath': path,
      'PDFimgUrl': url,
      'Titleimg': imgurl,
      'Create time': now,
      'Deviceid': await getDeviceId(),
      'Jsonurl': jsonurl,
      'Sumjsonurl': sumjsonurl,
      'favorite': false,
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

      filePath.add(file.path);
      filename.add(result.names.last.toString());
      pdfName = result.names.last.toString();

      images = await convertPDFtoImages(file.path);
      ocrText = await performOCR(images!);
      ocrText = ocrText.map((e) => e.replaceAll('\n', '').replaceAll('"', '')).toList();
      img = images[0].buffer.asUint8List();

      Map<String, List<String>> data = {
        'ocrText': ocrText,
      };
      //String summaryString = jsonEncode(data);
      final summaryData = await server.postData(ocrText);


      String sumString = jsonEncode(summaryData);
      String jsonString = jsonEncode(data); //ocr텍스트 json 변환
      final bytes = utf8.encode(jsonString);
      final sumbytes = utf8.encode(sumString);

      final jsondirectory = await getTemporaryDirectory();
      final jsonfilePath = '${jsondirectory.path}/$filename.json';
      final sumjsonfilePath = '${jsondirectory.path}/(요약)$filename.json';
      File jsonfile = File(jsonfilePath);
      File sumjsonfile = File(sumjsonfilePath);

      await sumjsonfile.writeAsBytes(sumbytes);
      await jsonfile.writeAsBytes(bytes);

      File pdfFile = await convertImagesToPDF(pdfName, images); //List<Uint8List> 타입 images를 File타입으로 변환

      final ref = FirebaseStorage.instance.ref().child('$pdfName');
      final tasks = await Future.wait([
        ref.putFile(pdfFile),
        ref.child('$pdfName.jpg').putData(img),
        ref.child('$pdfName.json').putFile(jsonfile),
        ref.child('(요약)$pdfName.json').putFile(sumjsonfile),
      ]);
      final pdfurl = await ref.getDownloadURL();
      final titleimg = await ref.child('$pdfName.jpg').getDownloadURL();
      final jsonurl = await ref.child('$pdfName.json').getDownloadURL();
      final sumjsonurl = await ref.child('(요약)$pdfName.json').getDownloadURL();

      createDoc(pdfName, file.path, pdfurl, titleimg, jsonurl, sumjsonurl); //pdf이름, 경로, 변환된 텍스트, 다운로드 url, 등록 시간을 firebase에 업로드

      print("파일이름 : " + result.names.last.toString());

    }
  }
}