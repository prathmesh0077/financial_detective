import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════

enum Trend { improving, stable, declining }

enum SmartMoneySignal {
  fiiBuying,
  fiiSelling,
  retailAccumulating,
  retailDumping,
  mixed,
}

enum FlagSeverity { high, medium, low }

enum ChangeImpact { positive, negative, neutral }

// ═══════════════════════════════════════════════════════════════
// SUB-MODELS
// ═══════════════════════════════════════════════════════════════

class RedFlag {
  final String title;
  final String description;
  final FlagSeverity severity;

  const RedFlag({
    required this.title,
    required this.description,
    required this.severity,
  });
}

class WhatChanged {
  final String date;
  final String title;
  final String description;
  final ChangeImpact impact;

  const WhatChanged({
    required this.date,
    required this.title,
    required this.description,
    required this.impact,
  });

  IconData get icon {
    switch (impact) {
      case ChangeImpact.positive:
        return Icons.trending_up;
      case ChangeImpact.negative:
        return Icons.trending_down;
      case ChangeImpact.neutral:
        return Icons.info_outline;
    }
  }
}

class CredibilityEntry {
  final String claim;
  final String reality;
  final bool met;
  final String quarter;

  const CredibilityEntry({
    required this.claim,
    required this.reality,
    required this.met,
    required this.quarter,
  });
}

class SmartMoneyData {
  final double fiiHolding;
  final double diiHolding;
  final double retailHolding;
  final double fiiChange;
  final double diiChange;
  final double retailChange;
  final bool isRetailTrap;
  final String sentiment;

  const SmartMoneyData({
    required this.fiiHolding,
    required this.diiHolding,
    required this.retailHolding,
    required this.fiiChange,
    required this.diiChange,
    required this.retailChange,
    required this.isRetailTrap,
    required this.sentiment,
  });
}

class ExpenseItem {
  final String name;
  final double amount;
  final Color color;

  const ExpenseItem({
    required this.name,
    required this.amount,
    required this.color,
  });
}

class MoneyTrailData {
  final double revenue;
  final double grossProfit;
  final double operatingIncome;
  final double netIncome;
  final double cogs;
  final double operatingExpenses;
  final double taxes;
  final double cashConversion;
  final int qualityScore;
  final String riskLevel;
  final List<ExpenseItem> expenses;
  final double taxPaid;

  const MoneyTrailData({
    required this.revenue,
    required this.grossProfit,
    required this.operatingIncome,
    required this.netIncome,
    required this.cogs,
    required this.operatingExpenses,
    required this.taxes,
    required this.cashConversion,
    required this.qualityScore,
    required this.riskLevel,
    required this.expenses,
    required this.taxPaid,
  });

  double get grossMargin => (grossProfit / revenue) * 100;
  double get operatingMargin => (operatingIncome / revenue) * 100;
  double get netMargin => (netIncome / revenue) * 100;
  double get taxRate => (taxes / operatingIncome) * 100;
}

class FraudSimilarity {
  final String fraudName;
  final double similarity;
  final String description;

  const FraudSimilarity({
    required this.fraudName,
    required this.similarity,
    required this.description,
  });
}

// ═══════════════════════════════════════════════════════════════
// MAIN COMPANY MODEL
// ═══════════════════════════════════════════════════════════════

class Company {
  final String name;
  final String ticker;
  final String sector;
  final double price;
  final double changePercent;

  // ── Scores ──
  final int truthScore;
  final int accountingRiskScore;
  final int sentimentScore;
  final int credibilityScore;
  final int managementHonestyScore;

  // ── Signals ──
  final Trend trend;
  final SmartMoneySignal smartMoneySignal;

  // ── Analysis ──
  final double beneishMScore;
  final double altmanZScore;
  final double roce;
  final double operatingMargin;
  final double debtToEquity;

  // ── Insights & Flags ──
  final List<String> keyInsights;
  final List<RedFlag> redFlags;
  final List<WhatChanged> whatChanged;
  final List<CredibilityEntry> credibilityTimeline;
  final List<FraudSimilarity> fraudSimilarities;

  // ── Smart Money & Money Trail ──
  final SmartMoneyData smartMoneyData;
  final MoneyTrailData moneyTrailData;

  // ── Charts ──
  final List<double> priceHistory;
  final List<double> truthScoreHistory;

  const Company({
    required this.name,
    required this.ticker,
    required this.sector,
    required this.price,
    required this.changePercent,
    required this.truthScore,
    required this.accountingRiskScore,
    required this.sentimentScore,
    required this.credibilityScore,
    required this.managementHonestyScore,
    required this.trend,
    required this.smartMoneySignal,
    required this.beneishMScore,
    required this.altmanZScore,
    required this.roce,
    required this.operatingMargin,
    required this.debtToEquity,
    required this.keyInsights,
    required this.redFlags,
    required this.whatChanged,
    required this.credibilityTimeline,
    required this.fraudSimilarities,
    required this.smartMoneyData,
    required this.moneyTrailData,
    required this.priceHistory,
    required this.truthScoreHistory,
  });

  String get beneishRisk {
    if (beneishMScore > -1.78) return 'High Manipulation Risk';
    if (beneishMScore > -2.22) return 'Moderate Risk';
    return 'Low Risk';
  }

  String get altmanStatus {
    if (altmanZScore > 2.99) return 'Safe Zone';
    if (altmanZScore > 1.81) return 'Grey Zone';
    return 'Distress Zone';
  }

  String get trendLabel {
    switch (trend) {
      case Trend.improving:
        return 'Improving';
      case Trend.stable:
        return 'Stable';
      case Trend.declining:
        return 'Declining';
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// PORTFOLIO MODEL
// ═══════════════════════════════════════════════════════════════

class PortfolioHolding {
  final String ticker;
  final String companyName;
  final int shares;
  final double avgPrice;
  final double currentPrice;
  final int truthScore;

  const PortfolioHolding({
    required this.ticker,
    required this.companyName,
    required this.shares,
    required this.avgPrice,
    required this.currentPrice,
    required this.truthScore,
  });

  double get totalValue => shares * currentPrice;
  double get totalCost => shares * avgPrice;
  double get returnPercent => ((currentPrice - avgPrice) / avgPrice) * 100;
  double get pnl => totalValue - totalCost;
}

class Portfolio {
  final String name;
  final List<PortfolioHolding> holdings;

  const Portfolio({
    required this.name,
    required this.holdings,
  });

  double get totalValue =>
      holdings.fold(0.0, (sum, h) => sum + h.totalValue);

  double get totalCost =>
      holdings.fold(0.0, (sum, h) => sum + h.totalCost);

  double get totalReturn => totalCost > 0
      ? ((totalValue - totalCost) / totalCost) * 100
      : 0;

  double get totalPnl => totalValue - totalCost;

  int get portfolioTruthScore {
    if (holdings.isEmpty) return 0;
    final weighted = holdings.fold<double>(
      0,
      (sum, h) => sum + (h.truthScore * h.totalValue),
    );
    return (weighted / totalValue).round();
  }
}
