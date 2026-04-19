import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Alerts', 'Paddy', 'Tea', 'Tomato'];

  final List<Map<String, dynamic>> _news = [
    {
      'title': 'Paddy Blast Warning - Kurunegala District',
      'description':
          'Department of Agriculture warns farmers in Kurunegala about high risk of Paddy Blast due to recent weather conditions. Take preventive measures immediately.',
      'category': 'Alerts',
      'date': 'Apr 4, 2026',
      'source': 'Dept. of Agriculture',
      'isAlert': true,
      'color': AppColors.danger,
      'icon': Icons.warning_amber_rounded,
    },
    {
      'title': 'Brown Planthopper Spreading in North Western Province',
      'description':
          'Farmers in North Western Province report increasing Brown Planthopper infestations. Use resistant varieties and avoid excessive nitrogen.',
      'category': 'Paddy',
      'date': 'Apr 3, 2026',
      'source': 'Rice Research Institute',
      'isAlert': true,
      'color': AppColors.warning,
      'icon': Icons.bug_report,
    },
    {
      'title': 'New Organic Pesticide Available at Lanka Agro Shops',
      'description':
          'A new government-approved organic pesticide for paddy diseases is now available at all Lanka Agro Shops island-wide at subsidized prices.',
      'category': 'Paddy',
      'date': 'Apr 2, 2026',
      'source': 'Lanka Agro',
      'isAlert': false,
      'color': AppColors.primary,
      'icon': Icons.local_pharmacy,
    },
    {
      'title': 'Tea Blister Blight Season - Be Prepared',
      'description':
          'Tea Research Institute advises hill country farmers to apply preventive copper fungicide sprays before the upcoming wet season begins.',
      'category': 'Tea',
      'date': 'Apr 1, 2026',
      'source': 'Tea Research Institute',
      'isAlert': true,
      'color': AppColors.warning,
      'icon': Icons.eco,
    },
    {
      'title': 'Tomato Early Blight Reported in Nuwara Eliya',
      'description':
          'Several farms in Nuwara Eliya have reported Early Blight on tomato crops. Farmers advised to inspect crops and apply mancozeb if needed.',
      'category': 'Tomato',
      'date': 'Mar 31, 2026',
      'source': 'Horticulture Dept.',
      'isAlert': false,
      'color': AppColors.danger,
      'icon': Icons.report_problem,
    },
    {
      'title': 'Government Subsidy for Paddy Farmers Announced',
      'description':
          'The Ministry of Agriculture has announced a new subsidy program for paddy farmers affected by crop diseases in 2026 season.',
      'category': 'Paddy',
      'date': 'Mar 30, 2026',
      'source': 'Ministry of Agriculture',
      'isAlert': false,
      'color': AppColors.primary,
      'icon': Icons.campaign,
    },
    {
      'title': 'Free Crop Disease Diagnosis Camp - Anuradhapura',
      'description':
          'Department of Agriculture organizing free crop disease diagnosis camps in Anuradhapura district every Saturday during April 2026.',
      'category': 'All',
      'date': 'Mar 29, 2026',
      'source': 'Dept. of Agriculture',
      'isAlert': false,
      'color': AppColors.secondary,
      'icon': Icons.event,
    },
  ];

  List<Map<String, dynamic>> get _filteredNews {
    if (_selectedCategory == 'All') return _news;
    return _news.where((n) => n['category'] == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Agri News & Alerts')),
      body: SafeArea(
        child: Column(
          children: [
            _buildAlertBanner(),
            _buildCategoryFilter(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredNews.length,
                itemBuilder: (context, index) {
                  return _buildNewsCard(_filteredNews[index]);
                },
              ),
            ),
          ],
        ),
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
                  '2 Active Alerts in Your Area',
                  style: AppTextStyles.bodyText.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.danger,
                  ),
                ),
                Text(
                  'Paddy Blast & Brown Planthopper risk is high',
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

  Widget _buildNewsCard(Map<String, dynamic> news) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: news['isAlert']
            ? Border.all(color: (news['color'] as Color).withValues(alpha: 0.3))
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
                    color: (news['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    news['icon'] as IconData,
                    color: news['color'] as Color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (news['isAlert'])
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (news['color'] as Color).withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '⚠ ALERT',
                            style: AppTextStyles.caption.copyWith(
                              color: news['color'] as Color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Text(
                        news['source'] as String,
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                Text(news['date'] as String, style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              news['title'] as String,
              style: AppTextStyles.bodyText.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              news['description'] as String,
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
                    news['category'] as String,
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
}
