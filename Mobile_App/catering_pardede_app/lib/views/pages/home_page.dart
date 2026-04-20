import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      body: Column(
        children: [

          // ================= HEADER =================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF8B1E1E),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Logo + Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Pardede Catering',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.notifications, color: Colors.white),
                          SizedBox(width: 10),
                          Icon(Icons.person, color: Colors.white),
                        ],
                      )
                    ],
                  ),

                  SizedBox(height: 15),

                  Text(
                    'Welcome',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  Text(
                    'User',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),

                  SizedBox(height: 15),

                  // Search
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ================= TAB =================
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                categoryTab('Semua', true),
                categoryTab('Menu', false),
                categoryTab('Kategori', false),
                categoryTab('Minuman', false),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ================= MENU GRID =================
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(12),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: const [
                MenuCard(
                  name: 'Arsik Ikan Mas',
                  image: 'https://via.placeholder.com/150',
                ),
                MenuCard(
                  name: 'Rendang Daging',
                  image: 'https://via.placeholder.com/150',
                ),
                MenuCard(
                  name: 'Lappet Toba',
                  image: 'https://via.placeholder.com/150',
                ),
                MenuCard(
                  name: 'Naniura Batak',
                  image: 'https://via.placeholder.com/150',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= TAB =================
  Widget categoryTab(String text, bool active) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      child: Chip(
        label: Text(text),
        backgroundColor: active ? Colors.orange : Colors.grey.shade300,
      ),
    );
  }
}

// ================= MENU CARD =================
class MenuCard extends StatelessWidget {
  final String name;
  final String image;

  const MenuCard({super.key, required this.name, required this.image});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4)
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.network(image, fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Expanded(child: Text('Menu')),
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.red,
                  child: Icon(Icons.add, size: 16, color: Colors.white),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}