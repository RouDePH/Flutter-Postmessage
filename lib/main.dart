
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Import for Android features.
import 'package:webview_flutter_android/webview_flutter_android.dart';
// Import for iOS features.
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';


void main() {
  runApp( TestPostmessageApp());
}



class TestPostmessageApp extends StatefulWidget{

  final paymentUrl = "https://fc.gerc.ua:8443/api_test/postMessage.php";

  const TestPostmessageApp({super.key});

  @override
  State<StatefulWidget> createState() {
    return TestPostmessageAppState();
  }

}

class TestPostmessageAppState extends State<TestPostmessageApp>{

  late WebViewController _controller;


  @override
  void initState() {
    super.initState();
  }

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
                        case ConnectionState.waiting: return Container();
                        default:
                          return WebViewWidget(controller: _controller);
                      }
                    })
            )
        ),
      );
  }

}
//
//
// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(title: Text('WebView with postMessage Listener')),
//         body: WebViewWithPostMessageListener(),
//       ),
//     );
//   }
// }
//
// class WebViewWithPostMessageListener extends StatefulWidget {
//   @override
//   _WebViewWithPostMessageListenerState createState() =>
//       _WebViewWithPostMessageListenerState();
// }
//
// class _WebViewWithPostMessageListenerState
//     extends State<WebViewWithPostMessageListener> {
//   final webViewPlugin = FlutterWebviewPlugin();
//
//   @override
//   void initState() {
//     super.initState();
//
//     webViewPlugin.onStateChanged.listen((WebViewStateChanged state) {
//       if (state.type == WebViewState.finishLoad) {
//
//         webViewPlugin.evalJavascript("""
//                  window.parent.postMessage = function(data) {
//                             window.GERC.postMessage(JSON.stringify(data));
//                         };
//               """);
//         webViewPlugin.evalJavascript('''
//           window.addEventListener("message", (event) => {
//             window.parent.postMessage(JSON.stringify(event.data));
//           });
//         ''');
//       }
//     });
//
//     webViewPlugin.evalJavascript("""
//                  window.parent.postMessage = function(data) {
//                             window.GERC.postMessage(JSON.stringify(data));
//                         };
//               """);
//
//     // webViewPlugin.onJavascriptChannelReceive.listen((JavascriptChannelMessage message) {
//     //   print('Received message from WebView: ${message.message}');
//     // });
//   }
//
//   @override
//   void dispose() {
//     webViewPlugin.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return WebviewScaffold(
//       url: 'https://fc.gerc.ua:8443/api_test/postMessage.php',
//       headers: <String, String>{
//         'Access-Control-Allow-Origin': '*',
//         'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
//         'Access-Control-Allow-Credentials': 'true',
//         'Content-Type': 'type="text/javascript'
//       },
//       javascriptChannels: {
//         JavascriptChannel(
//           name: 'parent',
//           onMessageReceived: (JavascriptMessage message) {
//             print('Received message from WebView: ${message.message}');
//           },
//         ),
//       },
//     );
//   }
// }