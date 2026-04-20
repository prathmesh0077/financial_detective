import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String _supabaseUrl = 'https://qnfoyfavdhbavsjozvld.supabase.co';
  static const String _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFuZm95ZmF2ZGhiYXZzam96dmxkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY2NjE4MTcsImV4cCI6MjA5MjIzNzgxN30.wIwY6t8LXWPOHrpT3UIXfDOk-WcfYtYp_NSDxlPnd6s';

  static Future<void> init() async {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  // ── Auth helpers ──

  static String? get currentUserId => client.auth.currentUser?.id;
  static String? get currentUserEmail => client.auth.currentUser?.email;
  static bool get isLoggedIn => client.auth.currentSession != null;

  static Future<AuthResponse> signIn(String email, String password) {
    return client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<AuthResponse> signUp(String email, String password) {
    return client.auth.signUp(email: email, password: password);
  }

  static Future<void> signOut() => client.auth.signOut();

  // ── Companies ──

  static Future<List<Map<String, dynamic>>> fetchCompanies() async {
    final data = await client.from('companies').select();
    return List<Map<String, dynamic>>.from(data);
  }

  // ── Watchlist ──

  static Future<List<String>> fetchWatchlist(String userId) async {
    final data = await client
        .from('watchlists')
        .select('ticker')
        .eq('user_id', userId)
        .order('position');
    return List<String>.from(data.map((r) => r['ticker']));
  }

  static Future<void> addToWatchlist(String userId, String ticker, int position) async {
    await client.from('watchlists').upsert({
      'user_id': userId,
      'ticker': ticker,
      'position': position,
    }, onConflict: 'user_id,ticker');
  }

  static Future<void> removeFromWatchlist(String userId, String ticker) async {
    await client
        .from('watchlists')
        .delete()
        .eq('user_id', userId)
        .eq('ticker', ticker);
  }

  static Future<void> updateWatchlistPositions(
      String userId, List<String> tickers) async {
    for (var i = 0; i < tickers.length; i++) {
      await client
          .from('watchlists')
          .update({'position': i})
          .eq('user_id', userId)
          .eq('ticker', tickers[i]);
    }
  }

  // ── Portfolio ──

  static Future<List<Map<String, dynamic>>> fetchPortfolio(String userId) async {
    final data = await client
        .from('portfolio_holdings')
        .select()
        .eq('user_id', userId);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<void> upsertHolding(
      String userId, String ticker, int shares, double avgPrice) async {
    await client.from('portfolio_holdings').upsert({
      'user_id': userId,
      'ticker': ticker,
      'shares': shares,
      'avg_price': avgPrice,
    }, onConflict: 'user_id,ticker');
  }

  static Future<void> removeHolding(String userId, String ticker) async {
    await client
        .from('portfolio_holdings')
        .delete()
        .eq('user_id', userId)
        .eq('ticker', ticker);
  }
}
