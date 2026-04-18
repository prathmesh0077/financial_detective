import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../models/company.dart';
import '../../providers/app_providers.dart';
import '../../widgets/truth_score_badge.dart';
import '../../widgets/insight_card.dart';

class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  final _fmt = NumberFormat('#,##,##0.00', 'en_IN');

  @override
  Widget build(BuildContext context) {
    final portfolio = ref.watch(portfolioProvider);
    final companies = ref.watch(companiesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.warningDim,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.cases_outlined, color: AppColors.warning, size: 20),
          ),
        ),
        title: const Text('Financial Detective', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textSecondary),
            onPressed: () => _showAddDialog(companies),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // ── HEADER SECTION ──
            _PortfolioHeader(portfolio: portfolio, fmt: _fmt),
            const SizedBox(height: 16),
            // ── MINI BAR CHART ──
            _MiniBarChart(portfolio: portfolio),
            const SizedBox(height: 20),
            // ── SEARCH BAR ──
            GestureDetector(
              onTap: () => _showAddDialog(companies),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline, color: AppColors.textTertiary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Search and add stock to simulate...',
                        style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.cardLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('CMD + K', style: TextStyle(color: AppColors.textTertiary, fontSize: 10, letterSpacing: 0.5)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // ── HOLDINGS HEADER ──
            Row(
              children: [
                Expanded(
                  child: Text(
                    'CURRENT HOLDINGS (${portfolio.holdings.length})',
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Flexible(
                  child: Text(
                    'PERFORMANCE / SCORE',
                    textAlign: TextAlign.right,
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // ── HOLDINGS LIST ──
            ...portfolio.holdings.map((h) => PortfolioCard(
              ticker: h.ticker,
              name: h.companyName,
              shares: '${h.shares}',
              avgPrice: _fmt.format(h.avgPrice),
              returnPercent: h.returnPercent,
              currentValue: _fmt.format(h.totalValue),
              onDelete: () {
                ref.read(portfolioProvider.notifier).removeHolding(h.ticker);
              },
            )),
            if (portfolio.holdings.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, color: AppColors.textTertiary, size: 48),
                    const SizedBox(height: 12),
                    Text('No holdings yet', style: TextStyle(color: AppColors.textTertiary)),
                    const SizedBox(height: 8),
                    Text('Swipe stocks from watchlist or tap + to add', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            // ── SIMULATION INSIGHT ──
            _SimulationInsight(portfolio: portfolio),
            const SizedBox(height: 16),
            // ── VOLATILITY ──
            _VolatilityCard(portfolio: portfolio),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(List<Company> companies) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, controller) {
            return _AddStockSheet(
              companies: companies,
              controller: controller,
              onAdd: (company) {
                ref.read(portfolioProvider.notifier).addHolding(
                  company.ticker,
                  10,
                  company.price,
                );
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PORTFOLIO HEADER
// ═══════════════════════════════════════════════════════════════

class _PortfolioHeader extends StatelessWidget {
  final Portfolio portfolio;
  final NumberFormat fmt;
  const _PortfolioHeader({required this.portfolio, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACTIVE PLAYGROUND SIMULATION',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${fmt.format(portfolio.totalValue)}',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          TruthScoreBadge(score: portfolio.portfolioTruthScore),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                portfolio.totalReturn >= 0 ? Icons.trending_up : Icons.trending_down,
                color: portfolio.totalReturn >= 0 ? AppColors.primary : AppColors.error,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${portfolio.totalReturn >= 0 ? '+' : ''}${portfolio.totalReturn.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: portfolio.totalReturn >= 0 ? AppColors.primary : AppColors.error,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Text('OVERALL', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MINI BAR CHART
// ═══════════════════════════════════════════════════════════════

class _MiniBarChart extends StatelessWidget {
  final Portfolio portfolio;
  const _MiniBarChart({required this.portfolio});

  @override
  Widget build(BuildContext context) {
    if (portfolio.holdings.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 48,
      child: Row(
        children: portfolio.holdings.map((h) {
          final fraction = portfolio.totalValue > 0 ? h.totalValue / portfolio.totalValue : 0.0;
          return Expanded(
            flex: (fraction * 100).round().clamp(1, 100),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: h.returnPercent >= 0
                    ? AppColors.primary.withValues(alpha: 0.2 + (fraction * 0.6))
                    : AppColors.error.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SIMULATION INSIGHT
// ═══════════════════════════════════════════════════════════════

class _SimulationInsight extends StatelessWidget {
  final Portfolio portfolio;
  const _SimulationInsight({required this.portfolio});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SIMULATION INSIGHT',
            style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5),
          ),
          const SizedBox(height: 10),
          Text(
            portfolio.holdings.length > 3 ? 'High Concentration Risk' : 'Portfolio Diversification Needed',
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            portfolio.holdings.length > 3
                ? 'Your portfolio is 65% weighted in Financials. Consider adding defensive IT or FMCG stocks to balance the Truth Score volatility.'
                : 'Your portfolio has limited diversification. Add more stocks across different sectors for better risk-adjusted returns.',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: const Text(
              'OPTIMIZE SIMULATION',
              style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// VOLATILITY CARD
// ═══════════════════════════════════════════════════════════════

class _VolatilityCard extends StatelessWidget {
  final Portfolio portfolio;
  const _VolatilityCard({required this.portfolio});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Text(
            'VOLATILITY',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          const Text(
            'Low',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            '0.82 Beta',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ADD STOCK BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════

class _AddStockSheet extends StatefulWidget {
  final List<Company> companies;
  final ScrollController controller;
  final Function(Company) onAdd;

  const _AddStockSheet({
    required this.companies,
    required this.controller,
    required this.onAdd,
  });

  @override
  State<_AddStockSheet> createState() => _AddStockSheetState();
}

class _AddStockSheetState extends State<_AddStockSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.companies
        : widget.companies.where((c) =>
            c.name.toLowerCase().contains(_query.toLowerCase()) ||
            c.ticker.toLowerCase().contains(_query.toLowerCase())).toList();

    return Column(
      children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            autofocus: true,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search company...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
              fillColor: AppColors.card,
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: widget.controller,
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final c = filtered[index];
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.scoreBgColor(c.truthScore),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text('${c.truthScore}', style: TextStyle(color: AppColors.scoreColor(c.truthScore), fontWeight: FontWeight.w700)),
                ),
                title: Text(c.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                subtitle: Text(c.ticker, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                trailing: Text('₹${c.price.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textSecondary)),
                onTap: () => widget.onAdd(c),
              );
            },
          ),
        ),
      ],
    );
  }
}
