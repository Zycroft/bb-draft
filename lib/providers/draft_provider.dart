import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/draft.dart';
import '../models/player.dart';
import '../services/draft_service.dart';
import '../services/socket_service.dart';

class DraftProvider extends ChangeNotifier {
  final DraftService _draftService = DraftService();
  final SocketService _socketService = SocketService();

  Draft? _draft;
  List<DraftPick> _picks = [];
  int _timeRemaining = 0;
  bool _isLoading = false;
  bool _isConnected = false;
  String? _error;
  String? _currentTeamId;

  // Subscriptions
  StreamSubscription? _stateSubscription;
  StreamSubscription? _pickSubscription;
  StreamSubscription? _clockSubscription;
  StreamSubscription? _autoPickSubscription;
  StreamSubscription? _completedSubscription;
  StreamSubscription? _errorSubscription;

  Draft? get draft => _draft;
  List<DraftPick> get picks => _picks;
  int get timeRemaining => _timeRemaining;
  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;
  String? get error => _error;
  bool get isMyTurn => _draft?.onTheClock?.teamId == _currentTeamId;

  Future<void> loadDraft(String draftId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _draft = await _draftService.getDraft(draftId);
      _picks = _draft?.picks ?? [];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load draft: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> connectToDraft(String draftId, String teamId) async {
    _currentTeamId = teamId;

    // Set up socket listeners
    _stateSubscription = _socketService.draftState.listen((event) {
      _draft = event.draft;
      _picks = event.picks;
      _timeRemaining = event.timeRemaining;
      _isConnected = true;
      notifyListeners();
    });

    _pickSubscription = _socketService.pickMade.listen((event) {
      _picks.add(event.pick);
      _timeRemaining = event.timeRemaining;

      // Update draft state based on next pick
      if (event.nextPick != null && _draft != null) {
        _draft = Draft.fromJson({
          ..._draftToJson(_draft!),
          'currentRound': event.nextPick!.round,
          'currentPick': event.nextPick!.pickInRound,
          'currentOverallPick': event.nextPick!.overallPick,
          'onTheClock': {
            'teamId': event.nextPick!.teamId,
            'clockStarted': DateTime.now().toIso8601String(),
            'clockExpires': DateTime.now().add(Duration(seconds: _timeRemaining)).toIso8601String(),
          },
        });
      }
      notifyListeners();
    });

    _clockSubscription = _socketService.clockTick.listen((event) {
      _timeRemaining = event.timeRemaining;
      notifyListeners();
    });

    _autoPickSubscription = _socketService.autoPick.listen((event) {
      _picks.add(event.pick);
      notifyListeners();
    });

    _completedSubscription = _socketService.draftCompleted.listen((draftId) {
      if (_draft?.draftId == draftId) {
        _draft = Draft.fromJson({
          ..._draftToJson(_draft!),
          'status': 'completed',
        });
        notifyListeners();
      }
    });

    _errorSubscription = _socketService.errors.listen((error) {
      _error = error.message;
      notifyListeners();
    });

    // Connect and join draft
    await _socketService.connect();
    _socketService.joinDraft(draftId, teamId);
  }

  Map<String, dynamic> _draftToJson(Draft draft) {
    return {
      'draftId': draft.draftId,
      'leagueId': draft.leagueId,
      'seasonYear': draft.seasonYear,
      'mode': draft.mode.value,
      'status': draft.status.value,
      'format': draft.format,
      'scheduledStart': draft.scheduledStart,
      'actualStart': draft.actualStart,
      'completedAt': draft.completedAt,
      'currentRound': draft.currentRound,
      'currentPick': draft.currentPick,
      'currentOverallPick': draft.currentOverallPick,
      'totalRounds': draft.totalRounds,
      'teamCount': draft.teamCount,
      'pickTimer': draft.pickTimer,
      'draftOrder': draft.draftOrder,
      'configuration': draft.configuration.toJson(),
      'skipQueue': draft.skipQueue.map((s) => {
        'skipId': s.skipId,
        'draftId': s.draftId,
        'teamId': s.teamId,
        'round': s.round,
        'pickInRound': s.pickInRound,
        'overallPick': s.overallPick,
        'skippedAt': s.skippedAt,
        'reason': s.reason,
        'originalDeadline': s.originalDeadline,
        'catchUpEligible': s.catchUpEligible,
        'catchUpDeadline': s.catchUpDeadline,
        'catchUpStatus': s.catchUpStatus,
      }).toList(),
      'timeBank': draft.timeBank,
    };
  }

  void makePick(String playerId) {
    if (_draft == null || _currentTeamId == null) return;
    _socketService.makePick(_draft!.draftId, _currentTeamId!, playerId);
  }

  void updateQueue(List<String> queue) {
    if (_draft == null || _currentTeamId == null) return;
    _socketService.updateQueue(_draft!.draftId, _currentTeamId!, queue);
  }

  Future<Draft?> startDraft(String draftId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _draft = await _draftService.startDraft(draftId);
      _isLoading = false;
      notifyListeners();
      return _draft;
    } catch (e) {
      _error = 'Failed to start draft: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<Draft?> pauseDraft(String draftId) async {
    try {
      _draft = await _draftService.pauseDraft(draftId);
      notifyListeners();
      return _draft;
    } catch (e) {
      _error = 'Failed to pause draft: $e';
      notifyListeners();
      return null;
    }
  }

  Future<Draft?> resumeDraft(String draftId) async {
    try {
      _draft = await _draftService.resumeDraft(draftId);
      notifyListeners();
      return _draft;
    } catch (e) {
      _error = 'Failed to resume draft: $e';
      notifyListeners();
      return null;
    }
  }

  Future<Draft?> createDraft({
    required String leagueId,
    DraftMode mode = DraftMode.live,
    String? scheduledStart,
    DraftConfiguration? configuration,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _draft = await _draftService.createDraft(
        leagueId: leagueId,
        mode: mode,
        scheduledStart: scheduledStart,
        configuration: configuration,
      );
      _isLoading = false;
      notifyListeners();
      return _draft;
    } catch (e) {
      _error = 'Failed to create draft: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<Draft?> updateConfiguration(
    String draftId,
    DraftConfiguration configuration,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _draft = await _draftService.updateConfiguration(draftId, configuration);
      _isLoading = false;
      notifyListeners();
      return _draft;
    } catch (e) {
      _error = 'Failed to update configuration: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<SkipQueueResult?> getSkipQueue(String draftId) async {
    try {
      return await _draftService.getSkipQueue(draftId);
    } catch (e) {
      _error = 'Failed to get skip queue: $e';
      notifyListeners();
      return null;
    }
  }

  Future<void> makeCatchUpPick({
    required String draftId,
    required String teamId,
    required String playerId,
    required String skipId,
  }) async {
    try {
      final result = await _draftService.makeCatchUpPick(
        draftId: draftId,
        teamId: teamId,
        playerId: playerId,
        skipId: skipId,
      );
      _picks.add(result.pick);
      _draft = result.draft;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to make catch-up pick: $e';
      notifyListeners();
      rethrow;
    }
  }

  void disconnect() {
    if (_draft != null) {
      _socketService.leaveDraft(_draft!.draftId);
    }
    _socketService.disconnect();
    _isConnected = false;

    _stateSubscription?.cancel();
    _pickSubscription?.cancel();
    _clockSubscription?.cancel();
    _autoPickSubscription?.cancel();
    _completedSubscription?.cancel();
    _errorSubscription?.cancel();

    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    _draftService.dispose();
    _socketService.dispose();
    super.dispose();
  }
}
