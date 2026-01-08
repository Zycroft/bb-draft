import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/league_provider.dart';
import '../../services/trade_service.dart';
import '../../services/league_service.dart';

class ProposeTradeScreen extends StatefulWidget {
  final String leagueId;
  final String myTeamId;

  const ProposeTradeScreen({
    super.key,
    required this.leagueId,
    required this.myTeamId,
  });

  @override
  State<ProposeTradeScreen> createState() => _ProposeTradeScreenState();
}

class _ProposeTradeScreenState extends State<ProposeTradeScreen> {
  final TradeService _tradeService = TradeService();

  List<DraftOrderEntry> _teams = [];
  DraftOrderEntry? _selectedTeam;
  List<TradeAsset> _sending = [];
  List<TradeAsset> _receiving = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  // Available picks (simplified - in real app, fetch from backend)
  final List<int> _availableYears = [2025, 2026, 2027];
  final List<int> _availableRounds = [1, 2, 3, 4, 5];

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  @override
  void dispose() {
    _tradeService.dispose();
    super.dispose();
  }

  Future<void> _loadTeams() async {
    setState(() => _isLoading = true);

    final draftOrder = await context.read<LeagueProvider>().getDraftOrder(widget.leagueId);

    setState(() {
      _teams = draftOrder?.order
              .where((t) => t.teamId != widget.myTeamId)
              .toList() ??
          [];
      _isLoading = false;
    });
  }

  void _addSendingPick() {
    _showPickSelector(isSending: true);
  }

  void _addReceivingPick() {
    _showPickSelector(isSending: false);
  }

  void _showPickSelector({required bool isSending}) {
    int selectedYear = _availableYears.first;
    int selectedRound = _availableRounds.first;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isSending ? 'Add Pick to Send' : 'Request Pick',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Year Selection
              const Text('Season Year', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _availableYears.map((year) {
                  final isSelected = year == selectedYear;
                  return ChoiceChip(
                    label: Text('$year'),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setModalState(() => selectedYear = year);
                      }
                    },
                    selectedColor: Colors.green[200],
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Round Selection
              const Text('Round', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _availableRounds.map((round) {
                  final isSelected = round == selectedRound;
                  return ChoiceChip(
                    label: Text('Round $round'),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setModalState(() => selectedRound = round);
                      }
                    },
                    selectedColor: Colors.green[200],
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final asset = TradeAsset(
                      type: 'pick',
                      seasonYear: selectedYear,
                      round: selectedRound,
                    );

                    setState(() {
                      if (isSending) {
                        _sending.add(asset);
                      } else {
                        _receiving.add(asset);
                      }
                    });

                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Add Pick', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _removeSending(int index) {
    setState(() => _sending.removeAt(index));
  }

  void _removeReceiving(int index) {
    setState(() => _receiving.removeAt(index));
  }

  Future<void> _submitTrade() async {
    if (_selectedTeam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a team to trade with')),
      );
      return;
    }

    if (_sending.isEmpty && _receiving.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one asset to the trade')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _tradeService.proposeTrade(
        leagueId: widget.leagueId,
        receivingTeamId: _selectedTeam!.teamId,
        sending: _sending,
        receiving: _receiving,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trade proposed successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to propose trade: $e')),
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
        title: const Text('Propose Trade'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Team Selection
                  const Text(
                    'Trade With',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<DraftOrderEntry>(
                          isExpanded: true,
                          value: _selectedTeam,
                          hint: const Text('Select a team'),
                          items: _teams.map((team) {
                            return DropdownMenuItem(
                              value: team,
                              child: Text(team.teamName),
                            );
                          }).toList(),
                          onChanged: (team) {
                            setState(() => _selectedTeam = team);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // You Send Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'You Send',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: _addSendingPick,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Pick'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildAssetList(_sending, true),
                  const SizedBox(height: 24),

                  // Trade Arrow
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.swap_vert, color: Colors.green[700], size: 32),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // You Receive Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'You Receive',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: _addReceivingPick,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Pick'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildAssetList(_receiving, false),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitTrade,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Propose Trade',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAssetList(List<TradeAsset> assets, bool isSending) {
    if (assets.isEmpty) {
      return Card(
        child: Container(
          padding: const EdgeInsets.all(32),
          width: double.infinity,
          child: Column(
            children: [
              Icon(Icons.inbox, size: 40, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                isSending ? 'No assets to send' : 'No assets to receive',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: assets.asMap().entries.map((entry) {
            final index = entry.key;
            final asset = entry.value;

            return ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: asset.type == 'player' ? Colors.blue[50] : Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  asset.type == 'player' ? Icons.person : Icons.confirmation_number,
                  color: asset.type == 'player' ? Colors.blue[700] : Colors.green[700],
                ),
              ),
              title: Text(asset.displayName),
              subtitle: asset.type == 'pick'
                  ? Text('Draft Pick')
                  : null,
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.red),
                onPressed: () {
                  if (isSending) {
                    _removeSending(index);
                  } else {
                    _removeReceiving(index);
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
