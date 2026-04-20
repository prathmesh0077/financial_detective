import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/company.dart';
import '../data/company_data.dart';
import '../services/supabase_service.dart';
import '../services/price_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());


// ═══════════════════════════════════════════════════════════════
// AUTH PROVIDER
// ═══════════════════════════════════════════════════════════════

class AuthState {
  final bool isLoggedIn;
  final String? email;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.isLoggedIn = false,
    this.email,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    String? email,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      email: email ?? this.email,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _restoreSession();
  }

  void _restoreSession() {
    if (SupabaseService.isLoggedIn) {
      state = AuthState(
        isLoggedIn: true,
        email: SupabaseService.currentUserEmail,
      );
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await SupabaseService.signIn(email, password);
      state = AuthState(
        isLoggedIn: true,
        email: SupabaseService.currentUserEmail ?? email,
      );
    } catch (e) {
      String msg = 'Login failed';
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('invalid login credentials') ||
          errStr.contains('invalid_credentials')) {
        msg = 'Invalid email or password';
      } else if (errStr.contains('email not confirmed')) {
        msg = 'Please confirm your email first';
      } else if (errStr.contains('user not found')) {
        msg = 'No account found with this email';
      } else if (errStr.contains('network') || errStr.contains('socket')) {
        msg = 'Network error. Check your connection.';
      }
      state = state.copyWith(isLoading: false, errorMessage: msg);
    }
  }

  Future<void> signup(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await SupabaseService.signUp(email, password);
      if (response.user != null) {
        // Check if email confirmation is required
        if (response.session != null) {
          state = AuthState(
            isLoggedIn: true,
            email: response.user!.email ?? email,
          );
        } else {
          // Email confirmation required
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'Check your email to confirm your account',
          );
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Signup failed. Please try again.',
        );
      }
    } catch (e) {
      String msg = 'Signup failed';
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('already registered') ||
          errStr.contains('user_already_exists')) {
        msg = 'An account with this email already exists';
      } else if (errStr.contains('password')) {
        msg = 'Password must be at least 6 characters';
      } else if (errStr.contains('valid email') || errStr.contains('invalid')) {
        msg = 'Please enter a valid email address';
      } else if (errStr.contains('network') || errStr.contains('socket')) {
        msg = 'Network error. Check your connection.';
      }
      state = state.copyWith(isLoading: false, errorMessage: msg);
    }
  }

  Future<void> logout() async {
    try {
      await SupabaseService.signOut();
    } catch (_) {}
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);

// ═══════════════════════════════════════════════════════════════
// COMPANIES PROVIDER
// ═══════════════════════════════════════════════════════════════

Company _mapRowToCompany(Map<String, dynamic> row) {
  // Parse smart money signal
  SmartMoneySignal parseSignal(String? s) {
    switch (s) {
      case 'fiiBuying': return SmartMoneySignal.fiiBuying;
      case 'fiiSelling': return SmartMoneySignal.fiiSelling;
      case 'retailAccumulating': return SmartMoneySignal.retailAccumulating;
      case 'retailDumping': return SmartMoneySignal.retailDumping;
      default: return SmartMoneySignal.mixed;
    }
  }

  Trend parseTrend(String? s) {
    switch (s) {
      case 'improving': return Trend.improving;
      case 'declining': return Trend.declining;
      default: return Trend.stable;
    }
  }

  FlagSeverity parseSeverity(String? s) {
    switch (s) {
      case 'high': return FlagSeverity.high;
      case 'medium': return FlagSeverity.medium;
      default: return FlagSeverity.low;
    }
  }

  ChangeImpact parseImpact(String? s) {
    switch (s) {
      case 'positive': return ChangeImpact.positive;
      case 'negative': return ChangeImpact.negative;
      default: return ChangeImpact.neutral;
    }
  }

  // Parse JSON arrays safely
  final keyInsightsRaw = row['key_insights'];
  List<String> keyInsights = [];
  if (keyInsightsRaw is List) {
    keyInsights = keyInsightsRaw.map((e) => e.toString()).toList();
  } else if (keyInsightsRaw is String) {
    try { keyInsights = List<String>.from(jsonDecode(keyInsightsRaw)); } catch (_) {}
  }

  final redFlagsRaw = row['red_flags'];
  List<RedFlag> redFlags = [];
  if (redFlagsRaw is List) {
    redFlags = redFlagsRaw.map((e) {
      final m = e is Map<String, dynamic> ? e : <String, dynamic>{};
      return RedFlag(
        title: m['title']?.toString() ?? '',
        description: m['description']?.toString() ?? '',
        severity: parseSeverity(m['severity']?.toString()),
      );
    }).toList();
  } else if (redFlagsRaw is String) {
    try {
      final decoded = jsonDecode(redFlagsRaw) as List;
      redFlags = decoded.map((m) => RedFlag(
        title: m['title']?.toString() ?? '',
        description: m['description']?.toString() ?? '',
        severity: parseSeverity(m['severity']?.toString()),
      )).toList();
    } catch (_) {}
  }

  final whatChangedRaw = row['what_changed'];
  List<WhatChanged> whatChanged = [];
  if (whatChangedRaw is List) {
    whatChanged = whatChangedRaw.map((e) {
      final m = e is Map<String, dynamic> ? e : <String, dynamic>{};
      return WhatChanged(
        date: m['date']?.toString() ?? '',
        title: m['title']?.toString() ?? '',
        description: m['description']?.toString() ?? '',
        impact: parseImpact(m['impact']?.toString()),
      );
    }).toList();
  } else if (whatChangedRaw is String) {
    try {
      final decoded = jsonDecode(whatChangedRaw) as List;
      whatChanged = decoded.map((m) => WhatChanged(
        date: m['date']?.toString() ?? '',
        title: m['title']?.toString() ?? '',
        description: m['description']?.toString() ?? '',
        impact: parseImpact(m['impact']?.toString()),
      )).toList();
    } catch (_) {}
  }

  final credRaw = row['credibility_timeline'];
  List<CredibilityEntry> credTimeline = [];
  if (credRaw is List) {
    credTimeline = credRaw.map((e) {
      final m = e is Map<String, dynamic> ? e : <String, dynamic>{};
      return CredibilityEntry(
        claim: m['claim']?.toString() ?? '',
        reality: m['reality']?.toString() ?? '',
        met: m['met'] == true,
        quarter: m['quarter']?.toString() ?? '',
      );
    }).toList();
  } else if (credRaw is String) {
    try {
      final decoded = jsonDecode(credRaw) as List;
      credTimeline = decoded.map((m) => CredibilityEntry(
        claim: m['claim']?.toString() ?? '',
        reality: m['reality']?.toString() ?? '',
        met: m['met'] == true,
        quarter: m['quarter']?.toString() ?? '',
      )).toList();
    } catch (_) {}
  }

  final fraudRaw = row['fraud_similarities'];
  List<FraudSimilarity> fraudSim = [];
  if (fraudRaw is List) {
    fraudSim = fraudRaw.map((e) {
      final m = e is Map<String, dynamic> ? e : <String, dynamic>{};
      return FraudSimilarity(
        fraudName: m['fraudName']?.toString() ?? '',
        similarity: (m['similarity'] as num?)?.toDouble() ?? 0,
        description: m['description']?.toString() ?? '',
      );
    }).toList();
  } else if (fraudRaw is String) {
    try {
      final decoded = jsonDecode(fraudRaw) as List;
      fraudSim = decoded.map((m) => FraudSimilarity(
        fraudName: m['fraudName']?.toString() ?? '',
        similarity: (m['similarity'] as num?)?.toDouble() ?? 0,
        description: m['description']?.toString() ?? '',
      )).toList();
    } catch (_) {}
  }

  // Parse smart money data
  final smdRaw = row['smart_money_data'];
  Map<String, dynamic> smdMap = {};
  if (smdRaw is Map<String, dynamic>) {
    smdMap = smdRaw;
  } else if (smdRaw is String) {
    try { smdMap = Map<String, dynamic>.from(jsonDecode(smdRaw)); } catch (_) {}
  }
  final smartMoneyData = SmartMoneyData(
    fiiHolding: (smdMap['fiiHolding'] as num?)?.toDouble() ?? 15.0,
    diiHolding: (smdMap['diiHolding'] as num?)?.toDouble() ?? 20.0,
    retailHolding: (smdMap['retailHolding'] as num?)?.toDouble() ?? 65.0,
    fiiChange: (smdMap['fiiChange'] as num?)?.toDouble() ?? 0,
    diiChange: (smdMap['diiChange'] as num?)?.toDouble() ?? 0,
    retailChange: (smdMap['retailChange'] as num?)?.toDouble() ?? 0,
    isRetailTrap: smdMap['isRetailTrap'] == true,
    sentiment: smdMap['sentiment']?.toString() ?? 'Mixed signals',
  );

  // Parse money trail data
  final mtRaw = row['money_trail_data'];
  Map<String, dynamic> mtMap = {};
  if (mtRaw is Map<String, dynamic>) {
    mtMap = mtRaw;
  } else if (mtRaw is String) {
    try { mtMap = Map<String, dynamic>.from(jsonDecode(mtRaw)); } catch (_) {}
  }
  final revenue = (mtMap['revenue'] as num?)?.toDouble() ?? 1000.0;
  final grossProfit = (mtMap['grossProfit'] as num?)?.toDouble() ?? 400.0;
  final operatingIncome = (mtMap['operatingIncome'] as num?)?.toDouble() ?? 200.0;
  final netIncome = (mtMap['netIncome'] as num?)?.toDouble() ?? 150.0;
  final cogs = (mtMap['cogs'] as num?)?.toDouble() ?? 600.0;
  final operatingExpenses = (mtMap['operatingExpenses'] as num?)?.toDouble() ?? 200.0;
  final taxes = (mtMap['taxes'] as num?)?.toDouble() ?? 50.0;

  final expensesRaw = mtMap['expenses'];
  List<ExpenseItem> expenses = [];
  if (expensesRaw is List) {
    expenses = expensesRaw.map((e) {
      final m = e is Map<String, dynamic> ? e : <String, dynamic>{};
      return ExpenseItem(
        name: m['name']?.toString() ?? 'Other',
        amount: (m['amount'] as num?)?.toDouble() ?? 0,
        color: Color(int.tryParse(m['color']?.toString() ?? '0xFF448AFF') ?? 0xFF448AFF),
      );
    }).toList();
  }
  if (expenses.isEmpty) {
    expenses = [
      ExpenseItem(name: 'Payroll', amount: operatingExpenses * 0.45, color: const Color(0xFF448AFF)),
      ExpenseItem(name: 'Marketing', amount: operatingExpenses * 0.25, color: const Color(0xFF00E676)),
      ExpenseItem(name: 'Administrative', amount: operatingExpenses * 0.20, color: const Color(0xFFFFD740)),
      ExpenseItem(name: 'R&D', amount: operatingExpenses * 0.10, color: const Color(0xFF7C4DFF)),
    ];
  }

  final moneyTrailData = MoneyTrailData(
    revenue: revenue,
    grossProfit: grossProfit,
    operatingIncome: operatingIncome,
    netIncome: netIncome,
    cogs: cogs,
    operatingExpenses: operatingExpenses,
    taxes: taxes,
    cashConversion: (mtMap['cashConversion'] as num?)?.toDouble() ?? 75.0,
    qualityScore: (mtMap['qualityScore'] as num?)?.toInt() ?? 70,
    riskLevel: mtMap['riskLevel']?.toString() ?? 'Low',
    expenses: expenses,
    taxPaid: (mtMap['taxPaid'] as num?)?.toDouble() ?? taxes,
  );

  // Parse price/score histories
  List<double> priceHistory = [];
  final phRaw = row['price_history'];
  if (phRaw is List) {
    priceHistory = phRaw.map((e) => (e as num).toDouble()).toList();
  } else if (phRaw is String) {
    try { priceHistory = List<double>.from((jsonDecode(phRaw) as List).map((e) => (e as num).toDouble())); } catch (_) {}
  }
  if (priceHistory.isEmpty) {
    priceHistory = [(row['price'] as num?)?.toDouble() ?? 100.0];
  }

  List<double> truthScoreHistory = [];
  final tshRaw = row['truth_score_history'];
  if (tshRaw is List) {
    truthScoreHistory = tshRaw.map((e) => (e as num).toDouble()).toList();
  } else if (tshRaw is String) {
    try { truthScoreHistory = List<double>.from((jsonDecode(tshRaw) as List).map((e) => (e as num).toDouble())); } catch (_) {}
  }
  if (truthScoreHistory.isEmpty) {
    truthScoreHistory = [(row['truth_score'] as num?)?.toDouble() ?? 50.0];
  }

  return Company(
    name: row['name']?.toString() ?? '',
    ticker: row['ticker']?.toString() ?? '',
    sector: row['sector']?.toString() ?? '',
    price: (row['price'] as num?)?.toDouble() ?? 0,
    changePercent: (row['change_percent'] as num?)?.toDouble() ?? 0,
    volatility: (row['volatility'] as num?)?.toDouble() ?? 20,
    truthScore: (row['truth_score'] as num?)?.toInt() ?? 50,
    accountingRiskScore: (row['accounting_risk_score'] as num?)?.toInt() ?? 25,
    sentimentScore: (row['sentiment_score'] as num?)?.toInt() ?? 50,
    credibilityScore: (row['credibility_score'] as num?)?.toInt() ?? 50,
    managementHonestyScore: (row['management_honesty_score'] as num?)?.toInt() ?? 50,
    trend: parseTrend(row['trend']?.toString()),
    smartMoneySignal: parseSignal(row['smart_money_signal']?.toString()),
    beneishMScore: (row['beneish_m_score'] as num?)?.toDouble() ?? -2.5,
    altmanZScore: (row['altman_z_score'] as num?)?.toDouble() ?? 3.0,
    roce: (row['roce'] as num?)?.toDouble() ?? 0,
    operatingMargin: (row['operating_margin'] as num?)?.toDouble() ?? 0,
    debtToEquity: (row['debt_to_equity'] as num?)?.toDouble() ?? 0,
    keyInsights: keyInsights,
    redFlags: redFlags,
    whatChanged: whatChanged,
    credibilityTimeline: credTimeline,
    fraudSimilarities: fraudSim,
    smartMoneyData: smartMoneyData,
    moneyTrailData: moneyTrailData,
    priceHistory: priceHistory,
    truthScoreHistory: truthScoreHistory,
  );
}

class CompaniesNotifier extends StateNotifier<List<Company>> {
  Timer? _priceTimer;

  CompaniesNotifier() : super([]) {
    _init();
  }

  Future<void> _init() async {
    // Try loading from Supabase first
    try {
      final rows = await SupabaseService.fetchCompanies();
      if (rows.isNotEmpty) {
        state = rows.map(_mapRowToCompany).toList();
      } else {
        // No data in Supabase yet — use local mock data as fallback
        state = CompanyDataGenerator.generateAll();
      }
    } catch (_) {
      // Supabase unreachable — use local mock data
      state = CompanyDataGenerator.generateAll();
    }

    // Refresh prices every 5 minutes
    _priceTimer = Timer.periodic(const Duration(minutes: 5), (_) => _refreshPrices());
    // Also refresh once on startup after a short delay
    Future.delayed(const Duration(seconds: 5), _refreshPrices);
  }

  Future<void> _refreshPrices() async {
    if (state.isEmpty) return;
    try {
      final tickers = state.map((c) => c.ticker).toList();
      final prices = await PriceService.fetchPrices(tickers);
      if (prices.isEmpty) return;

      state = state.map((c) {
        final p = prices[c.ticker];
        if (p == null) return c;
        return Company(
          name: c.name,
          ticker: c.ticker,
          sector: c.sector,
          price: p.price,
          changePercent: p.changePercent,
          volatility: c.volatility,
          truthScore: c.truthScore,
          accountingRiskScore: c.accountingRiskScore,
          sentimentScore: c.sentimentScore,
          credibilityScore: c.credibilityScore,
          managementHonestyScore: c.managementHonestyScore,
          trend: c.trend,
          smartMoneySignal: c.smartMoneySignal,
          beneishMScore: c.beneishMScore,
          altmanZScore: c.altmanZScore,
          roce: c.roce,
          operatingMargin: c.operatingMargin,
          debtToEquity: c.debtToEquity,
          keyInsights: c.keyInsights,
          redFlags: c.redFlags,
          whatChanged: c.whatChanged,
          credibilityTimeline: c.credibilityTimeline,
          fraudSimilarities: c.fraudSimilarities,
          smartMoneyData: c.smartMoneyData,
          moneyTrailData: c.moneyTrailData,
          priceHistory: [...c.priceHistory, p.price],
          truthScoreHistory: c.truthScoreHistory,
        );
      }).toList();
    } catch (_) {
      // Keep last known prices on failure
    }
  }

  @override
  void dispose() {
    _priceTimer?.cancel();
    super.dispose();
  }
}

final companiesProvider = StateNotifierProvider<CompaniesNotifier, List<Company>>((ref) {
  return CompaniesNotifier();
});

// ═══════════════════════════════════════════════════════════════
// WATCHLIST PROVIDER
// ═══════════════════════════════════════════════════════════════

class WatchlistNotifier extends StateNotifier<List<String>> {
  WatchlistNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;
    try {
      state = await SupabaseService.fetchWatchlist(uid);
    } catch (_) {}
  }

  Future<void> addTicker(String ticker) async {
    if (state.contains(ticker)) return;
    state = [...state, ticker];
    final uid = SupabaseService.currentUserId;
    if (uid != null) {
      try {
        await SupabaseService.addToWatchlist(uid, ticker, state.length - 1);
      } catch (_) {}
    }
  }

  Future<void> removeTicker(String ticker) async {
    state = state.where((t) => t != ticker).toList();
    final uid = SupabaseService.currentUserId;
    if (uid != null) {
      try {
        await SupabaseService.removeFromWatchlist(uid, ticker);
      } catch (_) {}
    }
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final list = [...state];
    if (newIndex > oldIndex) newIndex--;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = list;
    final uid = SupabaseService.currentUserId;
    if (uid != null) {
      try {
        await SupabaseService.updateWatchlistPositions(uid, state);
      } catch (_) {}
    }
  }
}

final watchlistProvider =
    StateNotifierProvider<WatchlistNotifier, List<String>>((ref) {
  // Re-create when auth changes so watchlist reloads on login/logout
  ref.watch(authProvider);
  return WatchlistNotifier();
});

final watchlistCompaniesProvider = Provider<List<Company>>((ref) {
  final tickers = ref.watch(watchlistProvider);
  final companies = ref.watch(companiesProvider);
  if (companies.isEmpty) return [];
  return tickers
      .where((t) => companies.any((c) => c.ticker == t))
      .map((t) => companies.firstWhere((c) => c.ticker == t))
      .toList();
});

// ═══════════════════════════════════════════════════════════════
// PORTFOLIO PROVIDER
// ═══════════════════════════════════════════════════════════════

class PortfolioNotifier extends StateNotifier<Portfolio> {
  PortfolioNotifier(List<Company> companies)
      : super(const Portfolio(name: 'My Portfolio', holdings: [])) {
    _load(companies);
  }

  Future<void> _load(List<Company> companies) async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;
    try {
      final rows = await SupabaseService.fetchPortfolio(uid);
      final holdings = rows.map((r) {
        final ticker = r['ticker'] as String;
        final comp = companies.where((c) => c.ticker == ticker).firstOrNull;
        return PortfolioHolding(
          ticker: ticker,
          companyName: comp?.name ?? ticker,
          shares: (r['shares'] as num).toInt(),
          avgPrice: (r['avg_price'] as num).toDouble(),
          currentPrice: comp?.price ?? 0,
          volatility: comp?.volatility ?? 20,
          truthScore: comp?.truthScore ?? 50,
        );
      }).toList();
      state = Portfolio(name: 'My Portfolio', holdings: holdings);
    } catch (_) {}
  }

  void syncPrices(List<Company> companies) {
    if (state.holdings.isEmpty) return;
    
    final newHoldings = state.holdings.map((h) {
      final comp = companies.where((c) => c.ticker == h.ticker).firstOrNull;
      if (comp == null) return h;
      return PortfolioHolding(
        ticker: h.ticker,
        companyName: h.companyName,
        shares: h.shares,
        avgPrice: h.avgPrice,
        currentPrice: comp.price,
        volatility: comp.volatility,
        truthScore: comp.truthScore,
      );
    }).toList();
    
    state = Portfolio(name: state.name, holdings: newHoldings);
  }

  Future<void> optimizeSimulation() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    final newHoldings = state.holdings.map((h) {
      return PortfolioHolding(
        ticker: h.ticker,
        companyName: h.companyName,
        shares: (h.shares * 1.1).round(),
        avgPrice: h.avgPrice,
        currentPrice: h.currentPrice,
        volatility: h.volatility,
        truthScore: h.truthScore,
      );
    }).toList();
    state = Portfolio(name: state.name, holdings: newHoldings);
    _saveAll();
  }

  Future<void> addHolding(String ticker, int shares, double avgPrice, {Company? company}) async {
    if (company == null) return;
    final existing = state.holdings.indexWhere((h) => h.ticker == ticker);

    List<PortfolioHolding> newHoldings;
    int finalShares;
    double finalAvgPrice;

    if (existing >= 0) {
      final old = state.holdings[existing];
      finalShares = old.shares + shares;
      final totalCost = old.totalCost + (shares * avgPrice);
      finalAvgPrice = totalCost / finalShares;
      newHoldings = [...state.holdings];
      newHoldings[existing] = PortfolioHolding(
        ticker: ticker,
        companyName: company.name,
        shares: finalShares,
        avgPrice: finalAvgPrice,
        currentPrice: company.price,
        volatility: company.volatility,
        truthScore: company.truthScore,
      );
    } else {
      finalShares = shares;
      finalAvgPrice = avgPrice;
      newHoldings = [
        ...state.holdings,
        PortfolioHolding(
          ticker: ticker,
          companyName: company.name,
          shares: shares,
          avgPrice: avgPrice,
          currentPrice: company.price,
          volatility: company.volatility,
          truthScore: company.truthScore,
        ),
      ];
    }

    state = Portfolio(name: state.name, holdings: newHoldings);
    
    final uid = SupabaseService.currentUserId;
    if (uid != null) {
      try {
        await SupabaseService.upsertHolding(uid, ticker, finalShares, finalAvgPrice);
      } catch (_) {}
    }
  }

  Future<void> removeHolding(String ticker) async {
    final newHoldings =
        state.holdings.where((h) => h.ticker != ticker).toList();
    state = Portfolio(name: state.name, holdings: newHoldings);
    
    final uid = SupabaseService.currentUserId;
    if (uid != null) {
      try {
        await SupabaseService.removeHolding(uid, ticker);
      } catch (_) {}
    }
  }

  Future<void> _saveAll() async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;
    for (final h in state.holdings) {
      try {
        await SupabaseService.upsertHolding(uid, h.ticker, h.shares, h.avgPrice);
      } catch (_) {}
    }
  }
}

final portfolioProvider =
    StateNotifierProvider<PortfolioNotifier, Portfolio>((ref) {
  // Re-create when auth changes
  ref.watch(authProvider);
  final initialCompanies = ref.read(companiesProvider);
  final notifier = PortfolioNotifier(initialCompanies);
  
  ref.listen<List<Company>>(companiesProvider, (prev, next) {
    notifier.syncPrices(next);
  });
  
  return notifier;
});

// ═══════════════════════════════════════════════════════════════
// SELECTED COMPANY
// ═══════════════════════════════════════════════════════════════

final selectedCompanyProvider = StateProvider<Company?>((ref) => null);

// ═══════════════════════════════════════════════════════════════
// SEARCH PROVIDER
// ═══════════════════════════════════════════════════════════════

final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredCompaniesProvider = Provider<List<Company>>((ref) {
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final companies = ref.watch(companiesProvider);
  if (query.isEmpty) return companies;
  return companies
      .where((c) =>
          c.name.toLowerCase().contains(query) ||
          c.ticker.toLowerCase().contains(query) ||
          c.sector.toLowerCase().contains(query))
      .toList();
});

// ═══════════════════════════════════════════════════════════════
// BOTTOM NAV
// ═══════════════════════════════════════════════════════════════

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);
