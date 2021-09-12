//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<emoji_picker/EmojiPickerPlugin.h>)
#import <emoji_picker/EmojiPickerPlugin.h>
#else
@import emoji_picker;
#endif

#if __has_include(<shared_preferences/FLTSharedPreferencesPlugin.h>)
#import <shared_preferences/FLTSharedPreferencesPlugin.h>
#else
@import shared_preferences;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [EmojiPickerPlugin registerWithRegistrar:[registry registrarForPlugin:@"EmojiPickerPlugin"]];
  [FLTSharedPreferencesPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTSharedPreferencesPlugin"]];
}

@end
