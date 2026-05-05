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
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(
        Uri.parse(
          "https://app.sandbox.midtrans.com/snap/v2/vtweb/${widget.snapToken}",
        ),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            debugPrint("URL: $url");

            // 🔥 DETEKSI JIKA PEMBAYARAN SELESAI
            if (url.contains("finish") || url.contains("success")) {
              Navigator.pop(context); // kembali ke halaman sebelumnya

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Pembayaran berhasil")),
              );
            }
          },
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pembayaran"),
        backgroundColor: const Color(0xFF8B0000),
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}