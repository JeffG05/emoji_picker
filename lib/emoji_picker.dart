library emoji_picker;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'emoji_lists.dart' as emojiList;

import 'package:shared_preferences/shared_preferences.dart';

/// All the possible categories that [Emoji] can be put into
///
/// All [Category] are shown in the keyboard bottombar with the exception of [Category.RECOMMENDED]
/// which only displays when keywords are given
/// todo: height with layoutbuilder
enum Category { RECOMMENDED, RECENT, SMILEYS, ANIMALS, FOODS, TRAVEL, ACTIVITIES, OBJECTS, SYMBOLS, FLAGS }

/// Enum to alter the keyboard button style
enum ButtonMode {
  /// Android button style - gives the button a splash color with ripple effect
  MATERIAL,

  /// iOS button style - gives the button a fade out effect when pressed
  CUPERTINO
}

/// Callback function for when emoji is selected
///
/// The function returns the selected [Emoji] as well as the [Category] from which it originated
typedef void OnEmojiSelected(Emoji emoji, Category category);

/// The Emoji Keyboard widget
///
/// This widget displays a grid of [Emoji] sorted by [Category] which the user can horizontally scroll through.
///
/// There is also a bottombar which displays all the possible [Category] and allow the user to quickly switch to that [Category]
class EmojiPicker extends StatefulWidget {
  @override
  _EmojiPickerState createState() => new _EmojiPickerState();

  /// Number of columns in keyboard grid
  final int columns;

  /// Number of rows in keyboard grid
  final int rows;

  /// The currently selected [Category]
  ///
  /// This [Category] will have its button in the bottombar darkened
  final Category selectedCategory;

  /// The function called when the emoji is selected
  final OnEmojiSelected onEmojiSelected;

  /// The background color of the keyboard
  final Color bgColor;

  /// The color of the keyboard page indicator
  final Color indicatorColor;

  static const Color _defaultBgColor = Color.fromRGBO(242, 242, 242, 1);

  /// A list of keywords that are used to provide the user with recommended emojis in [Category.RECOMMENDED]
  List<String> recommendKeywords;

  ///
  final enableRecommend;

  ///
  final enableRecent;

  /// The maximum number of emojis to be recommended
  final int numRecommended;

  /// The string to be displayed if no recommendations found
  final String noRecommendationsText;

  /// The text style for the [noRecommendationsText]
  final TextStyle noRecommendationsStyle;

  /// The string to be displayed if no recent emojis to display
  final String noRecentsText;

  /// The text style for the [noRecentsText]
  final TextStyle noRecentsStyle;

  /// Determines the icon to display for each [Category]
  final CategoryIcons categoryIcons;

  /// Determines the style given to the keyboard keys
  ButtonMode buttonMode;

  EmojiPicker({
    Key key,
    @required this.onEmojiSelected,
    this.columns = 7,
    this.rows = 3,
    this.selectedCategory,
    this.bgColor = _defaultBgColor,
    this.indicatorColor = Colors.blue,
    this.recommendKeywords,
    this.numRecommended = 10,
    this.noRecommendationsText = "No Recommendations",
    TextStyle noRecommendationsStyle,
    this.noRecentsText = "No Recents",
    TextStyle noRecentsStyle,
    this.enableRecent = false,
    this.enableRecommend = false,
    CategoryIcons categoryIcons,
    this.buttonMode = ButtonMode.MATERIAL,
    //this.unavailableEmojiIcon,
  })  : this.categoryIcons = categoryIcons ?? CategoryIcons(),
        this.noRecommendationsStyle = noRecommendationsStyle ?? TextStyle(fontSize: 20, color: Colors.black26),
        this.noRecentsStyle = noRecentsStyle ?? TextStyle(fontSize: 20, color: Colors.black26),
        super(key: key);
}

class _Recommended {
  final String name;
  final String emoji;
  final int tier;
  final int numSplitEqualKeyword;
  final int numSplitPartialKeyword;

  _Recommended({this.name, this.emoji, this.tier, this.numSplitEqualKeyword = 0, this.numSplitPartialKeyword = 0});
}

/// Class that defines the icon representing a [Category]
class CategoryIcon {
  /// The icon to represent the category
  IconData icon;

  /// The default color of the icon
  Color color;

  /// The color of the icon once the category is selected
  Color selectedColor;

  CategoryIcon({@required this.icon, this.color, this.selectedColor}) {
    if (this.color == null) {
      this.color = Color.fromRGBO(211, 211, 211, 1);
    }
    if (this.selectedColor == null) {
      this.selectedColor = Color.fromRGBO(178, 178, 178, 1);
    }
  }
}

/// Class used to define all the [CategoryIcon] shown for each [Category]
///
/// This allows the keyboard to be personalized by changing icons shown.
/// If a [CategoryIcon] is set as null or not defined during initialization, the default icons will be used instead
class CategoryIcons {
  /// Icon for [Category.RECOMMENDED]
  CategoryIcon recommendationIcon;

  /// Icon for [Category.RECENT]
  CategoryIcon recentIcon;

  /// Icon for [Category.SMILEYS]
  CategoryIcon smileyIcon;

  /// Icon for [Category.ANIMALS]
  CategoryIcon animalIcon;

  /// Icon for [Category.FOODS]
  CategoryIcon foodIcon;

  /// Icon for [Category.TRAVEL]
  CategoryIcon travelIcon;

  /// Icon for [Category.ACTIVITIES]
  CategoryIcon activityIcon;

  /// Icon for [Category.OBJECTS]
  CategoryIcon objectIcon;

  /// Icon for [Category.SYMBOLS]
  CategoryIcon symbolIcon;

  /// Icon for [Category.FLAGS]
  CategoryIcon flagIcon;

  CategoryIcons(
      {this.recommendationIcon,
      this.recentIcon,
      this.smileyIcon,
      this.animalIcon,
      this.foodIcon,
      this.travelIcon,
      this.activityIcon,
      this.objectIcon,
      this.symbolIcon,
      this.flagIcon}) {
    if (recommendationIcon == null) {
      recommendationIcon = CategoryIcon(icon: Icons.search);
    }
    if (recentIcon == null) {
      recentIcon = CategoryIcon(icon: Icons.access_time);
    }
    if (smileyIcon == null) {
      smileyIcon = CategoryIcon(icon: Icons.tag_faces);
    }
    if (animalIcon == null) {
      animalIcon = CategoryIcon(icon: Icons.pets);
    }
    if (foodIcon == null) {
      foodIcon = CategoryIcon(icon: Icons.fastfood);
    }
    if (travelIcon == null) {
      travelIcon = CategoryIcon(icon: Icons.location_city);
    }
    if (activityIcon == null) {
      activityIcon = CategoryIcon(icon: Icons.directions_run);
    }
    if (objectIcon == null) {
      objectIcon = CategoryIcon(icon: Icons.lightbulb_outline);
    }
    if (symbolIcon == null) {
      symbolIcon = CategoryIcon(icon: Icons.euro_symbol);
    }
    if (flagIcon == null) {
      flagIcon = CategoryIcon(icon: Icons.flag);
    }
  }
}

/// A class to store data for each individual emoji
class Emoji {
  /// The name or description for this emoji
  final String name;

  /// The unicode string for this emoji
  ///
  /// This is the string that should be displayed to view the emoji
  final String emoji;

  Emoji({@required this.name, @required this.emoji});

  @override
  String toString() {
    return "Name: " + name + ", Emoji: " + emoji;
  }
}

class _EmojiPickerState extends State<EmojiPicker> {
  static const platform = const MethodChannel("emoji_picker");

  ValueNotifier<List<Widget>> pagesProvider = ValueNotifier<List<Widget>>([]);
  List<Widget> pages = <Widget>[];
  int recommendedPagesNum = 1;
  int recentPagesNum = 1;
  int smileyPagesNum = 1;
  int animalPagesNum = 1;
  int foodPagesNum = 1;
  int travelPagesNum = 1;
  int activityPagesNum = 1;
  int objectPagesNum = 1;
  int symbolPagesNum = 1;
  int flagPagesNum = 1;
  List<String> allNames = [];
  List<String> allEmojis = [];
  List<String> recentEmojis = [];

  Map<String, String> smileyMap = {};
  Map<String, String> animalMap = {};
  Map<String, String> foodMap = {};
  Map<String, String> travelMap = {};
  Map<String, String> activityMap = {};
  Map<String, String> objectMap = {};
  Map<String, String> symbolMap = {};
  Map<String, String> flagMap = {};
  Category selectedCategory;
  bool loaded = false;

  @override
  void initState() {
    selectedCategory = widget.selectedCategory;

    if (selectedCategory == null) {
      selectedCategory = Category.SMILEYS;
    } else if (widget.recommendKeywords == null && selectedCategory == Category.RECOMMENDED) {
      selectedCategory = Category.SMILEYS;
    }

    updateEmojis().then((_) {
      loaded = true;
    });
    super.initState();
  }

  Future<bool> _isEmojiAvailable(String emoji) async {
    if (Platform.isAndroid) {
      bool isAvailable;
      try {
        isAvailable = await platform.invokeMethod("isAvailable", {"emoji": emoji});
      } on PlatformException catch (_) {
        isAvailable = false;
      }
      return isAvailable;
    } else {
      return true;
    }
  }

  Future<List<String>> getRecentEmojis() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final key = "recents";
    recentEmojis = prefs.getStringList(key) ?? new List();
    return recentEmojis;
  }

  void addRecentEmoji(Emoji emoji) async {
    final prefs = await SharedPreferences.getInstance();
    final key = "recents";
    getRecentEmojis().then((_) {
      //print("adding emoji");
      recentEmojis.insert(0, emoji.name);
      prefs.setStringList(key, recentEmojis);

      pages.removeAt(recommendedPagesNum);
      pages.insert(recommendedPagesNum, recentPage());
      // need use toList making a copy
      pagesProvider.value = pages.toList();
    });
  }

  Future<Map<String, String>> getAvailableEmojis(Map<String, String> map) async {
    Map<String, String> newMap = Map<String, String>();

    for (String key in map.keys) {
      bool isAvailable = await _isEmojiAvailable(map[key]);
      if (isAvailable) {
        newMap[key] = map[key];
      }
    }

    return newMap;
  }

  Widget _emojiIcon(String emojiTxt, Function onSelected) {
    switch (widget.buttonMode) {
      case ButtonMode.MATERIAL:
        return Center(
            child: FlatButton(
                padding: EdgeInsets.all(0),
                child: Center(
                  child: Text(
                    emojiTxt,
                    style: TextStyle(fontSize: 24),
                  ),
                ),
                onPressed: onSelected
                //   widget.onEmojiSelected(emoji, selectedCategory);
                // },
                ));
        break;
      case ButtonMode.CUPERTINO:
        return Center(
            child: CupertinoButton(
                pressedOpacity: 0.4,
                padding: EdgeInsets.all(0),
                child: Center(
                  child: Text(
                    emojiTxt,
                    style: TextStyle(fontSize: 24),
                  ),
                ),
                onPressed: onSelected
                //   widget.onEmojiSelected(emoji, selectedCategory);
                // },
                ));
        break;
      default:
        return Container();
    }
  }

  Future<Map<String, String>> getEmojis(
    Map<String, String> defines,
    Function(List<Widget>) items,
  ) async {
    final avalidMap = await getAvailableEmojis(defines);
    allNames.addAll(avalidMap.keys);
    allEmojis.addAll(avalidMap.values);

    var pagesNum = (avalidMap.values.toList().length / (widget.rows * widget.columns)).ceil();

    List<Widget> avalidPages = [];

    final keyList = avalidMap.keys.toList();
    final valueList = avalidMap.values.toList();

    for (var i = 0; i < pagesNum; i++) {
      avalidPages.add(Container(
        key: Key("pkmj_${avalidMap.keys.first}_$i"),
        color: widget.bgColor,
        child: GridView.count(
          childAspectRatio: 1.3,
          shrinkWrap: true,
          primary: true,
          crossAxisCount: widget.columns,
          children: List.generate(widget.rows * widget.columns, (index) {
            if (index + (widget.columns * widget.rows * i) < valueList.length) {
              String emojiTxt = valueList[index + (widget.columns * widget.rows * i)];
              return _emojiIcon(emojiTxt, () {
                var emoji = Emoji(
                  name: keyList[index + (widget.columns * widget.rows * i)],
                  emoji: valueList[index + (widget.columns * widget.rows * i)],
                );
                widget.onEmojiSelected(emoji, selectedCategory);
                addRecentEmoji(emoji);
              });
            } else {
              return Container();
            }
          }),
        ),
      ));
    }

    items(avalidPages);
    return avalidMap;
  }

  Future<List<Widget>> _getRecommentPages(List<String> recommends) async {
    recommendedPagesNum = 0;
    List<_Recommended> recommendedEmojis = new List();
    List<Widget> recommendedPages = new List();
    if (recommends != null) {
      allNames.forEach((name) {
        int numSplitEqualKeyword = 0;
        int numSplitPartialKeyword = 0;

        recommends.forEach((keyword) {
          if (name.toLowerCase() == keyword.toLowerCase()) {
            recommendedEmojis.add(_Recommended(name: name, emoji: allEmojis[allNames.indexOf(name)], tier: 1));
          } else {
            List<String> splitName = name.split(" ");

            splitName.forEach((splitName) {
              if (splitName.replaceAll(":", "").toLowerCase() == keyword.toLowerCase()) {
                numSplitEqualKeyword += 1;
              } else if (splitName.replaceAll(":", "").toLowerCase().contains(keyword.toLowerCase())) {
                numSplitPartialKeyword += 1;
              }
            });
          }
        });

        if (numSplitEqualKeyword > 0) {
          if (numSplitEqualKeyword == name.split(" ").length) {
            recommendedEmojis.add(_Recommended(name: name, emoji: allEmojis[allNames.indexOf(name)], tier: 1));
          } else {
            recommendedEmojis.add(_Recommended(
                name: name,
                emoji: allEmojis[allNames.indexOf(name)],
                tier: 2,
                numSplitEqualKeyword: numSplitEqualKeyword,
                numSplitPartialKeyword: numSplitPartialKeyword));
          }
        } else if (numSplitPartialKeyword > 0) {
          recommendedEmojis.add(_Recommended(
              name: name,
              emoji: allEmojis[allNames.indexOf(name)],
              tier: 3,
              numSplitPartialKeyword: numSplitPartialKeyword));
        }
      });

      recommendedEmojis.sort((a, b) {
        if (a.tier < b.tier) {
          return -1;
        } else if (a.tier > b.tier) {
          return 1;
        } else {
          if (a.tier == 1) {
            if (a.name.split(" ").length > b.name.split(" ").length) {
              return -1;
            } else if (a.name.split(" ").length < b.name.split(" ").length) {
              return 1;
            } else {
              return 0;
            }
          } else if (a.tier == 2) {
            if (a.numSplitEqualKeyword > b.numSplitEqualKeyword) {
              return -1;
            } else if (a.numSplitEqualKeyword < b.numSplitEqualKeyword) {
              return 1;
            } else {
              if (a.numSplitPartialKeyword > b.numSplitPartialKeyword) {
                return -1;
              } else if (a.numSplitPartialKeyword < b.numSplitPartialKeyword) {
                return 1;
              } else {
                if (a.name.split(" ").length < b.name.split(" ").length) {
                  return -1;
                } else if (a.name.split(" ").length > b.name.split(" ").length) {
                  return 1;
                } else {
                  return 0;
                }
              }
            }
          } else if (a.tier == 3) {
            if (a.numSplitPartialKeyword > b.numSplitPartialKeyword) {
              return -1;
            } else if (a.numSplitPartialKeyword < b.numSplitPartialKeyword) {
              return 1;
            } else {
              return 0;
            }
          }
        }

        return 0;
      });

      if (recommendedEmojis.length > widget.numRecommended) {
        recommendedEmojis = recommendedEmojis.getRange(0, widget.numRecommended).toList();
      }
      //print("reocmmend items: ${recommendedEmojis.length}");
      if (recommendedEmojis.length != 0) {
        recommendedPagesNum = (recommendedEmojis.length / (widget.rows * widget.columns)).ceil();

        for (var i = 0; i < recommendedPagesNum; i++) {
          recommendedPages.add(Container(
            color: widget.bgColor,
            child: GridView.count(
              shrinkWrap: true,
              primary: true,
              crossAxisCount: widget.columns,
              children: List.generate(widget.rows * widget.columns, (index) {
                if (index + (widget.columns * widget.rows * i) < recommendedEmojis.length) {
                  var emojiTxt = recommendedEmojis[index + (widget.columns * widget.rows * i)].emoji;

                  return _emojiIcon(emojiTxt, () {
                    _Recommended recommended = recommendedEmojis[index + (widget.columns * widget.rows * i)];
                    var emoji = Emoji(name: recommended.name, emoji: recommended.emoji);
                    widget.onEmojiSelected(emoji, selectedCategory);
                    addRecentEmoji(emoji);
                  });
                } else {
                  return Container();
                }
              }),
            ),
          ));
        }
      } else {
        // not found
        recommendedPagesNum = 1;

        recommendedPages.add(Container(
            color: widget.bgColor,
            child: Center(
                child: Text(
              widget.noRecommendationsText,
              style: widget.noRecommendationsStyle,
            ))));
      }
    } else {
      // no search string
      recommendedPagesNum = 1;

      recommendedPages.add(Container(
          color: widget.bgColor,
          child: Center(
              child: Text(
            widget.noRecommendationsText,
            style: widget.noRecommendationsStyle,
          ))));
    }
    return recommendedPages;
  }

  Future updateEmojis() async {
    if (widget.enableRecommend) {
      final recommendedPages = await _getRecommentPages(null);
      pages.addAll(recommendedPages); // 1 emtpy, try lastest
      pagesProvider.value = pages;
    } else {
      recommendedPagesNum = 0;
    }

    if (widget.enableRecent) {
      recentPagesNum = 1;
      pages.add(recentPage());
      pagesProvider.value = pages;
    } else {
      recentPagesNum = 0;
    }

    smileyMap = await getEmojis(emojiList.smileys, (items) {
      smileyPagesNum = items.length;
      pages.addAll(items);
      pagesProvider.value = pages;
    });
    animalMap = await getEmojis(emojiList.animals, (items) {
      animalPagesNum = items.length;
      pages.addAll(items);
      pagesProvider.value = pages;
    });

    foodMap = await getEmojis(emojiList.foods, (items) {
      foodPagesNum = items.length;
      pages.addAll(items);
      pagesProvider.value = pages;
    });

    travelMap = await getEmojis(emojiList.travel, (items) {
      travelPagesNum = items.length;
      pages.addAll(items);
      pagesProvider.value = pages;
    });

    activityMap = await getEmojis(emojiList.activities, (items) {
      activityPagesNum = items.length;
      pages.addAll(items);
      pagesProvider.value = pages;
    });
    objectMap = await getEmojis(emojiList.objects, (items) {
      objectPagesNum = items.length;
      pages.addAll(items);
      pagesProvider.value = pages;
    });
    symbolMap = await getEmojis(emojiList.symbols, (items) {
      symbolPagesNum = items.length;
      pages.addAll(items);
      pagesProvider.value = pages;
    });
    flagMap = await getEmojis(emojiList.flags, (items) {
      flagPagesNum = items.length;
      pages.addAll(items);
      pagesProvider.value = pages;
    });

    if (widget.enableRecommend) {
      final preNum = recommendedPagesNum;
      final recommendedPages2 = await _getRecommentPages(widget.recommendKeywords);
      pages.removeRange(0, preNum);
      pages.insertAll(0, recommendedPages2);
      // need use toList making a copy
      pagesProvider.value = pages.toList();
    } else {
      recommendedPagesNum = 0;
    }

    if (widget.enableRecent) {
      getRecentEmojis().then((_) {
        pages.removeAt(recommendedPagesNum);
        pages.insert(recommendedPagesNum, recentPage());
        // need use toList making a copy
        pagesProvider.value = pages.toList();
      });
    } else {
      recentPagesNum = 0;
    }
  }

  Widget recentPage() {
    if (recentEmojis.length != 0) {
      return Container(
          color: widget.bgColor,
          child: GridView.count(
            shrinkWrap: true,
            primary: true,
            crossAxisCount: widget.columns,
            children: List.generate(widget.rows * widget.columns, (index) {
              if (index < recentEmojis.length) {
                var emojiTxt = allEmojis[allNames.indexOf(recentEmojis[index])];
                return _emojiIcon(emojiTxt, () {
                  String emojiName = recentEmojis[index];
                  widget.onEmojiSelected(
                      Emoji(name: emojiName, emoji: allEmojis[allNames.indexOf(emojiName)]), selectedCategory);
                });
              } else {
                return Container();
              }
            }),
          ));
    } else {
      return Container(
          color: widget.bgColor,
          child: Center(
              child: Text(
            widget.noRecentsText,
            style: widget.noRecentsStyle,
          )));
    }
  }

  Widget defaultButton(CategoryIcon categoryIcon) {
    return SizedBox(
      width: MediaQuery.of(context).size.width / (widget.recommendKeywords == null ? 9 : 10),
      height: MediaQuery.of(context).size.width / (widget.recommendKeywords == null ? 9 : 10),
      child: Container(
        color: widget.bgColor,
        child: Center(
          child: Icon(
            categoryIcon.icon,
            size: 22,
            color: categoryIcon.color,
          ),
        ),
      ),
    );
  }

  PageController pageController;

  int _pageIndex(Category category) {
    // make page could be custom
    // Num == 1 => enabled page
    var pageToIndex = {
      Category.RECOMMENDED: 0,
      Category.RECENT: recommendedPagesNum,
      Category.SMILEYS: recentPagesNum + recommendedPagesNum,
      Category.ANIMALS: smileyPagesNum + recentPagesNum + recommendedPagesNum,
      Category.FOODS: smileyPagesNum + animalPagesNum + recentPagesNum + recommendedPagesNum,
      Category.TRAVEL: smileyPagesNum + animalPagesNum + foodPagesNum + recentPagesNum + recommendedPagesNum,
      Category.ACTIVITIES:
          smileyPagesNum + animalPagesNum + foodPagesNum + travelPagesNum + recentPagesNum + recommendedPagesNum,
      Category.OBJECTS: smileyPagesNum +
          animalPagesNum +
          foodPagesNum +
          travelPagesNum +
          activityPagesNum +
          recentPagesNum +
          recommendedPagesNum,
      Category.SYMBOLS: smileyPagesNum +
          animalPagesNum +
          foodPagesNum +
          travelPagesNum +
          activityPagesNum +
          objectPagesNum +
          recentPagesNum +
          recommendedPagesNum,
      Category.FLAGS: smileyPagesNum +
          animalPagesNum +
          foodPagesNum +
          travelPagesNum +
          activityPagesNum +
          objectPagesNum +
          symbolPagesNum +
          recentPagesNum +
          recommendedPagesNum
    };

    return pageToIndex[category];
  }

  void _makePageController() {
    if (pageController != null) {
      pageController.dispose();
    }

    pageController = PageController(initialPage: _pageIndex(selectedCategory));

    // pageController.addListener(() {
    //   setState(() {});
    // });
  }

  @override
  Widget build(BuildContext context) {
    if (true) {
      // update with latest chaged
      // if (widget.enableRecent) {
      //   pages.removeAt(recommendedPagesNum);
      //   pages.insert(recommendedPagesNum, recentPage());
      // }

      return LayoutBuilder(builder: (context, constrains) {
        final fullWidth = MediaQuery.of(context).size.width;
        final fullHeight = (MediaQuery.of(context).size.width / widget.columns) * widget.rows;

        return ChangeNotifierProvider.value(
          value: pagesProvider,
          child: Consumer<ValueNotifier<List<Widget>>>(
            builder: (ctx, value, w) {
              _makePageController();
              //print("page rebuild");
              return Column(
                children: <Widget>[
                  SizedBox(
                    height: min(fullHeight, constrains.maxHeight - 40),
                    width: min(fullWidth, constrains.maxWidth),
                    child: PageView(
                      children: value.value,
                      controller: pageController,
                      onPageChanged: (index) {
                        // print("page changed $index");
                        if (widget.enableRecommend && widget.recommendKeywords != null && index < recommendedPagesNum) {
                          selectedCategory = Category.RECOMMENDED;
                        } else if (widget.enableRecent && index < recentPagesNum + recommendedPagesNum) {
                          selectedCategory = Category.RECENT;
                        } else if (index < recentPagesNum + smileyPagesNum + recommendedPagesNum) {
                          selectedCategory = Category.SMILEYS;
                        } else if (index < recentPagesNum + smileyPagesNum + animalPagesNum + recommendedPagesNum) {
                          selectedCategory = Category.ANIMALS;
                        } else if (index <
                            recentPagesNum + smileyPagesNum + animalPagesNum + foodPagesNum + recommendedPagesNum) {
                          selectedCategory = Category.FOODS;
                        } else if (index <
                            recentPagesNum +
                                smileyPagesNum +
                                animalPagesNum +
                                foodPagesNum +
                                travelPagesNum +
                                recommendedPagesNum) {
                          selectedCategory = Category.TRAVEL;
                        } else if (index <
                            recentPagesNum +
                                smileyPagesNum +
                                animalPagesNum +
                                foodPagesNum +
                                travelPagesNum +
                                activityPagesNum +
                                recommendedPagesNum) {
                          selectedCategory = Category.ACTIVITIES;
                        } else if (index <
                            recentPagesNum +
                                smileyPagesNum +
                                animalPagesNum +
                                foodPagesNum +
                                travelPagesNum +
                                activityPagesNum +
                                objectPagesNum +
                                recommendedPagesNum) {
                          selectedCategory = Category.OBJECTS;
                        } else if (index <
                            recentPagesNum +
                                smileyPagesNum +
                                animalPagesNum +
                                foodPagesNum +
                                travelPagesNum +
                                activityPagesNum +
                                objectPagesNum +
                                symbolPagesNum +
                                recommendedPagesNum) {
                          selectedCategory = Category.SYMBOLS;
                        } else {
                          selectedCategory = Category.FLAGS;
                        }
                        setState(() {});
                      },
                    ),
                  ),
                  Container(
                      color: widget.bgColor,
                      height: 6,
                      width: MediaQuery.of(context).size.width,
                      padding: EdgeInsets.only(top: 4, bottom: 0, right: 2, left: 2),
                      child: CustomPaint(
                        painter: _ProgressPainter(
                            context,
                            pageController,
                            Map.fromIterables([
                              Category.RECOMMENDED,
                              Category.RECENT,
                              Category.SMILEYS,
                              Category.ANIMALS,
                              Category.FOODS,
                              Category.TRAVEL,
                              Category.ACTIVITIES,
                              Category.OBJECTS,
                              Category.SYMBOLS,
                              Category.FLAGS
                            ], [
                              recommendedPagesNum,
                              recentPagesNum,
                              smileyPagesNum,
                              animalPagesNum,
                              foodPagesNum,
                              travelPagesNum,
                              activityPagesNum,
                              objectPagesNum,
                              symbolPagesNum,
                              flagPagesNum
                            ]),
                            selectedCategory,
                            widget.indicatorColor),
                      )),
                  // 下方類別
                  Container(
                    height: 30,
                    color: widget.bgColor,
                    child: Row(
                      children: () {
                        var ret = <Widget>[
                          // widget.recommendKeywords != null
                          //     ? _catgoryButton(Category.RECOMMENDED, widget.categoryIcons.recommendationIcon)
                          //     : Container(),
                          // _catgoryButton(Category.RECENT, widget.categoryIcons.recentIcon),
                          _catgoryButton(Category.SMILEYS, widget.categoryIcons.smileyIcon),
                          _catgoryButton(Category.ANIMALS, widget.categoryIcons.animalIcon),
                          _catgoryButton(Category.FOODS, widget.categoryIcons.foodIcon),
                          _catgoryButton(Category.TRAVEL, widget.categoryIcons.travelIcon),
                          _catgoryButton(Category.ACTIVITIES, widget.categoryIcons.activityIcon),
                          _catgoryButton(Category.OBJECTS, widget.categoryIcons.objectIcon),
                          _catgoryButton(Category.SYMBOLS, widget.categoryIcons.symbolIcon),
                          _catgoryButton(Category.FLAGS, widget.categoryIcons.flagIcon),
                        ];
                        if (widget.enableRecent) {
                          ret.insert(
                            0,
                            _catgoryButton(Category.RECENT, widget.categoryIcons.recentIcon),
                          );
                        }
                        if (widget.enableRecommend) {
                          ret.insert(0, _catgoryButton(Category.RECOMMENDED, widget.categoryIcons.recommendationIcon));
                        }
                        return ret;
                      }(),
                    ),
                  )
                ],
              );
            },
          ),
        );
      });
    } else {
      // loading
      return Column(
        children: <Widget>[
          SizedBox(
            height: (MediaQuery.of(context).size.width / widget.columns) * widget.rows,
            width: MediaQuery.of(context).size.width,
            child: Container(
              color: widget.bgColor,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
          Container(
            height: 6,
            width: MediaQuery.of(context).size.width,
            color: widget.bgColor,
            padding: EdgeInsets.only(top: 4, left: 2, right: 2),
            child: Container(
              color: widget.indicatorColor,
            ),
          ),
          Container(
            height: 50,
            child: Row(
              children: <Widget>[
                widget.recommendKeywords != null ? defaultButton(widget.categoryIcons.recommendationIcon) : Container(),
                defaultButton(widget.categoryIcons.recentIcon),
                defaultButton(widget.categoryIcons.smileyIcon),
                defaultButton(widget.categoryIcons.animalIcon),
                defaultButton(widget.categoryIcons.foodIcon),
                defaultButton(widget.categoryIcons.travelIcon),
                defaultButton(widget.categoryIcons.activityIcon),
                defaultButton(widget.categoryIcons.objectIcon),
                defaultButton(widget.categoryIcons.symbolIcon),
                defaultButton(widget.categoryIcons.flagIcon),
              ],
            ),
          )
        ],
      );
    }
  }

  Widget _catgoryButton(Category category, CategoryIcon icon) {
    return SizedBox(
      width: MediaQuery.of(context).size.width / (widget.recommendKeywords == null ? 9 : 10),
      height: MediaQuery.of(context).size.width / (widget.recommendKeywords == null ? 9 : 10),
      child: widget.buttonMode == ButtonMode.MATERIAL
          ? FlatButton(
              padding: EdgeInsets.all(0),
              color: selectedCategory == category ? Colors.black12 : Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(0))),
              child: Center(
                child: Icon(
                  icon.icon,
                  size: 22,
                  color: selectedCategory == category ? icon.selectedColor : icon.color,
                ),
              ),
              onPressed: () {
                if (selectedCategory == category) {
                  return;
                }

                pageController.jumpToPage(_pageIndex(category));
              },
            )
          : CupertinoButton(
              pressedOpacity: 0.4,
              padding: EdgeInsets.all(0),
              color: selectedCategory == category ? Colors.black12 : Colors.transparent,
              borderRadius: BorderRadius.all(Radius.circular(0)),
              child: Center(
                child: Icon(
                  icon.icon,
                  size: 22,
                  color: selectedCategory == category ? icon.selectedColor : icon.color,
                ),
              ),
              onPressed: () {
                if (selectedCategory == category) {
                  return;
                }
                final jumpTo = _pageIndex(category);
                pageController.jumpToPage(jumpTo);
              },
            ),
    );
  }
}

class _ProgressPainter extends CustomPainter {
  final BuildContext context;
  final PageController pageController;
  final Map<Category, int> pages;
  final Category selectedCategory;
  final Color indicatorColor;

  _ProgressPainter(this.context, this.pageController, this.pages, this.selectedCategory, this.indicatorColor);

  @override
  void paint(Canvas canvas, Size size) {
    double actualPageWidth = MediaQuery.of(context).size.width;
    double offsetInPages = 0;
    if (selectedCategory == Category.RECOMMENDED) {
      offsetInPages = pageController.offset / actualPageWidth;
    } else if (selectedCategory == Category.RECENT) {
      offsetInPages = (pageController.offset - (pages[Category.RECOMMENDED] * actualPageWidth)) / actualPageWidth;
    } else if (selectedCategory == Category.SMILEYS) {
      offsetInPages =
          (pageController.offset - ((pages[Category.RECOMMENDED] + pages[Category.RECENT]) * actualPageWidth)) /
              actualPageWidth;
    } else if (selectedCategory == Category.ANIMALS) {
      offsetInPages = (pageController.offset -
              ((pages[Category.RECOMMENDED] + pages[Category.RECENT] + pages[Category.SMILEYS]) * actualPageWidth)) /
          actualPageWidth;
    } else if (selectedCategory == Category.FOODS) {
      offsetInPages = (pageController.offset -
              ((pages[Category.RECOMMENDED] +
                      pages[Category.RECENT] +
                      pages[Category.SMILEYS] +
                      pages[Category.ANIMALS]) *
                  actualPageWidth)) /
          actualPageWidth;
    } else if (selectedCategory == Category.TRAVEL) {
      offsetInPages = (pageController.offset -
              ((pages[Category.RECOMMENDED] +
                      pages[Category.RECENT] +
                      pages[Category.SMILEYS] +
                      pages[Category.ANIMALS] +
                      pages[Category.FOODS]) *
                  actualPageWidth)) /
          actualPageWidth;
    } else if (selectedCategory == Category.ACTIVITIES) {
      offsetInPages = (pageController.offset -
              ((pages[Category.RECOMMENDED] +
                      pages[Category.RECENT] +
                      pages[Category.SMILEYS] +
                      pages[Category.ANIMALS] +
                      pages[Category.FOODS] +
                      pages[Category.TRAVEL]) *
                  actualPageWidth)) /
          actualPageWidth;
    } else if (selectedCategory == Category.OBJECTS) {
      offsetInPages = (pageController.offset -
              ((pages[Category.RECOMMENDED] +
                      pages[Category.RECENT] +
                      pages[Category.SMILEYS] +
                      pages[Category.ANIMALS] +
                      pages[Category.FOODS] +
                      pages[Category.TRAVEL] +
                      pages[Category.ACTIVITIES]) *
                  actualPageWidth)) /
          actualPageWidth;
    } else if (selectedCategory == Category.SYMBOLS) {
      offsetInPages = (pageController.offset -
              ((pages[Category.RECOMMENDED] +
                      pages[Category.RECENT] +
                      pages[Category.SMILEYS] +
                      pages[Category.ANIMALS] +
                      pages[Category.FOODS] +
                      pages[Category.TRAVEL] +
                      pages[Category.ACTIVITIES] +
                      pages[Category.OBJECTS]) *
                  actualPageWidth)) /
          actualPageWidth;
    } else if (selectedCategory == Category.FLAGS) {
      offsetInPages = (pageController.offset -
              ((pages[Category.RECOMMENDED] +
                      pages[Category.RECENT] +
                      pages[Category.SMILEYS] +
                      pages[Category.ANIMALS] +
                      pages[Category.FOODS] +
                      pages[Category.TRAVEL] +
                      pages[Category.ACTIVITIES] +
                      pages[Category.OBJECTS] +
                      pages[Category.SYMBOLS]) *
                  actualPageWidth)) /
          actualPageWidth;
    }
    double indicatorPageWidth = size.width / (pages[selectedCategory] <= 0 ? 1 : pages[selectedCategory]);

    Rect bgRect = Offset(0, 0) & size;

    Rect indicator = Offset(max(0, offsetInPages * indicatorPageWidth), 0) &
        Size(
            indicatorPageWidth -
                max(0, (indicatorPageWidth + (offsetInPages * indicatorPageWidth)) - size.width) +
                min(0, offsetInPages * indicatorPageWidth),
            size.height);

    canvas.drawRect(bgRect, Paint()..color = Colors.black12);
    canvas.drawRect(indicator, Paint()..color = indicatorColor);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
