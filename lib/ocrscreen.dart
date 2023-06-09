import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:mypdfconverter/TTS/tts.dart';
import 'package:mypdfconverter/stt.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:mypdfconverter/ttsplayer.dart';

class OCRscreen extends StatefulWidget {
  const OCRscreen({Key? key, required this.OCRurl, required this.Extracturl}) : super(key: key);
  final String OCRurl; //main.dart에서 OCR로 추출된 텍스트 List
  final String Extracturl;
  @override
  State<OCRscreen> createState() => _OCRscreenState();
}

class _OCRscreenState extends State<OCRscreen> {
  var ocrjson = null;
  TTS tts = TTS();
  String? summary;
  String STTtest = '';

  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemScrollController itemScrollController2 = ItemScrollController();

  void scrollToItem(int index) {
    itemScrollController.scrollTo(
        index: index,
      duration: Duration(milliseconds: 500), // 애니메이션 지속 시간 설정
      curve: Curves.ease, // 애니메이션 커브 설정 (옵션)
    );
  }


  Future<dynamic> jsonParse(String jsonUrl, String extractUrl) async {
    http.Response response = await http.get(Uri.parse(jsonUrl));
    http.Response response1 = await http.get(Uri.parse(extractUrl));

    var json = jsonDecode(utf8.decode(response.bodyBytes));
    var json1 = jsonDecode(utf8.decode(response1.bodyBytes));
    STTtest = json['output'][0][0];
    print(STTtest.runtimeType);
    print(STTtest);
    var result = [
      [json], [json1]
    ];

    return result;
  }


  @override
  void initState()  {
    super.initState();
    tts.initTts();

  }

  @override
  void dispose() { //음성을 듣다가 화면을 빠져나오면 TTS가 중단되는 함수
    super.dispose();
    tts.flutterTts.stop();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        title: const Text('OCRscreen'),
        leading: GestureDetector(
          onLongPress: () {
            Navigator.pop(context);
          },
          child: IconButton( //뒤로가기 버튼
            onPressed: () {
              tts.speak('뒤로가기');
            },
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        actions: [
          GestureDetector(
            onLongPress: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                return SttPage(STTstr: STTtest,);
              },));
            },
            child: IconButton(
              onPressed: () {
                tts.speak('STT');
              },
              icon: Icon(Icons.mic),
            ),
          ),
        ],
      ),
      body: FutureBuilder(
        future: jsonParse(widget.OCRurl, widget.Extracturl),
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
                    itemCount: ocrjson[1][0]['output'].length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () async {
                          print("onTab : $index");
                          tts.speak(ocrjson[1][0]['output'][index].toString());
                        },
                        onLongPress: () async {
                          print('move to $index');
                          tts.speak('$index 번 목차 이동');
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
                                              text: ocrjson[1][0]['output'][index].toString().replaceAll('[', '').replaceAll(']', ""),
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
                      itemCount: ocrjson[0][0]['output'].length,
                      itemBuilder: (BuildContext context, int index) {
                        return Column(
                          children: [
                            ExpansionTile(
                              backgroundColor: Colors.black,
                              initiallyExpanded: false,
                              onExpansionChanged: (value) {
                                tts.speak('$index 번 페이지');
                              },
                              title: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '$index. ',
                                      style: TextStyle(
                                          fontSize: 20.0,
                                          fontWeight: FontWeight.w900,
                                          color: Theme.of(context).colorScheme.onBackground
                                      ),
                                    ),
                                    TextSpan(
                                        text: ocrjson[1][0]['output'][index].toString().replaceAll('[', '').replaceAll(']', ''),
                                        style: TextStyle(
                                            fontSize: 15.0,
                                            fontWeight: FontWeight.w700,
                                            color: Theme.of(context).colorScheme.onBackground
                                        )
                                    ),
                                  ],
                                ),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
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
                                              ocrjson[0][0]['output'][index].join('\n\n').toString(),
                                              style: TextStyle(
                                                  color: Theme.of(context).colorScheme.onBackground
                                              ),
                                            ),
                                            onTap: () async {
                                              print(ocrjson[0][0]['output'][index].toString());
                                              tts.speak('$index번째 페이지를 읽겠습니다 ${ocrjson[0][0]['output'][index]}');
                                            },
                                          ),
                                        ),
                                      ),
                                      const Divider(), // 구분선
                                    ],
                                  ),
                                ),
                              ]
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
          showTTSplayer(context, ocrjson[0][0]['output']);
        },
        child: FloatingActionButton.extended( //플로팅 액션 버튼
          onPressed: () async {
            tts.speak('음성 플레이어');
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