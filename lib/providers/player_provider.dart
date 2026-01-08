import 'package:flutter/foundation.dart';
import '../models/player.dart';
import '../services/player_service.dart';

class PlayerProvider extends ChangeNotifier {
  final PlayerService _service = PlayerService();

  List<Player> _batters = [];
  List<Player> _pitchers = [];
  List<Player> _searchResults = [];
  Player? _selectedPlayer;
  Map<String, EligibilityStatus> _eligibilities = {};
  String? _currentLeagueId;

  bool _isLoadingBatters = false;
  bool _isLoadingPitchers = false;
  bool _isSearching = false;
  bool _isLoadingEligibilities = false;
  String? _error;
  String _searchQuery = '';

  List<Player> get batters => _batters;
  List<Player> get pitchers => _pitchers;
  List<Player> get searchResults => _searchResults;
  Player? get selectedPlayer => _selectedPlayer;
  Map<String, EligibilityStatus> get eligibilities => _eligibilities;
  String? get currentLeagueId => _currentLeagueId;
  bool get isLoadingBatters => _isLoadingBatters;
  bool get isLoadingPitchers => _isLoadingPitchers;
  bool get isSearching => _isSearching;
  bool get isLoadingEligibilities => _isLoadingEligibilities;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  Future<void> loadBatters() async {
    if (_isLoadingBatters) return;

    _isLoadingBatters = true;
    _error = null;
    notifyListeners();

    try {
      _batters = await _service.getBatters();
      _isLoadingBatters = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load batters: $e';
      _isLoadingBatters = false;
      notifyListeners();
    }
  }

  Future<void> loadPitchers() async {
    if (_isLoadingPitchers) return;

    _isLoadingPitchers = true;
    _error = null;
    notifyListeners();

    try {
      _pitchers = await _service.getPitchers();
      _isLoadingPitchers = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load pitchers: $e';
      _isLoadingPitchers = false;
      notifyListeners();
    }
  }

  Future<void> searchPlayers(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      _searchQuery = '';
      notifyListeners();
      return;
    }

    _searchQuery = query;
    _isSearching = true;
    notifyListeners();

    try {
      _searchResults = await _service.searchPlayers(query);
      _isSearching = false;
      notifyListeners();
    } catch (e) {
      _error = 'Search failed: $e';
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<void> loadPlayer(String playerId) async {
    try {
      _selectedPlayer = await _service.getPlayer(playerId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load player: $e';
      notifyListeners();
    }
  }

  void selectPlayer(Player player) {
    _selectedPlayer = player;
    notifyListeners();
  }

  void clearSelection() {
    _selectedPlayer = null;
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    _searchQuery = '';
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Eligibility Management

  Future<void> loadEligibilities(String leagueId) async {
    if (_isLoadingEligibilities && _currentLeagueId == leagueId) return;

    _isLoadingEligibilities = true;
    _currentLeagueId = leagueId;
    notifyListeners();

    try {
      _eligibilities = await _service.getLeagueEligibilities(leagueId);
      _isLoadingEligibilities = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load eligibilities: $e';
      _isLoadingEligibilities = false;
      notifyListeners();
    }
  }

  Future<void> setPlayerEligibility(
    String playerId,
    String leagueId,
    DraftEligibility eligibility, {
    String? note,
    String? ownerTeamId,
  }) async {
    try {
      final status = await _service.setPlayerEligibility(
        playerId,
        leagueId,
        eligibility: eligibility,
        note: note,
        ownerTeamId: ownerTeamId,
      );

      // Update local cache
      _eligibilities[playerId] = status;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to set eligibility: $e';
      notifyListeners();
      rethrow;
    }
  }

  DraftEligibility getPlayerEligibility(String playerId) {
    final status = _eligibilities[playerId];
    return status?.eligibility ?? DraftEligibility.eligible;
  }

  EligibilityStatus? getPlayerEligibilityStatus(String playerId) {
    return _eligibilities[playerId];
  }

  Future<void> bulkSetEligibility(
    String leagueId,
    List<BulkEligibilityUpdate> updates,
  ) async {
    try {
      await _service.bulkSetEligibility(leagueId, updates);

      // Update local cache
      for (final update in updates) {
        _eligibilities[update.playerId] = EligibilityStatus(
          playerId: update.playerId,
          leagueId: leagueId,
          eligibility: update.eligibility,
          note: update.note,
          ownerTeamId: update.ownerTeamId,
        );
      }
      notifyListeners();
    } catch (e) {
      _error = 'Failed to bulk set eligibility: $e';
      notifyListeners();
      rethrow;
    }
  }

  void clearEligibilities() {
    _eligibilities = {};
    _currentLeagueId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
