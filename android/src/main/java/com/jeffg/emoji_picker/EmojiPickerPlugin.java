package com.jeffg.emoji_picker;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import android.graphics.Paint;
import androidx.core.graphics.PaintCompat;

import java.util.HashMap;
import java.util.Map;

/** EmojiPickerPlugin */
public class EmojiPickerPlugin implements FlutterPlugin, MethodCallHandler {
  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    final MethodChannel channel = new MethodChannel(flutterPluginBinding.getFlutterEngine().getDartExecutor(),
        "emoji_picker");
    channel.setMethodCallHandler(new EmojiPickerPlugin());
  }

  // This static function is optional and equivalent to onAttachedToEngine. It
  // supports the old
  // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
  // plugin registration via this function while apps migrate to use the new
  // Android APIs
  // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
  //
  // It is encouraged to share logic between onAttachedToEngine and registerWith
  // to keep
  // them functionally equivalent. Only one of onAttachedToEngine or registerWith
  // will be called
  // depending on the user's project. onAttachedToEngine or registerWith must both
  // be defined
  // in the same class.
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "emoji_picker");
    channel.setMethodCallHandler(new EmojiPickerPlugin());
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (call.method.equals("isAvailable")) {
      Paint paint = new Paint();
      result.success(PaintCompat.hasGlyph(paint, call.argument("emoji").toString()));
    } else if(call.method.equals("checkAvailability")) {
      Paint paint = new Paint();
      HashMap<String, String> map = call.argument("emoji");
      HashMap<String, String> filtered = new HashMap<>();
      for (Map.Entry entry: map.entrySet()) {
        if(PaintCompat.hasGlyph(paint, entry.getValue().toString())){
          filtered.put(entry.getKey().toString(), entry.getValue().toString());
        }
      }
      result.success(filtered);
    } else {
      result.notImplemented();
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
  }
}
