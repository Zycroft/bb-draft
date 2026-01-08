import 'package:flutter/foundation.dart';
import '../models/league.dart';
import '../models/team.dart';
import '../services/league_service.dart';

class LeagueProvider extends ChangeNotifier {
  final LeagueService _service = LeagueService();

  List<League> _leagues = [];
  League? _selectedLeague;
  bool _isLoading = false;
  String? _error;

  List<League> get leagues => _leagues;
  League? get selectedLeague => _selectedLeague;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadLeagues() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _leagues = await _service.getMyLeagues();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load leagues: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadLeague(String leagueId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedLeague = await _service.getLeague(leagueId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load league: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<League?> createLeague({
    required String name,
    int maxTeams = 12,
    String draftFormat = 'serpentine',
    int pickTimer = 90,
    int rounds = 23,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final league = await _service.createLeague(
        name: name,
        maxTeams: maxTeams,
        draftFormat: draftFormat,
        pickTimer: pickTimer,
        rounds: rounds,
      );
      _leagues.add(league);
      _selectedLeague = league;
      _isLoading = false;
      notifyListeners();
      return league;
    } catch (e) {
      _error = 'Failed to create league: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<JoinLeagueResult?> joinLeague(String inviteCode, {String? teamName}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.joinLeague(inviteCode, teamName: teamName);

      // Add league if not already in list
      if (!_leagues.any((l) => l.leagueId == result.league.leagueId)) {
        _leagues.add(result.league);
      }

      _selectedLeague = result.league;
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = 'Failed to join league: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateLeague(String leagueId, {String? name, Map<String, dynamic>? settings}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _service.updateLeague(leagueId, name: name, settings: settings);

      // Update in list
      final index = _leagues.indexWhere((l) => l.leagueId == leagueId);
      if (index != -1) {
        _leagues[index] = updated;
      }

      if (_selectedLeague?.leagueId == leagueId) {
        _selectedLeague = updated;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update league: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteLeague(String leagueId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.deleteLeague(leagueId);
      _leagues.removeWhere((l) => l.leagueId == leagueId);

      if (_selectedLeague?.leagueId == leagueId) {
        _selectedLeague = null;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete league: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void selectLeague(League league) {
    _selectedLeague = league;
    notifyListeners();
  }

  void clearSelection() {
    _selectedLeague = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Alias for loadLeague to match screen usage
  Future<void> loadLeagueDetails(String leagueId) => loadLeague(leagueId);

  // Draft Order Management
  Future<DraftOrder?> getDraftOrder(String leagueId) async {
    try {
      return await _service.getDraftOrder(leagueId);
    } catch (e) {
      _error = 'Failed to get draft order: $e';
      notifyListeners();
      return null;
    }
  }

  Future<List<DraftOrderEntry>?> setDraftOrder(String leagueId, List<DraftOrderEntry> order) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _service.setDraftOrder(leagueId, order);
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = 'Failed to set draft order: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<List<DraftOrderEntry>?> randomizeDraftOrder(String leagueId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _service.randomizeDraftOrder(leagueId);
      _isLoading = false;
      // Reload league to get updated teams with draft positions
      await loadLeague(leagueId);
      return result;
    } catch (e) {
      _error = 'Failed to randomize draft order: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> swapDraftPositions(String leagueId, String teamId1, String teamId2) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.swapDraftPositions(leagueId, teamId1, teamId2);
      _isLoading = false;
      await loadLeague(leagueId);
      return true;
    } catch (e) {
      _error = 'Failed to swap draft positions: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Team Management (Commissioner)
  Future<List<Team>?> getLeagueTeams(String leagueId) async {
    try {
      return await _service.getLeagueTeams(leagueId);
    } catch (e) {
      _error = 'Failed to get league teams: $e';
      notifyListeners();
      return null;
    }
  }

  Future<bool> removeTeam(String leagueId, String teamId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.removeTeam(leagueId, teamId);
      _isLoading = false;
      await loadLeague(leagueId);
      return true;
    } catch (e) {
      _error = 'Failed to remove team: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> transferTeam(String leagueId, String teamId, String newOwnerId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.transferTeam(leagueId, teamId, newOwnerId);
      _isLoading = false;
      await loadLeague(leagueId);
      return true;
    } catch (e) {
      _error = 'Failed to transfer team: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Announcements
  Future<bool> sendAnnouncement(String leagueId, String message, {String? title}) async {
    try {
      await _service.sendAnnouncement(leagueId, message, title: title);
      return true;
    } catch (e) {
      _error = 'Failed to send announcement: $e';
      notifyListeners();
      return false;
    }
  }

  // Invite Code Management
  Future<String?> regenerateInviteCode(String leagueId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newCode = await _service.regenerateInviteCode(leagueId);
      _isLoading = false;
      await loadLeague(leagueId);
      return newCode;
    } catch (e) {
      _error = 'Failed to regenerate invite code: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
