import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../theme/app_colors.dart';
import '../../models/company.dart';
import '../../providers/app_providers.dart';

class MoneyTrailScreen extends ConsumerWidget {
  const MoneyTrailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companies = ref.watch(companiesProvider);
    // Use first company or a selected one
    final company = ref.watch(selectedCompanyProvider) ?? companies.first;
    final mt = company.moneyTrailData;
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');

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
            child: const Icon(Icons.account_tree_outlined, color: AppColors.primary, size: 20),
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
            // ── HEADER ──
            Text(
              'MONEY TRAIL',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'FISCAL YEAR 2023 REVENUE RECONCILIATION',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 11, letterSpacing: 1.5),
            ),
            const SizedBox(height: 12),
            // Quality + Risk
            Row(
              children: [
                _ScoreChip(label: 'QUALITY SCORE', value: '${mt.qualityScore}/100', color: AppColors.primary),
                const SizedBox(width: 12),
                _ScoreChip(
                  label: 'RISK LEVEL',
                  value: mt.riskLevel.toUpperCase(),
                  color: mt.riskLevel == 'Low' ? AppColors.primary : AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: 24),
            // ── SANKEY FLOW DIAGRAM ──
            _SankeyVisualization(mt: mt, fmt: fmt),
            const SizedBox(height: 24),
            // ── CFO INTEGRITY ──
            _CfoIntegrity(mt: mt),
            const SizedBox(height: 16),
            // ── EXPENSE BREAKDOWN ──
            _ExpenseBreakdown(mt: mt, fmt: fmt),
            const SizedBox(height: 16),
            // ── TAX LEAKAGE ──
            _TaxLeakage(mt: mt, fmt: fmt),
            const SizedBox(height: 16),
            // ── DETAILED FLOW LEDGER ──
            // _FlowLedger(mt: mt, fmt: fmt),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SCORE CHIP
// ═══════════════════════════════════════════════════════════════

class _ScoreChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ScoreChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: AppColors.textTertiary, fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SANKEY VISUALIZATION (CustomPainter)
// ═══════════════════════════════════════════════════════════════

class _SankeyVisualization extends StatelessWidget {
  final MoneyTrailData mt;
  final NumberFormat fmt;
  const _SankeyVisualization({required this.mt, required this.fmt});

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
        children: [
          SizedBox(
            height: 220,
            width: double.infinity,
            child: CustomPaint(
              painter: _SankeyPainter(mt: mt),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _LegendItem(color: AppColors.chartGreen, label: 'REVENUE'),
              _LegendItem(color: AppColors.chartBlue, label: 'GROSS PROFIT'),
              _LegendItem(color: AppColors.chartOrange, label: 'OP. INCOME'),
              _LegendItem(color: AppColors.chartPurple, label: 'NET INCOME'),
              _LegendItem(color: AppColors.error, label: 'COGS / LEAKAGE'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 9, letterSpacing: 0.5)),
      ],
    );
  }
}

class _SankeyPainter extends CustomPainter {
  final MoneyTrailData mt;
  _SankeyPainter({required this.mt});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Normalize values to height
    final maxVal = mt.revenue;
    double norm(double v) => (v / maxVal) * (h * 0.85);

    final revH = norm(mt.revenue);
    final gpH = norm(mt.grossProfit);
    final opH = norm(mt.operatingIncome);
    final netH = norm(mt.netIncome);
    final cogsH = norm(mt.cogs);

    // Column positions
    final cols = [w * 0.05, w * 0.30, w * 0.55, w * 0.80];
    const barW = 24.0;
    final baseY = h * 0.9;

    // Draw bars
    _drawBar(canvas, Rect.fromLTWH(cols[0], baseY - revH, barW, revH), AppColors.chartGreen.withValues(alpha: 0.7));
    _drawBar(canvas, Rect.fromLTWH(cols[1], baseY - gpH, barW, gpH), AppColors.chartBlue.withValues(alpha: 0.7));
    _drawBar(canvas, Rect.fromLTWH(cols[2], baseY - opH, barW, opH), AppColors.chartOrange.withValues(alpha: 0.7));
    _drawBar(canvas, Rect.fromLTWH(cols[3], baseY - netH, barW, netH), AppColors.chartPurple.withValues(alpha: 0.7));

    // Draw flows between bars
    _drawFlow(canvas, cols[0] + barW, baseY - revH, cols[1], baseY - gpH, gpH, AppColors.chartBlue.withValues(alpha: 0.15));
    _drawFlow(canvas, cols[0] + barW, baseY - revH + gpH, cols[1] + barW + 8, baseY - cogsH, cogsH, AppColors.error.withValues(alpha: 0.1));
    _drawFlow(canvas, cols[1] + barW, baseY - gpH, cols[2], baseY - opH, opH, AppColors.chartOrange.withValues(alpha: 0.15));
    _drawFlow(canvas, cols[2] + barW, baseY - opH, cols[3], baseY - netH, netH, AppColors.chartPurple.withValues(alpha: 0.15));

    // Labels
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    final labels = ['Revenue', 'Gross\nProfit', 'Op.\nIncome', 'Net\nIncome'];
    for (var i = 0; i < 4; i++) {
      textPainter.text = TextSpan(
        text: labels[i],
        style: const TextStyle(color: AppColors.textTertiary, fontSize: 9),
      );
      textPainter.layout(maxWidth: barW + 16);
      textPainter.paint(canvas, Offset(cols[i] - 4, baseY + 6));
    }
  }

  void _drawBar(Canvas canvas, Rect rect, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
    canvas.drawRRect(rrect, paint);

    // Glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(rrect, glowPaint);
  }

  void _drawFlow(Canvas canvas, double x1, double y1, double x2, double y2, double flowH, Color color) {
    final path = Path()
      ..moveTo(x1, y1)
      ..cubicTo(x1 + (x2 - x1) * 0.5, y1, x2 - (x2 - x1) * 0.5, y2, x2, y2)
      ..lineTo(x2, y2 + flowH)
      ..cubicTo(x2 - (x2 - x1) * 0.5, y2 + flowH, x1 + (x2 - x1) * 0.5, y1 + flowH, x1, y1 + flowH)
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════
// CFO INTEGRITY
// ═══════════════════════════════════════════════════════════════

class _CfoIntegrity extends StatelessWidget {
  final MoneyTrailData mt;
  const _CfoIntegrity({required this.mt});

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
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('CFO INTEGRITY', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              Icon(Icons.verified, color: mt.cashConversion > 70 ? AppColors.primary : AppColors.warning, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(child: Text('Cash Conversion', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
              Text('${mt.cashConversion.toStringAsFixed(0)}%',
                style: TextStyle(color: mt.cashConversion > 70 ? AppColors.primary : AppColors.warning, fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: mt.cashConversion / 100,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(mt.cashConversion > 70 ? AppColors.primary : AppColors.warning),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            mt.cashConversion > 70
                ? 'Above benchmark: 65% for sector peers. Strong cash conversion indicates quality earnings.'
                : 'Below benchmark: 65% for sector peers. Low conversion implies aggressive revenue recognition.',
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EXPENSE BREAKDOWN
// ═══════════════════════════════════════════════════════════════

class _ExpenseBreakdown extends StatelessWidget {
  final MoneyTrailData mt;
  final NumberFormat fmt;
  const _ExpenseBreakdown({required this.mt, required this.fmt});

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
          const Text('EXPENSE BREAKDOWN', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ...mt.expenses.map((exp) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: exp.color, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 10),
                Expanded(child: Text(exp.name, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                Text('₹${_formatCrore(exp.amount)}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  String _formatCrore(double val) {
    if (val >= 100) return '${(val / 1).toStringAsFixed(1)} Cr';
    return '${val.toStringAsFixed(1)} Cr';
  }
}

// ═══════════════════════════════════════════════════════════════
// TAX LEAKAGE
// ═══════════════════════════════════════════════════════════════

class _TaxLeakage extends StatelessWidget {
  final MoneyTrailData mt;
  final NumberFormat fmt;
  const _TaxLeakage({required this.mt, required this.fmt});

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
          const Text('TAX LEAKAGE', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${mt.taxPaid.toStringAsFixed(0)}Cr',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                    Text('PAID IN FY23', style: TextStyle(color: AppColors.textTertiary, fontSize: 10, letterSpacing: 1)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.errorDim,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${mt.taxRate.toStringAsFixed(0)}%',
                  style: const TextStyle(color: AppColors.error, fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// DETAILED FLOW LEDGER
// ═══════════════════════════════════════════════════════════════

// class _FlowLedger extends StatelessWidget {
//   final MoneyTrailData mt;
//   final NumberFormat fmt;
//   const _FlowLedger({required this.mt, required this.fmt});
//
//   @override
//   Widget build(BuildContext context) {
//     final rows = [
//       _LedgerRow(component: 'Gross Sales', amount: mt.revenue, pctRev: 100.0, trend: '+12.4%', trendPositive: true),
//       _LedgerRow(component: 'Cost of Goods\nSold\n(Leakage)', amount: mt.cogs, pctRev: (mt.cogs / mt.revenue) * 100, trend: '-5.2%', trendPositive: true),
//       _LedgerRow(component: 'Gross\nProfit', amount: mt.grossProfit, pctRev: mt.grossMargin, trend: '+14.2%', trendPositive: true),
//       _LedgerRow(component: 'Operating\nExpenses\n(OPEX)', amount: mt.operatingExpenses, pctRev: (mt.operatingExpenses / mt.revenue) * 100, trend: '+34.2%', trendPositive: false),
//       _LedgerRow(component: 'Net\nProfit\nbefore Tax', amount: mt.operatingIncome, pctRev: mt.operatingMargin, trend: '-3.8%', trendPositive: false),
//       _LedgerRow(component: 'Taxes', amount: mt.taxes, pctRev: (mt.taxes / mt.revenue) * 100, trend: '-2.1%', trendPositive: true),
//       _LedgerRow(component: 'Net\nIncome\n(Bottom\nLine)', amount: mt.netIncome, pctRev: mt.netMargin, trend: '+51.5%', trendPositive: true, isHighlight: true),
//     ];
//
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: AppColors.card,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: AppColors.border, width: 0.5),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               const Expanded(
//                 child: Text('DETAILED FLOW LEDGER', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
//               ),
//               Text('⬆ EXPORT CSV', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
//             ],
//           ),
//           const SizedBox(height: 16),
//           // Table header
//           _TableHeader(),
//           const Divider(color: AppColors.border, height: 1),
//           // Table rows
//           ...rows,
//         ],
//       ),
//     );
//   }
// }
//
// class _TableHeader extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         children: const [
//           Expanded(flex: 3, child: Text('COMPONENT', style: TextStyle(color: AppColors.textTertiary, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1))),
//           Expanded(flex: 3, child: Text('AMOUNT', style: TextStyle(color: AppColors.textTertiary, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1))),
//           Expanded(flex: 2, child: Text('% OF\nREV', style: TextStyle(color: AppColors.textTertiary, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1))),
//           Expanded(flex: 2, child: Text('TREND', style: TextStyle(color: AppColors.textTertiary, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1), textAlign: TextAlign.right)),
//         ],
//       ),
//     );
//   }
// }
//
// class _LedgerRow extends StatelessWidget {
//   final String component;
//   final double amount;
//   final double pctRev;
//   final String trend;
//   final bool trendPositive;
//   final bool isHighlight;
//
//   const _LedgerRow({
//     required this.component,
//     required this.amount,
//     required this.pctRev,
//     required this.trend,
//     required this.trendPositive,
//     this.isHighlight = false,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 10),
//       decoration: BoxDecoration(
//         color: isHighlight ? AppColors.primarySurface : Colors.transparent,
//         border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.3))),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             flex: 3,
//             child: Text(
//               component,
//               style: TextStyle(
//                 color: isHighlight ? AppColors.primary : AppColors.textSecondary,
//                 fontSize: 11,
//                 fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w400,
//               ),
//             ),
//           ),
//           Expanded(
//             flex: 3,
//             child: Text(
//               '₹${_formatAmount(amount)}',
//               style: TextStyle(
//                 color: isHighlight ? AppColors.primary : AppColors.textPrimary,
//                 fontSize: 11,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//           Expanded(
//             flex: 2,
//             child: Text(
//               '${pctRev.toStringAsFixed(1)}%',
//               style: TextStyle(
//                 color: AppColors.textSecondary,
//                 fontSize: 11,
//               ),
//             ),
//           ),
//           Expanded(
//             flex: 2,
//             child: Text(
//               trend,
//               style: TextStyle(
//                 color: trendPositive ? AppColors.primary : AppColors.error,
//                 fontSize: 11,
//                 fontWeight: FontWeight.w600,
//               ),
//               textAlign: TextAlign.right,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   String _formatAmount(double val) {
//     if (val >= 10000) return '${(val / 1000).toStringAsFixed(1)}K Cr';
//     if (val >= 1000) return '${(val / 1).toStringAsFixed(0)} Cr';
//     return '${val.toStringAsFixed(1)} Cr';
//   }
// }

// ═══════════════════════════════════════════════════════════════
// MONEY TRAIL BODY (embeddable tab content)
// ═══════════════════════════════════════════════════════════════

class MoneyTrailBody extends ConsumerWidget {
  const MoneyTrailBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companies = ref.watch(companiesProvider);
    final company = ref.watch(selectedCompanyProvider) ?? companies.first;
    final mt = company.moneyTrailData;
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'MONEY TRAIL',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'FISCAL YEAR 2023 REVENUE RECONCILIATION',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 11, letterSpacing: 1.5),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ScoreChip(label: 'QUALITY SCORE', value: '${mt.qualityScore}/100', color: AppColors.primary),
              const SizedBox(width: 12),
              _ScoreChip(
                label: 'RISK LEVEL',
                value: mt.riskLevel.toUpperCase(),
                color: mt.riskLevel == 'Low' ? AppColors.primary : AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SankeyVisualization(mt: mt, fmt: fmt),
          const SizedBox(height: 24),
          _CfoIntegrity(mt: mt),
          const SizedBox(height: 16),
          _ExpenseBreakdown(mt: mt, fmt: fmt),
          const SizedBox(height: 16),
          _TaxLeakage(mt: mt, fmt: fmt),
          const SizedBox(height: 16),
          // _FlowLedger(mt: mt, fmt: fmt),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
