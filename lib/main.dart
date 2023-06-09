import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mypdfconverter/PDF/PDFUtils.dart';
import 'package:mypdfconverter/stt.dart';
import 'package:mypdfconverter/style/color_schemes.g.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:mypdfconverter/TTS/tts.dart';
import 'menu.dart';
import 'option.dart';
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


class _HomeState extends State<Home>  {
  TTS tts = TTS();
  List<String> filePath = [];
  bool isLoading = false;
  List<Uint8List> convertimages = [];
  List<String> ocrText = [];
  List<String> filename = [];
  var deviceIdFuture;




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

  Future<String?> getDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.androidId;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor;
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  @override
  void initState() {
    deviceIdFuture = getDeviceId();
    tts.initTts();
    super.initState();

  }

  @override
  void dispose() { //음성을 듣다가 화면을 빠져나오면 TTS가 중단되는 함수
    super.dispose();
    tts.flutterTts.stop();

  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width * 0.6;
    return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Home'),
            actions: [
                GestureDetector(
                  onLongPress: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                      return Option();
                    },));
                  },
                  child: IconButton(
                    onPressed: () {
                      tts.speak('환경설정');
                    },
                    icon: Icon(Icons.manage_accounts),
                  ),
                ),
              /*GestureDetector(
                onLongPress: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                    return SttPage();
                  },));
                },
                child: IconButton(
                  onPressed: () {
                    tts.speak('STT');
                  },
                  icon: Icon(Icons.mic),
                ),
              ),*/
            ],
          ),
          body: TabBarView(
            children: [
              Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Divider(),
                FutureBuilder<String?>(
                  future: deviceIdFuture,
                  builder: (context, snapshot) {
                  String? deviceId = snapshot.data;
                  return StreamBuilder<QuerySnapshot> (
                    stream: FirebaseFirestore.instance.collection('pdfs')
                        .where('Deviceid', isEqualTo: deviceId)
                        .snapshots(),
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
                                onLongPress: () async {
                                    String? docId = snapshot.data?.docs[index].id;
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                      builder: (context) => menu(docId: docId),
                                    ),
                                  );
                                },
                                onTap: () {
                                  tts.speak(snapshot.data?.docs[index]['PDFname']);
                                },
                                child: GestureDetector(
                                  onDoubleTap: () {
                                    FirebaseFirestore.instance
                                        .collection('pdfs')
                                        .doc(snapshot.data?.docs[index].id) // 업데이트할 문서의 ID를 지정
                                        .update({'favorite': true}); // 필드 값을 업데이트
                                    tts.speak('즐겨찾기 등록 완료');

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
                                          child: Row(
                                            children: [
                                              Column(
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
                                              SizedBox(
                                                width: 10,
                                                child: IconButton(
                                                    onPressed: () {

                                                    },
                                                    icon: snapshot.data?.docs[index]['favorite'] ? Icon(Icons.star, color: Colors.yellow,)
                                                        : Icon(Icons.star),
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                        ),
                      );
                    },
                  );
                  },
                ),
              ],
            ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Divider(),
                  FutureBuilder<String?>(
                    future: deviceIdFuture,
                    builder: (context, snapshot) {
                      String? deviceId = snapshot.data;
                    return StreamBuilder<QuerySnapshot> (
                      stream: FirebaseFirestore.instance.collection('pdfs')
                          .where('Deviceid', isEqualTo: deviceId)
                          .where('favorite', isEqualTo: true)
                          .snapshots(),
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
                                onLongPress: () async {
                                  String? docId = snapshot.data?.docs[index].id;
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => menu(docId: docId),
                                    ),
                                  );
                                },
                                child: GestureDetector(
                                  onTap: () {
                                    tts.speak(snapshot.data?.docs[index]['PDFname']);
                                  },
                                  onDoubleTap: () {
                                    FirebaseFirestore.instance
                                        .collection('pdfs')
                                        .doc(snapshot.data?.docs[index].id) // 업데이트할 문서의 ID를 지정
                                        .update({'favorite': false}); // 필드 값을 업데이트
                                    tts.speak('즐겨찾기 삭제 완료');

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
                                          child: Row(
                                            children: [
                                              Column(
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
                                              SizedBox(
                                                width: 10,
                                                child: IconButton(
                                                  onPressed: () {

                                                  },
                                                  icon: snapshot.data?.docs[index]['favorite'] ? Icon(Icons.star, color: Colors.yellow,)
                                                      : Icon(Icons.star),
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                    },
                  ),
                ],
              ),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            color: Theme.of(context).colorScheme.onSurfaceVariant
            ),
            child: Container(
              height: MediaQuery.of(context).size.height/ 10,
              padding: EdgeInsets.only(bottom: 10, top: 5),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.label,
                indicatorColor: Theme.of(context).colorScheme.inversePrimary,
                indicatorWeight: 2,
                labelColor: Theme.of(context).colorScheme.inversePrimary,
                unselectedLabelColor: Colors.black38,
                labelStyle: TextStyle(
                  fontSize: 13,
                ),
                tabs: [
                  GestureDetector(
                    onDoubleTap: () {
                      tts.speak('메인화면');
                    },
                    child: Tab(
                      icon: Icon(Icons.home_outlined),
                      text: '메인화면',
                    ),
                  ),
                  GestureDetector(
                    onDoubleTap: () {
                      tts.speak('즐겨찾기');
                    },
                    child: Tab(
                      icon: Icon(Icons.star),
                      text: '즐겨찾기',
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: GestureDetector(
            onLongPress: () async {
              PDFUtils pdfUtils = PDFUtils();
              showLoadingDialog(context);
              await pdfUtils.PDFpicker();
              Navigator.pop(context);
            },
            child: FloatingActionButton.extended(
              elevation: 2.0,
              icon: const Icon(Icons.upload),
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              onPressed: () async {
                tts.speak('업로드');
              },
              label: const Text('업로드'),
            ),
          ),
        ),
    );
  }
}