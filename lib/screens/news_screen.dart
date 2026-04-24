import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../theme/app_theme.dart';
import '../services/news_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadNews();
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
      case 'pharmacy':
        return Icons.local_pharmacy;
      case 'eco':
        return Icons.eco;
      case 'report':
        return Icons.report_problem;
      case 'campaign':
        return Icons.campaign;
      case 'event':
        return Icons.event;
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
      color: Colors.grey.shade600,
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
        border: Border.all(
          color: AppColors.danger.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.danger,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_alertCount Active Alert${_alertCount > 1 ? 's' : ''} in Your Area',
                  style: AppTextStyles.bodyText.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.danger,
                  ),
                ),
                Text(
                  'Stay alert and take preventive measures',
                  style: AppTextStyles.caption,
                ),
              ],
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  category,
                  style: AppTextStyles.bodyText.copyWith(
                    color: isSelected
                        ? AppColors.textLight
                        : AppColors.textPrimary,
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
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.danger),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadNews,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      );
    }
    if (_filteredNews.isEmpty) {
      return const Center(child: Text('No news available.'));
    }
    return RefreshIndicator(
      onRefresh: _loadNews,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredNews.length,
        itemBuilder: (context, index) =>
            _buildNewsCard(_filteredNews[index]),
      ),
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> news) {
    final color = _colorFromString(news['color'] as String? ?? 'primary');
    final icon = _iconFromString(news['icon'] as String? ?? 'article');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: news['isAlert'] == true
            ? Border.all(color: color.withValues(alpha: 0.3))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (news['isAlert'] == true)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '⚠ ALERT',
                            style: AppTextStyles.caption.copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Text(
                        news['source'] as String? ?? '',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                Text(
                  news['date'] as String? ?? '',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              news['title'] as String? ?? '',
              style: AppTextStyles.bodyText.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              news['description'] as String? ?? '',
              style: AppTextStyles.bodyText,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    news['category'] as String? ?? '',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Read More →',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} // end of _NewsScreenState