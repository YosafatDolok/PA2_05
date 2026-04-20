import 'package:flutter/material.dart';
import '../widgets/custom_header.dart';

class OrderPage extends StatelessWidget {
  const OrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      body: Column(
        children: const [
          CustomHeader(
            title: 'Halaman',
            subtitle: 'Order',
          ),

          Expanded(
            child: Center(
              child: Text(
                'Ini Halaman Order',
                style: TextStyle(fontSize: 16),
              ),
            ),
          )
        ],
      ),
    );
  }
}