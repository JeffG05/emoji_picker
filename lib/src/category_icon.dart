
import 'package:flutter/material.dart';

/// All the possible categories that [Emoji] can be put into
///
/// All [Category] are shown in the keyboard bottombar with the exception of [Category.RECOMMENDED]
/// which only displays when keywords are given

enum Category { RECOMMENDED, RECENT, SMILEYS, ANIMALS, FOODS, TRAVEL, ACTIVITIES, OBJECTS, SYMBOLS, FLAGS }


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
  final CategoryIcon recommendationIcon;

  /// Icon for [Category.RECENT]
  final CategoryIcon recentIcon;

  /// Icon for [Category.SMILEYS]
  final CategoryIcon smileyIcon;

  /// Icon for [Category.ANIMALS]
  final CategoryIcon animalIcon;

  /// Icon for [Category.FOODS]
  final CategoryIcon foodIcon;

  /// Icon for [Category.TRAVEL]
  final CategoryIcon travelIcon;

  /// Icon for [Category.ACTIVITIES]
  final CategoryIcon activityIcon;

  /// Icon for [Category.OBJECTS]
  final CategoryIcon objectIcon;

  /// Icon for [Category.SYMBOLS]
  final CategoryIcon symbolIcon;

  /// Icon for [Category.FLAGS]
  final CategoryIcon flagIcon;

  Map<Category, CategoryIcon > _categoryIconMap = {};

  CategoryIcons(
      {CategoryIcon recommendationIcon,
      CategoryIcon recentIcon,
      CategoryIcon smileyIcon,
      CategoryIcon animalIcon,
      CategoryIcon foodIcon,
      CategoryIcon travelIcon,
      CategoryIcon activityIcon,
      CategoryIcon objectIcon,
      CategoryIcon symbolIcon,
      CategoryIcon flagIcon}) :
    this.recommendationIcon = recommendationIcon?? CategoryIcon(icon: Icons.search),
    this.recentIcon = recentIcon?? CategoryIcon(icon: Icons.access_time),
    this.smileyIcon = smileyIcon?? CategoryIcon(icon: Icons.tag_faces),
    this.animalIcon = animalIcon?? CategoryIcon(icon: Icons.pets),
    this.foodIcon = foodIcon?? CategoryIcon(icon: Icons.fastfood),
    this.travelIcon = travelIcon?? CategoryIcon(icon: Icons.location_city),
    this.activityIcon = activityIcon?? CategoryIcon(icon: Icons.directions_run),
    this.objectIcon = objectIcon?? CategoryIcon(icon: Icons.lightbulb_outline),
    this.symbolIcon = symbolIcon?? CategoryIcon(icon: Icons.euro_symbol),
    this.flagIcon = flagIcon?? CategoryIcon(icon: Icons.flag),
    _categoryIconMap = {
      Category.RECOMMENDED: recommendationIcon,
      Category.RECENT: recentIcon,
      Category.SMILEYS: smileyIcon,
      Category.ANIMALS: animalIcon,
      Category.FOODS: foodIcon,
      Category.TRAVEL: travelIcon,
      Category.ACTIVITIES: activityIcon,
      Category.OBJECTS: objectIcon,
      Category.SYMBOLS: symbolIcon,
      Category.FLAGS: flagIcon
    };
  

  CategoryIcon operator [](Category category){
    return _categoryIconMap[category];
  }

  
}
