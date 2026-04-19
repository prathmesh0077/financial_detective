import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../models/company.dart';
// insight_card not directly used on this screen

class PerformanceScreen extends ConsumerStatefulWidget {
  const PerformanceScreen({super.key});

  @override
  ConsumerState<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends ConsumerState<PerformanceScreen> {
  int _selectedPeriod = 3; // default ALL
  final _fmt = NumberFormat('#,##,##0.00', 'en_IN');
  final _periods = [];

  @override
  Widget build(BuildContext context) {
    final portfolio = ref.watch(portfolioProvider);

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
            child: const Icon(Icons.show_chart, color: AppColors.primary, size: 20),
          ),
        ),
        title: const Text('Financial Detective', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: AppColors.textSecondary), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // ── TOTAL GAINS ──
            _MetricSection(
              label: 'TOTAL GAINS',
              icon: Icons.trending_up,
              iconColor: AppColors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '+₹${_fmt.format(portfolio.totalPnl.abs())}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: portfolio.totalPnl >= 0 ? AppColors.primary : AppColors.error,
                    ),
                  ),
                  Text(
                    '+${portfolio.totalReturn.toStringAsFixed(1)}% YTD',
                    style: TextStyle(color: AppColors.primary, fontSize: 13),
                  ),
                ],
              ),
            ),
            // // ── ANNUALIZED ALPHA ──
            // _MetricSection(
            //   label: 'ANNUALIZED ALPHA',
            //   icon: Icons.star_outline,
            //   iconColor: AppColors.warning,
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       const Text('+8.42%', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            //       Text('vs Nifty 50 Benchmark', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
            //     ],
            //   ),
            // ),
            // // ── VOLATILITY ──
            // _MetricSection(
            //   label: 'VOLATILITY (σ)',
            //   icon: Icons.bar_chart,
            //   iconColor: AppColors.chartPurple,
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       const Text('12.1%', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            //       Text('Sharpe Ratio: 1.84', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
            //     ],
            //   ),
            // ),
            // const SizedBox(height: 16),
            // ── EQUITY CURVE ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Equity Curve Comparison',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Relative performance against national benchmark',
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  // Period selector
                  Row(
                    children: List.generate(
                      _periods.length,
                      (i) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedPeriod = i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: _selectedPeriod == i ? AppColors.primary : AppColors.cardLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _periods[i],
                              style: TextStyle(
                                color: _selectedPeriod == i ? AppColors.background : AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Chart
                  SizedBox(
                    height: 200,
                    child: LineChart(_buildEquityCurve()),
                  ),
                  const SizedBox(height: 12),
                  // X-axis labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('JAN 23', style: TextStyle(color: AppColors.textTertiary, fontSize: 9)),
                      Text('MAR 23', style: TextStyle(color: AppColors.textTertiary, fontSize: 9)),
                      Text('MAY 23', style: TextStyle(color: AppColors.textTertiary, fontSize: 9)),
                      Text('JUL 23', style: TextStyle(color: AppColors.textTertiary, fontSize: 9)),
                      Text('SEP 23', style: TextStyle(color: AppColors.textTertiary, fontSize: 9)),
                      Text('NOV 23', style: TextStyle(color: AppColors.textTertiary, fontSize: 9)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // ── RISK METRICS ──
            _RiskMetrics(),
            const SizedBox(height: 16),
            // ── TOP ALPHA DRIVERS ──
            _AlphaDrivers(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  LineChartData _buildEquityCurve() {
    final rng = Random(42);
    final portfolioSpots = <FlSpot>[];
    final benchmarkSpots = <FlSpot>[];

    var portVal = 100.0;
    var benchVal = 100.0;

    final count = [6, 12, 24, 48][_selectedPeriod];

    for (var i = 0; i < count; i++) {
      portVal += portVal * (rng.nextDouble() * 0.06 - 0.015);
      benchVal += benchVal * (rng.nextDouble() * 0.04 - 0.015);
      portfolioSpots.add(FlSpot(i.toDouble(), portVal));
      benchmarkSpots.add(FlSpot(i.toDouble(), benchVal));
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 15,
        getDrawingHorizontalLine: (v) => FlLine(
          color: AppColors.border.withValues(alpha: 0.3),
          strokeWidth: 0.5,
        ),
      ),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: portfolioSpots,
          isCurved: true,
          color: AppColors.primary,
          barWidth: 2.5,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withValues(alpha: 0.15),
                AppColors.primary.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
        LineChartBarData(
          spots: benchmarkSpots,
          isCurved: true,
          color: AppColors.textTertiary,
          barWidth: 1.5,
          dotData: const FlDotData(show: false),
          dashArray: [6, 4],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// METRIC SECTION
// ═══════════════════════════════════════════════════════════════

class _MetricSection extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _MetricSection({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
              const Spacer(),
              Icon(icon, color: iconColor, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// RISK METRICS
// ═══════════════════════════════════════════════════════════════

class _RiskMetrics extends StatelessWidget {
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
          Row(
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text('RISK METRICS ENGINE V2.0', style: TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 16),
          _RiskRow(label: 'MAX DRAWDOWN', value: '-6.42%', color: AppColors.error),
          _RiskRow(label: 'SORTINO RATIO', value: '2.14', color: AppColors.textPrimary),
          _RiskRow(label: 'BETA VS INDEX', value: '0.88', color: AppColors.textPrimary),
          _RiskRow(label: 'UP CAPTURE', value: '114.2%', color: AppColors.primary),
        ],
      ),
    );
  }
}

class _RiskRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _RiskRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
          Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ALPHA DRIVERS
// ═══════════════════════════════════════════════════════════════

class _AlphaDrivers extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final drivers = [
      {'sector': 'Information Tech', 'alpha': '+12.4%', 'color': AppColors.primary, 'barColor': AppColors.primary},
      {'sector': 'Banking & Finance', 'alpha': '+8.1%', 'color': AppColors.primary, 'barColor': AppColors.chartBlue},
      {'sector': 'Energy Sector', 'alpha': '-2.3%', 'color': AppColors.error, 'barColor': AppColors.error},
    ];

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
          Text('TOP ALPHA DRIVERS', style: TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          ...drivers.map((d) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: Text(d['sector'] as String, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                    Text(d['alpha'] as String, style: TextStyle(color: d['color'] as Color, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: 0.6,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation(d['barColor'] as Color),
                    minHeight: 3,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PERFORMANCE BODY (embeddable tab content)
// ═══════════════════════════════════════════════════════════════

class PerformanceBody extends ConsumerStatefulWidget {
  final Company company;
  const PerformanceBody({super.key, required this.company});

  @override
  ConsumerState<PerformanceBody> createState() => _PerformanceBodyState();
}

class _PerformanceBodyState extends ConsumerState<PerformanceBody> {
  int _selectedPeriod = 3;
  final _periods = [];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _MetricSection(
            label: 'TOTAL GAINS',
            icon: Icons.trending_up,
            iconColor: AppColors.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.company.changePercent >= 0 ? '+' : ''}${widget.company.changePercent.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: widget.company.changePercent >= 0 ? AppColors.primary : AppColors.error,
                  ),
                ),
                Text(
                  '₹${widget.company.price.toStringAsFixed(2)} Current Price',
                  style: TextStyle(color: widget.company.changePercent >= 0 ? AppColors.primary : AppColors.error, fontSize: 13),
                ),
              ],
            ),
          ),
          // _MetricSection(
          //   label: 'ANNUALIZED ALPHA',
          //   icon: Icons.star_outline,
          //   iconColor: AppColors.warning,
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       const Text('+8.42%', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          //       Text('vs Nifty 50 Benchmark', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
          //     ],
          //   ),
          // ),
          // _MetricSection(
          //   label: 'VOLATILITY (σ)',
          //   icon: Icons.bar_chart,
          //   iconColor: AppColors.chartPurple,
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       const Text('12.1%', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          //       Text('Sharpe Ratio: 1.84', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
          //     ],
          //   ),
          // ),
          // const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Equity Curve Comparison',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Relative performance against national benchmark',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(
                    _periods.length,
                    (i) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedPeriod = i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: _selectedPeriod == i ? AppColors.primary : AppColors.cardLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _periods[i],
                            style: TextStyle(
                              color: _selectedPeriod == i ? AppColors.background : AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: LineChart(_buildEquityCurve()),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('JAN 23', style: TextStyle(color: AppColors.textTertiary, fontSize: 9)),
                    Text('MAR 23', style: TextStyle(color: AppColors.textTertiary, fontSize: 9)),
                    Text('MAY 23', style: TextStyle(color: AppColors.textTertiary, fontSize: 9)),
                    Text('JUL 23', style: TextStyle(color: AppColors.textTertiary, fontSize: 9)),
                    Text('SEP 23', style: TextStyle(color: AppColors.textTertiary, fontSize: 9)),
                    Text('NOV 23', style: TextStyle(color: AppColors.textTertiary, fontSize: 9)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _RiskMetrics(),
          const SizedBox(height: 16),
          _AlphaDrivers(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  LineChartData _buildEquityCurve() {
    final rng = Random(42);
    final portfolioSpots = <FlSpot>[];
    final benchmarkSpots = <FlSpot>[];

    var portVal = 100.0;
    var benchVal = 100.0;

    final count = [6, 12, 24, 48][_selectedPeriod];

    for (var i = 0; i < count; i++) {
      portVal += portVal * (rng.nextDouble() * 0.06 - 0.015);
      benchVal += benchVal * (rng.nextDouble() * 0.04 - 0.015);
      portfolioSpots.add(FlSpot(i.toDouble(), portVal));
      benchmarkSpots.add(FlSpot(i.toDouble(), benchVal));
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 15,
        getDrawingHorizontalLine: (v) => FlLine(
          color: AppColors.border.withValues(alpha: 0.3),
          strokeWidth: 0.5,
        ),
      ),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: portfolioSpots,
          isCurved: true,
          color: AppColors.primary,
          barWidth: 2.5,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withValues(alpha: 0.15),
                AppColors.primary.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
        LineChartBarData(
          spots: benchmarkSpots,
          isCurved: true,
          color: AppColors.textTertiary,
          barWidth: 1.5,
          dotData: const FlDotData(show: false),
          dashArray: [6, 4],
        ),
      ],
    );
  }
}

