import 'package:webview_flutter_web/webview_flutter_web.dart';
import 'package:webview_flutter/webview_flutter.dart';

void setupWebViewPlatform() {
  WebViewPlatform.instance = WebWebViewPlatform();
}
