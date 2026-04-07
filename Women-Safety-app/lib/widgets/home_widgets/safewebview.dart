import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';


class SafeWebView extends StatefulWidget {
  final String url;
  SafeWebView({required this.url});

  @override
  _SafeWebViewState createState() => _SafeWebViewState();
}

class _SafeWebViewState extends State<SafeWebView> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Safe Web View")),
      body: WebViewWidget(controller: controller), // Corrected WebView usage
    );
  }
}
