import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/news_service.dart';
import '../widgets/ai_fab.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Alerts',
    'Crops',
    'Weather',
    'Farming',
  ];

  final NewsService _newsService = NewsService();

  List<Map<String, dynamic>> _news = [];
  bool _isLoading = true;
  bool _isOffline = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _openNews(String url) async {
    if (url.isEmpty) return;

    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _loadNews() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await Connectivity().checkConnectivity();
      _isOffline = result == ConnectivityResult.none;

      final news = await _newsService.getNews();

      setState(() {
        _news = news;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load news.';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredNews {
    if (_selectedCategory == 'All') return _news;
    return _news.where((n) => n['category'] == _selectedCategory).toList();
  }

  int get _alertCount =>
      _news.where((n) => n['isAlert'] == true).length;

  Color _colorFromString(String c) {
    switch (c) {
      case 'danger':
        return AppColors.danger;
      case 'warning':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  IconData _iconFromString(String i) {
    switch (i) {
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'bug':
        return Icons.bug_report;
      case 'eco':
        return Icons.eco;
      default:
        return Icons.article;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Agri News & Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNews,
          ),
        ],
      ),
      floatingActionButton: const AiFab(),
      body: SafeArea(
        child: Column(
          children: [
            if (_isOffline) _buildOfflineBanner(),
            if (_alertCount > 0) _buildAlertBanner(),
            _buildCategoryFilter(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      color: Colors.grey,
      child: const Text(
        'Offline mode',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildAlertBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$_alertCount Active Alerts',
        style: const TextStyle(color: AppColors.danger),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: Container(
              margin: const EdgeInsets.all(6),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(child: Text(category)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_filteredNews.isEmpty) {
      return const Center(child: Text('No news available.'));
    }

    return RefreshIndicator(
      onRefresh: _loadNews,
      child: ListView.builder(
        itemCount: _filteredNews.length,
        itemBuilder: (context, index) =>
            _buildNewsCard(_filteredNews[index]),
      ),
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> news) {
    final imageUrl = news['image'] ?? '';

    return Card(
      margin: const EdgeInsets.all(10),
      child: Column(
        children: [
          if (imageUrl.isNotEmpty)
            Image.network(
              imageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.image_not_supported),
            ),
          ListTile(
            title: Text(news['title']),
            subtitle: Text(news['description']),
            trailing: Text(news['date']),
          ),
        ],
      ),
    );
  }
}