
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';


void main() {
  runApp(const TestPostmessageApp());
}



class TestPostmessageApp extends StatefulWidget{

  final paymentUrl = "https://myfirstdbproject.000webhostapp.com/index.html";

  const TestPostmessageApp({super.key});

  @override
  State<StatefulWidget> createState() {
    return TestPostmessageAppState();
  }

}

class TestPostmessageAppState extends State<TestPostmessageApp>{

  var controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)

    ..addJavaScriptChannel(
        'GERC',
        onMessageReceived: (JavaScriptMessage message) {
          print('GERC : ${message.message}');
          }
    );

  @override
  void initState() {
    super.initState();
    initStateAsync();
  }

  Future<void> initStateAsync() async {

    await controller.loadRequest(Uri.parse(widget.paymentUrl)).then((_) async => {
      await controller.runJavaScript("""
             window.postMessage = function(data) {
                        window.GERC.postMessage(JSON.stringify(data));
                    };
          """) });

  }



  @override
  Widget build(BuildContext context) {


      return MaterialApp(
        home: SafeArea(
            child: Scaffold(
                body: WebViewWidget(controller: controller)
            )
        ),
      );
  }

}