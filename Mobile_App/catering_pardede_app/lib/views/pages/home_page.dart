import 'package:flutter/material.dart';
import '../widgets/app_layout.dart';
import '../widgets/custom_header.dart';
import '../../core/theme/app_text_styles.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Home',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            CustomHeader(
              title: 'Selamat Datang 👋',
              subtitle: 'Nikmati hidangan terbaik hari ini',
            ),
            SizedBox(height: 20),
            _SectionTitle(title: 'Kategori'),
            SizedBox(height: 10),
            _CategoryList(),
            SizedBox(height: 20),
            _SectionTitle(title: 'Menu Favorit'),
            SizedBox(height: 10),
            _MenuList(),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.title);
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList();

  @override
  Widget build(BuildContext context) {
    final categories = ['Nasi', 'Snack', 'Minuman', 'Paket'];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return Chip(label: Text(categories[index]));
        },
      ),
    );
  }
}

class _MenuList extends StatelessWidget {
  const _MenuList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(3, (index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.restaurant),
            title: Text('Menu ${index + 1}'),
            subtitle: const Text('Deskripsi menu singkat'),
            trailing: const Text('Rp 25.000'),
          ),
        );
      }),
    );
  }
}