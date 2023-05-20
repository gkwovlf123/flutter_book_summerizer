import 'dart:typed_data';
import 'dart:io';
import 'package:native_pdf_renderer/native_pdf_renderer.dart';


Future<List<Uint8List>> convertPDFtoImages(String path) async {
  final file = File(path);
  final document = await PdfDocument.openFile(file.path);
  final pageCount = document.pagesCount;
  final List<Uint8List> images = [];
  //print('device id = ${await getDeviceId()}'); //기기 uid
  

  for (int i = 0; i < pageCount; i++) {
    final page = await document.getPage(i + 1);
    final pageImage = await page.render(
      width: page.width * 2,
      height: page.height * 2,
      format: PdfPageImageFormat.png,
    );
    final imageData = pageImage?.bytes;
    images.add(imageData!);
    await page.close();
  }
  

  await document.close();
  return images;
}