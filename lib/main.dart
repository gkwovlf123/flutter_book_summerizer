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
import 'package:cloud_firestore/cloud_firestore.dart';

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


class _HomeState extends State<Home> {
  List<String> filePath = [];
  bool isLoading = false;
  List<Uint8List> convertimages = [];
  List<String> ocrText = [];
  List<String> filename = [];




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
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width * 0.6;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
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
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('pdfs').orderBy('Create time', descending: true).snapshots(),
              builder: (context, snapshot) {
                if(snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator(backgroundColor: lightColorScheme.primaryContainer,);
                }
                return ListView.builder(
                    shrinkWrap: true,
                    itemCount: snapshot.data?.docs.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () async {
                            String? docId = snapshot.data?.docs[index].id;
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                              builder: (context) => Imgscreen(docId: docId),
                            ),
                          );
                        },
                        child: Card(
                          child: Row(
                            children: [
                              SizedBox(
                                child: Image.network(snapshot.data?.docs[index]['Titleimg'],
                                  width: 70,
                                  height: 70,
                                )
                              ),
                              Padding(
                                padding: EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(snapshot.data?.docs[index]['PDFname'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Text(snapshot.data?.docs[index]['Create time'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.upload),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        onPressed: () async {
          PDFUtils pdfUtils = PDFUtils();
          showLoadingDialog(context);
          await pdfUtils.PDFpicker();
          Navigator.pop(context);
        },
        label: const Text('upload'),
      ),
    );
  }
}