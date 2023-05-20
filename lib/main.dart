import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('pdfs').orderBy('Create time', descending: true).snapshots(),
            builder: (context, snapshot) {
              if(snapshot.connectionState == ConnectionState.waiting) {
                return Center(child:CircularProgressIndicator());
              }
              return RawScrollbar(
                thumbColor: Theme.of(context).colorScheme.secondary,
                thickness: 6.0, // 스크롤 너비
                radius: const Radius.circular(20.0), // 스크롤 라운딩
                isAlwaysShown: false,
                child: ListView.builder(
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
                                    SizedBox(
                                      child: Text(
                                        snapshot.data?.docs[index]['PDFname'] /*끝에 ?? '' 입력하면 null이면 ?? 뒤의 문자로 대체함*/,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      width: width,
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    SizedBox(
                                      child: Text(snapshot.data?.docs[index]['Create time'],
                                          style: TextStyle(
                                            fontSize: 10,
                                          ),
                                        overflow: TextOverflow.ellipsis,
                                        ),
                                      width: width,
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
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        elevation: 2.0,
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