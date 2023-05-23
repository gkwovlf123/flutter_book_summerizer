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
  List<String> filePath = []; // pdf 파일 경로가 저장되는 list
  List<Uint8List> images = []; // pdf의 각 이미지가 저장되는 list, ocr 처리 시 사용
  List<String> ocrText = []; // ocr된 텍스트가 저장되는 list
  List<String> filename = []; // pdf 파일 이름이 저장되는 list
  late Uint8List img; // pdf title 이미지가 저장되는 변수
  String pdfName = ''; // pdf 이름이 저장되는 변수
  String now = DateFormat('yyyy-MM-dd HH:mm').format(date); // 현재 날짜 변수
  Server server = Server(); // 서버 통신 객체

  //파이어베이스 업로드 함수
  Future<void> createDoc(String? name, String path, String url, String imgurl, String jsonurl, String sumjsonurl, String refinejsonurl) async {
    FirebaseFirestore.instance.collection('pdfs').add({
      'PDFname': name, // pdf 이름
      'PDFpath': path, // pdf 경로
      'PDFimgUrl': url, // pdf 파일 다운로드 url
      'Titleimg': imgurl, // 타이틀 이미지 url
      'Create time': now, // 업로드 시간
      'Deviceid': await getDeviceId(), // 디바이스 id
      'Jsonurl': jsonurl, // ocr 텍스트 다운로드 url
      'Sumjsonurl': sumjsonurl, // 요약 텍스트 다운로드 url
      'Refinejsonurl': refinejsonurl, // 정제된 텍스트 다운로드 url
      'favorite': false, // 즐겨찾기, 기본 false
    });
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
      type: FileType.custom, // 선택할 파일을 직접 정할 수 있음
      allowedExtensions: ['pdf'], //pdf로 제한
    );
    if (result != null) { // 파일을 선택했을 경우
      File file = File(result.files.single.path!); // 선택한 파일의 정보를 가져옴
      filePath.add(file.path); // 파일 경로
      filename.add(result.names.last.toString()); // 파일 이름
      pdfName = result.names.last.toString(); // 파일 이름

      images = await convertPDFtoImages(file.path); // PDF 파일을 이미지로 한장 한장 변환
      ocrText = await performOCR(images!); // 변환된 이미지를 ocr 처리
      ocrText = ocrText.map((e) => e.replaceAll('\n', '').replaceAll('"', '')).toList(); //ocrtext에서 쌍따옴표, 줄바꿈 문자 제거
      img = images[0].buffer.asUint8List(); // convertPDFtoImages 함수에서 변환된 이미지 배열의 첫 인덱스(타이틀 이미지) 저장

      Map<String, List<String>> data = { // ocrtext를 ocrText라는 키의 값으로 설정
        'ocrText': ocrText,
      };
      //String summaryString = jsonEncode(data);
      final summaryData = await server.postData(ocrText); // ocrtext를 서버로 보내서 요약
      print('요약완료');
      final refineData = await server.postrefineData(ocrText); // ocrtext를 서버로 보내서 읽기 쉬운 형태로 재정리
      print('정리완료');

      //텍스트 json 인코딩
      String refineString = jsonEncode(refineData);
      String sumString = jsonEncode(summaryData);
      String jsonString = jsonEncode(data);

      //텍스트 utf8 포맷으로 인코딩
      final bytes = utf8.encode(jsonString);
      final sumbytes = utf8.encode(sumString);
      final refinebytes = utf8.encode(refineString);

      //db로 업로드 하기전에 업로드 할 파일을 이름을 지정해서 임시 디렉토리에 보관
      final jsondirectory = await getTemporaryDirectory();
      final jsonfilePath = '${jsondirectory.path}/$filename.json';
      final sumjsonfilePath = '${jsondirectory.path}/(요약)$filename.json';
      final refinejsonfilePath = '${jsondirectory.path}/(가공)$filename.json';

      //임시 파일을 실제 파일과 매핑
      File jsonfile = File(jsonfilePath);
      File sumjsonfile = File(sumjsonfilePath);
      File refinejsonfile = File(refinejsonfilePath);

      await refinejsonfile.writeAsBytes(refinebytes);
      await sumjsonfile.writeAsBytes(sumbytes);
      await jsonfile.writeAsBytes(bytes);


      final ref = FirebaseStorage.instance.ref().child('$pdfName'); // 파이어베이스에 pdf명으로 폴더 생성

      // 폴더 내부에 json, jpg, pdf 파일 저장
      final tasks = await Future.wait([
        ref.putFile(file),
        ref.child('$pdfName.jpg').putData(img),
        ref.child('$pdfName.json').putFile(jsonfile),
        ref.child('(요약)$pdfName.json').putFile(sumjsonfile),
        ref.child('(가공)$pdfName.json').putFile(refinejsonfile),
      ]);

      //각 파일들의 다운로드 url 가져옴
      final pdfurl = await ref.getDownloadURL();
      final titleimg = await ref.child('$pdfName.jpg').getDownloadURL();
      final jsonurl = await ref.child('$pdfName.json').getDownloadURL();
      final sumjsonurl = await ref.child('(요약)$pdfName.json').getDownloadURL();
      final refinejsonurl = await ref.child('(가공)$pdfName.json').getDownloadURL();

      //최종적으로 db에 각 다운로드 링크, 파일 정보들을 업로드
      createDoc(pdfName, file.path, pdfurl, titleimg, jsonurl, sumjsonurl, refinejsonurl); //pdf이름, 경로, 변환된 텍스트, 다운로드 url, 등록 시간을 firebase에 업로드

      print("업로드 파일이름 : " + result.names.last.toString());

    }
  }
}