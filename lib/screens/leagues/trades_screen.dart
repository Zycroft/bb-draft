import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/trade_service.dart';
import '../../config/routes.dart';

class TradesScreen extends StatefulWidget {
  final String leagueId;

  const TradesScreen({super.key, required this.leagueId});

  @override
  State<TradesScreen> createState() => _TradesScreenState();
}

class _TradesScreenState extends State<TradesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TradeService _tradeService = TradeService();
  List<Trade> _myTrades = [];
  List<Trade> _leagueTrades = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTrades();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tradeService.dispose();
    super.dispose();
  }

  Future<void> _loadTrades() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _tradeService.getMyTrades(widget.leagueId),
        _tradeService.getLeagueTrades(widget.leagueId),
      ]);

      setState(() {
        _myTrades = results[0];
        _leagueTrades = results[1];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load trades: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        title: const Text('Trades'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'My Trades (${_myTrades.length})'),
            Tab(text: 'All Trades (${_leagueTrades.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _TradesList(
                  trades: _myTrades,
                  isMyTrades: true,
                  onRefresh: _loadTrades,
                  tradeService: _tradeService,
                ),
                _TradesList(
                  trades: _leagueTrades,
                  isMyTrades: false,
                  onRefresh: _loadTrades,
                  tradeService: _tradeService,
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Get myTeamId from provider
          Navigator.pushNamed(
            context,
            AppRoutes.proposeTrade,
            arguments: {
              'leagueId': widget.leagueId,
              'myTeamId': context.read<AuthProvider>().user?.uid ?? '',
            },
          );
        },
        backgroundColor: Colors.green[700],
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Propose Trade', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _TradesList extends StatelessWidget {
  final List<Trade> trades;
  final bool isMyTrades;
  final VoidCallback onRefresh;
  final TradeService tradeService;

  const _TradesList({
    required this.trades,
    required this.isMyTrades,
    required this.onRefresh,
    required this.tradeService,
  });

  @override
  Widget build(BuildContext context) {
    if (trades.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swap_horiz, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              isMyTrades ? 'No trades involving your team' : 'No trades in this league',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: trades.length,
        itemBuilder: (context, index) {
          final trade = trades[index];
          return _TradeCard(
            trade: trade,
            isMyTrades: isMyTrades,
            tradeService: tradeService,
            onRefresh: onRefresh,
          );
        },
      ),
    );
  }
}

class _TradeCard extends StatelessWidget {
  final Trade trade;
  final bool isMyTrades;
  final TradeService tradeService;
  final VoidCallback onRefresh;

  const _TradeCard({
    required this.trade,
    required this.isMyTrades,
    required this.tradeService,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().user?.uid ?? '';
    final isProposer = trade.proposingTeam.teamId == currentUserId;
    final isReceiver = trade.receivingTeam.teamId == currentUserId;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getStatusColor(trade.status).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                _StatusBadge(status: trade.status),
                const Spacer(),
                Text(
                  _formatDate(trade.proposedAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Trade Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Proposing Team
                _TeamAssets(
                  teamName: trade.proposingTeam.teamName ?? 'Team',
                  assets: trade.proposingTeam.sending,
                  label: 'Sends',
                  isAccepted: trade.proposingTeam.accepted,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Icon(Icons.swap_vert, color: Colors.grey),
                ),
                // Receiving Team
                _TeamAssets(
                  teamName: trade.receivingTeam.teamName ?? 'Team',
                  assets: trade.receivingTeam.receiving,
                  label: 'Receives',
                  isAccepted: trade.receivingTeam.accepted,
                ),
              ],
            ),
          ),

          // Actions
          if (trade.isPending && isMyTrades)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isReceiver) ...[
                    TextButton(
                      onPressed: () => _rejectTrade(context),
                      child: const Text('Reject', style: TextStyle(color: Colors.red)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _acceptTrade(context),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                      child: const Text('Accept', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                  if (isProposer)
                    TextButton(
                      onPressed: () => _cancelTrade(context),
                      child: const Text('Cancel Trade'),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(TradeStatus status) {
    switch (status) {
      case TradeStatus.pending:
        return Colors.orange;
      case TradeStatus.accepted:
        return Colors.blue;
      case TradeStatus.rejected:
        return Colors.red;
      case TradeStatus.executed:
        return Colors.green;
      case TradeStatus.cancelled:
        return Colors.grey;
      case TradeStatus.expired:
        return Colors.grey;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.month}/${date.day}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _acceptTrade(BuildContext context) async {
    try {
      await tradeService.acceptTrade(trade.tradeId);
      onRefresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trade accepted!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept trade: $e')),
        );
      }
    }
  }

  Future<void> _rejectTrade(BuildContext context) async {
    try {
      await tradeService.rejectTrade(trade.tradeId);
      onRefresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trade rejected')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject trade: $e')),
        );
      }
    }
  }

  Future<void> _cancelTrade(BuildContext context) async {
    try {
      await tradeService.cancelTrade(trade.tradeId);
      onRefresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trade cancelled')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel trade: $e')),
        );
      }
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final TradeStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _getColor(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getColor() {
    switch (status) {
      case TradeStatus.pending:
        return Colors.orange;
      case TradeStatus.accepted:
        return Colors.blue;
      case TradeStatus.rejected:
        return Colors.red;
      case TradeStatus.executed:
        return Colors.green;
      case TradeStatus.cancelled:
        return Colors.grey;
      case TradeStatus.expired:
        return Colors.grey;
    }
  }
}

class _TeamAssets extends StatelessWidget {
  final String teamName;
  final List<TradeAsset> assets;
  final String label;
  final bool isAccepted;

  const _TeamAssets({
    required this.teamName,
    required this.assets,
    required this.label,
    required this.isAccepted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                teamName,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              if (isAccepted)
                Row(
                  children: [
                    Icon(Icons.check_circle, size: 14, color: Colors.green[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Accepted',
                      style: TextStyle(fontSize: 11, color: Colors.green[700]),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: assets.map((asset) => _AssetChip(asset: asset)).toList(),
          ),
        ),
      ],
    );
  }
}

class _AssetChip extends StatelessWidget {
  final TradeAsset asset;

  const _AssetChip({required this.asset});

  @override
  Widget build(BuildContext context) {
    final isPlayer = asset.type == 'player';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPlayer ? Colors.blue[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPlayer ? Colors.blue[200]! : Colors.green[200]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPlayer ? Icons.person : Icons.confirmation_number,
            size: 16,
            color: isPlayer ? Colors.blue[700] : Colors.green[700],
          ),
          const SizedBox(width: 4),
          Text(
            asset.displayName,
            style: TextStyle(
              fontSize: 12,
              color: isPlayer ? Colors.blue[700] : Colors.green[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
