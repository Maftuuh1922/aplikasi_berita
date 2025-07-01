import 'package:flutter/material.dart';
import '../main.dart';
import 'news_list_screen.dart';

class CategoryItem {
  final String id;
  final String name;
  final String icon;
  const CategoryItem({required this.id, required this.name, required this.icon});
}

class CategoryScreen extends StatelessWidget {
  final NewsSource activeSource;
  const CategoryScreen({Key? key, required this.activeSource}) : super(key: key);

  static const List<CategoryItem> _categoriesIndo = [
    CategoryItem(id: 'nasional', name: 'Nasional', icon: '🇮🇩'),
    CategoryItem(id: 'ekonomi', name: 'Ekonomi', icon: '💼'),
    CategoryItem(id: 'olahraga', name: 'Olahraga', icon: '⚽'),
    CategoryItem(id: 'teknologi', name: 'Teknologi', icon: '💻'),
  ];

  static const List<CategoryItem> _categoriesLuar = [
    CategoryItem(id: 'general', name: 'Terkini', icon: '⚡'),
    CategoryItem(id: 'world', name: 'Dunia', icon: '🌍'),
    CategoryItem(id: 'business', name: 'Bisnis', icon: '💼'),
    CategoryItem(id: 'sports', name: 'Olahraga', icon: '🏅'),
  ];

  void _navigateToNewsList(BuildContext context, String categoryId, String categoryName, NewsSource source) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewsListScreen(
          categoryId: categoryId,
          categoryName: categoryName,
          source: source,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesToShow = activeSource == NewsSource.indo ? _categoriesIndo : _categoriesLuar;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jelajahi Kategori'),
        automaticallyImplyLeading: false,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.0,
        ),
        itemCount: categoriesToShow.length,
        itemBuilder: (context, index) {
          final category = categoriesToShow[index];
          return _CategoryCard(
            item: category,
            onTap: () => _navigateToNewsList(context, category.id, category.name, activeSource),
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryItem item;
  final VoidCallback onTap;
  const _CategoryCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 8),
              Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}