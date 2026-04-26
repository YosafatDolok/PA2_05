import 'package:flutter/material.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDE7DF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),

              // LOGO
              const Icon(
                Icons.restaurant,
                size: 90,
                color: Color(0xFFD4A017),
              ),

              const SizedBox(height: 20),

              // TITLE
              const Text(
                "Pardede",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD4A017),
                ),
              ),

              const Text(
                "CATERING",
                style: TextStyle(
                  fontSize: 14,
                  letterSpacing: 4,
                  color: Colors.brown,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Nikmati Hidangan Lezat\nTanpa Ribet",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15),
              ),

              const Spacer(),

              // PRIMARY BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B1E1E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Pesan Sekarang",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // SECONDARY BUTTON (GUEST MODE)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/user-dashboard');
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.brown),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Lihat Menu",
                    style: TextStyle(color: Colors.brown),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}