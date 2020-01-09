# Flutter Emoji Keyboard

[![pub package](https://img.shields.io/pub/v/emoji_picker.svg)](https://pub.dartlang.org/packages/emoji_picker)

A Flutter package that provides an Emoji Keyboard widget.

## Key Features
* View and select 390 emojis
* 8 categories
* Optionally add keywords to recommend emojis
* Material Design and Cupertino mode
* Emojis that cannot be displayed are filtered out (Android Only)


## Usage
To use this plugin, add `emoji_picker` as dependency in your pubspec.yaml file.

## Sample Usage

```
import 'package:flutter/material.dart';
import 'package:emoji_picker/emoji_picker.dart';

void main() => runApp(MainApp());

class MainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Flutter Emoji Picker Example",
      home: Scaffold(
        appBar: AppBar(
          title: Text("Flutter Emoji Picker Example"),
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
  @override
  Widget build(BuildContext context) {
    return EmojiPicker(
      rows: 3,
      columns: 7,
      recommendKeywords: ["racing", "horse"],
      numRecommended: 10,
      onEmojiSelected: (emoji, category) {
        print(emoji);
      },
    );
  }
}
```
See the `example` directory for the complete sample app.
