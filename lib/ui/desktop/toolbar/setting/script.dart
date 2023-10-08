/*
 * Copyright 2023 the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:network_proxy/network/util/script_manager.dart';
import 'package:network_proxy/ui/component/utils.dart';

class ScriptWidget extends StatefulWidget {
  final WindowController? windowController;

  const ScriptWidget({super.key, this.windowController});

  @override
  State<ScriptWidget> createState() => _ScriptWidgetState();
}

class _ScriptWidgetState extends State<ScriptWidget> {
  static String template = """
// 在请求到达服务器之前,调用此函数,您可以在此处修改请求数据
// 例如Add/Update/Remove：URL、Headers、Body
async function onRequest(context, request) {
  console.log(request.url);
  //request.url = "http://localhost:8080";
  // 更新或添加新标头
  //request.headers["X-New-Headers"] = "My-Value";

  // Body
  // var body = request.body;
  // request.body = body;
  return request;
}

// 在将响应数据发送到客户端之前,调用此函数,您可以在此处修改响应数据
async function onResponse(context, request, response) {
  // 更新或添加新标头
  // response.headers["Content-Type"] = "application/json";

  // Update status Code
  // response.statusCode = 500;

  // Update Body
  // var body = response.body;
  // body["new-key"] = "Proxyman";
  // response.body = body;
  return response;
}
  """;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        appBar: AppBar(
          title: const Text("脚本", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          toolbarHeight: 36,
          centerTitle: true,
          actions: const [SizedBox(width: 10)],
        ),
        body: Padding(
            padding: const EdgeInsets.only(left: 15, right: 10),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(children: [
                    futureWidget(
                        ScriptManager.instance,
                        (data) => SizedBox(
                            width: 300,
                            child: SwitchListTile(
                              subtitle: const Text("使用 JavaScript 修改请求和响应"),
                              title: const Text('启用脚本工具'),
                              dense: true,
                              onChanged: (value) {},
                              value: data.enabled,
                            ))),
                    Expanded(
                        child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const SizedBox(width: 10),
                        FilledButton(
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.only(left: 20, right: 20)),
                          onPressed: showAdd,
                          child: const Text("添加"),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.only(left: 20, right: 20)),
                          onPressed: () {},
                          child: const Text("导入"),
                        )
                      ],
                    )),
                    const SizedBox(width: 15)
                  ]),
                  const SizedBox(height: 5),
                  Container(
                      padding: const EdgeInsets.only(top: 10),
                      constraints: const BoxConstraints(minWidth: 500, minHeight: 300),
                      child: Column(children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SizedBox(width: 200, child: Text("名称")),
                            VerticalDivider(width: 1, thickness: 1),
                            SizedBox(width: 100, child: Text("启用")),
                            VerticalDivider(),
                            Expanded(child: Text("URL")),
                          ],
                        ),
                        const Divider(),
                        futureWidget(ScriptManager.instance, (data) => Column(children: rows(data.scripts)),
                            loading: true)
                      ])),
                ])));
  }

  List<Widget> rows(List<ScriptItem> list) {
    return List.generate(list.length, (index) {
      return InkWell(
          onTap: () {},
          onSecondaryTapDown: (details) {
            showContextMenu(context, details.globalPosition, items: [
              const PopupMenuItem(height: 35, child: Text("编辑")),
              const PopupMenuItem(height: 35, child: Text("导出")),
              const PopupMenuDivider(),
              const PopupMenuItem(height: 35, child: Text("删除")),
            ]);
          },
          child: Container(
              color: index.isEven ? Colors.grey.withOpacity(0.3) : null,
              height: 30,
              padding: const EdgeInsets.only(top: 5, bottom: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 200, child: Text("脚本名称")),
                  SizedBox(width: 50, child: Switch(value: true, onChanged: (val) {})),
                  SizedBox(width: 50),
                  Expanded(child: Text("github.com/api/*")),
                ],
              )));
    });
  }

  ///显示添加
  showAdd() {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => AlertDialog(
            scrollable: true,
            titlePadding: const EdgeInsets.only(left: 15, top: 10, right: 15),
            title: const Row(children: [
              Text("编辑脚本", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              SizedBox(width: 10),
              Tooltip(
                  message: "使用 JavaScript 修改请求和响应",
                  child: Icon(
                    Icons.help_outline,
                    size: 20,
                  )),
              Expanded(child: Align(alignment: Alignment.topRight, child: CloseButton()))
            ]),
            actionsPadding: const EdgeInsets.only(right: 10, bottom: 10),
            actions: [
              ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text("取消")),
              FilledButton(onPressed: () async {
                ScriptManager.instance.then((value) => value);
              }, child: const Text("保存")),
            ],
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const SizedBox(width: 80, child: Text("是否启用:")),
                  Expanded(child: Switch(value: true, onChanged: (val) {}))
                ]),
                const Row(children: [
                  SizedBox(width: 50, child: Text("名称:")),
                  Expanded(
                      child: TextField(
                    decoration: InputDecoration(
                        hintText: "请输入名称", constraints: BoxConstraints(maxHeight: 40), border: OutlineInputBorder()),
                  ))
                ]),
                const SizedBox(height: 10),
                const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  SizedBox(width: 50, child: Text("URL:")),
                  Expanded(
                      child: TextField(
                    decoration: InputDecoration(
                        hintText: "github.com/api/*",
                        isDense: true,
                        constraints: BoxConstraints(maxHeight: 40),
                        border: OutlineInputBorder()),
                  ))
                ]),
                const SizedBox(height: 10),
                const Text("脚本:"),
                const SizedBox(height: 5),
                SizedBox(
                    width: 850,
                    height: 500,
                    child: CodeTheme(
                        data: CodeThemeData(styles: monokaiSublimeTheme),
                        child: SingleChildScrollView(
                          child: CodeField(
                              textStyle: const TextStyle(fontSize: 13),
                              controller: CodeController(language: javascript, text: template)),
                        )))
              ],
            )));
  }
}
