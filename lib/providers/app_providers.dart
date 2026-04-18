import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/company.dart';
import '../data/company_data.dart';

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

final companiesProvider = Provider<List<Company>>((ref) {
  return CompanyDataGenerator.generateAll();
});

// ═══════════════════════════════════════════════════════════════
// WATCHLIST PROVIDER
// ═══════════════════════════════════════════════════════════════

class WatchlistNotifier extends StateNotifier<List<String>> {
  WatchlistNotifier(List<Company> companies)
      : super(companies.map((c) => c.ticker).toList());

  void addTicker(String ticker) {
    if (!state.contains(ticker)) {
      state = [...state, ticker];
    }
  }

  void removeTicker(String ticker) {
    state = state.where((t) => t != ticker).toList();
  }

  void reorder(int oldIndex, int newIndex) {
    final list = [...state];
    if (newIndex > oldIndex) newIndex--;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = list;
  }
}

final watchlistProvider =
    StateNotifierProvider<WatchlistNotifier, List<String>>((ref) {
  final companies = ref.watch(companiesProvider);
  return WatchlistNotifier(companies);
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
  final List<Company> _companies;

  PortfolioNotifier(this._companies)
      : super(Portfolio(
          name: 'My Portfolio',
          holdings: _defaultHoldings(_companies),
        ));

  static List<PortfolioHolding> _defaultHoldings(List<Company> companies) {
    final selected = [
      {'ticker': 'RELIANCE', 'shares': 120, 'avgPrice': 2450.00},
      {'ticker': 'HDFCBANK', 'shares': 45, 'avgPrice': 1580.00},
      {'ticker': 'INFY', 'shares': 80, 'avgPrice': 1320.00},
      {'ticker': 'TATAMOTORS', 'shares': 250, 'avgPrice': 640.00},
    ];

    return selected.map((s) {
      final company =
          companies.firstWhere((c) => c.ticker == s['ticker'] as String);
      return PortfolioHolding(
        ticker: company.ticker,
        companyName: company.name,
        shares: s['shares'] as int,
        avgPrice: (s['avgPrice'] as num).toDouble(),
        currentPrice: company.price,
        truthScore: company.truthScore,
      );
    }).toList();
  }

  void addHolding(String ticker, int shares, double avgPrice) {
    final company = _companies.firstWhere((c) => c.ticker == ticker);
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
          truthScore: company.truthScore,
        ),
      ];
    }

    state = Portfolio(name: state.name, holdings: newHoldings);
  }

  void removeHolding(String ticker) {
    final newHoldings =
        state.holdings.where((h) => h.ticker != ticker).toList();
    state = Portfolio(name: state.name, holdings: newHoldings);
  }
}

final portfolioProvider =
    StateNotifierProvider<PortfolioNotifier, Portfolio>((ref) {
  final companies = ref.watch(companiesProvider);
  return PortfolioNotifier(companies);
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
