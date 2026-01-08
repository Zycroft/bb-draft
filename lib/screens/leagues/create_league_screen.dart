import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/league_provider.dart';
import '../../config/routes.dart';

class CreateLeagueScreen extends StatefulWidget {
  const CreateLeagueScreen({super.key});

  @override
  State<CreateLeagueScreen> createState() => _CreateLeagueScreenState();
}

class _CreateLeagueScreenState extends State<CreateLeagueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  int _maxTeams = 12;
  String _draftFormat = 'serpentine';
  int _pickTimer = 90;
  int _rounds = 23;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createLeague() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<LeagueProvider>();
    final league = await provider.createLeague(
      name: _nameController.text.trim(),
      maxTeams: _maxTeams,
      draftFormat: _draftFormat,
      pickTimer: _pickTimer,
      rounds: _rounds,
    );

    if (league != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('League created! Invite code: ${league.inviteCode}'),
          backgroundColor: Colors.green[600],
        ),
      );
      Navigator.pushReplacementNamed(context, AppRoutes.leagues);
    } else if (provider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error!), backgroundColor: Colors.red[600]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        title: const Text('Create League'),
      ),
      body: Consumer<LeagueProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // League Name
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'League Name',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: 'Enter league name',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a league name';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Team Settings
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Team Settings',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Text('Max Teams: '),
                              const Spacer(),
                              DropdownButton<int>(
                                value: _maxTeams,
                                items: [4, 6, 8, 10, 12, 14, 16, 20, 24]
                                    .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                                    .toList(),
                                onChanged: (value) => setState(() => _maxTeams = value!),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Draft Settings
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Draft Settings',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Text('Format: '),
                              const Spacer(),
                              SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment(value: 'serpentine', label: Text('Serpentine')),
                                  ButtonSegment(value: 'straight', label: Text('Straight')),
                                ],
                                selected: {_draftFormat},
                                onSelectionChanged: (value) => setState(() => _draftFormat = value.first),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Text('Pick Timer: '),
                              const Spacer(),
                              DropdownButton<int>(
                                value: _pickTimer,
                                items: [30, 60, 90, 120, 180, 300]
                                    .map((n) => DropdownMenuItem(value: n, child: Text('${n}s')))
                                    .toList(),
                                onChanged: (value) => setState(() => _pickTimer = value!),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Text('Rounds: '),
                              const Spacer(),
                              DropdownButton<int>(
                                value: _rounds,
                                items: [10, 15, 20, 23, 25, 30]
                                    .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                                    .toList(),
                                onChanged: (value) => setState(() => _rounds = value!),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Create Button
                  ElevatedButton(
                    onPressed: provider.isLoading ? null : _createLeague,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: provider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Create League', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
