library emoji_picker;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'dart:math';
import '../emoji_lists.dart' as emojiList;

import 'package:shared_preferences/shared_preferences.dart';

import 'category_icon.dart';

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

enum ScrollType {
  SCROLL_CATEGORY,
  SCROLL_HORIZONTAL,
  SCROLL_VERTICAL,
}

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
  final ValueNotifier<List<String>> recommendKeywords;

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
  final ButtonMode buttonMode;

  /// size of icon
  final double iconSize;

  /// grid factor
  final double gridFactor;

  final ScrollType scollType;

  EmojiPicker({
    Key key,
    @required this.onEmojiSelected,
    this.columns = 7,
    this.rows = 3,
    this.selectedCategory,
    this.gridFactor = 1.3,
    this.iconSize = 24,
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
    this.scollType,
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

class _EmojiPickerState extends State<EmojiPicker> with SingleTickerProviderStateMixin {
  static const platform = const MethodChannel("emoji_picker");
  static const double CATEGORY_BUTTON_HEIGHT = 30;

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

  List<Widget> _categoryTabs = [];
  List<Category> _categoryList = [];
  TabController _categoryTabController;
  List<Widget> scrollableItems = [];

  @override
  void initState() {
    selectedCategory = widget.selectedCategory;

    if (selectedCategory == null) {
      selectedCategory = Category.SMILEYS;
    } else if (widget.recommendKeywords == null && selectedCategory == Category.RECOMMENDED) {
      selectedCategory = Category.SMILEYS;
    }

    widget.recommendKeywords.addListener(_recommendChanged);

    _createTabBar();
    updateEmojis().then((_) {
      loaded = true;
    });
    super.initState();
  }

  @override
  void dispose() {
    delayTimer?.cancel();
    super.dispose();
  }

  void _createTabBar() {
    _categoryTabs = [];
    _categoryList = [];
    if (widget.enableRecent) {
      _categoryTabs.add(
        _tabBarButton(
          Category.RECENT,
          widget.categoryIcons.recentIcon,
        ),
      );
      _categoryList.add(Category.RECENT);
    }
    if (widget.enableRecommend) {
      _categoryTabs.add(
        _tabBarButton(
          Category.RECOMMENDED,
          widget.categoryIcons.recommendationIcon,
        ),
      );
      _categoryList.add(Category.RECOMMENDED);
    }
    _categoryList.addAll([
      Category.SMILEYS,
      Category.ANIMALS,
      Category.FOODS,
      Category.TRAVEL,
      Category.ACTIVITIES,
      Category.OBJECTS,
      Category.SYMBOLS,
      Category.FLAGS
    ]);
    _categoryTabs.addAll([
      _tabBarButton(Category.SMILEYS, widget.categoryIcons.smileyIcon),
      _tabBarButton(Category.ANIMALS, widget.categoryIcons.animalIcon),
      _tabBarButton(Category.FOODS, widget.categoryIcons.foodIcon),
      _tabBarButton(Category.TRAVEL, widget.categoryIcons.travelIcon),
      _tabBarButton(Category.ACTIVITIES, widget.categoryIcons.activityIcon),
      _tabBarButton(Category.OBJECTS, widget.categoryIcons.objectIcon),
      _tabBarButton(Category.SYMBOLS, widget.categoryIcons.symbolIcon),
      _tabBarButton(Category.FLAGS, widget.categoryIcons.flagIcon),
    ]);

    if (_categoryTabController == null) {
      _categoryTabController = TabController(length: _categoryTabs.length, vsync: this);
    }
    itemPositionsListener.itemPositions.addListener(() {
      if (itemPositionsListener.itemPositions.value.isNotEmpty) {
        final indexList = itemPositionsListener.itemPositions.value.map((e) => e.index);
        final maxIndex = indexList.reduce(max);
        final _ = indexList.reduce(min);

        _categoryTabController.animateTo(maxIndex);
      }
    });
  }

  static const RecommendChangeDelayTime = 500;
  Timer delayTimer;

  void _recommendChanged() async {
    delayTimer?.cancel();
    delayTimer = Timer.periodic(
      Duration(milliseconds: RecommendChangeDelayTime),
      (timer) async {
        final preNum = recommendedPagesNum;
        final recommendedPages2 = await _getRecommentPages(widget.recommendKeywords.value);
        pages.removeRange(0, preNum);
        pages.insertAll(0, recommendedPages2);
        // need use toList making a copy
        pagesProvider.value = pages.toList();
      },
    );
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
    if (widget.enableRecent == false) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final key = "recents";
    getRecentEmojis().then((_) {
      //print("adding emoji");
      recentEmojis.removeWhere((element) => element == emoji.name);
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
                    style: TextStyle(fontSize: widget.iconSize),
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
          onPressed: onSelected,
          child: Container(
            //pressedOpacity: 0.4,
            padding: EdgeInsets.all(0),
            color: widget.bgColor,
            child: Center(
              child: Text(
                emojiTxt,
                style: TextStyle(fontSize: 24),
              ),
            ),
            //onPressed: onSelected
            //   widget.onEmojiSelected(emoji, selectedCategory);
            // },
          ),
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
          childAspectRatio: widget.gridFactor,
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

  List<Widget> _getRecommentPages(
    List<String> recommends, {
    Function(List<_Recommended>) searchResult,
  }) {
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
      if (searchResult != null) {
        searchResult(recommendedEmojis);
      }

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
      //scrollableItems.add(scrollableItems[0]);
      scrollableItems.add(Container());
    } else {
      recommendedPagesNum = 0;
    }

    if (widget.enableRecent) {
      recentPagesNum = 1;
      pages.add(recentPage());
      // scrollableItems.add(recentPage());
      pagesProvider.value = pages;
      scrollableItems.add(Container());
    } else {
      recentPagesNum = 0;
    }

    smileyMap = await getEmojis(emojiList.smileys, (items) {
      smileyPagesNum = items.length;
      pages.addAll(items);
      pagesProvider.value = pages;
    });
    scrollableItems.add(_gridCategory(smileyMap, name: "emoji_smile"));

    animalMap = await getEmojis(emojiList.animals, (items) {
      animalPagesNum = items.length;
      pages.addAll(items);
      pagesProvider.value = pages;
    });
    scrollableItems.add(_gridCategory(animalMap, name: "emoji_animal"));

    foodMap = await getEmojis(emojiList.foods, (items) {
      foodPagesNum = items.length;
      pages.addAll(items);
      pagesProvider.value = pages;
    });
    scrollableItems.add(_gridCategory(foodMap, name: "emoji_food"));

    travelMap = await getEmojis(emojiList.travel, (items) {
      travelPagesNum = items.length;
      pages.addAll(items);
      pagesProvider.value = pages;
    });
    scrollableItems.add(_gridCategory(travelMap, name: "emoji_travel"));

    activityMap = await getEmojis(emojiList.activities, (items) {
      activityPagesNum = items.length;
      pages.addAll(items);
      pagesProvider.value = pages;
    });
    scrollableItems.add(_gridCategory(activityMap, name: "emoji_activity"));

    objectMap = await getEmojis(emojiList.objects, (items) {
      objectPagesNum = items.length;
      pages.addAll(items);
      pagesProvider.value = pages;
    });
    scrollableItems.add(_gridCategory(objectMap, name: "emoji_object"));

    symbolMap = await getEmojis(emojiList.symbols, (items) {
      symbolPagesNum = items.length;
      pages.addAll(items);
      pagesProvider.value = pages;
    });
    scrollableItems.add(_gridCategory(symbolMap, name: "emoji_symbol"));

    flagMap = await getEmojis(emojiList.flags, (items) {
      flagPagesNum = items.length;
      pages.addAll(items);
      pagesProvider.value = pages;
    });
    scrollableItems.add(_gridCategory(flagMap, name: "emojy_flag"));

    if (widget.enableRecommend) {
      final preNum = recommendedPagesNum;
      final recommendedPages2 = _getRecommentPages(widget.recommendKeywords.value);
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

  Widget _gridCategory(Map<String, String> itemMap, {String name}) {
    final items = itemMap.values.toList();
    final keyList = itemMap.keys.toList();
    return Container(
      key: name != null ? Key(name) : null,
      color: widget.bgColor,
      child: GridView.count(
        children: List.generate(items.length, (index) {
          String emojiTxt = items[index];
          return _emojiIcon(emojiTxt, () {
            var emoji = Emoji(
              name: keyList[index],
              emoji: items[index],
            );
            widget.onEmojiSelected(emoji, selectedCategory);
            addRecentEmoji(emoji);
          });
        }),
        shrinkWrap: true,
        scrollDirection: Axis.vertical,
        crossAxisCount: widget.columns,
        physics: ClampingScrollPhysics(),
      ),
    );
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

  Widget mainPanel(List<Widget> items) {
    return PageView(
      children: items,
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
        } else if (index < recentPagesNum + smileyPagesNum + animalPagesNum + foodPagesNum + recommendedPagesNum) {
          selectedCategory = Category.FOODS;
        } else if (index <
            recentPagesNum + smileyPagesNum + animalPagesNum + foodPagesNum + travelPagesNum + recommendedPagesNum) {
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
        _categoryTabController.animateTo(_categoryList.indexOf(selectedCategory));

        setState(() {});
      },
    );
  }

  ItemScrollController scrollListController = ItemScrollController();
  ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();

  Widget scrollableMainPanel() {
    if (selectedCategory == Category.RECOMMENDED) {
      // search / recommended
      Widget ret;
      _getRecommentPages(widget.recommendKeywords.value, searchResult: (recommendedEmojis) {
        final emojiMap = <String, String>{};
        for (var obj in recommendedEmojis) {
          emojiMap[obj.name] = obj.emoji;
        }
        ret = _gridCategory(emojiMap, name: "emoji_search");
      });
      return ret;
    } else if (selectedCategory == Category.RECENT) {
      return recentPage();
    }

    return ScrollablePositionedList.builder(
      itemCount: scrollableItems.length,
      itemScrollController: scrollListController,
      itemPositionsListener: itemPositionsListener,
      itemBuilder: (context, index) {
        if ([Category.RECENT, Category.RECOMMENDED].contains(_categoryList[index])) {
          return Container();
        }
        return Container(
          color: widget.bgColor,
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 1,
                    child: Divider(color: Colors.grey),
                  ),
                  Icon(
                    widget.categoryIcons[_categoryList[index]].icon,
                    color: Colors.white,
                  ),
                  Expanded(flex: 8, child: Divider(color: Colors.grey)),
                ],
              ),
              scrollableItems[index],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constrains) {
      final fullWidth = MediaQuery.of(context).size.width;
      final fullHeight = (MediaQuery.of(context).size.width / widget.columns) * widget.rows;

      return ChangeNotifierProvider.value(
        value: pagesProvider,
        child: Consumer<ValueNotifier<List<Widget>>>(
          builder: (ctx, value, w) {
            if (value.value.isEmpty) {
              return _loadingPage();
            }
            _makePageController();
            //print("page rebuild");
            return Column(
              children: <Widget>[
                SizedBox(
                    height: min(fullHeight, constrains.maxHeight - CATEGORY_BUTTON_HEIGHT),
                    width: min(fullWidth, constrains.maxWidth),
                    //child: mainPanel(value.value)
                    child: scrollableMainPanel()),
                //_progressBar(),
                _categoryButtons()
              ],
            );
          },
        ),
      );
    });
  }

  Widget _progressBar() {
    return Container(
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
        ));
  }

  Widget _categoryButtons() {
    Category _indexToCategory(int index) {
      return _categoryList[index];
    }

    return TabBar(
      tabs: _categoryTabs,
      indicatorSize: TabBarIndicatorSize.tab,
      unselectedLabelColor: Colors.white,
      controller: _categoryTabController,
      labelPadding: EdgeInsets.symmetric(vertical: 5),
      onTap: (index) {
        final newCategory = _indexToCategory(index);
        if (selectedCategory != newCategory) {
          bool needRefresh = false;
          final oldSelection = selectedCategory;
          selectedCategory = newCategory;

          //pageController.jumpToPage(_pageIndex(newCategory));
          if ([Category.RECENT, Category.RECOMMENDED].contains(oldSelection) ||
              [Category.RECENT, Category.RECOMMENDED].contains(newCategory)) {
            needRefresh = true;
          }

          if (needRefresh) {
            setState(() {});
            if ([Category.RECENT, Category.RECOMMENDED].contains(oldSelection) &&
                [Category.RECENT, Category.RECOMMENDED].contains(newCategory) == false) {
              SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
                scrollListController.scrollTo(index: index, duration: Duration(milliseconds: 500));
              });
            }
          } else {
            scrollListController.scrollTo(index: index, duration: Duration(milliseconds: 500));
          }
        }
      },
    );
    return Container(
      height: CATEGORY_BUTTON_HEIGHT,
      color: widget.bgColor,
      child: Row(
        children: () {
          var ret = <Widget>[
            // widget.recommendKeywords != null
            //     ? _catgoryButton(Category.RECOMMENDED, widget.categoryIcons.recommendationIcon)
            //     : Container(),
            // _catgoryButton(Category.RECENT, widget.categoryIcons.recentIcon),
            _categoryButton(Category.SMILEYS, widget.categoryIcons.smileyIcon),
            _categoryButton(Category.ANIMALS, widget.categoryIcons.animalIcon),
            _categoryButton(Category.FOODS, widget.categoryIcons.foodIcon),
            _categoryButton(Category.TRAVEL, widget.categoryIcons.travelIcon),
            _categoryButton(Category.ACTIVITIES, widget.categoryIcons.activityIcon),
            _categoryButton(Category.OBJECTS, widget.categoryIcons.objectIcon),
            _categoryButton(Category.SYMBOLS, widget.categoryIcons.symbolIcon),
            _categoryButton(Category.FLAGS, widget.categoryIcons.flagIcon),
          ];
          if (widget.enableRecent) {
            ret.insert(
              0,
              _categoryButton(Category.RECENT, widget.categoryIcons.recentIcon),
            );
          }
          if (widget.enableRecommend) {
            ret.insert(0, _categoryButton(Category.RECOMMENDED, widget.categoryIcons.recommendationIcon));
          }
          return ret;
        }(),
      ),
    );
  }

  Widget _loadingPage() {
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
        _categoryButtons()
      ],
    );
  }

  Widget _categoryButton(Category category, CategoryIcon icon) {
    return SizedBox(
      width: MediaQuery.of(context).size.width / (widget.recommendKeywords == null ? 9 : 10),
      height: MediaQuery.of(context).size.width / (widget.recommendKeywords == null ? 9 : 10),
      child: widget.buttonMode == ButtonMode.MATERIAL
          ? FlatButton(
              padding: EdgeInsets.all(0),
              //color: selectedCategory == category ? Colors.black12 : Colors.transparent,
              color: Colors.blue,
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
              pressedOpacity: 1.0,
              padding: EdgeInsets.all(0),
              //color: Colors.blue,
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

  Widget _tabBarButton(Category category, CategoryIcon icon) {
    return Container(
      padding: EdgeInsets.all(0),
      alignment: Alignment.center,
      child: Icon(icon.icon, size: 22, color: icon.color),
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
