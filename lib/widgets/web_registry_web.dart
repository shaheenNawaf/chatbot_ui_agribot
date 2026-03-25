import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;

void registerIframeView(String viewType, String url, void Function() onLoaded) {
  ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
    final iframe =
        web.document.createElement('iframe') as web.HTMLIFrameElement;
    iframe.src = url;
    iframe.style.border = 'none';
    iframe.style.width = '100%';
    iframe.style.height = '100%';
    iframe.onload = (web.Event _) {
      onLoaded();
    }.toJS;
    return iframe;
  });
}
