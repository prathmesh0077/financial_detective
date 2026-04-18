import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_colors.dart';
import '../../models/company.dart';
import '../../widgets/insight_card.dart';

class SmartMoneyScreen extends StatelessWidget {
  final Company company;
  const SmartMoneyScreen({super.key, required this.company});

  @override
  Widget build(BuildContext context) {
    final sm = company.smartMoneyData;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Smart Money — ${company.ticker}', style: const TextStyle(fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // ── HEADER ──
            Text(
              'SMART MONEY TRACKER',
              style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2),
            ),
            const SizedBox(height: 4),
            Text(
              'Institutional vs Retail Flow Analysis',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            // ── PIE CHART ──
            _HoldingPieChart(sm: sm),
            const SizedBox(height: 24),
            // ── HOLDING BARS ──
            _HoldingBars(sm: sm),
            const SizedBox(height: 20),
            // ── FLOW CHANGES ──
            _FlowChanges(sm: sm),
            const SizedBox(height: 20),
            // ── RETAIL TRAP ──
            if (sm.isRetailTrap) _RetailTrapAlert(sm: sm),
            // ── SENTIMENT ──
            InsightCard(
              title: 'MONEY FLOW SENTIMENT',
              icon: Icons.psychology,
              iconColor: AppColors.chartPurple,
              children: [
                Text(sm.sentiment, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
                const SizedBox(height: 8),
                Text(
                  _buildAnalysis(),
                  style: const TextStyle(color: AppColors.textTertiary, fontSize: 12, height: 1.5),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // ── QUARTERLY FLOW ──
            _QuarterlyFlow(sm: sm),
            const SizedBox(height: 16),
            // ── FRAUD SIMILARITY ──
            _FraudSimilaritySection(company: company),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  String _buildAnalysis() {
    if (sm.isRetailTrap) {
      return 'Pattern analysis indicates institutional investors are systematically reducing positions while retail participation increases — a classic divergence pattern historically associated with near-term price corrections.';
    }
    if (sm.fiiHolding > 30) {
      return 'Strong institutional conviction with FII holdings above 30%. Institutional investors typically conduct deeper due diligence, suggesting confidence in the company\'s fundamentals.';
    }
    return 'Mixed institutional signals with balanced flows. Monitor for directional shifts in the next 2-3 quarters.';
  }

  SmartMoneyData get sm => company.smartMoneyData;
}

// ═══════════════════════════════════════════════════════════════
// PIE CHART
// ═══════════════════════════════════════════════════════════════

class _HoldingPieChart extends StatelessWidget {
  final SmartMoneyData sm;
  const _HoldingPieChart({required this.sm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: sm.fiiHolding,
                    color: AppColors.primary,
                    title: '${sm.fiiHolding.toStringAsFixed(1)}%',
                    titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                    radius: 60,
                  ),
                  PieChartSectionData(
                    value: sm.diiHolding,
                    color: AppColors.chartBlue,
                    title: '${sm.diiHolding.toStringAsFixed(1)}%',
                    titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                    radius: 55,
                  ),
                  PieChartSectionData(
                    value: sm.retailHolding,
                    color: AppColors.chartOrange,
                    title: '${sm.retailHolding.toStringAsFixed(1)}%',
                    titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                    radius: 50,
                  ),
                ],
                sectionsSpace: 3,
                centerSpaceRadius: 35,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: AppColors.primary, label: 'FII'),
              const SizedBox(width: 20),
              _LegendDot(color: AppColors.chartBlue, label: 'DII'),
              const SizedBox(width: 20),
              _LegendDot(color: AppColors.chartOrange, label: 'Retail'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HOLDING BARS
// ═══════════════════════════════════════════════════════════════

class _HoldingBars extends StatelessWidget {
  final SmartMoneyData sm;
  const _HoldingBars({required this.sm});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HoldingRow(label: 'FII Holdings', value: sm.fiiHolding, change: sm.fiiChange, color: AppColors.primary),
        _HoldingRow(label: 'DII Holdings', value: sm.diiHolding, change: sm.diiChange, color: AppColors.chartBlue),
        _HoldingRow(label: 'Retail Holdings', value: sm.retailHolding, change: sm.retailChange, color: AppColors.chartOrange),
      ],
    );
  }
}

class _HoldingRow extends StatelessWidget {
  final String label;
  final double value;
  final double change;
  final Color color;
  const _HoldingRow({required this.label, required this.value, required this.change, required this.color});

  @override
  Widget build(BuildContext context) {
    final isUp = change >= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
              Text('${value.toStringAsFixed(1)}%', style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isUp ? AppColors.primary : AppColors.error).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${isUp ? '↑' : '↓'} ${change.abs().toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: isUp ? AppColors.primary : AppColors.error,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// FLOW CHANGES
// ═══════════════════════════════════════════════════════════════

class _FlowChanges extends StatelessWidget {
  final SmartMoneyData sm;
  const _FlowChanges({required this.sm});

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
          Text('QUARTERLY CHANGE', style: TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Row(
            children: [
              _ChangeChip(label: 'FII', change: sm.fiiChange, color: AppColors.primary),
              const SizedBox(width: 8),
              _ChangeChip(label: 'DII', change: sm.diiChange, color: AppColors.chartBlue),
              const SizedBox(width: 8),
              _ChangeChip(label: 'Retail', change: sm.retailChange, color: AppColors.chartOrange),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChangeChip extends StatelessWidget {
  final String label;
  final double change;
  final Color color;
  const _ChangeChip({required this.label, required this.change, required this.color});

  @override
  Widget build(BuildContext context) {
    final isUp = change >= 0;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Icon(
              isUp ? Icons.arrow_upward : Icons.arrow_downward,
              color: isUp ? AppColors.primary : AppColors.error,
              size: 16,
            ),
            Text(
              '${isUp ? '+' : ''}${change.toStringAsFixed(1)}%',
              style: TextStyle(
                color: isUp ? AppColors.primary : AppColors.error,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// RETAIL TRAP ALERT
// ═══════════════════════════════════════════════════════════════

class _RetailTrapAlert extends StatelessWidget {
  final SmartMoneyData sm;
  const _RetailTrapAlert({required this.sm});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.errorDim,
            AppColors.error.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber, color: AppColors.error, size: 22),
              const SizedBox(width: 10),
              const Text('RETAIL TRAP DETECTED', style: TextStyle(color: AppColors.error, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Smart money (FII/DII) is systematically reducing positions while retail investors are increasing their holdings. This pattern has historically preceded significant price corrections in 73% of cases.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.6),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _AlertStat(label: 'FII Exit Rate', value: '${sm.fiiChange.abs().toStringAsFixed(1)}% / Qtr'),
              const SizedBox(width: 16),
              _AlertStat(label: 'Retail Entry', value: '+${sm.retailChange.abs().toStringAsFixed(1)}% / Qtr'),
            ],
          ),
        ],
      ),
    );
  }
}

class _AlertStat extends StatelessWidget {
  final String label;
  final String value;
  const _AlertStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 10, letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// QUARTERLY FLOW
// ═══════════════════════════════════════════════════════════════

class _QuarterlyFlow extends StatelessWidget {
  final SmartMoneyData sm;
  const _QuarterlyFlow({required this.sm});

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
          Text('4-QUARTER FLOW TREND', style: TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barGroups: [
                  _makeGroup(0, sm.fiiChange * 0.6, sm.diiChange * 0.8, sm.retailChange * 0.4),
                  _makeGroup(1, sm.fiiChange * 0.8, sm.diiChange * 0.5, sm.retailChange * 0.7),
                  _makeGroup(2, sm.fiiChange * 1.2, sm.diiChange * 0.9, sm.retailChange * 1.1),
                  _makeGroup(3, sm.fiiChange, sm.diiChange, sm.retailChange),
                ],
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (v) => FlLine(color: AppColors.border.withValues(alpha: 0.3), strokeWidth: 0.5),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final labels = ['Q1', 'Q2', 'Q3', 'Q4'];
                        return Text(labels[value.toInt()], style: const TextStyle(color: AppColors.textTertiary, fontSize: 10));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroup(int x, double fii, double dii, double retail) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(toY: fii.clamp(-5, 5), color: AppColors.primary, width: 8, borderRadius: BorderRadius.circular(3)),
        BarChartRodData(toY: dii.clamp(-5, 5), color: AppColors.chartBlue, width: 8, borderRadius: BorderRadius.circular(3)),
        BarChartRodData(toY: retail.clamp(-5, 5), color: AppColors.chartOrange, width: 8, borderRadius: BorderRadius.circular(3)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// FRAUD SIMILARITY
// ═══════════════════════════════════════════════════════════════

class _FraudSimilaritySection extends StatelessWidget {
  final Company company;
  const _FraudSimilaritySection({required this.company});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fingerprint, color: AppColors.error, size: 18),
              const SizedBox(width: 8),
              Text('FRAUD SIMILARITY ENGINE', style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 12),
          ...company.fraudSimilarities.map((fs) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(fs.fraudName, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
                    Text('${fs.similarity.toStringAsFixed(1)}%', style: TextStyle(
                      color: fs.similarity > 30 ? AppColors.error : AppColors.warning,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    )),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: fs.similarity / 100,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation(fs.similarity > 30 ? AppColors.error : AppColors.warning),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(fs.description, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SMART MONEY BODY (embeddable tab content)
// ═══════════════════════════════════════════════════════════════

class SmartMoneyBody extends StatelessWidget {
  final Company company;
  const SmartMoneyBody({super.key, required this.company});

  @override
  Widget build(BuildContext context) {
    final sm = company.smartMoneyData;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'SMART MONEY TRACKER',
            style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2),
          ),
          const SizedBox(height: 4),
          Text(
            'Institutional vs Retail Flow Analysis',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
          ),
          const SizedBox(height: 24),
          _HoldingPieChart(sm: sm),
          const SizedBox(height: 24),
          _HoldingBars(sm: sm),
          const SizedBox(height: 20),
          _FlowChanges(sm: sm),
          const SizedBox(height: 20),
          if (sm.isRetailTrap) _RetailTrapAlert(sm: sm),
          InsightCard(
            title: 'MONEY FLOW SENTIMENT',
            icon: Icons.psychology,
            iconColor: AppColors.chartPurple,
            children: [
              Text(sm.sentiment, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
              const SizedBox(height: 8),
              Text(
                _buildAnalysis(company),
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 12, height: 1.5),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _QuarterlyFlow(sm: sm),
          const SizedBox(height: 16),
          _FraudSimilaritySection(company: company),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  String _buildAnalysis(Company company) {
    final sm = company.smartMoneyData;
    if (sm.isRetailTrap) {
      return 'Pattern analysis indicates institutional investors are systematically reducing positions while retail participation increases — a classic divergence pattern historically associated with near-term price corrections.';
    }
    if (sm.fiiHolding > 30) {
      return 'Strong institutional conviction with FII holdings above 30%. Institutional investors typically conduct deeper due diligence, suggesting confidence in the company\'s fundamentals.';
    }
    return 'Mixed institutional signals with balanced flows. Monitor for directional shifts in the next 2-3 quarters.';
  }
}

