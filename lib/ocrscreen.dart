import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:mypdfconverter/server/serverUtils.dart';
import 'package:mypdfconverter/ttsplayer.dart';

class OCRscreen extends StatefulWidget {
  const OCRscreen({Key? key, required this.OCRurl}) : super(key: key);
  final String OCRurl; //main.dart에서 OCR로 추출된 텍스트 List
  @override
  State<OCRscreen> createState() => _OCRscreenState();
}

class _OCRscreenState extends State<OCRscreen> {
  var ocrjson = null;
  late FlutterTts flutterTts;
  Server server = Server();
  String? summary;
  double volume = 1.0;
  double pitch = 1.0;
  double rate = 0.5;

  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemScrollController itemScrollController2 = ItemScrollController();

  void scrollToItem(int index) {
    itemScrollController.scrollTo(
        index: index,
      duration: Duration(milliseconds: 500), // 애니메이션 지속 시간 설정
      curve: Curves.ease, // 애니메이션 커브 설정 (옵션)
    );
  }

  List<String> convertListToString(List<dynamic> dataList) {
    List<String> stringList = dataList.map((item) => item.toString()).toList();
    return stringList;
  }

  Future<dynamic> jsonParse(String jsonUrl) async {
    http.Response response = await http.get(Uri.parse(jsonUrl));
    var json = jsonDecode(utf8.decode(response.bodyBytes));

    return json;
  }

  Future<void> initTts() async {
    flutterTts = FlutterTts();
    await flutterTts.setEngine('Google TTS');
    await flutterTts.setLanguage('ko-KR');
    await flutterTts.setPitch(pitch);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setVolume(volume);
  }

  Future<void> speak(String str) async {
    await flutterTts.speak(str);

  }

  @override
  void initState()  {
    super.initState();
    initTts();

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
        title: const Text('OCRscreen'),
        leading: IconButton( //뒤로가기 버튼
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back),
        ),

      ),
      body: FutureBuilder(
        future: jsonParse(widget.OCRurl),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error'),
            );
          }
          else {
            ocrjson = snapshot.data;
            return Column(
              children: [
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height / 10,
                  padding: const EdgeInsets.all(8.0),
                  child: ScrollablePositionedList.builder(
                    itemScrollController: itemScrollController2,
                    scrollDirection: Axis.horizontal,
                    itemCount: ocrjson[1]['extract'].length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () async {
                          print("onTab : $index");
                          await speak('$index 번 목차');
                        },
                        onLongPress: () async {
                          print('move to $index');
                          await speak('$index 번 이동');
                          scrollToItem(index);
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      offset: const Offset(1.0, 1.0),
                                      blurRadius: 1.0,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                    BoxShadow(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      offset: const Offset(-2.0, -2.0),
                                      blurRadius: 1.0,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(8.0),
                                margin: const EdgeInsets.only(
                                    right: 8.0, top: 8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                              text: '$index. ',
                                              style: TextStyle(
                                                  fontSize: 20.0,
                                                  fontWeight: FontWeight.w700,
                                                  color: Theme.of(context).colorScheme.surface
                                              )
                                          ),
                                          TextSpan(
                                              text: ocrjson[1]['extract'][index].toString().replaceAll('[', '').replaceAll(']', ""),
                                              style: TextStyle(
                                                  fontSize: 15.0,
                                                  fontWeight: FontWeight.w500,
                                                  color: Theme.of(context).colorScheme.surface
                                              )
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ), // 수평 목차 리스트 뷰
                Container(
                  child: Expanded(
                    child: ScrollablePositionedList.builder(
                      itemScrollController: itemScrollController,
                      itemCount: ocrjson[0]['output'].length,
                      itemBuilder: (BuildContext context, int index) {
                        return Column(
                          children: [
                            Container(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                        child: Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(
                                                  text: '$index. ',
                                                  style: TextStyle(
                                                      fontSize: 30.0,
                                                      fontWeight: FontWeight.w900,
                                                      color: Theme.of(context).colorScheme.onBackground
                                                  ),
                                              ),
                                              TextSpan(
                                                  text: ocrjson[1]['extract'][index].toString().replaceAll('[', '').replaceAll(']', ''),
                                                  style: TextStyle(
                                                      fontSize: 20.0,
                                                      fontWeight: FontWeight.w700,
                                                      color: Theme.of(context).colorScheme.onBackground
                                                  )
                                              ),
                                            ],
                                          ),
                                        ),
                                    ),
                                    const Divider(), // 구분선
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(
                                              10),
                                          boxShadow: [
                                            BoxShadow(
                                              offset: const Offset(1.0, 1.0),
                                              blurRadius: 1.0,
                                              color: Theme.of(context).colorScheme.onSurface,
                                            ),
                                            BoxShadow(
                                              color: Theme.of(context).colorScheme.onSurface,
                                              offset: const Offset(-2.0, -2.0),
                                              blurRadius: 1.0,
                                            ),
                                          ],
                                        ),
                                        width: double.infinity,
                                        child: ListTile(
                                          title: Text(
                                            ocrjson[0]['output'][index].join('\n\n').toString(),
                                            style: TextStyle(
                                                color: Theme.of(context).colorScheme.onBackground
                                            ),
                                          ),
                                          onTap: () async {
                                            print(ocrjson[0]['output'][index].toString());
                                            await speak('$index번째 페이지를 읽겠습니다 ${ocrjson[0]['output'][index]}');
                                          },
                                          onLongPress: () async {

                                          },

                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ), // 수직 페이지별 텍스트 리스트 뷰
              ],
            );
          }
        },
      ),
      floatingActionButton: GestureDetector(
        onLongPress: () {
          showTTSplayer(context, ocrjson[0]['output']);
        },
        child: FloatingActionButton.extended( //플로팅 액션 버튼
          onPressed: () async {
            await speak('음성 플레이어');
          },
          label: Text('음성 플레이어',
            style: TextStyle(
              color: Theme.of(context).colorScheme.surface
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          icon: Icon(Icons.arrow_upward,
            color: Theme.of(context).colorScheme.surface,
          ),
        ),
      ),
    );
  }
}