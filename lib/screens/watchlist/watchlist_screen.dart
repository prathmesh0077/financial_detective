import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../models/company.dart';
import '../../providers/app_providers.dart';
import '../../widgets/truth_score_badge.dart';
import '../stock_detail/stock_detail_screen.dart';

class WatchlistScreen extends ConsumerStatefulWidget {
  const WatchlistScreen({super.key});

  @override
  ConsumerState<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends ConsumerState<WatchlistScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  bool _showSuggestions = false;
  String _query = '';
  late AnimationController _emptyAnim;
  late Animation<double> _emptyFade;

  @override
  void initState() {
    super.initState();
    _emptyAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _emptyFade = CurvedAnimation(parent: _emptyAnim, curve: Curves.easeOut);

    _focusNode.addListener(() {
      setState(() => _showSuggestions = _focusNode.hasFocus && _query.isNotEmpty);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _emptyAnim.dispose();
    super.dispose();
  }

  List<Company> get _suggestions {
    if (_query.trim().isEmpty) return [];
    final q = _query.toLowerCase();
    final allCompanies = ref.read(companiesProvider);
    final watchlistTickers = ref.read(watchlistProvider);
    return allCompanies
        .where((c) =>
            !watchlistTickers.contains(c.ticker) &&
            (c.name.toLowerCase().contains(q) ||
                c.ticker.toLowerCase().contains(q) ||
                c.sector.toLowerCase().contains(q)))
        .take(8)
        .toList();
  }

  void _onQueryChanged(String v) {
    setState(() {
      _query = v;
      _showSuggestions = v.isNotEmpty;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _focusNode.unfocus();
    setState(() {
      _query = '';
      _showSuggestions = false;
    });
  }

  void _addToWatchlist(Company company) {
    ref.read(watchlistProvider.notifier).addTicker(company.ticker);
    _clearSearch();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.bookmark_added, color: AppColors.primary, size: 18),
            const SizedBox(width: 10),
            Text('${company.ticker} added to watchlist',
                style: const TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        backgroundColor: AppColors.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  void _removeFromWatchlist(String ticker) {
    ref.read(watchlistProvider.notifier).removeTicker(ticker);
  }

  void _openDetail(Company company) {
    ref.read(selectedCompanyProvider.notifier).state = company;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StockDetailScreen(company: company)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final watchlistCompanies = ref.watch(watchlistCompaniesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            _focusNode.unfocus();
            setState(() => _showSuggestions = false);
          },
          behavior: HitTestBehavior.translucent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── HEADER ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.shield_outlined,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Watchlist',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (watchlistCompanies.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${watchlistCompanies.length} stocks',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── LARGE SEARCH BAR ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SearchBar(
                  controller: _searchController,
                  focusNode: _focusNode,
                  onChanged: _onQueryChanged,
                  onClear: _query.isNotEmpty ? _clearSearch : null,
                ),
              ),
              const SizedBox(height: 8),

              // ── SUGGESTIONS OVERLAY ─ rendered inline below search ──
              if (_showSuggestions) ...[
                Builder(builder: (ctx) {
                  final suggestions = _suggestions;
                  if (suggestions.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.search_off,
                              size: 16, color: AppColors.textTertiary),
                          const SizedBox(width: 8),
                          Text('No matching stocks found',
                              style: TextStyle(
                                  color: AppColors.textTertiary, fontSize: 13)),
                        ],
                      ),
                    );
                  }
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: ((MediaQuery.of(ctx).size.height -
                                  MediaQuery.of(ctx).viewInsets.bottom) *
                              0.40)
                          .clamp(100.0, 420.0),
                    ),
                    child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: AppColors.border, width: 0.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        itemCount: suggestions.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: AppColors.border.withValues(alpha: 0.4),
                        ),
                        itemBuilder: (_, i) =>
                            _SuggestionTile(
                              company: suggestions[i],
                              onAdd: () => _addToWatchlist(suggestions[i]),
                              onTap: () => _openDetail(suggestions[i]),
                            ),
                      ),
                    ),
                  ));
                }),
                const SizedBox(height: 8),
              ],

              // ── WATCHLIST SECTION LABEL ──
              if (!_showSuggestions && watchlistCompanies.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        'MY WATCHLIST',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Swipe ← to remove',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ── BODY: EMPTY STATE or WATCHLIST ──
              Expanded(
                child: _showSuggestions
                    ? const SizedBox.shrink()
                    : watchlistCompanies.isEmpty
                        ? _EmptyState(fadeAnim: _emptyFade)
                        : ReorderableListView.builder(
                            padding: const EdgeInsets.only(bottom: 100),
                            onReorder: (oldIdx, newIdx) {
                              ref
                                  .read(watchlistProvider.notifier)
                                  .reorder(oldIdx, newIdx);
                            },
                            proxyDecorator: (child, index, animation) {
                              return AnimatedBuilder(
                                animation: animation,
                                builder: (context, child) => Material(
                                  color: AppColors.card.withValues(alpha: 0.95),
                                  elevation: 8,
                                  borderRadius: BorderRadius.circular(12),
                                  child: child,
                                ),
                                child: child,
                              );
                            },
                            itemCount: watchlistCompanies.length,
                            itemBuilder: (_, i) {
                              final company = watchlistCompanies[i];
                              return _WatchlistTile(
                                key: ValueKey(company.ticker),
                                company: company,
                                onTap: () => _openDetail(company),
                                onRemove: () =>
                                    _removeFromWatchlist(company.ticker),
                                onAddPortfolio: () =>
                                    _addToPortfolio(company),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addToPortfolio(Company company) {
    ref.read(portfolioProvider.notifier).addHolding(
          company.ticker,
          10,
          company.price,
          company: company,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.add_chart, color: AppColors.primary, size: 18),
            const SizedBox(width: 10),
            Text('${company.ticker} added to portfolio',
                style: const TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        backgroundColor: AppColors.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(12),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SEARCH BAR
// ═══════════════════════════════════════════════════════════════

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // No fixed height — symmetric vertical padding centers text naturally
      padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 0),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                hintText: 'Search stocks by name or symbol…',
                hintStyle: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                // isCollapsed + zero padding: TextField takes exactly its
                // natural line height. The Container's symmetric padding
                // is the sole centering mechanism — works on all devices.
                isCollapsed: true,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              textAlignVertical: TextAlignVertical.center,
              textInputAction: TextInputAction.search,
              onChanged: onChanged,
            ),
          ),
          if (onClear != null) ...[
            GestureDetector(
              onTap: onClear,
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.cardLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: AppColors.textSecondary, size: 14),
              ),
            ),
          ] else ...[
            const SizedBox(width: 16),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SUGGESTION TILE
// ═══════════════════════════════════════════════════════════════

class _SuggestionTile extends StatelessWidget {
  final Company company;
  final VoidCallback onAdd;
  final VoidCallback onTap;

  const _SuggestionTile({
    required this.company,
    required this.onAdd,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = company.changePercent >= 0;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Score badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.scoreBgColor(company.truthScore),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.scoreColor(company.truthScore)
                      .withValues(alpha: 0.3),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '${company.truthScore}',
                style: TextStyle(
                  color: AppColors.scoreColor(company.truthScore),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    company.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          company.ticker,
                          style: const TextStyle(
                              color: AppColors.textTertiary, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            company.sector,
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Price
            SizedBox(
              width: 72,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${company.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${isPositive ? '+' : ''}${company.changePercent.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: isPositive ? AppColors.primary : AppColors.error,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Add button
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      width: 0.5),
                ),
                child: const Text(
                  '+ Add',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EMPTY STATE
// ═══════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final Animation<double> fadeAnim;
  const _EmptyState({required this.fadeAnim});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnim,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      width: 1.5),
                ),
                child: const Icon(
                  Icons.bookmarks_outlined,
                  color: AppColors.primary,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No stocks in your watchlist yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Search for stocks above and tap "+ Add" to start tracking them here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.search, color: AppColors.primary, size: 15),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Search and add stocks to get started',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        softWrap: true,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// WATCHLIST TILE
// ═══════════════════════════════════════════════════════════════

class _WatchlistTile extends StatelessWidget {
  final Company company;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback onAddPortfolio;

  const _WatchlistTile({
    super.key,
    required this.company,
    required this.onTap,
    required this.onRemove,
    required this.onAddPortfolio,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = company.changePercent >= 0;
    return Dismissible(
      key: ValueKey('dismiss_${company.ticker}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onAddPortfolio();
        } else {
          onRemove();
        }
        return false;
      },
      // Swipe RIGHT → Add to Portfolio (green, left-aligned)
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          border: Border(
            bottom:
                BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_chart, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Add to Portfolio',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      // Swipe LEFT → Remove from Watchlist (red, right-aligned)
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.errorDim,
          border: Border(
            bottom:
                BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_remove, color: AppColors.error),
            SizedBox(width: 8),
            Text('Remove',
                style: TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.3)),
            ),
          ),
          child: Row(
            children: [
              // Truth score badge
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.scoreBgColor(company.truthScore),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.scoreColor(company.truthScore)
                        .withValues(alpha: 0.3),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${company.truthScore}',
                  style: TextStyle(
                    color: AppColors.scoreColor(company.truthScore),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Company info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          company.ticker,
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        TrendBadge(trend: company.trendLabel),
                      ],
                    ),
                  ],
                ),
              ),

              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${company.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isPositive ? AppColors.primary : AppColors.error)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${isPositive ? '+' : ''}${company.changePercent.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: isPositive ? AppColors.primary : AppColors.error,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
