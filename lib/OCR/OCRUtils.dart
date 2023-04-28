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
  int num = 0;
  final List<String> texts = [];
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
    final response = await vision.images.annotate(batchRequest);
    final annotation = response.responses!.first.fullTextAnnotation!;
    //
    final text = annotation.text!;
    //num += text.length;
    //print(num);
    texts.add(text);
  }
  return texts;
}