package com.jeffg.emoji_picker;

import androidx.annotation.NonNull;
import android.content.Context;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import android.graphics.Paint;
import androidx.core.graphics.PaintCompat;

import java.util.HashMap;
import java.util.Map;

/** EmojiPickerPlugin */
public class EmojiPickerPlugin implements FlutterPlugin, MethodCallHandler {

  private MethodChannel channel;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    channel = new MethodChannel(binding.getBinaryMessenger(), "emoji_picker");
    channel.setMethodCallHandler(this);
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
    channel.setMethodCallHandler(null);
    channel = null;
  }
}
