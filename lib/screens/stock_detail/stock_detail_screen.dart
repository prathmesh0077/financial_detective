import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../models/company.dart';
import '../../providers/app_providers.dart';
import '../dashboard/forensic_dashboard_screen.dart';
import '../smart_money/smart_money_screen.dart';
import '../money_trail/money_trail_screen.dart';
import '../performance/performance_screen.dart';

class StockDetailScreen extends ConsumerStatefulWidget {
  final Company company;
  const StockDetailScreen({super.key, required this.company});

  @override
  ConsumerState<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends ConsumerState<StockDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ensure selectedCompanyProvider is set for sub-screens that rely on it
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedCompanyProvider.notifier).state = widget.company;
    });

    final company = widget.company;
    final isPositive = company.changePercent >= 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.scoreBgColor(company.truthScore),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.scoreColor(company.truthScore)
                      .withValues(alpha: 0.3),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '${company.truthScore}',
                style: TextStyle(
                  color: AppColors.scoreColor(company.truthScore),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    company.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Text(
                        company.ticker,
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₹${company.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: (isPositive
                                  ? AppColors.primary
                                  : AppColors.error)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${isPositive ? '+' : ''}${company.changePercent.toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: isPositive
                                ? AppColors.primary
                                : AppColors.error,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppColors.primary,
              indicatorWeight: 2.5,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textTertiary,
              labelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
              labelPadding:
                  const EdgeInsets.symmetric(horizontal: 14),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined, size: 14),
                      SizedBox(width: 5),
                      Text('FORENSIC'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up, size: 14),
                      SizedBox(width: 5),
                      Text('SMART MONEY'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.account_tree_outlined, size: 14),
                      SizedBox(width: 5),
                      Text('MONEY TRAIL'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.show_chart, size: 14),
                      SizedBox(width: 5),
                      Text('PERFORMANCE'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Forensic Analysis (uses the body content of ForensicDashboardScreen)
          const ForensicDashboardBody(),
          // Tab 2: Smart Money
          SmartMoneyBody(company: company),
          // Tab 3: Money Trail
          const MoneyTrailBody(),
          // Tab 4: Performance
          const PerformanceBody(),
        ],
      ),
    );
  }
}
