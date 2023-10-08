import 'dart:convert';
import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:network_proxy/network/http/http.dart';
import 'package:network_proxy/ui/component/encoder.dart';
import 'package:network_proxy/ui/content/body.dart';
import 'package:network_proxy/ui/desktop/left/request_editor.dart';
import 'package:network_proxy/ui/desktop/toolbar/setting/script.dart';
import 'package:network_proxy/utils/platform.dart';
import 'package:window_manager/window_manager.dart';

///多窗口
Widget multiWindow(int windowId, Map<dynamic, dynamic> argument) {
  if (argument['name'] == 'RequestEditor') {
    return RequestEditor(
        windowController: WindowController.fromWindowId(windowId),
        request: argument['request'] == null ? null : HttpRequest.fromJson(argument['request']));
  }
  //请求体
  if (argument['name'] == 'HttpBodyWidget') {
    return HttpBodyWidget(
        windowController: WindowController.fromWindowId(windowId),
        httpMessage: HttpMessage.fromJson(argument['httpMessage']),
        inNewWindow: true,
        hideRequestRewrite: true);
  }
  //编码
  if (argument['name'] == 'EncoderWidget') {
    return EncoderWidget(
        type: EncoderType.nameOf(argument['type']),
        text: argument['text'],
        windowController: WindowController.fromWindowId(windowId));
  }
  //脚本
  if (argument['name'] == 'ScriptWidget') {
    return ScriptWidget(windowController: WindowController.fromWindowId(windowId));
  }

  return const SizedBox();
}

//打开编码窗口
encodeWindow(EncoderType type, BuildContext context, [String? text]) async {
  if (Platforms.isMobile()) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => EncoderWidget(type: type, text: text)));
    return;
  }

  var ratio = 1.0;
  if (Platform.isWindows) {
    ratio = WindowManager.instance.getDevicePixelRatio();
  }

  final window = await DesktopMultiWindow.createWindow(jsonEncode(
    {'name': 'EncoderWidget', 'type': type.name, 'text': text},
  ));
  window.setTitle('编码');
  window
    ..setFrame(const Offset(80, 80) & Size(900 * ratio, 600 * ratio))
    ..center()
    ..show();
}

///打开脚本窗口
openScriptWindow() async {
  var ratio = 1.0;
  if (Platform.isWindows) {
    ratio = WindowManager.instance.getDevicePixelRatio();
  }

  final window = await DesktopMultiWindow.createWindow(jsonEncode(
    {'name': 'ScriptWidget'},
  ));
  window.setTitle('脚本');
  window
    ..setFrame(const Offset(80, 80) & Size(800 * ratio, 850 * ratio))
    ..center()
    ..show();
}
