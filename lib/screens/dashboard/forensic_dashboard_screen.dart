import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_colors.dart';
import '../../models/company.dart';
import '../../providers/app_providers.dart';
import '../../widgets/circular_gauge.dart';
// truth_score_badge used indirectly via InsightCard
import '../../widgets/insight_card.dart';
import '../smart_money/smart_money_screen.dart';

class ForensicDashboardScreen extends ConsumerWidget {
  const ForensicDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final company = ref.watch(selectedCompanyProvider);
    if (company == null) {
      return const Scaffold(
        body: Center(child: Text('No company selected')),
      );
    }

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
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 16),
            ),
            const SizedBox(width: 10),
            const Text('Financial Detective', style: TextStyle(fontSize: 16)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // ── COMPANY HEADER ──
            _CompanyHeader(company: company),
            const SizedBox(height: 24),
            // ── TRUTH SCORE GAUGE ──
            _TruthScoreSection(company: company),
            const SizedBox(height: 24),
            // ── ACCOUNTING RISK ──
            _AccountingRiskSection(company: company),
            const SizedBox(height: 8),
            // ── TRUTH VS PRICE CORRELATION ──
            _TruthPriceChart(company: company),
            const SizedBox(height: 8),
            // ── FORENSIC SIGNALS ──
            _ForensicSignals(company: company),
            const SizedBox(height: 8),
            // ── FUNDAMENTAL TRENDS ──
            _FundamentalTrends(company: company),
            const SizedBox(height: 8),
            // ── RED FLAGS ──
            _RedFlagsSection(company: company),
            const SizedBox(height: 8),
            // ── WHAT CHANGED ──
            _WhatChangedSection(company: company),
            const SizedBox(height: 8),
            // ── CREDIBILITY SUMMARY ──
            _CredibilitySection(company: company),
            const SizedBox(height: 8),
            // ── SMART MONEY + FRAUD SIMILARITY ──
            _SmartMoneyPreview(company: company, context: context),
            const SizedBox(height: 16),
            // ── DOWNLOAD BUTTON ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download, size: 18),
                label: const Text('DOWNLOAD FULL FORENSIC PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// COMPANY HEADER
// ═══════════════════════════════════════════════════════════════

class _CompanyHeader extends StatelessWidget {
  final Company company;
  const _CompanyHeader({required this.company});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    company.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last forensic audit: Oct 24, 2023 • 08:42 UTC',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${company.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  company.ticker,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TRUTH SCORE SECTION
// ═══════════════════════════════════════════════════════════════

class _TruthScoreSection extends StatelessWidget {
  final Company company;
  const _TruthScoreSection({required this.company});

  @override
  Widget build(BuildContext context) {
    String confidence;
    if (company.truthScore >= 80) {
      confidence = 'HIGH CONFIDENCE';
    } else if (company.truthScore >= 60) {
      confidence = 'MODERATE CONFIDENCE';
    } else {
      confidence = 'LOW CONFIDENCE';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Text(
            'TRUTH SCORE INDEX',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          CircularGauge(
            score: company.truthScore,
            size: 180,
            label: confidence,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ACCOUNTING RISK
// ═══════════════════════════════════════════════════════════════

class _AccountingRiskSection extends StatelessWidget {
  final Company company;
  const _AccountingRiskSection({required this.company});

  @override
  Widget build(BuildContext context) {
    return InsightCard(
      title: 'ACCOUNTING RISK',
      icon: Icons.account_balance,
      iconColor: AppColors.riskColor(company.accountingRiskScore),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.riskColor(company.accountingRiskScore).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          AppColors.riskLabel(company.accountingRiskScore),
          style: TextStyle(
            color: AppColors.riskColor(company.accountingRiskScore),
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      children: [
        _MetricRow(label: 'Beneish M-Score', value: company.beneishMScore.toStringAsFixed(2), desc: company.beneishRisk),
        _MetricRow(label: 'Revenue Recognition', value: company.accountingRiskScore < 30 ? 'Standard' : 'Aggressive'),
        _MetricRow(label: 'Depreciation Policy', value: 'Straight Line'),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final String? desc;

  const _MetricRow({required this.label, required this.value, this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
              if (desc != null)
                Text(desc!, style: TextStyle(color: AppColors.textTertiary, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TRUTH VS PRICE CHART
// ═══════════════════════════════════════════════════════════════

class _TruthPriceChart extends StatelessWidget {
  final Company company;
  const _TruthPriceChart({required this.company});

  @override
  Widget build(BuildContext context) {
    final prices = company.priceHistory;
    final maxPriceIdx = (prices.length - 1).toDouble();
    final maxTruthIdx = (company.truthScoreHistory.length - 1).toDouble();
    final maxX = maxPriceIdx > 0 ? maxPriceIdx : 1.0;
    final double titleInterval = (maxX / 5).clamp(1.0, double.infinity).ceilToDouble();

    return InsightCard(
      title: 'TRUTH VS PRICE CORRELATION',
      icon: Icons.show_chart,
      iconColor: AppColors.chartBlue,
      children: [
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: maxX,
              gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                drawVerticalLine: false,
                horizontalInterval: 25,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppColors.border.withValues(alpha: 0.4),
                  strokeWidth: 0.5,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: titleInterval,
                    getTitlesWidget: (value, meta) {
                      if (value >= maxX) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text('Now', style: TextStyle(color: AppColors.textTertiary, fontSize: 10)),
                        );
                      }
                      if (value == 0) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text('Start', style: TextStyle(color: AppColors.textTertiary, fontSize: 10)),
                        );
                      }
                      final periodsAgo = (maxX - value).round();
                      if (periodsAgo <= 0 || periodsAgo >= maxX.round()) return const SizedBox.shrink();
                      
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('-$periodsAgo', style: const TextStyle(color: AppColors.textTertiary, fontSize: 10)),
                      );
                    },
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                // Truth Score line
                LineChartBarData(
                  spots: company.truthScoreHistory
                      .asMap()
                      .entries
                      .map((e) => FlSpot(
                            maxTruthIdx > 0 ? (e.key / maxTruthIdx) * maxX : 0.0,
                            e.value.toDouble(),
                          ))
                      .toList(),
                  isCurved: true,
                  color: AppColors.primary,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.primary.withValues(alpha: 0.08),
                  ),
                ),
                // Price line (normalized to 0-100)
                LineChartBarData(
                  spots: _normalizedPrices(prices),
                  isCurved: true,
                  color: AppColors.chartBlue,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  dashArray: [6, 4],
                ),
              ],
              minY: 0,
              maxY: 100,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _LegendItem(color: AppColors.primary, label: 'TRUTH'),
            const SizedBox(width: 20),
            _LegendItem(color: AppColors.chartBlue, label: 'PRICE'),
          ],
        ),
      ],
    );
  }

  List<FlSpot> _normalizedPrices(List<double> prices) {
    if (prices.isEmpty) return [];
    final minP = prices.reduce((a, b) => a < b ? a : b);
    final maxP = prices.reduce((a, b) => a > b ? a : b);
    final range = maxP - minP;

    return prices
        .asMap()
        .entries
        .map((e) => FlSpot(
              e.key.toDouble(),
              range > 0 ? ((e.value - minP) / range) * 80 + 10 : 50,
            ))
        .toList();
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: AppColors.textTertiary, fontSize: 10, letterSpacing: 1)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// FORENSIC SIGNALS
// ═══════════════════════════════════════════════════════════════

class _ForensicSignals extends StatelessWidget {
  final Company company;
  const _ForensicSignals({required this.company});

  @override
  Widget build(BuildContext context) {
    final signals = <Map<String, dynamic>>[
      if (company.truthScore > 70)
        {'label': 'Profit growth backed by CFO', 'positive': true},
      if (company.trend == Trend.improving)
        {'label': 'ROCE improving YoY', 'positive': true},
      if (company.altmanZScore > 2.99)
        {'label': 'Strong Altman Z-Score', 'positive': true},
      if (company.accountingRiskScore > 40)
        {'label': 'Elevated accounting risk', 'positive': false},
      if (company.beneishMScore > -2.0)
        {'label': 'Beneish flag: manipulation risk', 'positive': false},
      if (company.debtToEquity > 1.0)
        {'label': 'High debt-to-equity ratio', 'positive': false},
    ];

    if (signals.isEmpty) {
      signals.add({'label': 'No significant signals detected', 'positive': true});
    }

    return InsightCard(
      title: 'FORENSIC SIGNALS',
      icon: Icons.radar,
      iconColor: AppColors.chartPurple,
      children: [
        ...signals.take(4).map((s) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    s['positive'] as bool ? Icons.check_circle : Icons.warning,
                    color: s['positive'] as bool ? AppColors.primary : AppColors.error,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s['label'] as String,
                      style: TextStyle(
                        color: s['positive'] as bool ? AppColors.primary : AppColors.error,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// FUNDAMENTAL TRENDS
// ═══════════════════════════════════════════════════════════════

class _FundamentalTrends extends StatelessWidget {
  final Company company;
  const _FundamentalTrends({required this.company});

  @override
  Widget build(BuildContext context) {
    return InsightCard(
      title: 'FUNDAMENTAL TRENDS',
      icon: Icons.analytics_outlined,
      iconColor: AppColors.info,
      children: [
        Row(
          children: [
            _TrendMetric(label: 'ROCE', value: '${company.roce.toStringAsFixed(1)}%'),
            _TrendMetric(label: 'Op. Margin', value: '${company.operatingMargin.toStringAsFixed(1)}%'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _TrendMetric(label: 'Debt/Eq', value: company.debtToEquity.toStringAsFixed(2)),
            _TrendMetric(label: 'FCF Yield', value: '${(company.roce * 0.3).toStringAsFixed(1)}%'),
          ],
        ),
      ],
    );
  }
}

class _TrendMetric extends StatelessWidget {
  final String label;
  final String value;
  const _TrendMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 10, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// RED FLAGS
// ═══════════════════════════════════════════════════════════════

class _RedFlagsSection extends StatelessWidget {
  final Company company;
  const _RedFlagsSection({required this.company});

  @override
  Widget build(BuildContext context) {
    return InsightCard(
      title: '🔴 RED FLAGS ALERT',
      children: company.redFlags.map((flag) {
        final color = flag.severity == FlagSeverity.high
            ? AppColors.error
            : flag.severity == FlagSeverity.medium
                ? AppColors.warning
                : AppColors.textTertiary;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.flag, color: color, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      flag.title,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24, top: 2),
                child: Text(
                  flag.description,
                  style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// WHAT CHANGED
// ═══════════════════════════════════════════════════════════════

class _WhatChangedSection extends StatelessWidget {
  final Company company;
  const _WhatChangedSection({required this.company});

  @override
  Widget build(BuildContext context) {
    return InsightCard(
      title: '🔍 WHAT CHANGED?',
      children: company.whatChanged.map((change) {
        Color impactColor;
        switch (change.impact) {
          case ChangeImpact.positive:
            impactColor = AppColors.primary;
            break;
          case ChangeImpact.negative:
            impactColor = AppColors.error;
            break;
          case ChangeImpact.neutral:
            impactColor = AppColors.info;
            break;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: impactColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(change.icon, color: impactColor, size: 16),
                  ),
                  if (company.whatChanged.last != change)
                    Container(width: 1, height: 24, color: AppColors.border),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      change.date,
                      style: TextStyle(color: AppColors.textTertiary, fontSize: 10, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      change.title,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      change.description,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CREDIBILITY SECTION
// ═══════════════════════════════════════════════════════════════

class _CredibilitySection extends StatelessWidget {
  final Company company;
  const _CredibilitySection({required this.company});

  @override
  Widget build(BuildContext context) {
    final met = company.credibilityTimeline.where((e) => e.met).length;
    final total = company.credibilityTimeline.length;

    return InsightCard(
      title: 'CREDIBILITY SUMMARY',
      icon: Icons.verified_outlined,
      iconColor: AppColors.chartTeal,
      children: [
        // Summary text
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            _buildSummary(company),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontStyle: FontStyle.italic, height: 1.5),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _CredStat(
                label: 'Institutional Sentiment',
                value: company.smartMoneyData.fiiHolding > 20 ? 'Bullish' : 'Neutral',
                color: company.smartMoneyData.fiiHolding > 20 ? AppColors.primary : AppColors.warning,
              ),
            ),
            Expanded(
              child: _CredStat(label: 'Met/Reported', value: '$met / $total', color: AppColors.textPrimary),
            ),
          ],
        ),
      ],
    );
  }

  String _buildSummary(Company c) {
    if (c.credibilityScore > 75) {
      return '"${c.name} maintains a robust financial disclosure framework. While pledging remains a point of observation, the operational cash flows exhibit high consistency with reported profits. Accounting maneuvers appear conservative relative to industry peers."';
    }
    if (c.credibilityScore > 50) {
      return '"${c.name} shows moderate consistency between management claims and outcomes. Some areas of working capital management deserve closer scrutiny. Overall financial reporting is within acceptable bounds."';
    }
    return '"${c.name} exhibits concerning patterns in financial reporting. Significant gaps between management promises and actual results. Cash flow quality and aggressive accounting practices warrant careful monitoring."';
  }
}

class _CredStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _CredStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 10, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SMART MONEY PREVIEW
// ═══════════════════════════════════════════════════════════════

class _SmartMoneyPreview extends StatelessWidget {
  final Company company;
  final BuildContext context;
  const _SmartMoneyPreview({required this.company, required this.context});

  @override
  Widget build(BuildContext context) {
    return InsightCard(
      title: 'SMART MONEY TRACKER',
      icon: Icons.trending_up,
      iconColor: AppColors.chartOrange,
      trailing: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SmartMoneyScreen(company: company),
            ),
          );
        },
        child: const Text('VIEW →', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
      children: [
        Row(
          children: [
            _HoldingBar(label: 'FII', value: company.smartMoneyData.fiiHolding, color: AppColors.primary),
            const SizedBox(width: 8),
            _HoldingBar(label: 'DII', value: company.smartMoneyData.diiHolding, color: AppColors.chartBlue),
            const SizedBox(width: 8),
            _HoldingBar(label: 'Retail', value: company.smartMoneyData.retailHolding, color: AppColors.chartOrange),
          ],
        ),
        if (company.smartMoneyData.isRetailTrap) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.errorDim,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber, color: AppColors.error, size: 16),
                SizedBox(width: 8),
                Expanded(child: Text('⚠️ Retail Trap Signal Detected', style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _HoldingBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _HoldingBar({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text('${value.toStringAsFixed(1)}%', style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 10)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// FORENSIC DASHBOARD BODY (embeddable tab content)
// ═══════════════════════════════════════════════════════════════

class ForensicDashboardBody extends ConsumerWidget {
  const ForensicDashboardBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final company = ref.watch(selectedCompanyProvider);
    if (company == null) {
      return const Center(child: Text('No company selected'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _CompanyHeader(company: company),
          const SizedBox(height: 24),
          _TruthScoreSection(company: company),
          const SizedBox(height: 24),
          _AccountingRiskSection(company: company),
          const SizedBox(height: 8),
          _TruthPriceChart(company: company),
          const SizedBox(height: 8),
          _ForensicSignals(company: company),
          const SizedBox(height: 8),
          _FundamentalTrends(company: company),
          const SizedBox(height: 8),
          _RedFlagsSection(company: company),
          const SizedBox(height: 8),
          _WhatChangedSection(company: company),
          const SizedBox(height: 8),
          _CredibilitySection(company: company),
          const SizedBox(height: 8),
          _SmartMoneyPreview(company: company, context: context),
          const SizedBox(height: 16),
          // SizedBox(
          //   width: double.infinity,
          //   height: 52,
          //   child: ElevatedButton.icon(
          //     onPressed: () {},
          //     icon: const Icon(Icons.download, size: 18),
          //     label: const Text('DOWNLOAD FULL FORENSIC PDF'),
          //     style: ElevatedButton.styleFrom(
          //       backgroundColor: AppColors.primary,
          //       foregroundColor: AppColors.background,
          //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          //     ),
          //   ),
          // ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
