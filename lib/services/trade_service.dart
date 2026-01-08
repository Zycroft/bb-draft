import 'api_service.dart';

class TradeService {
  final ApiService _api = ApiService();

  Future<Trade> proposeTrade({
    required String leagueId,
    required String receivingTeamId,
    required List<TradeAsset> sending,
    required List<TradeAsset> receiving,
  }) async {
    final response = await _api.post('/trades', {
      'leagueId': leagueId,
      'receivingTeamId': receivingTeamId,
      'sending': sending.map((a) => a.toJson()).toList(),
      'receiving': receiving.map((a) => a.toJson()).toList(),
    });
    return Trade.fromJson(response);
  }

  Future<List<Trade>> getLeagueTrades(String leagueId, {String? status}) async {
    String endpoint = '/trades/league/$leagueId';
    if (status != null) endpoint += '?status=$status';
    final response = await _api.get(endpoint);
    if (response is List) {
      return response.map((json) => Trade.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<Trade>> getMyTrades(String leagueId) async {
    final response = await _api.get('/trades/my-trades/$leagueId');
    if (response is List) {
      return response.map((json) => Trade.fromJson(json)).toList();
    }
    return [];
  }

  Future<Trade> getTrade(String tradeId) async {
    final response = await _api.get('/trades/$tradeId');
    return Trade.fromJson(response);
  }

  Future<Trade> acceptTrade(String tradeId) async {
    final response = await _api.post('/trades/$tradeId/accept', {});
    return Trade.fromJson(response['trade']);
  }

  Future<Trade> rejectTrade(String tradeId) async {
    final response = await _api.post('/trades/$tradeId/reject', {});
    return Trade.fromJson(response['trade']);
  }

  Future<Trade> cancelTrade(String tradeId) async {
    final response = await _api.post('/trades/$tradeId/cancel', {});
    return Trade.fromJson(response['trade']);
  }

  Future<Trade> vetoTrade(String tradeId, {String? reason}) async {
    final response = await _api.post('/trades/$tradeId/veto', {
      if (reason != null) 'reason': reason,
    });
    return Trade.fromJson(response['trade']);
  }

  Future<Trade> approveTrade(String tradeId) async {
    final response = await _api.post('/trades/$tradeId/approve', {});
    return Trade.fromJson(response['trade']);
  }

  void dispose() {
    _api.dispose();
  }
}

// Trade Models
class Trade {
  final String tradeId;
  final String leagueId;
  final TradeStatus status;
  final String proposedAt;
  final TradeParty proposingTeam;
  final TradeParty receivingTeam;
  final CommissionerApproval? commissionerApproval;
  final String? executedAt;
  final String? cancelledAt;
  final String? expiresAt;

  Trade({
    required this.tradeId,
    required this.leagueId,
    required this.status,
    required this.proposedAt,
    required this.proposingTeam,
    required this.receivingTeam,
    this.commissionerApproval,
    this.executedAt,
    this.cancelledAt,
    this.expiresAt,
  });

  factory Trade.fromJson(Map<String, dynamic> json) => Trade(
    tradeId: json['tradeId'] ?? '',
    leagueId: json['leagueId'] ?? '',
    status: TradeStatus.fromString(json['status']),
    proposedAt: json['proposedAt'] ?? '',
    proposingTeam: TradeParty.fromJson(json['proposingTeam'] ?? {}),
    receivingTeam: TradeParty.fromJson(json['receivingTeam'] ?? {}),
    commissionerApproval: json['commissionerApproval'] != null
        ? CommissionerApproval.fromJson(json['commissionerApproval'])
        : null,
    executedAt: json['executedAt'],
    cancelledAt: json['cancelledAt'],
    expiresAt: json['expiresAt'],
  );

  bool get isPending => status == TradeStatus.pending;
  bool get isExecuted => status == TradeStatus.executed;
  bool get isExpired => status == TradeStatus.expired;
}

enum TradeStatus {
  pending('pending'),
  accepted('accepted'),
  rejected('rejected'),
  executed('executed'),
  cancelled('cancelled'),
  expired('expired');

  final String value;
  const TradeStatus(this.value);

  static TradeStatus fromString(String? value) {
    switch (value) {
      case 'pending':
        return TradeStatus.pending;
      case 'accepted':
        return TradeStatus.accepted;
      case 'rejected':
        return TradeStatus.rejected;
      case 'executed':
        return TradeStatus.executed;
      case 'cancelled':
        return TradeStatus.cancelled;
      case 'expired':
        return TradeStatus.expired;
      default:
        return TradeStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case TradeStatus.pending:
        return 'Pending';
      case TradeStatus.accepted:
        return 'Accepted';
      case TradeStatus.rejected:
        return 'Rejected';
      case TradeStatus.executed:
        return 'Executed';
      case TradeStatus.cancelled:
        return 'Cancelled';
      case TradeStatus.expired:
        return 'Expired';
    }
  }
}

class TradeParty {
  final String teamId;
  final String? teamName;
  final bool accepted;
  final List<TradeAsset> sending;
  final List<TradeAsset> receiving;

  TradeParty({
    required this.teamId,
    this.teamName,
    required this.accepted,
    required this.sending,
    required this.receiving,
  });

  factory TradeParty.fromJson(Map<String, dynamic> json) => TradeParty(
    teamId: json['teamId'] ?? '',
    teamName: json['teamName'],
    accepted: json['accepted'] ?? false,
    sending: (json['sending'] as List? ?? [])
        .map((a) => TradeAsset.fromJson(a))
        .toList(),
    receiving: (json['receiving'] as List? ?? [])
        .map((a) => TradeAsset.fromJson(a))
        .toList(),
  );
}

class TradeAsset {
  final String type; // 'pick' or 'player'
  final String? playerId;
  final String? playerName;
  final int? seasonYear;
  final int? round;
  final String? originalOwner;

  TradeAsset({
    required this.type,
    this.playerId,
    this.playerName,
    this.seasonYear,
    this.round,
    this.originalOwner,
  });

  factory TradeAsset.fromJson(Map<String, dynamic> json) => TradeAsset(
    type: json['type'] ?? 'pick',
    playerId: json['playerId'],
    playerName: json['playerName'],
    seasonYear: json['seasonYear'],
    round: json['round'],
    originalOwner: json['originalOwner'],
  );

  Map<String, dynamic> toJson() => {
    'type': type,
    if (playerId != null) 'playerId': playerId,
    if (playerName != null) 'playerName': playerName,
    if (seasonYear != null) 'seasonYear': seasonYear,
    if (round != null) 'round': round,
    if (originalOwner != null) 'originalOwner': originalOwner,
  };

  String get displayName {
    if (type == 'player') {
      return playerName ?? 'Unknown Player';
    }
    return 'Round $round Pick ($seasonYear)';
  }
}

class CommissionerApproval {
  final bool approved;
  final String reviewedAt;
  final String reviewedBy;
  final String? notes;

  CommissionerApproval({
    required this.approved,
    required this.reviewedAt,
    required this.reviewedBy,
    this.notes,
  });

  factory CommissionerApproval.fromJson(Map<String, dynamic> json) =>
      CommissionerApproval(
        approved: json['approved'] ?? false,
        reviewedAt: json['reviewedAt'] ?? '',
        reviewedBy: json['reviewedBy'] ?? '',
        notes: json['notes'],
      );
}
