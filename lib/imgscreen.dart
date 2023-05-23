import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'package:mypdfconverter/ocrscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:mypdfconverter/server/serverUtils.dart';

class Imgscreen extends StatefulWidget {
  const Imgscreen({Key? key, required this.pdfurl}) : super(key: key);
  final String pdfurl;

  @override
  State<Imgscreen> createState() => _ImgscreenState();
}
class _ImgscreenState extends State<Imgscreen> {
  late Future<Uint8List> pdfFuture;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    pdfFuture = _fetchPDF();
  }

  Future<Uint8List> _fetchPDF() async {

    Uint8List pdfBytes = (await NetworkAssetBundle(Uri.parse(widget.pdfurl)).load('')).buffer.asUint8List();

    return pdfBytes;
  }
  @override

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        title: Text('OCRscreen'),
        leading: IconButton( //뒤로가기 버튼
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back),
        ),
      ),
      body: Center(
          child: FutureBuilder<Uint8List>(
            future: pdfFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasData) {
                  return PDF().cachedFromUrl(
                    widget.pdfurl,
                    placeholder: (progress) => Center(child: CircularProgressIndicator()),
                    errorWidget: (error) => Center(child: Text('Failed to load PDF')),
                  );
                } else {
                  return Text('PDF 파일을 가져오는데 실패했습니다.');
                }
              } else {
                return CircularProgressIndicator();
              }
            },
          ),
      ),
    );
  }
}