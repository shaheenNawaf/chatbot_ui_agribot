import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;

// Shown after all 10 eval questions are rated.
// On Android: renders the Google Form in an in-app WebView.
// On Web: renders the form in an iframe via HtmlElementView.
// The deviceId is appended as a pre-fill query param so responses can be
// joined with the Supabase eval_responses table.
class GoogleFormModal extends StatefulWidget {
  final String deviceId;

  // Replace with your actual Google Form URL.
  // To pre-fill the deviceId field, generate a pre-filled link from Google Forms
  // and replace the entry.XXXXXXXXX param name with your actual field entry ID.
  static const String _baseFormUrl =
      'https://docs.google.com/forms/d/e/1FAIpQLSeagLF1ChL5xXoJvntc53DsRc_ZJkGxbzBEIoFmJQC3iHfXcA/viewform?usp=header';

  const GoogleFormModal({super.key, required this.deviceId});

  static Future<void> show(BuildContext context, {required String deviceId}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => GoogleFormModal(deviceId: deviceId),
    );
  }

  @override
  State<GoogleFormModal> createState() => _GoogleFormModalState();
}

class _GoogleFormModalState extends State<GoogleFormModal> {
  late final String _formUrl;
  WebViewController? _webViewController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _formUrl = '${GoogleFormModal._baseFormUrl}${widget.deviceId}';

    if (!kIsWeb) {
      _initMobileWebView();
    } else {
      _registerIframe();
    }
  }

  void _initMobileWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => _isLoading = false),
        ),
      )
      ..loadRequest(Uri.parse(_formUrl));
  }

  void _registerIframe() {
    ui_web.platformViewRegistry.registerViewFactory(
      'google-form-iframe-${widget.deviceId}',
      (int viewId) {
        final iframe =
            web.document.createElement('iframe') as web.HTMLIFrameElement;
        iframe.src = _formUrl;
        iframe.style.border = 'none';
        iframe.style.width = '100%';
        iframe.style.height = '100%';
        iframe.onload = (web.Event _) {
          if (mounted) setState(() => _isLoading = false);
        }.toJS;
        return iframe;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      height: screenHeight * 0.9,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildFormView()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "One Last Step! 🌾",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
                Text(
                  "Please fill out this short form to complete your evaluation.",
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              "Done",
              style: GoogleFonts.poppins(
                color: const Color(0xFF2E7D32),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormView() {
    if (kIsWeb) {
      return Stack(
        children: [
          HtmlElementView(viewType: 'google-form-iframe-${widget.deviceId}'),
          if (_isLoading) _buildLoader(),
        ],
      );
    }

    return Stack(
      children: [
        WebViewWidget(controller: _webViewController!),
        if (_isLoading) _buildLoader(),
      ],
    );
  }

  Widget _buildLoader() {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
    );
  }
}
