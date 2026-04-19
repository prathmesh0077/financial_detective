import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../models/company.dart';
import '../../providers/app_providers.dart';
import '../../widgets/truth_score_badge.dart';
import '../stock_detail/stock_detail_screen.dart';

class WatchlistScreen extends ConsumerStatefulWidget {
  const WatchlistScreen({super.key});

  @override
  ConsumerState<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends ConsumerState<WatchlistScreen> {
  bool _isSearching = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final companies = _isSearching
        ? ref.watch(filteredCompaniesProvider)
        : ref.watch(watchlistCompaniesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
          ),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Search companies...',
                  hintStyle: TextStyle(color: AppColors.textTertiary),
                  border: InputBorder.none,
                  fillColor: Colors.transparent,
                  filled: true,
                ),
                onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
              )
            : const Text(
                'Financial Detective',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: AppColors.textSecondary),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  ref.read(searchQueryProvider.notifier).state = '';
                }
              });
            },
          ),
        ],
      ),
      body: companies.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off, color: AppColors.textTertiary, size: 48),
                  const SizedBox(height: 12),
                  Text('No companies found', style: TextStyle(color: AppColors.textTertiary)),
                ],
              ),
            )
          : _isSearching
              ? ListView.builder(
                  itemCount: companies.length,
                  padding: const EdgeInsets.only(bottom: 80),
                  itemBuilder: (context, index) => _WatchlistTile(
                    company: companies[index],
                    onTap: () => _openDashboard(companies[index]),
                    onSwipe: () => _addToPortfolio(companies[index]),
                  ),
                )
              : ReorderableListView.builder(
                  itemCount: companies.length,
                  padding: const EdgeInsets.only(bottom: 80),
                  onReorder: (oldIdx, newIdx) {
                    ref.read(watchlistProvider.notifier).reorder(oldIdx, newIdx);
                  },
                  proxyDecorator: (child, index, animation) {
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) => Material(
                        color: AppColors.card.withValues(alpha: 0.95),
                        elevation: 8,
                        borderRadius: BorderRadius.circular(12),
                        child: child,
                      ),
                      child: child,
                    );
                  },
                  itemBuilder: (context, index) => _WatchlistTile(
                    key: ValueKey(companies[index].ticker),
                    company: companies[index],
                    onTap: () => _openDashboard(companies[index]),
                    onSwipe: () => _addToPortfolio(companies[index]),
                  ),
                ),
    );
  }

  void _openDashboard(Company company) {
    ref.read(selectedCompanyProvider.notifier).state = company;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StockDetailScreen(company: company)),
    );
  }

  void _addToPortfolio(Company company) {
    ref.read(portfolioProvider.notifier).addHolding(
      company.ticker,
      10,
      company.price,
      company: company,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${company.ticker} added to portfolio'),
        backgroundColor: AppColors.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _WatchlistTile extends StatelessWidget {
  final Company company;
  final VoidCallback onTap;
  final VoidCallback onSwipe;

  const _WatchlistTile({
    super.key,
    required this.company,
    required this.onTap,
    required this.onSwipe,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = company.changePercent >= 0;
    return Dismissible(
      key: ValueKey('dismiss_${company.ticker}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        onSwipe();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppColors.primarySurface,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_circle_outline, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Add to Portfolio', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
            ),
          ),
          child: Row(
            children: [
              // Truth score badge (compact)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.scoreBgColor(company.truthScore),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.scoreColor(company.truthScore).withValues(alpha: 0.3),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${company.truthScore}',
                  style: TextStyle(
                    color: AppColors.scoreColor(company.truthScore),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Company info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          company.ticker,
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        TrendBadge(trend: company.trendLabel),
                      ],
                    ),
                  ],
                ),
              ),
              // Price info
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${company.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isPositive ? AppColors.primary : AppColors.error).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${isPositive ? '+' : ''}${company.changePercent.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: isPositive ? AppColors.primary : AppColors.error,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
