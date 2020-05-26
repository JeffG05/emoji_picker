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
  @override
  void initState() {
    textController = TextEditingController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        TextField(
          controller: textController,
        ),
        Container(
          height: 180,
          child: EmojiPicker(
            rows: 2,
            columns: 7,
            bgColor: Colors.black,
            indicatorColor: Colors.white,
            buttonMode: ButtonMode.CUPERTINO,
            recommendKeywords: ["racing", "horse"],
            numRecommended: 10,
            categoryIcons: CategoryIcons(
              smileyIcon: CategoryIcon(
                icon: Icons.tag_faces,
                selectedColor: Colors.yellowAccent,
              ),
              animalIcon: CategoryIcon(
                icon: Icons.pets,
                selectedColor: Colors.yellowAccent,
              ),
              foodIcon: CategoryIcon(
                icon: Icons.fastfood,
                selectedColor: Colors.yellowAccent,
              ),
              travelIcon: CategoryIcon(
                icon: Icons.location_city,
                selectedColor: Colors.yellowAccent,
              ),
              activityIcon: CategoryIcon(
                icon: Icons.directions_run,
                selectedColor: Colors.yellowAccent,
              ),
              objectIcon: CategoryIcon(
                icon: Icons.lightbulb_outline,
                selectedColor: Colors.yellowAccent,
              ),
              symbolIcon: CategoryIcon(
                icon: Icons.euro_symbol,
                selectedColor: Colors.yellowAccent,
              ),
              flagIcon: CategoryIcon(
                icon: Icons.flag,
                selectedColor: Colors.yellowAccent,
              ),
            ),
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
