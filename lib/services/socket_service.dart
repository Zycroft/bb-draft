import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_config.dart';
import '../models/draft.dart';

class SocketService {
  io.Socket? _socket;
  bool _isConnected = false;

  // Stream controllers for events
  final _draftStateController = StreamController<DraftStateEvent>.broadcast();
  final _pickMadeController = StreamController<PickMadeEvent>.broadcast();
  final _clockTickController = StreamController<ClockTickEvent>.broadcast();
  final _autoPickController = StreamController<AutoPickEvent>.broadcast();
  final _completedController = StreamController<String>.broadcast();
  final _errorController = StreamController<SocketError>.broadcast();
  final _userConnectedController = StreamController<UserConnectionEvent>.broadcast();
  final _userDisconnectedController = StreamController<UserConnectionEvent>.broadcast();
  final _chatMessageController = StreamController<ChatMessage>.broadcast();

  // Public streams
  Stream<DraftStateEvent> get draftState => _draftStateController.stream;
  Stream<PickMadeEvent> get pickMade => _pickMadeController.stream;
  Stream<ClockTickEvent> get clockTick => _clockTickController.stream;
  Stream<AutoPickEvent> get autoPick => _autoPickController.stream;
  Stream<String> get draftCompleted => _completedController.stream;
  Stream<SocketError> get errors => _errorController.stream;
  Stream<UserConnectionEvent> get userConnected => _userConnectedController.stream;
  Stream<UserConnectionEvent> get userDisconnected => _userDisconnectedController.stream;
  Stream<ChatMessage> get chatMessages => _chatMessageController.stream;

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_socket != null && _isConnected) return;

    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) {
      _errorController.add(SocketError(code: 'AUTH', message: 'Not authenticated'));
      return;
    }

    _socket = io.io(
      ApiConfig.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
    });

    _socket!.on('draft:state', (data) {
      _draftStateController.add(DraftStateEvent.fromJson(data));
    });

    _socket!.on('draft:pick_made', (data) {
      _pickMadeController.add(PickMadeEvent.fromJson(data));
    });

    _socket!.on('draft:clock_tick', (data) {
      _clockTickController.add(ClockTickEvent.fromJson(data));
    });

    _socket!.on('draft:auto_pick', (data) {
      _autoPickController.add(AutoPickEvent.fromJson(data));
    });

    _socket!.on('draft:completed', (data) {
      _completedController.add(data['draftId']);
    });

    _socket!.on('draft:error', (data) {
      _errorController.add(SocketError.fromJson(data));
    });

    _socket!.on('draft:user_connected', (data) {
      _userConnectedController.add(UserConnectionEvent.fromJson(data));
    });

    _socket!.on('draft:user_disconnected', (data) {
      _userDisconnectedController.add(UserConnectionEvent.fromJson(data));
    });

    _socket!.on('draft:chat_message', (data) {
      _chatMessageController.add(ChatMessage.fromJson(data));
    });

    _socket!.connect();
  }

  void joinDraft(String draftId, String teamId) {
    _socket?.emit('draft:join', {'draftId': draftId, 'teamId': teamId});
  }

  void leaveDraft(String draftId) {
    _socket?.emit('draft:leave', {'draftId': draftId});
  }

  void makePick(String draftId, String teamId, String playerId) {
    _socket?.emit('draft:pick', {
      'draftId': draftId,
      'teamId': teamId,
      'playerId': playerId,
    });
  }

  void updateQueue(String draftId, String teamId, List<String> queue) {
    _socket?.emit('draft:queue_update', {
      'draftId': draftId,
      'teamId': teamId,
      'queue': queue,
    });
  }

  void sendChatMessage(String draftId, String message) {
    _socket?.emit('draft:chat', {'draftId': draftId, 'message': message});
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _draftStateController.close();
    _pickMadeController.close();
    _clockTickController.close();
    _autoPickController.close();
    _completedController.close();
    _errorController.close();
    _userConnectedController.close();
    _userDisconnectedController.close();
    _chatMessageController.close();
  }
}

// Event classes
class DraftStateEvent {
  final Draft draft;
  final List<DraftPick> picks;
  final int timeRemaining;
  final List<ConnectedUser> connectedUsers;

  DraftStateEvent({
    required this.draft,
    required this.picks,
    required this.timeRemaining,
    required this.connectedUsers,
  });

  factory DraftStateEvent.fromJson(Map<String, dynamic> json) {
    final draft = Draft.fromJson(json['draft'] ?? json);
    final picks = (json['picks'] as List? ?? [])
        .map((p) => DraftPick.fromJson(p))
        .toList();
    final users = (json['connectedUsers'] as List? ?? [])
        .map((u) => ConnectedUser.fromJson(u))
        .toList();

    return DraftStateEvent(
      draft: draft,
      picks: picks,
      timeRemaining: json['timeRemaining'] ?? 0,
      connectedUsers: users,
    );
  }
}

class PickMadeEvent {
  final DraftPick pick;
  final NextPick? nextPick;
  final int timeRemaining;

  PickMadeEvent({
    required this.pick,
    this.nextPick,
    required this.timeRemaining,
  });

  factory PickMadeEvent.fromJson(Map<String, dynamic> json) {
    NextPick? nextPick;
    if (json['nextPick'] != null) {
      nextPick = NextPick.fromJson(json['nextPick']);
    }

    return PickMadeEvent(
      pick: DraftPick.fromJson(json['pick']),
      nextPick: nextPick,
      timeRemaining: json['timeRemaining'] ?? 0,
    );
  }
}

class NextPick {
  final String teamId;
  final int round;
  final int pickInRound;
  final int overallPick;

  NextPick({
    required this.teamId,
    required this.round,
    required this.pickInRound,
    required this.overallPick,
  });

  factory NextPick.fromJson(Map<String, dynamic> json) => NextPick(
    teamId: json['teamId'] ?? '',
    round: json['round'] ?? 0,
    pickInRound: json['pickInRound'] ?? 0,
    overallPick: json['overallPick'] ?? 0,
  );
}

class ClockTickEvent {
  final int timeRemaining;
  final OnTheClock? onTheClock;

  ClockTickEvent({required this.timeRemaining, this.onTheClock});

  factory ClockTickEvent.fromJson(Map<String, dynamic> json) {
    OnTheClock? onTheClock;
    if (json['onTheClock'] != null) {
      onTheClock = OnTheClock.fromJson(json['onTheClock']);
    }
    return ClockTickEvent(
      timeRemaining: json['timeRemaining'] ?? 0,
      onTheClock: onTheClock,
    );
  }
}

class AutoPickEvent {
  final DraftPick pick;
  final String reason;

  AutoPickEvent({required this.pick, required this.reason});

  factory AutoPickEvent.fromJson(Map<String, dynamic> json) => AutoPickEvent(
    pick: DraftPick.fromJson(json['pick']),
    reason: json['reason'] ?? '',
  );
}

class SocketError {
  final String code;
  final String message;

  SocketError({required this.code, required this.message});

  factory SocketError.fromJson(Map<String, dynamic> json) => SocketError(
    code: json['code'] ?? 'ERROR',
    message: json['message'] ?? 'Unknown error',
  );
}

class UserConnectionEvent {
  final String userId;
  final String teamId;

  UserConnectionEvent({required this.userId, required this.teamId});

  factory UserConnectionEvent.fromJson(Map<String, dynamic> json) => UserConnectionEvent(
    userId: json['userId'] ?? '',
    teamId: json['teamId'] ?? '',
  );
}

class ConnectedUser {
  final String userId;
  final String teamId;

  ConnectedUser({required this.userId, required this.teamId});

  factory ConnectedUser.fromJson(Map<String, dynamic> json) => ConnectedUser(
    userId: json['userId'] ?? '',
    teamId: json['teamId'] ?? '',
  );
}

class ChatMessage {
  final String userId;
  final String message;
  final String timestamp;

  ChatMessage({required this.userId, required this.message, required this.timestamp});

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    userId: json['userId'] ?? '',
    message: json['message'] ?? '',
    timestamp: json['timestamp'] ?? '',
  );
}
