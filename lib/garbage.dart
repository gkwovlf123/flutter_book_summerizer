import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mypdfconverter/PDF/PDFUtils.dart';
import 'package:mypdfconverter/style/color_schemes.g.dart';
import 'imgscreen.dart';
/*
void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: lightColorScheme,
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: darkColorScheme,
        ),
        themeMode: ThemeMode.system,

        home: Home()
    );
  }
}


class Home extends StatefulWidget {


  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();

}

class _HomeState extends State<Home> {
  String filePath = 'null';
  bool isLoading = false;
  late List<Uint8List> convertimages = [];
  late List<String> ocrText = [];


  @override
  void initState() {
    // TODO: implement initState
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          if(filePath != 'null')
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OCRscreen(convertText: ocrText, images: convertimages,),
                  ),
                );
              },
              icon: Icon(Icons.text_snippet),
            )
        ],
      ),
      body: Center(
        child: isLoading ?
        CircularProgressIndicator() :
        ListView.builder(
          itemCount: convertimages.length,
          itemBuilder: (context, index) {
            return Image.memory(convertimages[index]);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.upload),
        onPressed: () async {
          PDFUtils pdfUtils = PDFUtils();
          setState(() {
            if(PDFUtils.isLoading == false) {
              PDFUtils.isLoading = true;
              isLoading = PDFUtils.isLoading;
            }
            else {
              isLoading = PDFUtils.isLoading;
            }
          });
          await pdfUtils.PDFpicker();
          setState(()  {
            isLoading = PDFUtils.isLoading;
            convertimages = PDFUtils.images;
            filePath = PDFUtils.filePath;
            ocrText = PDFUtils.ocrText;
          });


        },
        label: const Text('upload'),
      ),
    );
  }
}
*/