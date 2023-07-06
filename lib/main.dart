
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

void main() {
  runApp( const TestPostMessageApp());
}



class TestPostMessageApp extends StatefulWidget{

  final paymentUrl = "https://fc.gerc.ua:8443/api_test/postMessage.php";

  const TestPostMessageApp({super.key});

  @override
  State<StatefulWidget> createState() {
    return TestPostMessageAppState();
  }

}

class TestPostMessageAppState extends State<TestPostMessageApp>{

  late WebViewController _controller;

  Future<bool> initStateAsync() async {

    var controller = WebViewController();
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);

    await (controller.platform as AndroidWebViewController)
        .addJavaScriptChannel(JavaScriptChannelParams(
        name: 'GERC',
        onMessageReceived: (JavaScriptMessage message) {
          print('GERC : ${message.message}');

          var data = json.decode(message.message);

          if (data.containsKey('type')) {
            if (data['type'] == "payment-status") {
              print("object");
            }
          }
        }));

    await controller.loadRequest(Uri.parse(
        widget.paymentUrl));

    await controller
        .setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) async {
      await controller.runJavaScript("""
             window.parent.postMessage = function(data) {
                        window.GERC.postMessage(JSON.stringify(data));
                    };
          """);
    }, onPageFinished: (url) async {
      await controller.runJavaScript("""
             window.parent.postMessage = function(data) {
                        window.GERC.postMessage(JSON.stringify(data));
                    };
          """);
    }));


    await controller
        .loadRequest(Uri.parse(widget.paymentUrl))
        .then((_) async => {
      await controller.runJavaScript("""
             window.parent.postMessage = function(data) {
                        window.GERC.postMessage(JSON.stringify(data));
                    };
          """)
    });

    await controller.runJavaScriptReturningResult("""
             window.parent.postMessage = function(data) {
                        window.GERC.postMessage(JSON.stringify(data));
                    };
          """).then((_) async => await Future.delayed(
        const Duration(seconds: 1), () {
      controller.loadRequest(Uri.parse(widget.paymentUrl));
    }));

    _controller = controller;
    return true;
  }

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
        home: SafeArea(
            child: Scaffold(
                body: FutureBuilder<bool>(
                    future: initStateAsync(),
                    builder: (BuildContext context, AsyncSnapshot<bool> snapshot){
                      switch (snapshot.connectionState){
                        case ConnectionState.waiting:
                        return const Center(
                          child: Text("Loading.."),
                        );
                      default:
                          return snapshot.data!
                            ? WebViewWidget(controller: _controller)
                            : const Center(child: Text("Error"));
                    }
                    })
            )
        ),
      );
  }

}