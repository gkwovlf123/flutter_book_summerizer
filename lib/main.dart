import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mypdfconverter/Image/ImageUtils.dart';
import 'package:mypdfconverter/OCR/OCRUtils.dart';
import 'package:mypdfconverter/PDF/PDFUtils.dart';
import 'package:mypdfconverter/style/color_schemes.g.dart';
import 'imgscreen.dart';

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
var date = DateTime.now();

class _HomeState extends State<Home> {
  List<String> filePath = [];
  bool isLoading = false;
  List<Uint8List> convertimages = [];
  List<String> ocrText = [];
  List<String> filename = [];
  String now = DateFormat('yyyy mm dd hh:mm').format(date);

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width * 0.6;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          if(filePath != 'null')
            IconButton(
              onPressed: () {

              },
              icon: Icon(Icons.manage_accounts),
            )
        ],
      ),
      body: Center(
        child: isLoading ?
        CircularProgressIndicator() :
        ListView.builder(
          itemCount: filename.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () async {

                convertimages = await convertPDFtoImages(filePath[index]);
                ocrText = await performOCR(convertimages);
                Navigator.push(context, MaterialPageRoute(
                      builder: (context) => Imgscreen(text: ocrText, images: convertimages),
                    ),
                  );
              },
              child: Card(
                child: Row(
                  children: [
                    SizedBox(
                      width: 70,
                      height: 70,
                      child: Icon(
                          Icons.picture_as_pdf,
                          size: 65
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Column(
                        children: [
                          Text(filename[index],
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          SizedBox(
                            width: width,
                            child: Text(filePath[index],
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey,
                              ),),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
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
            filePath = PDFUtils.filePath;
            filename = PDFUtils.filename;
          });


        },
        label: const Text('upload'),
      ),
    );
  }
}