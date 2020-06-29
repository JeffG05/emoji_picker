import 'package:flutter/material.dart';
import 'package:emoji_picker/emoji_picker.dart';

void main() => runApp(MainApp());

class MainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Test",
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text("Emoji Picker Test"),
        ),
        body: MainPage(),
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  MainPageState createState() => new MainPageState();
}

class MainPageState extends State<MainPage> {
  TextEditingController textController;
  TextEditingController textRecommendController;
  ValueNotifier<List<String>> recommendList = ValueNotifier<List<String>>([]);
  @override
  void initState() {
    textController = TextEditingController();
    textRecommendController = TextEditingController();

    textRecommendController.addListener(() {
      recommendList.value = textRecommendController.text.split(" ");
    });
    super.initState();
  }

  @override
  void dispose() {
    textController.dispose();
    textRecommendController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorGold = Color.fromRGBO(205, 167, 119, 1);
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text("Output"),
            ),
            Expanded(
              child: TextField(
                controller: textController,
              ),
            ),
          ],
        ),
        Row(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text("Search"),
            ),
            Expanded(
              child: TextField(
                controller: textRecommendController,
              ),
            ),
          ],
        ),
        Container(
          height: 430,
          child: EmojiPicker(
            rows: 4,
            columns: 7,
            iconSize: 20,
            gridFactor: 1.5,
            bgColor: Colors.black,
            indicatorColor: Colors.white,
            buttonMode: ButtonMode.CUPERTINO,
            recommendKeywords: recommendList,
            numRecommended: 10,
            categoryIcons: CategoryIcons(
              recommendationIcon: CategoryIcon(
                icon: Icons.search,
                selectedColor: colorGold,
              ),
              recentIcon: CategoryIcon(
                icon: Icons.access_time,
                selectedColor: colorGold,
              ),
              smileyIcon: CategoryIcon(
                icon: Icons.tag_faces,
                selectedColor: colorGold,
              ),
              animalIcon: CategoryIcon(
                icon: Icons.pets,
                selectedColor: colorGold,
              ),
              foodIcon: CategoryIcon(
                icon: Icons.fastfood,
                selectedColor: colorGold,
              ),
              travelIcon: CategoryIcon(
                icon: Icons.location_city,
                selectedColor: colorGold,
              ),
              activityIcon: CategoryIcon(
                icon: Icons.directions_run,
                selectedColor: colorGold,
              ),
              objectIcon: CategoryIcon(
                icon: Icons.lightbulb_outline,
                selectedColor: colorGold,
              ),
              symbolIcon: CategoryIcon(
                icon: Icons.euro_symbol,
                selectedColor: colorGold,
              ),
              flagIcon: CategoryIcon(
                icon: Icons.flag,
                selectedColor: colorGold,
              ),
            ),
            enableRecommend: true,
            enableRecent: true,
            onEmojiSelected: (emoji, category) {
              var txtOrg = textController.value.text;
              String txt;
              var selection = textController.value.selection;
              if (selection.start > 0) {
                txt = txtOrg.substring(0, selection.start);
                txt += emoji.emoji;
                final cursorPos = txt.length;
                txt += txtOrg.substring(selection.end, txtOrg.length);
                textController.text = txt;
                textController.selection = TextSelection.fromPosition(TextPosition(offset: cursorPos));
              } else {
                textController.text = textController.text + emoji.emoji;
              }
            },
          ),
        ),
      ],
    );
  }
}
