
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Import for Android features.
import 'package:webview_flutter_android/webview_flutter_android.dart';
// Import for iOS features.
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

void main() {
  runApp(const TestPostmessageApp());
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

    late final PlatformWebViewControllerCreationParams params;

    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{}
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller2 = WebViewController.fromPlatformCreationParams(params);

    await controller2.setJavaScriptMode(JavaScriptMode.unrestricted);

    if (controller2.platform is AndroidWebViewController) {

      await AndroidWebViewController.enableDebugging(true);
      await (controller2.platform as AndroidWebViewController).setMediaPlaybackRequiresUserGesture(false);

      await (controller2.platform as AndroidWebViewController).addJavaScriptChannel(
          JavaScriptChannelParams(name: 'GERC', onMessageReceived: (JavaScriptMessage message) {
            print('GERC : ${message.message}');
          })
      );
      await (controller2.platform as AndroidWebViewController).runJavaScript("""
              window.postMessage = function(data) {
                         window.GERC.postMessage(JSON.stringify(data));
                     };
           """);
      await (controller2.platform as AndroidWebViewController).loadRequest(LoadRequestParams(uri: Uri.parse(widget.paymentUrl)));
    }

    await controller2.setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) async {
          await controller2.runJavaScriptReturningResult("""
             window.postMessage = function(data) {
                        window.GERC.postMessage(JSON.stringify(data));
                    };
          """);
        },
        onPageFinished: (url) async {
          await controller2.runJavaScriptReturningResult("""
             window.postMessage = function(data) {
                        window.GERC.postMessage(JSON.stringify(data));
                    };
          """);
        },
        onNavigationRequest: (NavigationRequest request) async {

          await controller2.runJavaScriptReturningResult("""
             window.postMessage = function(data) {
                        window.GERC.postMessage(JSON.stringify(data));
                    };
          """);

          return NavigationDecision.navigate;
        }
    ));

    await controller2.loadRequest(Uri.parse(widget.paymentUrl)).then((_) async => {
      await controller2.runJavaScriptReturningResult("""
             window.postMessage = function(data) {
                        window.GERC.postMessage(JSON.stringify(data));
                    };
          """)
    });

    await controller2.runJavaScriptReturningResult("""
             window.postMessage = function(data) {
                        window.GERC.postMessage(JSON.stringify(data));
                    };
          """).then((_) async => await Future.delayed(Duration(seconds: 1),(){
        controller2.loadRequest(Uri.parse(widget.paymentUrl));
    }));

    _controller = await controller2;

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