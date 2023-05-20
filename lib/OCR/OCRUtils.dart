import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:googleapis/vision/v1.dart' as Vis;
import 'package:googleapis_auth/auth_io.dart';


Future<List<String>> performOCR(List<Uint8List> images) async {
  // Set up authentication credentials
  final credentials = ServiceAccountCredentials.fromJson(
      jsonDecode(await rootBundle.loadString('assets/credentials.json')));
  final client = await clientViaServiceAccount(credentials, [
    Vis.VisionApi.cloudVisionScope,
  ]);
  final vision = Vis.VisionApi(client);

  // 비동기 작업 리스트
  final List<Future<String>> ocrFutures = [];

  for (final image in images) {
    final inputImage = Vis.Image();
    inputImage.contentAsBytes = image;
    final feature = Vis.Feature();
    feature.type = 'DOCUMENT_TEXT_DETECTION';
    final request = Vis.AnnotateImageRequest();
    request.image = inputImage;
    request.features = [feature];
    final batchRequest = Vis.BatchAnnotateImagesRequest();
    batchRequest.requests = [request];

    // OCR 작업을 Future로 래핑하여 리스트에 추가
    final ocrFuture = vision.images.annotate(batchRequest)
        .then((response) {
      final annotation = response.responses!.first.fullTextAnnotation!;
      final text = annotation.text!;
      return text;
    });

    ocrFutures.add(ocrFuture);
  }

  // 병렬로 모든 OCR 작업을 실행하고 결과를 기다림
  final List<String> texts = await Future.wait(ocrFutures);

  return texts;
}