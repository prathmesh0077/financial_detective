import 'dart:convert';
import 'package:http/http.dart' as http;

class PriceService {
  /// Fetches current prices for NSE stocks via Yahoo Finance.
  /// Returns a map of ticker -> (price, changePercent).
  static Future<Map<String, ({double price, double changePercent})>> fetchPrices(
      List<String> tickers) async {
    final results = <String, ({double price, double changePercent})>{};

    for (final ticker in tickers) {
      try {
        // Yahoo Finance uses .NS suffix for NSE stocks
        // Handle special tickers like M&M -> M%26M
        final yahooTicker = ticker.replaceAll('&', '%26');
        final url = Uri.parse(
            'https://query1.finance.yahoo.com/v8/finance/chart/$yahooTicker.NS?interval=1d&range=1d');

        final response = await http.get(url, headers: {
          'User-Agent': 'Mozilla/5.0',
        });

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final result = data['chart']?['result'];
          if (result != null && result.isNotEmpty) {
            final meta = result[0]['meta'];
            final price = (meta['regularMarketPrice'] as num?)?.toDouble();
            final prevClose =
                (meta['previousClose'] as num?)?.toDouble() ?? price;

            if (price != null && price > 0) {
              final change = prevClose != null && prevClose > 0
                  ? ((price - prevClose) / prevClose) * 100
                  : 0.0;
              results[ticker] = (price: price, changePercent: change);
            }
          }
        }
      } catch (_) {
        // Skip failed tickers — caller keeps last known price
      }

      // Rate limiting: 100ms between requests
      await Future.delayed(const Duration(milliseconds: 100));
    }

    return results;
  }
}
