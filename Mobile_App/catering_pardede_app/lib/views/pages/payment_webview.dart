import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebView extends StatefulWidget {
  final String snapToken;

  const PaymentWebView({super.key, required this.snapToken});

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..loadRequest(
        Uri.parse("https://app.sandbox.midtrans.com/snap/v2/vtweb/${widget.snapToken}"),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pembayaran")),
      body: WebViewWidget(controller: controller),
    );
  }
}