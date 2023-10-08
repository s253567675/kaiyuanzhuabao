import 'dart:convert';
import 'dart:io';

import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:network_proxy/network/http/http.dart';
import 'package:path_provider/path_provider.dart';

/// @author wanghongen
/// 2023/10/06
/// js脚本
class ScriptManager {
  static ScriptManager? _instance;
  bool enabled = true;
  final List<ScriptItem> scripts = [];

  var flutterJs = getJavascriptRuntime();

  ScriptManager._();

  ///单例
  static Future<ScriptManager> get instance async {
    if (_instance == null) {
      _instance = ScriptManager._();
      await _instance?._init();
    }
    return _instance!;
  }

  //初始化
  Future<void> _init() async {
    var file = await _path;
    if (await file.exists()) {
      var content = await file.readAsString();
      var config = jsonDecode(content);
      enabled = config['enabled'] == true;
      for (var entry in config['scripts']) {
        scripts.add(ScriptItem.fromJson(entry));
      }
    }
  }

  static Future<File> get _path async {
    final directory = await getApplicationSupportDirectory();
    var file = File('${directory.path}${Platform.pathSeparator}script.json');
    if (!await file.exists()) {
      await file.create();
    }
    return file;
  }

  ///添加脚本

  Future<void> addScript(ScriptItem script) async {
    scripts.add(script);
  }

  ///运行脚本
  HttpRequest runScript(HttpRequest request) {
    if (!enabled) {
      return request;
    }
    var url = request.requestUrl;
    for (var script in scripts) {
      if (script.enabled && script.match(url)) {
        var jsRequest = jsonEncode(convertJsRequest(request));

        var evaluate = flutterJs.evaluate("""${script.script}\n httpRequest($jsRequest);""");
        var convertValue = flutterJs.convertValue(evaluate);
        return convertHttpRequest(request, convertValue);
      }
    }
    return request;
  }

  //转换js request
  Map<String, dynamic> convertJsRequest(HttpRequest request) {
    var requestUri = request.requestUri;
    return {
      'url': request.requestUrl,
      'path': requestUri?.path,
      'queries': requestUri?.queryParameters,
      'headers': request.headers.toMap(),
      'method': request.method.name,
      'body': request.bodyAsString
    };
  }

  //http request
  HttpRequest convertHttpRequest(HttpRequest request, Map<String, dynamic> map) {
    request.headers.clean();
    request.method = HttpMethod.values.firstWhere((element) => element.name == map['method']);
    String query = '';
    map['queries']?.forEach((key, value) {
      query += '$key=${value.join(",")}&';
    });

    request.uri = Uri.parse('${request.remoteDomain()} ${map['path']}?$query').toString();
    var httpRequest = HttpRequest(map['method'], map['url']);

    map['headers'].forEach((key, value) {
      httpRequest.headers.add(key, value);
    });
    httpRequest.body = map['body']?.toString().codeUnits;
    return httpRequest;
  }
}

class ScriptItem {
  bool enabled = true;
  String name;
  String url;
  String script;
  RegExp? urlReg;

  ScriptItem(this.enabled, this.name, this.url, this.script);

  //匹配url
  bool match(String url) {
    if (!this.url.startsWith('http')) {
      //不是http开头的url 需要去掉协议
      url = url.substring(url.indexOf('://') + 3);
    }
    urlReg ??= RegExp(url.replaceAll("*", ".*"));
    return urlReg!.hasMatch(url);
  }

  factory ScriptItem.fromJson(Map<String, dynamic> json) {
    return ScriptItem(json['enabled'], json['name'], json['url'], json['script']);
  }

  Map<String, dynamic> toJson() {
    return {'enabled': enabled, 'name': name, 'url': url, 'script': script};
  }
}
