import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/company.dart';
import '../data/company_data.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());


// ═══════════════════════════════════════════════════════════════
// AUTH PROVIDER
// ═══════════════════════════════════════════════════════════════

class AuthState {
  final bool isLoggedIn;
  final String? email;

  const AuthState({this.isLoggedIn = false, this.email});

  AuthState copyWith({bool? isLoggedIn, String? email}) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      email: email ?? this.email,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  void login(String email) {
    state = state.copyWith(isLoggedIn: true, email: email);
  }

  void logout() {
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);

// ═══════════════════════════════════════════════════════════════
// COMPANIES PROVIDER
// ═══════════════════════════════════════════════════════════════

class StockSimulatorNotifier extends StateNotifier<List<Company>> {
  Timer? _timer;

  StockSimulatorNotifier() : super(CompanyDataGenerator.generateAll()) {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      state = state.map((c) {
        final delta = c.price * (Random().nextDouble() * 0.01 - 0.005); // +/- 0.5%
        return Company(
          name: c.name,
          ticker: c.ticker,
          sector: c.sector,
          price: c.price + delta,
          changePercent: c.changePercent + (delta / c.price * 100),
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
          priceHistory: [...c.priceHistory, c.price + delta],
          truthScoreHistory: c.truthScoreHistory,
        );
      }).toList();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final companiesProvider = StateNotifierProvider<StockSimulatorNotifier, List<Company>>((ref) {
  return StockSimulatorNotifier();
});

// ═══════════════════════════════════════════════════════════════
// WATCHLIST PROVIDER
// ═══════════════════════════════════════════════════════════════

class WatchlistNotifier extends StateNotifier<List<String>> {
  final SharedPreferences _prefs;

  WatchlistNotifier(this._prefs, List<Company> companies)
      : super(_prefs.getStringList('watchlist_tickers') ?? companies.map((c) => c.ticker).toList());

  void _save() {
    _prefs.setStringList('watchlist_tickers', state);
  }

  void addTicker(String ticker) {
    if (!state.contains(ticker)) {
      state = [...state, ticker];
      _save();
    }
  }

  void removeTicker(String ticker) {
    state = state.where((t) => t != ticker).toList();
    _save();
  }

  void reorder(int oldIndex, int newIndex) {
    final list = [...state];
    if (newIndex > oldIndex) newIndex--;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = list;
    _save();
  }
}

final watchlistProvider =
    StateNotifierProvider<WatchlistNotifier, List<String>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final companies = ref.watch(companiesProvider);
  return WatchlistNotifier(prefs, companies);
});

final watchlistCompaniesProvider = Provider<List<Company>>((ref) {
  final tickers = ref.watch(watchlistProvider);
  final companies = ref.watch(companiesProvider);
  return tickers
      .map((t) => companies.firstWhere((c) => c.ticker == t))
      .toList();
});

// ═══════════════════════════════════════════════════════════════
// PORTFOLIO PROVIDER
// ═══════════════════════════════════════════════════════════════

class PortfolioNotifier extends StateNotifier<Portfolio> {
  final SharedPreferences _prefs;

  PortfolioNotifier(this._prefs, List<Company> companies)
      : super(Portfolio(
          name: 'My Portfolio',
          holdings: _loadHoldings(_prefs, companies),
        ));

  static List<PortfolioHolding> _loadHoldings(SharedPreferences prefs, List<Company> companies) {
    final data = prefs.getString('portfolio_holdings');
    List<Map<String, dynamic>> selected;
    if (data != null) {
      selected = List<Map<String, dynamic>>.from(jsonDecode(data));
    } else {
      selected = [
        {'ticker': 'RELIANCE', 'shares': 120, 'avgPrice': 2450.00},
        {'ticker': 'HDFCBANK', 'shares': 45, 'avgPrice': 1580.00},
        {'ticker': 'INFY', 'shares': 80, 'avgPrice': 1320.00},
        {'ticker': 'TATAMOTORS', 'shares': 250, 'avgPrice': 640.00},
      ];
    }

    return selected.map((s) {
      final company =
          companies.firstWhere((c) => c.ticker == s['ticker'] as String, orElse: () => companies.first);
      return PortfolioHolding(
        ticker: company.ticker,
        companyName: company.name,
        shares: s['shares'] as int,
        avgPrice: (s['avgPrice'] as num).toDouble(),
        currentPrice: company.price,
        volatility: company.volatility,
        truthScore: company.truthScore,
      );
    }).toList();
  }

  void _save() {
    final data = state.holdings.map((h) => {
      'ticker': h.ticker,
      'shares': h.shares,
      'avgPrice': h.avgPrice,
    }).toList();
    _prefs.setString('portfolio_holdings', jsonEncode(data));
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
        shares: (h.shares * 1.1).round(), // slightly increase shares for mock optimization
        avgPrice: h.avgPrice,
        currentPrice: h.currentPrice,
        volatility: h.volatility,
        truthScore: h.truthScore,
      );
    }).toList();
    state = Portfolio(name: state.name, holdings: newHoldings);
    _save();
  }

  void addHolding(String ticker, int shares, double avgPrice, {Company? company}) {
    if (company == null) return;
    final existing = state.holdings.indexWhere((h) => h.ticker == ticker);

    List<PortfolioHolding> newHoldings;
    if (existing >= 0) {
      final old = state.holdings[existing];
      final totalShares = old.shares + shares;
      final totalCost = old.totalCost + (shares * avgPrice);
      newHoldings = [...state.holdings];
      newHoldings[existing] = PortfolioHolding(
        ticker: ticker,
        companyName: company.name,
        shares: totalShares,
        avgPrice: totalCost / totalShares,
        currentPrice: company.price,
        volatility: company.volatility,
        truthScore: company.truthScore,
      );
    } else {
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
    _save();
  }

  void removeHolding(String ticker) {
    final newHoldings =
        state.holdings.where((h) => h.ticker != ticker).toList();
    state = Portfolio(name: state.name, holdings: newHoldings);
    _save();
  }
}

final portfolioProvider =
    StateNotifierProvider<PortfolioNotifier, Portfolio>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final initialCompanies = ref.read(companiesProvider);
  final notifier = PortfolioNotifier(prefs, initialCompanies);
  
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
