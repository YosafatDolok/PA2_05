import 'package:flutter/material.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDE7DF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // ICON / LOGO
            const Icon(Icons.restaurant, size: 100, color: Colors.orange),

            const SizedBox(height: 20),

            // TITLE
            const Text(
              "Pardede",
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD4A017),
              ),
            ),

            const Text(
              "CATERING",
              style: TextStyle(
                fontSize: 16,
                letterSpacing: 5,
                color: Colors.brown,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Nikmati Hidangan\nLezat Tanpa Ribet",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 30),

            // BUTTON PESAN
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B1E1E),
                padding: const EdgeInsets.symmetric(
                    horizontal: 40, vertical: 12),
              ),
              child: const Text("Pesan Sekarang"),
            ),

            const SizedBox(height: 15),

            // BUTTON MENU
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/user-dashboard');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown[200],
                padding: const EdgeInsets.symmetric(
                    horizontal: 40, vertical: 12),
              ),
              child: const Text("Lihat Menu"),
            ),
          ],
        ),
      ),
    );
  }
}