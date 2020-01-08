#import "EmojiPickerPlugin.h"
#if __has_include(<emoji_picker/emoji_picker-Swift.h>)
#import <emoji_picker/emoji_picker-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "emoji_picker-Swift.h"
#endif

@implementation EmojiPickerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftEmojiPickerPlugin registerWithRegistrar:registrar];
}
@end
