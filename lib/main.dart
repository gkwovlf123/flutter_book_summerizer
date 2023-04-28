import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mypdfconverter/Image/ImageUtils.dart';
import 'package:mypdfconverter/OCR/OCRUtils.dart';
import 'package:mypdfconverter/PDF/PDFUtils.dart';
import 'package:mypdfconverter/style/color_schemes.g.dart';
import 'imgscreen.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
            colorScheme: ColorScheme.fromSeed(
                seedColor: lightColorScheme.primary, brightness: Brightness.light)
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
              seedColor: darkColorScheme.primary, brightness: Brightness.dark),
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

  Future<void> showLoadingDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // 다이얼로그가 닫히지 않도록 설정
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(), // 인디케이터를 보여줌
        );
      },
    );
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(),
          Expanded(
            child: Center(
              child: isLoading ?
              CircularProgressIndicator(backgroundColor: lightColorScheme.primaryContainer,) :
              ListView.builder(
                itemCount: filename.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () async {
                      showLoadingDialog(context); //다이얼로그 함수
                      convertimages = await convertPDFtoImages(filePath[index]);
                      ocrText = await performOCR(convertimages);
                      Navigator.pop(context); //다이얼로그를 닫음
                      await Navigator.push(context, MaterialPageRoute(
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.upload),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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