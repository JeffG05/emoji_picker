import 'package:flutter/material.dart';
import 'package:emoji_picker/emoji_picker.dart';

void main() => runApp(MainApp());

class MainApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Test",
      debugShowCheckedModeBanner: false,
      home: MainPage(),
    );
  }

}

class MainPage extends StatefulWidget {

  @override
  MainPageState createState() => new MainPageState();

}

class MainPageState extends State<MainPage> {

  @override
  Widget build(BuildContext context) {
    return EmojiPicker();
  }

}