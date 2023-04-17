import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class OCRscreen extends StatefulWidget {
  const OCRscreen({Key? key, required this.convertText}) : super(key: key);
  final List<String> convertText; //main.dart에서 OCR로 추출된 텍스트 List

  @override
  State<OCRscreen> createState() => _OCRscreenState();
}

class _OCRscreenState extends State<OCRscreen> {
  FlutterTts flutterTts = FlutterTts();
  double volume = 1.0;
  double pitch = 1.0;
  double rate = 1.0;

  Future<void> _speak() async { //TTS를 설정하는 함수

    await flutterTts.setLanguage('ko');
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);

    for(int i=0; i<widget.convertText.length;i++) {
      await flutterTts.speak(widget.convertText[i]);
    }
    print(widget.convertText.length);
  }

  @override
  void dispose() { //음성을 듣다가 화면을 빠져나오면 TTS가 중단되는 함수
    super.dispose();
    flutterTts.stop();
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
          child: ListView.builder(
            itemCount: widget.convertText.length,
            itemBuilder: (context, index) {
              return Text(widget.convertText[index]);
            },
          )
      ),
      floatingActionButton: FloatingActionButton.extended( //음성 버튼
        onPressed: () {
          _speak();
        },
        label: Text('음성듣기'),
        icon: Icon(Icons.keyboard_voice),
      ),
    );
  }
}
