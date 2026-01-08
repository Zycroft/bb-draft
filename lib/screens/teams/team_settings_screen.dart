import 'package:flutter/material.dart';

class TeamSettingsScreen extends StatefulWidget {
  final String teamId;
  final String leagueId;

  const TeamSettingsScreen({
    super.key,
    required this.teamId,
    required this.leagueId,
  });

  @override
  State<TeamSettingsScreen> createState() => _TeamSettingsScreenState();
}

class _TeamSettingsScreenState extends State<TeamSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teamNameController = TextEditingController();
  final _mottoController = TextEditingController();

  bool _isLoading = false;
  bool _hasChanges = false;

  // Notification preferences
  bool _notifyOnPick = true;
  bool _notifyOnTrade = true;
  bool _notifyOnAnnouncement = true;
  bool _notifyOnDraftStart = true;

  // Draft preferences
  bool _enableAutoPick = false;
  int _autoPickDelay = 30;

  @override
  void initState() {
    super.initState();
    _loadTeamSettings();
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    _mottoController.dispose();
    super.dispose();
  }

  Future<void> _loadTeamSettings() async {
    // In a real app, load from backend
    setState(() {
      _teamNameController.text = 'My Fantasy Team';
      _mottoController.text = '';
    });
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // TODO: Save to backend
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasChanges = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved!')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
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
        title: const Text('Team Settings'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _saveSettings,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Team Info Section
            _SectionHeader(title: 'Team Info'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _teamNameController,
                      decoration: const InputDecoration(
                        labelText: 'Team Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.sports_baseball),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Team name is required';
                        }
                        if (value.length > 30) {
                          return 'Team name must be 30 characters or less';
                        }
                        return null;
                      },
                      onChanged: (_) => _markChanged(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _mottoController,
                      decoration: const InputDecoration(
                        labelText: 'Team Motto (optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.format_quote),
                        hintText: 'Go team!',
                      ),
                      maxLength: 50,
                      onChanged: (_) => _markChanged(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Notifications Section
            _SectionHeader(title: 'Notifications'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('When it\'s my turn to pick'),
                    subtitle: const Text('Get notified when you\'re on the clock'),
                    value: _notifyOnPick,
                    onChanged: (value) {
                      setState(() => _notifyOnPick = value);
                      _markChanged();
                    },
                    secondary: Icon(Icons.timer, color: Colors.green[700]),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Trade proposals'),
                    subtitle: const Text('Get notified about trade offers'),
                    value: _notifyOnTrade,
                    onChanged: (value) {
                      setState(() => _notifyOnTrade = value);
                      _markChanged();
                    },
                    secondary: Icon(Icons.swap_horiz, color: Colors.blue[700]),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('League announcements'),
                    subtitle: const Text('Get notified about commissioner messages'),
                    value: _notifyOnAnnouncement,
                    onChanged: (value) {
                      setState(() => _notifyOnAnnouncement = value);
                      _markChanged();
                    },
                    secondary: Icon(Icons.campaign, color: Colors.orange[700]),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Draft starting'),
                    subtitle: const Text('Get notified when the draft begins'),
                    value: _notifyOnDraftStart,
                    onChanged: (value) {
                      setState(() => _notifyOnDraftStart = value);
                      _markChanged();
                    },
                    secondary: Icon(Icons.play_circle, color: Colors.purple[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Draft Preferences Section
            _SectionHeader(title: 'Draft Preferences'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Auto-pick'),
                    subtitle: const Text('Automatically pick if timer expires'),
                    value: _enableAutoPick,
                    onChanged: (value) {
                      setState(() => _enableAutoPick = value);
                      _markChanged();
                    },
                    secondary: Icon(Icons.auto_mode, color: Colors.green[700]),
                  ),
                  if (_enableAutoPick) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Auto-pick delay'),
                              Text(
                                '$_autoPickDelay seconds',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Slider(
                            value: _autoPickDelay.toDouble(),
                            min: 10,
                            max: 60,
                            divisions: 5,
                            label: '$_autoPickDelay s',
                            activeColor: Colors.green[700],
                            onChanged: (value) {
                              setState(() => _autoPickDelay = value.toInt());
                              _markChanged();
                            },
                          ),
                          Text(
                            'Wait this long before auto-picking when it\'s your turn',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Danger Zone
            _SectionHeader(title: 'Danger Zone', color: Colors.red),
            Card(
              child: ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.red),
                title: const Text(
                  'Leave League',
                  style: TextStyle(color: Colors.red),
                ),
                subtitle: const Text('Remove your team from this league'),
                onTap: () => _confirmLeaveLeague(),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _confirmLeaveLeague() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave League?'),
        content: const Text(
          'Are you sure you want to leave this league? Your team and all draft picks will be removed. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Leave league
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Leave', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color? color;

  const _SectionHeader({required this.title, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color ?? Colors.grey[700],
        ),
      ),
    );
  }
}
