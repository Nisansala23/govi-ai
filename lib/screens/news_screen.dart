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
  final List<String> _categories = ['All', 'Alerts', 'Paddy', 'Tea', 'Tomato'];
  final NewsService _newsService = NewsService();

  List<Map<String, dynamic>> _news = [];
  bool _isLoading = true;
  bool _isOffline = false;
  String? _error;

  bool _isAgricultureRelated(String text) {
    final keywords = [
      'paddy','rice','tea','rubber','coconut',
      'farmer','farm','agriculture','crop',
      'fertilizer','harvest','plantation',
      'irrigation','drought','flood',
      'pest','disease','outbreak',
    ];

    final lower = text.toLowerCase();
    return keywords.any((k) => lower.contains(k));
  }

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _openNews(String url) async {
    if (url.isEmpty) return;

    final uri = Uri.parse(url);

    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      throw 'Could not launch $url';
    }
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
    final agriNews = _news.where((n) =>
      _isAgricultureRelated((n['title'] ?? '') + (n['description'] ?? ''))
    ).toList();

    if (_selectedCategory == 'All') return agriNews;

    return agriNews.where((n) => n['category'] == _selectedCategory).toList();
  }

  int get _alertCount =>
      _news.where((n) => n['isAlert'] == true).length;

  Color _colorFromString(String c) {
    switch (c) {
      case 'danger':
        return AppColors.danger;
      case 'warning':
        return AppColors.warning;
      case 'secondary':
        return AppColors.secondary;
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
      case 'campaign':
        return Icons.campaign;
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

      floatingActionButton: const AiFab(), // ✅ FIXED HERE

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
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      color: Colors.grey,
      child: const Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text(
            'Offline — showing cached news',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
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
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$_alertCount Active Alert${_alertCount > 1 ? 's' : ''} in Your Area',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = category),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_filteredNews.isEmpty) {
      return const Center(child: Text('No news available.'));
    }

    return RefreshIndicator(
      onRefresh: _loadNews,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredNews.length,
        itemBuilder: (context, index) =>
            _buildNewsCard(_filteredNews[index], index),
      ),
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> news, int index) {
    final color = _colorFromString(news['color'] ?? 'primary');
    final icon = _iconFromString(news['icon'] ?? 'article');
    final imageUrl = news['image'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl.isNotEmpty)
            Image.network(imageUrl, height: 180, fit: BoxFit.cover),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(news['source'] ?? '')),
                    Text(news['date'] ?? ''),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  news['title'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  news['description'] ?? '',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}