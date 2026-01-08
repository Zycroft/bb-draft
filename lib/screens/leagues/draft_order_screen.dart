import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/league_provider.dart';
import '../../services/league_service.dart';

class DraftOrderScreen extends StatefulWidget {
  final String leagueId;

  const DraftOrderScreen({super.key, required this.leagueId});

  @override
  State<DraftOrderScreen> createState() => _DraftOrderScreenState();
}

class _DraftOrderScreenState extends State<DraftOrderScreen> {
  DraftOrder? _draftOrder;
  List<DraftOrderEntry> _order = [];
  bool _isLoading = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadDraftOrder();
  }

  Future<void> _loadDraftOrder() async {
    setState(() => _isLoading = true);

    final order = await context.read<LeagueProvider>().getDraftOrder(widget.leagueId);

    setState(() {
      _draftOrder = order;
      _order = order?.order ?? [];
      _isLoading = false;
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (_draftOrder?.isLocked ?? false) return;

    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _order.removeAt(oldIndex);
      _order.insert(newIndex, item);

      // Update positions
      for (int i = 0; i < _order.length; i++) {
        _order[i] = DraftOrderEntry(
          position: i + 1,
          teamId: _order[i].teamId,
          teamName: _order[i].teamName,
        );
      }
      _hasChanges = true;
    });
  }

  Future<void> _saveOrder() async {
    final result = await context.read<LeagueProvider>().setDraftOrder(
      widget.leagueId,
      _order,
    );

    if (result != null && mounted) {
      setState(() {
        _order = result;
        _hasChanges = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft order saved!')),
      );
    }
  }

  Future<void> _randomize() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Randomize Draft Order?'),
        content: const Text(
          'This will completely randomize the draft order. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            child: const Text('Randomize', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final result = await context.read<LeagueProvider>().randomizeDraftOrder(widget.leagueId);
      if (result != null && mounted) {
        setState(() {
          _order = result;
          _hasChanges = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draft order randomized!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = _draftOrder?.isLocked ?? false;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        title: const Text('Draft Order'),
        actions: [
          if (!isLocked && _hasChanges)
            TextButton(
              onPressed: _saveOrder,
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Status Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: isLocked ? Colors.orange[100] : Colors.green[100],
                  child: Row(
                    children: [
                      Icon(
                        isLocked ? Icons.lock : Icons.lock_open,
                        color: isLocked ? Colors.orange[700] : Colors.green[700],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isLocked ? 'Draft Order Locked' : 'Draft Order Unlocked',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isLocked ? Colors.orange[700] : Colors.green[700],
                              ),
                            ),
                            Text(
                              isLocked
                                  ? 'The draft order has been locked and cannot be changed.'
                                  : 'Drag teams to reorder or use the randomize button.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isLocked ? Colors.orange[700] : Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Action Buttons
                if (!isLocked)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _randomize,
                            icon: const Icon(Icons.shuffle),
                            label: const Text('Randomize'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Order Info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        'Format: ${_draftOrder?.serpentine ?? true ? 'Serpentine' : 'Straight'}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const Spacer(),
                      Text(
                        '${_order.length} Teams',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Reorderable List
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _order.length,
                    onReorder: _onReorder,
                    buildDefaultDragHandles: !isLocked,
                    itemBuilder: (context, index) {
                      final entry = _order[index];
                      return _DraftOrderTile(
                        key: ValueKey(entry.teamId),
                        entry: entry,
                        isLocked: isLocked,
                        onSwap: !isLocked ? () => _showSwapDialog(entry) : null,
                      );
                    },
                  ),
                ),

                // Round Preview
                if (_order.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Round Preview',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        _buildRoundPreview(),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildRoundPreview() {
    final isSerpentine = _draftOrder?.serpentine ?? true;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Round 1', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text(
                _order.take(3).map((e) => e.teamName.split(' ').first).join(' > '),
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Round 2', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text(
                isSerpentine
                    ? _order.reversed.take(3).map((e) => e.teamName.split(' ').first).join(' > ')
                    : _order.take(3).map((e) => e.teamName.split(' ').first).join(' > '),
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showSwapDialog(DraftOrderEntry currentEntry) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Swap ${currentEntry.teamName} with:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            ..._order
                .where((e) => e.teamId != currentEntry.teamId)
                .map((entry) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green[100],
                        child: Text(
                          '${entry.position}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                      title: Text(entry.teamName),
                      onTap: () async {
                        Navigator.pop(context);
                        final success = await this.context
                            .read<LeagueProvider>()
                            .swapDraftPositions(
                              widget.leagueId,
                              currentEntry.teamId,
                              entry.teamId,
                            );
                        if (success && mounted) {
                          _loadDraftOrder();
                        }
                      },
                    )),
          ],
        ),
      ),
    );
  }
}

class _DraftOrderTile extends StatelessWidget {
  final DraftOrderEntry entry;
  final bool isLocked;
  final VoidCallback? onSwap;

  const _DraftOrderTile({
    super.key,
    required this.entry,
    required this.isLocked,
    this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.green[700],
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            '${entry.position}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        title: Text(
          entry.teamName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('Pick #${entry.position} in Round 1'),
        trailing: isLocked
            ? const Icon(Icons.lock, color: Colors.grey)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.swap_horiz),
                    onPressed: onSwap,
                    tooltip: 'Swap position',
                  ),
                  const Icon(Icons.drag_handle, color: Colors.grey),
                ],
              ),
      ),
    );
  }
}
