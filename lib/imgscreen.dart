import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mypdfconverter/ocrscreen.dart';

class Imgscreen extends StatefulWidget {
  const Imgscreen({Key? key, required this.text, required this.images}) : super(key: key);
  final List<String> text; //main.dart에서 OCR로 추출된 텍스트 List
  final List<Uint8List> images;
  @override
  State<Imgscreen> createState() => _ImgscreenState();
}

class _ImgscreenState extends State<Imgscreen> {
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
                Navigator.push(context, MaterialPageRoute(
                    builder: (context) => OCRscreen(convertText: widget.text),
                  )
                );
              },
              icon: Icon(Icons.text_snippet),
          )
        ],
      ),
      body: Center(
        child: ListView.builder(
          itemCount: widget.images.length,
          itemBuilder: (context, index) {
            return Image.memory(widget.images[index]);
          },
        )
      ),
    );
  }
}
