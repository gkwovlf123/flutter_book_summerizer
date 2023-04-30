import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'package:mypdfconverter/ocrscreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mypdfconverter/style/color_schemes.g.dart';
import 'package:native_pdf_renderer/native_pdf_renderer.dart';

class Imgscreen extends StatefulWidget {
  const Imgscreen({Key? key, required this.docId}) : super(key: key);
  final docId;

  @override
  State<Imgscreen> createState() => _ImgscreenState();
}
class _ImgscreenState extends State<Imgscreen> {
  late Future<Uint8List> pdfFuture;
  String OCRtext = '';
  String pdfUrl = '';
  Future<void> showLoadingDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // 다이얼로그가 닫히지 않도록 설정
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(backgroundColor: lightColorScheme.primaryContainer,), // 인디케이터를 보여줌
        );
      },
    );
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    pdfFuture = _fetchPDF();
  }

  Future<Uint8List> _fetchPDF() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('pdfs')
        .doc(widget.docId)
        .get();

    // PDF 파일의 URL을 가져와서 Uint8List 형식으로 변환합니다.
    OCRtext = doc.get('Jsonurl');
    pdfUrl = doc.get('PDFimgUrl');
    Uint8List pdfBytes = (await NetworkAssetBundle(Uri.parse(pdfUrl)).load('')).buffer.asUint8List();

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
        actions: [
          IconButton(
            onPressed: () {
              /*Navigator.push(context, MaterialPageRoute(
                builder: (context) => OCRscreen(convertText: OCRtext),
              )
              );*/
              print(OCRtext);
            },
            icon: Icon(Icons.text_snippet),
          )
        ],
      ),
      body: Center(
          child: FutureBuilder<Uint8List>(
            future: pdfFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasData) {
                  return PDF().cachedFromUrl(
                    pdfUrl,
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