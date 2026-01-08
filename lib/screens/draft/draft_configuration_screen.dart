import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/draft.dart';
import '../../providers/draft_provider.dart';

class DraftConfigurationScreen extends StatefulWidget {
  final String leagueId;
  final String leagueName;
  final Draft? existingDraft;

  const DraftConfigurationScreen({
    super.key,
    required this.leagueId,
    required this.leagueName,
    this.existingDraft,
  });

  @override
  State<DraftConfigurationScreen> createState() => _DraftConfigurationScreenState();
}

class _DraftConfigurationScreenState extends State<DraftConfigurationScreen> {
  late DraftMode _selectedMode;
  late DateTime _scheduledStart;
  late TimeOfDay _scheduledTime;
  bool _isLoading = false;

  // Live mode settings
  late int _pickTimer;
  late bool _autoPickOnTimeout;
  late String _autoPickStrategy;
  late bool _pauseEnabled;
  late int _maxPauseDuration;
  late int _breakBetweenRounds;

  // Untimed mode settings
  late bool _notifyOnTurn;
  late bool _allowQueuePicks;
  late int _maxQueueDepth;

  // Scheduled mode settings
  late int _windowDuration;
  late bool _skipOnWindowClose;
  late bool _catchUpEnabled;
  late int _catchUpWindow;
  late String _timezone;

  // Timed mode settings
  late String _clockBehavior;
  late int _skipThreshold;
  late String _catchUpPolicy;
  late int _catchUpTimeLimit;
  late int _bonusTime;

  @override
  void initState() {
    super.initState();
    _initializeFromExisting();
  }

  void _initializeFromExisting() {
    final config = widget.existingDraft?.configuration ?? DraftConfiguration();

    _selectedMode = widget.existingDraft?.mode ?? DraftMode.live;
    _scheduledStart = widget.existingDraft?.scheduledStart != null
        ? DateTime.parse(widget.existingDraft!.scheduledStart!)
        : DateTime.now().add(const Duration(days: 1));
    _scheduledTime = TimeOfDay.fromDateTime(_scheduledStart);

    // Live mode
    _pickTimer = config.pickTimer;
    _autoPickOnTimeout = config.autoPickOnTimeout;
    _autoPickStrategy = config.autoPickStrategy;
    _pauseEnabled = config.pauseEnabled;
    _maxPauseDuration = config.maxPauseDuration;
    _breakBetweenRounds = config.breakBetweenRounds;

    // Untimed mode
    _notifyOnTurn = config.notifyOnTurn;
    _allowQueuePicks = config.allowQueuePicks;
    _maxQueueDepth = config.maxQueueDepth;

    // Scheduled mode
    _windowDuration = config.windowDuration;
    _skipOnWindowClose = config.skipOnWindowClose;
    _catchUpEnabled = config.catchUpEnabled;
    _catchUpWindow = config.catchUpWindow;
    _timezone = config.timezone;

    // Timed mode
    _clockBehavior = config.clockBehavior;
    _skipThreshold = config.skipThreshold;
    _catchUpPolicy = config.catchUpPolicy;
    _catchUpTimeLimit = config.catchUpTimeLimit;
    _bonusTime = config.bonusTime;
  }

  DraftConfiguration _buildConfiguration() {
    return DraftConfiguration(
      pickTimer: _pickTimer,
      autoPickOnTimeout: _autoPickOnTimeout,
      autoPickStrategy: _autoPickStrategy,
      pauseEnabled: _pauseEnabled,
      maxPauseDuration: _maxPauseDuration,
      breakBetweenRounds: _breakBetweenRounds,
      notifyOnTurn: _notifyOnTurn,
      allowQueuePicks: _allowQueuePicks,
      maxQueueDepth: _maxQueueDepth,
      windowDuration: _windowDuration,
      skipOnWindowClose: _skipOnWindowClose,
      catchUpEnabled: _catchUpEnabled,
      catchUpWindow: _catchUpWindow,
      timezone: _timezone,
      clockBehavior: _clockBehavior,
      skipThreshold: _skipThreshold,
      catchUpPolicy: _catchUpPolicy,
      catchUpTimeLimit: _catchUpTimeLimit,
      bonusTime: _bonusTime,
    );
  }

  Future<void> _saveDraft() async {
    setState(() => _isLoading = true);

    try {
      final provider = context.read<DraftProvider>();
      final scheduledDateTime = DateTime(
        _scheduledStart.year,
        _scheduledStart.month,
        _scheduledStart.day,
        _scheduledTime.hour,
        _scheduledTime.minute,
      );

      if (widget.existingDraft != null) {
        // Update existing draft configuration
        await provider.updateConfiguration(
          widget.existingDraft!.draftId,
          _buildConfiguration(),
        );
      } else {
        // Create new draft
        await provider.createDraft(
          leagueId: widget.leagueId,
          mode: _selectedMode,
          scheduledStart: scheduledDateTime.toIso8601String(),
          configuration: _buildConfiguration(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingDraft != null
                ? 'Draft configuration updated'
                : 'Draft created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingDraft != null;
    final canEdit = widget.existingDraft == null ||
        widget.existingDraft!.status == DraftStatus.scheduled;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Draft Settings' : 'Configure Draft'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          if (canEdit)
            TextButton(
              onPressed: _isLoading ? null : _saveDraft,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // League Name Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events, color: Colors.amber[700], size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.leagueName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            isEditing ? 'Draft Configuration' : 'New Draft Setup',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Draft Mode Selection
            _buildSectionHeader('Draft Mode', Icons.schedule),
            const SizedBox(height: 8),
            _buildModeSelector(canEdit),
            const SizedBox(height: 8),
            _buildModeDescription(),
            const SizedBox(height: 24),

            // Schedule
            _buildSectionHeader('Schedule', Icons.calendar_today),
            const SizedBox(height: 8),
            _buildScheduleSection(canEdit),
            const SizedBox(height: 24),

            // Mode-specific settings
            ..._buildModeSettings(canEdit),

            // Catch-up Settings (for all modes)
            _buildSectionHeader('Catch-Up Settings', Icons.replay),
            const SizedBox(height: 8),
            _buildCatchUpSettings(canEdit),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.green[700]),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green[800],
          ),
        ),
      ],
    );
  }

  Widget _buildModeSelector(bool enabled) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: DraftMode.values.map((mode) {
            final isSelected = _selectedMode == mode;
            return RadioListTile<DraftMode>(
              title: Text(
                mode.displayName,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(_getModeSubtitle(mode)),
              value: mode,
              groupValue: _selectedMode,
              onChanged: enabled
                  ? (value) {
                      if (value != null) {
                        setState(() => _selectedMode = value);
                      }
                    }
                  : null,
              activeColor: Colors.green[700],
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getModeSubtitle(DraftMode mode) {
    switch (mode) {
      case DraftMode.live:
        return 'Real-time draft with countdown timer';
      case DraftMode.untimed:
        return 'No timer - pick at your own pace';
      case DraftMode.scheduled:
        return 'Per-pick windows with schedules';
      case DraftMode.timed:
        return 'Revolving clock with skip/catch-up';
    }
  }

  Widget _buildModeDescription() {
    String description;
    IconData icon;
    Color color;

    switch (_selectedMode) {
      case DraftMode.live:
        description = 'All participants join at the same time. Each team has a set amount of time to make their pick. If time expires, auto-pick or skip occurs.';
        icon = Icons.live_tv;
        color = Colors.red;
        break;
      case DraftMode.untimed:
        description = 'Asynchronous draft with no time limits. Teams are notified when it\'s their turn and can make picks whenever convenient.';
        icon = Icons.hourglass_empty;
        color = Colors.blue;
        break;
      case DraftMode.scheduled:
        description = 'Each pick has a dedicated time window (e.g., 2 hours). Teams must pick within their window or get skipped with catch-up opportunity.';
        icon = Icons.event;
        color = Colors.purple;
        break;
      case DraftMode.timed:
        description = 'Draft runs during set hours with a revolving clock. Skipped teams can catch up later. Good for slow drafts over multiple days.';
        icon = Icons.timer;
        color = Colors.orange;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection(bool enabled) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_month),
              title: const Text('Start Date'),
              subtitle: Text(
                '${_scheduledStart.month}/${_scheduledStart.day}/${_scheduledStart.year}',
              ),
              trailing: enabled ? const Icon(Icons.chevron_right) : null,
              onTap: enabled
                  ? () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _scheduledStart,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => _scheduledStart = date);
                      }
                    }
                  : null,
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: const Text('Start Time'),
              subtitle: Text(_scheduledTime.format(context)),
              trailing: enabled ? const Icon(Icons.chevron_right) : null,
              onTap: enabled
                  ? () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _scheduledTime,
                      );
                      if (time != null) {
                        setState(() => _scheduledTime = time);
                      }
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildModeSettings(bool enabled) {
    switch (_selectedMode) {
      case DraftMode.live:
        return _buildLiveModeSettings(enabled);
      case DraftMode.untimed:
        return _buildUntimedModeSettings(enabled);
      case DraftMode.scheduled:
        return _buildScheduledModeSettings(enabled);
      case DraftMode.timed:
        return _buildTimedModeSettings(enabled);
    }
  }

  List<Widget> _buildLiveModeSettings(bool enabled) {
    return [
      _buildSectionHeader('Timer Settings', Icons.timer),
      const SizedBox(height: 8),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSliderSetting(
                'Pick Timer',
                '${_pickTimer}s',
                _pickTimer.toDouble(),
                30,
                300,
                enabled,
                (value) => setState(() => _pickTimer = value.round()),
              ),
              const SizedBox(height: 16),
              _buildSwitchSetting(
                'Auto-Pick on Timeout',
                'Automatically select a player when timer expires',
                _autoPickOnTimeout,
                enabled,
                (value) => setState(() => _autoPickOnTimeout = value),
              ),
              if (_autoPickOnTimeout) ...[
                const SizedBox(height: 16),
                _buildDropdownSetting(
                  'Auto-Pick Strategy',
                  _autoPickStrategy,
                  ['queue', 'adp', 'positional'],
                  ['From Queue', 'Best ADP', 'Positional Need'],
                  enabled,
                  (value) => setState(() => _autoPickStrategy = value!),
                ),
              ],
              const SizedBox(height: 16),
              _buildSwitchSetting(
                'Allow Pause',
                'Commissioner can pause the draft',
                _pauseEnabled,
                enabled,
                (value) => setState(() => _pauseEnabled = value),
              ),
              if (_pauseEnabled) ...[
                const SizedBox(height: 16),
                _buildSliderSetting(
                  'Max Pause Duration',
                  '${_maxPauseDuration ~/ 60}min',
                  _maxPauseDuration.toDouble(),
                  60,
                  1800,
                  enabled,
                  (value) => setState(() => _maxPauseDuration = value.round()),
                ),
              ],
              const SizedBox(height: 16),
              _buildSliderSetting(
                'Break Between Rounds',
                _breakBetweenRounds == 0 ? 'None' : '${_breakBetweenRounds}s',
                _breakBetweenRounds.toDouble(),
                0,
                300,
                enabled,
                (value) => setState(() => _breakBetweenRounds = value.round()),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
    ];
  }

  List<Widget> _buildUntimedModeSettings(bool enabled) {
    return [
      _buildSectionHeader('Notification Settings', Icons.notifications),
      const SizedBox(height: 8),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSwitchSetting(
                'Notify on Turn',
                'Send notification when it\'s your turn',
                _notifyOnTurn,
                enabled,
                (value) => setState(() => _notifyOnTurn = value),
              ),
              const SizedBox(height: 16),
              _buildSwitchSetting(
                'Allow Queue Picks',
                'Teams can queue picks in advance',
                _allowQueuePicks,
                enabled,
                (value) => setState(() => _allowQueuePicks = value),
              ),
              if (_allowQueuePicks) ...[
                const SizedBox(height: 16),
                _buildSliderSetting(
                  'Max Queue Depth',
                  '$_maxQueueDepth players',
                  _maxQueueDepth.toDouble(),
                  5,
                  50,
                  enabled,
                  (value) => setState(() => _maxQueueDepth = value.round()),
                ),
              ],
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
    ];
  }

  List<Widget> _buildScheduledModeSettings(bool enabled) {
    return [
      _buildSectionHeader('Window Settings', Icons.window),
      const SizedBox(height: 8),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSliderSetting(
                'Pick Window Duration',
                '${_windowDuration}min',
                _windowDuration.toDouble(),
                15,
                480,
                enabled,
                (value) => setState(() => _windowDuration = value.round()),
              ),
              const SizedBox(height: 16),
              _buildSwitchSetting(
                'Skip on Window Close',
                'Auto-skip if no pick made within window',
                _skipOnWindowClose,
                enabled,
                (value) => setState(() => _skipOnWindowClose = value),
              ),
              const SizedBox(height: 16),
              _buildDropdownSetting(
                'Timezone',
                _timezone,
                [
                  'America/New_York',
                  'America/Chicago',
                  'America/Denver',
                  'America/Los_Angeles',
                ],
                ['Eastern', 'Central', 'Mountain', 'Pacific'],
                enabled,
                (value) => setState(() => _timezone = value!),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
    ];
  }

  List<Widget> _buildTimedModeSettings(bool enabled) {
    return [
      _buildSectionHeader('Clock Settings', Icons.watch_later),
      const SizedBox(height: 8),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSliderSetting(
                'Pick Timer',
                '${_pickTimer}s',
                _pickTimer.toDouble(),
                30,
                300,
                enabled,
                (value) => setState(() => _pickTimer = value.round()),
              ),
              const SizedBox(height: 16),
              _buildDropdownSetting(
                'Clock Behavior',
                _clockBehavior,
                ['reset', 'accumulate', 'carryover'],
                ['Reset Each Pick', 'Accumulate Unused', 'Carryover to Next'],
                enabled,
                (value) => setState(() => _clockBehavior = value!),
              ),
              const SizedBox(height: 16),
              _buildSliderSetting(
                'Bonus Time per Pick',
                '${_bonusTime}s',
                _bonusTime.toDouble(),
                0,
                60,
                enabled,
                (value) => setState(() => _bonusTime = value.round()),
              ),
              const SizedBox(height: 16),
              _buildSliderSetting(
                'Skip Threshold',
                '$_skipThreshold consecutive',
                _skipThreshold.toDouble(),
                1,
                10,
                enabled,
                (value) => setState(() => _skipThreshold = value.round()),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
    ];
  }

  Widget _buildCatchUpSettings(bool enabled) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSwitchSetting(
              'Enable Catch-Up',
              'Allow teams to make skipped picks later',
              _catchUpEnabled,
              enabled,
              (value) => setState(() => _catchUpEnabled = value),
            ),
            if (_catchUpEnabled) ...[
              const SizedBox(height: 16),
              _buildSliderSetting(
                'Catch-Up Window',
                '${_catchUpWindow}min',
                _catchUpWindow.toDouble(),
                5,
                120,
                enabled,
                (value) => setState(() => _catchUpWindow = value.round()),
              ),
              const SizedBox(height: 16),
              _buildDropdownSetting(
                'Catch-Up Policy',
                _catchUpPolicy,
                ['immediate', 'end_of_round', 'end_of_draft'],
                ['Immediate', 'End of Round', 'End of Draft'],
                enabled,
                (value) => setState(() => _catchUpPolicy = value!),
              ),
              const SizedBox(height: 16),
              _buildSliderSetting(
                'Catch-Up Time Limit',
                '${_catchUpTimeLimit}s',
                _catchUpTimeLimit.toDouble(),
                30,
                300,
                enabled,
                (value) => setState(() => _catchUpTimeLimit = value.round()),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSliderSetting(
    String label,
    String valueLabel,
    double value,
    double min,
    double max,
    bool enabled,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                valueLabel,
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: ((max - min) / (max > 100 ? 10 : 1)).round(),
          onChanged: enabled ? onChanged : null,
          activeColor: Colors.green[700],
        ),
      ],
    );
  }

  Widget _buildSwitchSetting(
    String label,
    String subtitle,
    bool value,
    bool enabled,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: enabled ? onChanged : null,
          activeColor: Colors.green[700],
        ),
      ],
    );
  }

  Widget _buildDropdownSetting(
    String label,
    String value,
    List<String> options,
    List<String> labels,
    bool enabled,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: List.generate(options.length, (i) {
            return DropdownMenuItem(
              value: options[i],
              child: Text(labels[i]),
            );
          }),
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }
}
