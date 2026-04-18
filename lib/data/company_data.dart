import 'dart:math';
import 'package:flutter/material.dart';
import '../models/company.dart';

// ═══════════════════════════════════════════════════════════════
// COMPANY DATA GENERATOR
// Generates realistic, varied data for 50 Indian companies
// ═══════════════════════════════════════════════════════════════

class CompanyDataGenerator {
  static final _rng = Random(42); // Fixed seed for consistency

  static double _rand(double min, double max) =>
      min + _rng.nextDouble() * (max - min);

  static int _randInt(int min, int max) =>
      min + _rng.nextInt(max - min + 1);

  static List<double> _genPriceHistory(double current, int count) {
    final history = <double>[];
    var price = current * (0.75 + _rng.nextDouble() * 0.2);
    for (var i = 0; i < count; i++) {
      price += price * (_rng.nextDouble() * 0.06 - 0.025);
      history.add(double.parse(price.toStringAsFixed(2)));
    }
    history.add(current);
    return history;
  }

  static List<double> _genScoreHistory(int current, int count) {
    final history = <double>[];
    var score = current - _randInt(-15, 15);
    for (var i = 0; i < count; i++) {
      score += _randInt(-3, 4);
      score = score.clamp(10, 100);
      history.add(score.toDouble());
    }
    history.add(current.toDouble());
    return history;
  }

  static SmartMoneyData _genSmartMoney({
    required double fii,
    required double dii,
    required bool trap,
  }) {
    final retail = 100.0 - fii - dii;
    return SmartMoneyData(
      fiiHolding: fii,
      diiHolding: dii,
      retailHolding: retail,
      fiiChange: _rand(-3, 4),
      diiChange: _rand(-2, 3),
      retailChange: _rand(-4, 5),
      isRetailTrap: trap,
      sentiment: trap
          ? 'Retail accumulating while FIIs exit'
          : (fii > 30 ? 'Institutional confidence high' : 'Mixed signals'),
    );
  }

  static MoneyTrailData _genMoneyTrail(double revenueBase) {
    final rev = revenueBase;
    final cogs = rev * _rand(0.35, 0.68);
    final gp = rev - cogs;
    final opex = gp * _rand(0.25, 0.55);
    final opIncome = gp - opex;
    final taxes = opIncome * _rand(0.18, 0.30);
    final netIncome = opIncome - taxes;
    return MoneyTrailData(
      revenue: rev,
      grossProfit: gp,
      operatingIncome: opIncome,
      netIncome: netIncome,
      cogs: cogs,
      operatingExpenses: opex,
      taxes: taxes,
      cashConversion: _rand(55, 95),
      qualityScore: _randInt(55, 95),
      riskLevel: _randInt(0, 10) > 6 ? 'Moderate' : 'Low',
      expenses: [
        ExpenseItem(name: 'Payroll', amount: opex * 0.45, color: const Color(0xFF448AFF)),
        ExpenseItem(name: 'Marketing', amount: opex * 0.25, color: const Color(0xFF00E676)),
        ExpenseItem(name: 'Administrative', amount: opex * 0.20, color: const Color(0xFFFFD740)),
        ExpenseItem(name: 'R&D', amount: opex * 0.10, color: const Color(0xFF7C4DFF)),
      ],
      taxPaid: taxes,
    );
  }

  static List<RedFlag> _buildFlags(int riskScore, String sector) {
    final flags = <RedFlag>[];
    if (riskScore > 60) {
      flags.add(const RedFlag(
        title: 'High Pledging Detected',
        description: 'Promoter pledged shares increased by 4.2% in last quarter.',
        severity: FlagSeverity.high,
      ));
    }
    if (riskScore > 45) {
      flags.add(const RedFlag(
        title: 'Related Party Transactions',
        description: 'Substantial inter-corporate loans to subsidiaries detected.',
        severity: FlagSeverity.medium,
      ));
    }
    if (riskScore > 30 && sector == 'Banking') {
      flags.add(const RedFlag(
        title: 'Rising NPAs',
        description: 'Non-performing assets increased 12% QoQ, outpacing industry average.',
        severity: FlagSeverity.high,
      ));
    }
    if (riskScore > 50) {
      flags.add(const RedFlag(
        title: 'Contingent Liabilities',
        description: 'FY23 disputes with tax authorities pending resolution.',
        severity: FlagSeverity.medium,
      ));
    }
    if (riskScore > 70) {
      flags.add(const RedFlag(
        title: 'Auditor Qualification',
        description: 'Auditors flagged issues with revenue recognition policy.',
        severity: FlagSeverity.high,
      ));
    }
    if (riskScore <= 30) {
      flags.add(const RedFlag(
        title: 'Minor Disclosure Gap',
        description: 'Segment-level cash flow data not separately reported.',
        severity: FlagSeverity.low,
      ));
    }
    return flags;
  }

  static List<WhatChanged> _buildChanges(int truth, Trend trend) {
    final changes = <WhatChanged>[];
    if (truth > 70) {
      changes.add(const WhatChanged(
        date: 'Mar 2024',
        title: 'Truth Score Upgrade (+4)',
        description: 'Improved debt-to-equity ratio verified via filings.',
        impact: ChangeImpact.positive,
      ));
    }
    if (trend == Trend.declining) {
      changes.add(const WhatChanged(
        date: 'Feb 2024',
        title: 'Margin Compression Detected',
        description: 'Operating margins fell 180bps below 4-quarter average.',
        impact: ChangeImpact.negative,
      ));
    }
    changes.add(WhatChanged(
      date: 'Jan 2024',
      title: truth > 60 ? 'Annual Report Released' : 'New Regulatory Notice',
      description: truth > 60
          ? 'Detailed disclosures confirmed for FY23.'
          : 'SEBI inquiry regarding disclosure of related parties.',
      impact: truth > 60 ? ChangeImpact.neutral : ChangeImpact.negative,
    ));
    return changes;
  }

  static List<CredibilityEntry> _buildCredibility(int credScore) {
    return [
      CredibilityEntry(
        claim: 'Revenue growth > 15% in FY24',
        reality: credScore > 60
            ? 'Achieved 16.2% revenue growth'
            : 'Actual growth was 8.4%',
        met: credScore > 60,
        quarter: 'Q4 FY24',
      ),
      CredibilityEntry(
        claim: 'Debt reduction by ₹5,000 Cr',
        reality: credScore > 50
            ? 'Reduced debt by ₹5,200 Cr'
            : 'Debt increased by ₹1,800 Cr',
        met: credScore > 50,
        quarter: 'Q3 FY24',
      ),
      CredibilityEntry(
        claim: 'New market expansion in FY24',
        reality: credScore > 55
            ? 'Entered 3 new geographies'
            : 'Expansion delayed to FY25',
        met: credScore > 55,
        quarter: 'Q2 FY24',
      ),
      CredibilityEntry(
        claim: 'Operating margin improvement',
        reality: credScore > 65
            ? 'Margins expanded by 120bps'
            : 'Margins contracted by 80bps',
        met: credScore > 65,
        quarter: 'Q1 FY24',
      ),
    ];
  }

  static List<FraudSimilarity> _buildFraudSim(int riskScore) {
    final sims = <FraudSimilarity>[];
    if (riskScore > 60) {
      sims.add(FraudSimilarity(
        fraudName: 'Satyam Pattern',
        similarity: _rand(25, 55),
        description: 'Revenue inflation & receivables mismatch pattern detected.',
      ));
    }
    if (riskScore > 40) {
      sims.add(FraudSimilarity(
        fraudName: 'IL&FS Pattern',
        similarity: _rand(10, 35),
        description: 'Complex inter-corporate loan structure observed.',
      ));
    }
    sims.add(FraudSimilarity(
      fraudName: 'Wirecard Pattern',
      similarity: _rand(5, 20),
      description: 'Third-party payment channel verification gaps.',
    ));
    return sims;
  }

  // ════════════════════════════════════════════════════════════
  // COMPANY SEEDS
  // ════════════════════════════════════════════════════════════

  static List<Company> generateAll() {
    final seeds = <Map<String, dynamic>>[
      {'name': 'Reliance Industries', 'ticker': 'RELIANCE', 'sector': 'Energy', 'price': 2456.70, 'change': 1.24, 'truth': 88, 'risk': 18, 'sent': 82, 'cred': 85, 'honest': 79, 'trend': Trend.improving, 'signal': SmartMoneySignal.fiiBuying, 'beneish': -2.85, 'altman': 3.42, 'roce': 12.5, 'margin': 14.2, 'debt': 0.45, 'fii': 27.5, 'dii': 31.2, 'trap': false, 'rev': 14204.5},
      {'name': 'HDFC Bank', 'ticker': 'HDFCBANK', 'sector': 'Banking', 'price': 1678.30, 'change': -0.42, 'truth': 91, 'risk': 12, 'sent': 88, 'cred': 90, 'honest': 87, 'trend': Trend.stable, 'signal': SmartMoneySignal.fiiBuying, 'beneish': -3.12, 'altman': 3.85, 'roce': 16.8, 'margin': 32.1, 'debt': 0.0, 'fii': 33.4, 'dii': 28.9, 'trap': false, 'rev': 8520.3},
      {'name': 'Bharti Airtel', 'ticker': 'BHARTIARTL', 'sector': 'Telecom', 'price': 1245.80, 'change': 2.15, 'truth': 76, 'risk': 32, 'sent': 74, 'cred': 71, 'honest': 68, 'trend': Trend.improving, 'signal': SmartMoneySignal.fiiBuying, 'beneish': -2.34, 'altman': 2.65, 'roce': 10.2, 'margin': 18.5, 'debt': 1.12, 'fii': 24.8, 'dii': 19.5, 'trap': false, 'rev': 5450.2},
      {'name': 'State Bank of India', 'ticker': 'SBIN', 'sector': 'Banking', 'price': 762.45, 'change': -1.08, 'truth': 72, 'risk': 38, 'sent': 65, 'cred': 68, 'honest': 62, 'trend': Trend.stable, 'signal': SmartMoneySignal.mixed, 'beneish': -2.15, 'altman': 2.42, 'roce': 14.5, 'margin': 25.3, 'debt': 0.0, 'fii': 11.2, 'dii': 35.6, 'trap': false, 'rev': 12800.5},
      {'name': 'ICICI Bank', 'ticker': 'ICICIBANK', 'sector': 'Banking', 'price': 1124.60, 'change': 0.87, 'truth': 85, 'risk': 15, 'sent': 83, 'cred': 82, 'honest': 80, 'trend': Trend.improving, 'signal': SmartMoneySignal.fiiBuying, 'beneish': -2.98, 'altman': 3.55, 'roce': 15.8, 'margin': 30.2, 'debt': 0.0, 'fii': 35.2, 'dii': 27.8, 'trap': false, 'rev': 7650.8},
      {'name': 'Tata Consultancy Services', 'ticker': 'TCS', 'sector': 'IT', 'price': 3542.15, 'change': -0.68, 'truth': 92, 'risk': 8, 'sent': 90, 'cred': 93, 'honest': 91, 'trend': Trend.stable, 'signal': SmartMoneySignal.fiiBuying, 'beneish': -3.45, 'altman': 4.12, 'roce': 42.5, 'margin': 24.8, 'debt': 0.05, 'fii': 14.2, 'dii': 8.5, 'trap': false, 'rev': 6120.4},
      {'name': 'Bajaj Finance', 'ticker': 'BAJFINANCE', 'sector': 'NBFC', 'price': 6845.20, 'change': 1.92, 'truth': 78, 'risk': 28, 'sent': 76, 'cred': 74, 'honest': 72, 'trend': Trend.improving, 'signal': SmartMoneySignal.fiiBuying, 'beneish': -2.45, 'altman': 3.22, 'roce': 19.2, 'margin': 35.6, 'debt': 2.85, 'fii': 18.5, 'dii': 12.8, 'trap': false, 'rev': 4580.6},
      {'name': 'Larsen & Toubro', 'ticker': 'LT', 'sector': 'Infrastructure', 'price': 3245.90, 'change': 0.45, 'truth': 82, 'risk': 22, 'sent': 78, 'cred': 80, 'honest': 76, 'trend': Trend.stable, 'signal': SmartMoneySignal.fiiBuying, 'beneish': -2.72, 'altman': 3.18, 'roce': 14.8, 'margin': 10.5, 'debt': 0.92, 'fii': 22.4, 'dii': 25.6, 'trap': false, 'rev': 9850.2},
      {'name': 'Infosys', 'ticker': 'INFY', 'sector': 'IT', 'price': 1456.80, 'change': -1.35, 'truth': 89, 'risk': 10, 'sent': 85, 'cred': 88, 'honest': 86, 'trend': Trend.stable, 'signal': SmartMoneySignal.fiiBuying, 'beneish': -3.25, 'altman': 4.05, 'roce': 35.2, 'margin': 21.5, 'debt': 0.08, 'fii': 35.8, 'dii': 15.2, 'trap': false, 'rev': 5420.8},
      {'name': 'Hindustan Unilever', 'ticker': 'HINDUNILVR', 'sector': 'FMCG', 'price': 2345.60, 'change': -0.22, 'truth': 86, 'risk': 14, 'sent': 80, 'cred': 84, 'honest': 82, 'trend': Trend.stable, 'signal': SmartMoneySignal.mixed, 'beneish': -3.08, 'altman': 3.92, 'roce': 85.2, 'margin': 23.8, 'debt': 0.02, 'fii': 12.8, 'dii': 9.5, 'trap': false, 'rev': 3850.4},
      {'name': 'Axis Bank', 'ticker': 'AXISBANK', 'sector': 'Banking', 'price': 1089.45, 'change': 1.56, 'truth': 74, 'risk': 30, 'sent': 70, 'cred': 72, 'honest': 68, 'trend': Trend.improving, 'signal': SmartMoneySignal.fiiBuying, 'beneish': -2.28, 'altman': 2.85, 'roce': 13.5, 'margin': 28.5, 'debt': 0.0, 'fii': 28.5, 'dii': 30.2, 'trap': false, 'rev': 6520.5},
      {'name': 'Maruti Suzuki', 'ticker': 'MARUTI', 'sector': 'Auto', 'price': 10845.30, 'change': 0.92, 'truth': 84, 'risk': 16, 'sent': 82, 'cred': 81, 'honest': 78, 'trend': Trend.improving, 'signal': SmartMoneySignal.fiiBuying, 'beneish': -2.95, 'altman': 3.68, 'roce': 18.5, 'margin': 12.2, 'debt': 0.0, 'fii': 22.5, 'dii': 18.4, 'trap': false, 'rev': 4520.8},
      {'name': 'Mahindra & Mahindra', 'ticker': 'M&M', 'sector': 'Auto', 'price': 2456.70, 'change': 2.45, 'truth': 77, 'risk': 26, 'sent': 75, 'cred': 73, 'honest': 71, 'trend': Trend.improving, 'signal': SmartMoneySignal.fiiBuying, 'beneish': -2.42, 'altman': 3.15, 'roce': 15.2, 'margin': 13.8, 'debt': 0.68, 'fii': 35.2, 'dii': 18.9, 'trap': false, 'rev': 5680.5},
      {'name': 'Sun Pharmaceutical', 'ticker': 'SUNPHARMA', 'sector': 'Pharma', 'price': 1678.90, 'change': -0.85, 'truth': 71, 'risk': 35, 'sent': 68, 'cred': 66, 'honest': 64, 'trend': Trend.stable, 'signal': SmartMoneySignal.mixed, 'beneish': -2.05, 'altman': 2.92, 'roce': 12.8, 'margin': 22.5, 'debt': 0.25, 'fii': 18.5, 'dii': 14.2, 'trap': false, 'rev': 3250.6},
      {'name': 'Titan', 'ticker': 'TITAN', 'sector': 'Consumer', 'price': 3245.80, 'change': 1.12, 'truth': 83, 'risk': 19, 'sent': 81, 'cred': 79, 'honest': 77, 'trend': Trend.improving, 'signal': SmartMoneySignal.fiiBuying, 'beneish': -2.88, 'altman': 3.52, 'roce': 25.5, 'margin': 12.5, 'debt': 0.15, 'fii': 19.8, 'dii': 11.5, 'trap': false, 'rev': 4120.3},
      {'name': 'HCL Technologies', 'ticker': 'HCLTECH', 'sector': 'IT', 'price': 1542.30, 'change': -0.45, 'truth': 87, 'risk': 11, 'sent': 84, 'cred': 86, 'honest': 83, 'trend': Trend.stable, 'signal': SmartMoneySignal.fiiBuying, 'beneish': -3.18, 'altman': 3.98, 'roce': 28.5, 'margin': 19.8, 'debt': 0.10, 'fii': 28.2, 'dii': 12.5, 'trap': false, 'rev': 4850.2},
      {'name': 'NTPC', 'ticker': 'NTPC', 'sector': 'Power', 'price': 342.60, 'change': 0.68, 'truth': 73, 'risk': 28, 'sent': 70, 'cred': 71, 'honest': 67, 'trend': Trend.stable, 'signal': SmartMoneySignal.mixed, 'beneish': -2.35, 'altman': 2.55, 'roce': 10.5, 'margin': 18.2, 'debt': 1.45, 'fii': 15.8, 'dii': 38.5, 'trap': false, 'rev': 8520.4},
      {'name': 'ITC', 'ticker': 'ITC', 'sector': 'FMCG', 'price': 445.20, 'change': -0.32, 'truth': 80, 'risk': 20, 'sent': 76, 'cred': 78, 'honest': 75, 'trend': Trend.stable, 'signal': SmartMoneySignal.mixed, 'beneish': -2.78, 'altman': 3.35, 'roce': 28.5, 'margin': 35.2, 'debt': 0.0, 'fii': 12.5, 'dii': 42.5, 'trap': false, 'rev': 5680.2},
      {'name': 'Kotak Mahindra Bank', 'ticker': 'KOTAKBANK', 'sector': 'Banking', 'price': 1845.60, 'change': 0.55, 'truth': 86, 'risk': 14, 'sent': 82, 'cred': 84, 'honest': 81, 'trend': Trend.stable, 'signal': SmartMoneySignal.fiiBuying, 'beneish': -3.05, 'altman': 3.72, 'roce': 14.2, 'margin': 38.5, 'debt': 0.0, 'fii': 38.5, 'dii': 18.2, 'trap': false, 'rev': 4850.5},
      {'name': 'Oil & Natural Gas Corp', 'ticker': 'ONGC', 'sector': 'Energy', 'price': 258.90, 'change': -1.65, 'truth': 62, 'risk': 42, 'sent': 58, 'cred': 60, 'honest': 55, 'trend': Trend.declining, 'signal': SmartMoneySignal.fiiSelling, 'beneish': -1.92, 'altman': 2.15, 'roce': 11.5, 'margin': 22.8, 'debt': 0.55, 'fii': 8.5, 'dii': 42.8, 'trap': true, 'rev': 12500.8},
      {'name': 'UltraTech Cement', 'ticker': 'ULTRACEMCO', 'sector': 'Cement', 'price': 9456.30, 'change': 0.78, 'truth': 81, 'risk': 20, 'sent': 79, 'cred': 77, 'honest': 75, 'trend': Trend.improving, 'signal': SmartMoneySignal.fiiBuying, 'beneish': -2.82, 'altman': 3.28, 'roce': 12.5, 'margin': 16.8, 'debt': 0.42, 'fii': 20.5, 'dii': 15.8, 'trap': false, 'rev': 6250.4},
      {'name': 'Adani Ports & SEZ', 'ticker': 'ADANIPORTS', 'sector': 'Infrastructure', 'price': 1245.60, 'change': -2.85, 'truth': 48, 'risk': 62, 'sent': 42, 'cred': 45, 'honest': 40, 'trend': Trend.declining, 'signal': SmartMoneySignal.fiiSelling, 'beneish': -1.55, 'altman': 1.95, 'roce': 9.8, 'margin': 42.5, 'debt': 1.85, 'fii': 14.2, 'dii': 22.5, 'trap': true, 'rev': 7850.6},
      {'name': 'Bharat Electronics', 'ticker': 'BEL', 'sector': 'Defence', 'price': 245.80, 'change': 3.42, 'truth': 79, 'risk': 22, 'sent': 77, 'cred': 76, 'honest': 74, 'trend': Trend.improving, 'signal': SmartMoneySignal.fiiBuying, 'beneish': -2.68, 'altman': 3.45, 'roce': 22.5, 'margin': 21.8, 'debt': 0.05, 'fii': 8.5, 'dii': 45.2, 'trap': false, 'rev': 3520.5},
      {'name': 'JSW Steel', 'ticker': 'JSWSTEEL', 'sector': 'Metals', 'price': 845.60, 'change': -1.42, 'truth': 65, 'risk': 40, 'sent': 62, 'cred': 63, 'honest': 60, 'trend': Trend.declining, 'signal': SmartMoneySignal.mixed, 'beneish': -2.08, 'altman': 2.25, 'roce': 8.5, 'margin': 12.8, 'debt': 1.25, 'fii': 18.2, 'dii': 22.5, 'trap': false, 'rev': 9520.8},
      {'name': 'Bajaj Finserv', 'ticker': 'BAJAJFINSV', 'sector': 'NBFC', 'price': 1645.30, 'change': 0.95, 'truth': 80, 'risk': 24, 'sent': 78, 'cred': 76, 'honest': 74, 'trend': Trend.stable, 'signal': SmartMoneySignal.fiiBuying, 'beneish': -2.62, 'altman': 3.15, 'roce': 12.8, 'margin': 28.5, 'debt': 1.45, 'fii': 11.5, 'dii': 8.5, 'trap': false, 'rev': 3450.2},
      {'name': 'Power Grid Corp', 'ticker': 'POWERGRID', 'sector': 'Power', 'price': 312.40, 'change': 0.38, 'truth': 75, 'risk': 25, 'sent': 72, 'cred': 73, 'honest': 70, 'trend': Trend.stable, 'signal': SmartMoneySignal.mixed, 'beneish': -2.52, 'altman': 2.72, 'roce': 14.5, 'margin': 35.2, 'debt': 1.85, 'fii': 22.5, 'dii': 32.8, 'trap': false, 'rev': 4520.8},
      {'name': 'Bajaj Auto', 'ticker': 'BAJAJ-AUTO', 'sector': 'Auto', 'price': 8456.70, 'change': 1.85, 'truth': 85, 'risk': 12, 'sent': 83, 'cred': 82, 'honest': 80, 'trend': Trend.improving, 'signal': SmartMoneySignal.fiiBuying, 'beneish': -3.05, 'altman': 3.82, 'roce': 28.5, 'margin': 18.5, 'debt': 0.0, 'fii': 12.5, 'dii': 14.8, 'trap': false, 'rev': 4250.6},
      {'name': 'Coal India', 'ticker': 'COALINDIA', 'sector': 'Mining', 'price': 425.30, 'change': -0.72, 'truth': 68, 'risk': 35, 'sent': 64, 'cred': 66, 'honest': 62, 'trend': Trend.declining, 'signal': SmartMoneySignal.fiiSelling, 'beneish': -2.18, 'altman': 2.48, 'roce': 55.2, 'margin': 28.5, 'debt': 0.08, 'fii': 8.2, 'dii': 48.5, 'trap': false, 'rev': 7850.4},
      {'name': 'Tata Steel', 'ticker': 'TATASTEEL', 'sector': 'Metals', 'price': 145.60, 'change': -2.15, 'truth': 58, 'risk': 48, 'sent': 55, 'cred': 56, 'honest': 52, 'trend': Trend.declining, 'signal': SmartMoneySignal.fiiSelling, 'beneish': -1.85, 'altman': 1.92, 'roce': 5.2, 'margin': 8.5, 'debt': 1.65, 'fii': 18.5, 'dii': 15.2, 'trap': true, 'rev': 11250.8},
      {'name': 'Adani Enterprises', 'ticker': 'ADANIENT', 'sector': 'Conglomerate', 'price': 2845.60, 'change': -3.42, 'truth': 35, 'risk': 78, 'sent': 32, 'cred': 30, 'honest': 28, 'trend': Trend.declining, 'signal': SmartMoneySignal.fiiSelling, 'beneish': -1.25, 'altman': 1.45, 'roce': 6.5, 'margin': 4.2, 'debt': 2.85, 'fii': 8.5, 'dii': 12.5, 'trap': true, 'rev': 15850.2},
      {'name': 'Nestle India', 'ticker': 'NESTLEIND', 'sector': 'FMCG', 'price': 2345.80, 'change': 0.28, 'truth': 90, 'risk': 8, 'sent': 88, 'cred': 91, 'honest': 89, 'trend': Trend.stable, 'signal': SmartMoneySignal.fiiBuying, 'beneish': -3.38, 'altman': 4.15, 'roce': 102.5, 'margin': 22.5, 'debt': 0.0, 'fii': 8.5, 'dii': 5.2, 'trap': false, 'rev': 1850.5},
      {'name': 'Eternal (Zomato)', 'ticker': 'ETERNAL', 'sector': 'Tech', 'price': 178.90, 'change': 4.25, 'truth': 55, 'risk': 52, 'sent': 72, 'cred': 48, 'honest': 50, 'trend': Trend.improving, 'signal': SmartMoneySignal.retailAccumulating, 'beneish': -1.62, 'altman': 1.85, 'roce': -2.5, 'margin': -5.8, 'debt': 0.15, 'fii': 32.5, 'dii': 12.8, 'trap': true, 'rev': 1250.4},
      {'name': 'Asian Paints', 'ticker': 'ASIANPAINT', 'sector': 'Consumer', 'price': 2845.30, 'change': -0.55, 'truth': 84, 'risk': 15, 'sent': 82, 'cred': 83, 'honest': 80, 'trend': Trend.stable, 'signal': SmartMoneySignal.mixed, 'beneish': -2.95, 'altman': 3.72, 'roce': 32.5, 'margin': 18.5, 'debt': 0.12, 'fii': 18.5, 'dii': 8.5, 'trap': false, 'rev': 3450.8},
      {'name': 'Hindalco Industries', 'ticker': 'HINDALCO', 'sector': 'Metals', 'price': 578.90, 'change': -1.85, 'truth': 64, 'risk': 38, 'sent': 60, 'cred': 62, 'honest': 58, 'trend': Trend.declining, 'signal': SmartMoneySignal.mixed, 'beneish': -2.12, 'altman': 2.35, 'roce': 9.5, 'margin': 10.8, 'debt': 0.95, 'fii': 28.5, 'dii': 15.2, 'trap': false, 'rev': 8520.6},
      {'name': 'Wipro', 'ticker': 'WIPRO', 'sector': 'IT', 'price': 445.60, 'change': -0.95, 'truth': 75, 'risk': 22, 'sent': 68, 'cred': 72, 'honest': 70, 'trend': Trend.declining, 'signal': SmartMoneySignal.fiiSelling, 'beneish': -2.55, 'altman': 3.15, 'roce': 15.8, 'margin': 16.2, 'debt': 0.18, 'fii': 8.5, 'dii': 12.8, 'trap': false, 'rev': 4520.4},
      {'name': 'Eicher Motors', 'ticker': 'EICHERMOT', 'sector': 'Auto', 'price': 4256.80, 'change': 1.45, 'truth': 82, 'risk': 18, 'sent': 80, 'cred': 78, 'honest': 76, 'trend': Trend.improving, 'signal': SmartMoneySignal.fiiBuying, 'beneish': -2.85, 'altman': 3.55, 'roce': 22.8, 'margin': 25.5, 'debt': 0.0, 'fii': 28.5, 'dii': 5.8, 'trap': false, 'rev': 1850.2},
      {'name': 'SBI Life Insurance', 'ticker': 'SBILIFE', 'sector': 'Insurance', 'price': 1456.30, 'change': 0.62, 'truth': 78, 'risk': 20, 'sent': 75, 'cred': 76, 'honest': 73, 'trend': Trend.stable, 'signal': SmartMoneySignal.mixed, 'beneish': -2.65, 'altman': 3.12, 'roce': 18.5, 'margin': 12.8, 'debt': 0.0, 'fii': 22.5, 'dii': 18.5, 'trap': false, 'rev': 2850.4},
      {'name': 'Shriram Finance', 'ticker': 'SHRIRAMFIN', 'sector': 'NBFC', 'price': 2345.80, 'change': 1.82, 'truth': 73, 'risk': 30, 'sent': 70, 'cred': 71, 'honest': 68, 'trend': Trend.improving, 'signal': SmartMoneySignal.fiiBuying, 'beneish': -2.32, 'altman': 2.85, 'roce': 13.5, 'margin': 32.5, 'debt': 3.25, 'fii': 42.5, 'dii': 15.2, 'trap': false, 'rev': 3250.6},
      {'name': 'Grasim Industries', 'ticker': 'GRASIM', 'sector': 'Cement', 'price': 2456.70, 'change': 0.32, 'truth': 76, 'risk': 25, 'sent': 73, 'cred': 74, 'honest': 71, 'trend': Trend.stable, 'signal': SmartMoneySignal.mixed, 'beneish': -2.48, 'altman': 2.95, 'roce': 8.5, 'margin': 11.2, 'debt': 0.55, 'fii': 18.5, 'dii': 22.8, 'trap': false, 'rev': 8520.4},
      {'name': 'Interglobe Aviation', 'ticker': 'INDIGO', 'sector': 'Aviation', 'price': 4256.30, 'change': 2.85, 'truth': 70, 'risk': 35, 'sent': 72, 'cred': 68, 'honest': 65, 'trend': Trend.improving, 'signal': SmartMoneySignal.fiiBuying, 'beneish': -2.15, 'altman': 2.42, 'roce': 35.5, 'margin': 14.8, 'debt': 1.25, 'fii': 42.8, 'dii': 8.5, 'trap': false, 'rev': 6520.8},
      {'name': 'Jio Financial Services', 'ticker': 'JIOFIN', 'sector': 'NBFC', 'price': 328.40, 'change': -1.25, 'truth': 52, 'risk': 55, 'sent': 65, 'cred': 42, 'honest': 45, 'trend': Trend.stable, 'signal': SmartMoneySignal.retailAccumulating, 'beneish': -1.72, 'altman': 1.95, 'roce': 2.5, 'margin': 8.5, 'debt': 0.0, 'fii': 5.2, 'dii': 8.5, 'trap': true, 'rev': 450.2},
      {'name': 'Tech Mahindra', 'ticker': 'TECHM', 'sector': 'IT', 'price': 1345.60, 'change': 0.72, 'truth': 74, 'risk': 24, 'sent': 70, 'cred': 72, 'honest': 69, 'trend': Trend.improving, 'signal': SmartMoneySignal.mixed, 'beneish': -2.45, 'altman': 3.08, 'roce': 12.8, 'margin': 11.5, 'debt': 0.12, 'fii': 28.5, 'dii': 12.5, 'trap': false, 'rev': 5250.4},
      {'name': 'Trent', 'ticker': 'TRENT', 'sector': 'Retail', 'price': 5245.80, 'change': 3.85, 'truth': 79, 'risk': 22, 'sent': 82, 'cred': 75, 'honest': 73, 'trend': Trend.improving, 'signal': SmartMoneySignal.fiiBuying, 'beneish': -2.58, 'altman': 3.22, 'roce': 18.5, 'margin': 8.5, 'debt': 0.45, 'fii': 15.2, 'dii': 8.5, 'trap': false, 'rev': 1450.6},
      {'name': 'HDFC Life Insurance', 'ticker': 'HDFCLIFE', 'sector': 'Insurance', 'price': 645.30, 'change': -0.42, 'truth': 81, 'risk': 18, 'sent': 78, 'cred': 80, 'honest': 77, 'trend': Trend.stable, 'signal': SmartMoneySignal.fiiBuying, 'beneish': -2.78, 'altman': 3.35, 'roce': 22.5, 'margin': 15.8, 'debt': 0.0, 'fii': 25.8, 'dii': 22.5, 'trap': false, 'rev': 2120.8},
      {'name': 'Tata Motors', 'ticker': 'TATAMOTORS', 'sector': 'Auto', 'price': 845.60, 'change': -0.68, 'truth': 67, 'risk': 38, 'sent': 72, 'cred': 62, 'honest': 60, 'trend': Trend.improving, 'signal': SmartMoneySignal.mixed, 'beneish': -2.02, 'altman': 2.15, 'roce': 8.5, 'margin': 6.8, 'debt': 1.42, 'fii': 18.5, 'dii': 22.5, 'trap': false, 'rev': 18520.6},
      {'name': 'Apollo Hospitals', 'ticker': 'APOLLOHOSP', 'sector': 'Healthcare', 'price': 6245.80, 'change': 1.25, 'truth': 80, 'risk': 22, 'sent': 78, 'cred': 77, 'honest': 75, 'trend': Trend.improving, 'signal': SmartMoneySignal.fiiBuying, 'beneish': -2.72, 'altman': 3.18, 'roce': 12.8, 'margin': 12.5, 'debt': 0.65, 'fii': 32.5, 'dii': 12.8, 'trap': false, 'rev': 2450.4},
      {'name': 'Tata Consumer Products', 'ticker': 'TATACONSUM', 'sector': 'FMCG', 'price': 1145.30, 'change': 0.55, 'truth': 77, 'risk': 21, 'sent': 74, 'cred': 75, 'honest': 72, 'trend': Trend.stable, 'signal': SmartMoneySignal.mixed, 'beneish': -2.58, 'altman': 3.12, 'roce': 8.5, 'margin': 14.5, 'debt': 0.18, 'fii': 18.5, 'dii': 15.2, 'trap': false, 'rev': 1850.6},
      {'name': 'Dr Reddys Laboratories', 'ticker': 'DRREDDY', 'sector': 'Pharma', 'price': 5645.80, 'change': 0.85, 'truth': 82, 'risk': 18, 'sent': 80, 'cred': 81, 'honest': 78, 'trend': Trend.stable, 'signal': SmartMoneySignal.fiiBuying, 'beneish': -2.82, 'altman': 3.48, 'roce': 18.5, 'margin': 24.5, 'debt': 0.12, 'fii': 22.5, 'dii': 12.8, 'trap': false, 'rev': 2850.4},
      {'name': 'Cipla', 'ticker': 'CIPLA', 'sector': 'Pharma', 'price': 1456.30, 'change': 1.12, 'truth': 81, 'risk': 17, 'sent': 79, 'cred': 80, 'honest': 77, 'trend': Trend.improving, 'signal': SmartMoneySignal.fiiBuying, 'beneish': -2.78, 'altman': 3.42, 'roce': 16.5, 'margin': 22.8, 'debt': 0.08, 'fii': 25.8, 'dii': 14.5, 'trap': false, 'rev': 2520.6},
      {'name': 'Max Healthcare', 'ticker': 'MAXHEALTH', 'sector': 'Healthcare', 'price': 845.60, 'change': 2.15, 'truth': 76, 'risk': 24, 'sent': 75, 'cred': 73, 'honest': 71, 'trend': Trend.improving, 'signal': SmartMoneySignal.fiiBuying, 'beneish': -2.52, 'altman': 3.08, 'roce': 14.5, 'margin': 18.5, 'debt': 0.35, 'fii': 28.5, 'dii': 12.5, 'trap': false, 'rev': 1250.8},
    ];

    return seeds.map((s) {
      final truthScore = s['truth'] as int;
      final riskScore = s['risk'] as int;
      final credScore = s['cred'] as int;
      final trend = s['trend'] as Trend;
      final price = s['price'] as double;

      return Company(
        name: s['name'] as String,
        ticker: s['ticker'] as String,
        sector: s['sector'] as String,
        price: price,
        changePercent: s['change'] as double,
        truthScore: truthScore,
        accountingRiskScore: riskScore,
        sentimentScore: s['sent'] as int,
        credibilityScore: credScore,
        managementHonestyScore: s['honest'] as int,
        trend: trend,
        smartMoneySignal: s['signal'] as SmartMoneySignal,
        beneishMScore: s['beneish'] as double,
        altmanZScore: s['altman'] as double,
        roce: s['roce'] as double,
        operatingMargin: s['margin'] as double,
        debtToEquity: s['debt'] as double,
        keyInsights: _generateInsights(s),
        redFlags: _buildFlags(riskScore, s['sector'] as String),
        whatChanged: _buildChanges(truthScore, trend),
        credibilityTimeline: _buildCredibility(credScore),
        fraudSimilarities: _buildFraudSim(riskScore),
        smartMoneyData: _genSmartMoney(
          fii: s['fii'] as double,
          dii: s['dii'] as double,
          trap: s['trap'] as bool,
        ),
        moneyTrailData: _genMoneyTrail(s['rev'] as double),
        priceHistory: _genPriceHistory(price, 24),
        truthScoreHistory: _genScoreHistory(truthScore, 12),
      );
    }).toList();
  }

  static List<String> _generateInsights(Map<String, dynamic> s) {
    final insights = <String>[];
    final truth = s['truth'] as int;
    final sector = s['sector'] as String;
    final trend = s['trend'] as Trend;

    if (truth > 80) {
      insights.add('Strong financial discipline with consistent cash flow generation over last 8 quarters.');
    } else if (truth > 60) {
      insights.add('Moderate financial health with some areas of concern in working capital management.');
    } else {
      insights.add('Elevated risk profile with significant divergence between reported earnings and cash flow.');
    }

    if (trend == Trend.improving) {
      insights.add('ROCE improving YoY indicating better capital deployment and operational efficiency.');
    } else if (trend == Trend.declining) {
      insights.add('Declining margins and rising debt levels signal potential stress in the business model.');
    }

    if (sector == 'Banking') {
      insights.add('Asset quality remains under watch — monitor GNPA trajectory for the next 2 quarters.');
    } else if (sector == 'IT') {
      insights.add('Deal pipeline healthy but attrition-driven margin pressure continues.');
    } else {
      insights.add('Industry tailwinds support near-term growth, but valuation stretched vs. peers.');
    }

    return insights;
  }
}
