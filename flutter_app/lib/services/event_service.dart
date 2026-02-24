import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/marketplace_item.dart';

class EventData {
  final String eventId;
  final String name;
  final String description;
  final DateTime startAt;
  final DateTime endAt;
  final Map<String, double> dropTable;
  final int maxAttempts;
  final String status;

  EventData({
    required this.eventId,
    required this.name,
    required this.description,
    required this.startAt,
    required this.endAt,
    required this.dropTable,
    required this.maxAttempts,
    required this.status,
  });

  Duration get timeRemaining {
    final diff = endAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  bool get isActive =>
      status == 'active' &&
      DateTime.now().isAfter(startAt) &&
      DateTime.now().isBefore(endAt);

  factory EventData.fromJson(Map<String, dynamic> json) {
    final dt = json['drop_table'];
    final dropTable = <String, double>{};
    if (dt is Map) {
      for (final e in dt.entries) {
        dropTable[e.key.toString()] = (e.value as num?)?.toDouble() ?? 0;
      }
    }
    return EventData(
      eventId: json['event_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      startAt: DateTime.tryParse(json['start_at'] ?? '') ?? DateTime.now(),
      endAt: DateTime.tryParse(json['end_at'] ?? '') ?? DateTime.now(),
      dropTable: dropTable,
      maxAttempts: json['max_attempts'] ?? 3,
      status: json['status'] ?? 'scheduled',
    );
  }
}

class EventReward {
  final String instanceId;
  final String itemTypeId;
  final String rarity;
  final int attemptsRemaining;

  EventReward({
    required this.instanceId,
    required this.itemTypeId,
    required this.rarity,
    required this.attemptsRemaining,
  });

  MarketplaceItemType? get itemType => MarketplaceItemType.getById(itemTypeId);
}

class EventService extends ChangeNotifier {
  String baseUrl;
  String? Function() userIdGetter;

  List<EventData> _events = [];
  Map<String, int> _attemptsUsed = {}; // eventId -> attempts used
  bool _loading = false;
  Timer? _refreshTimer;

  EventService({required this.baseUrl, required this.userIdGetter});

  List<EventData> get events => _events;
  List<EventData> get activeEvents => _events.where((e) => e.isActive).toList();
  bool get loading => _loading;

  int attemptsUsedFor(String eventId) => _attemptsUsed[eventId] ?? 0;
  int attemptsRemainingFor(EventData event) =>
      event.maxAttempts - attemptsUsedFor(event.eventId);

  String? get _userId => userIdGetter();

  void startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      notifyListeners(); // refresh countdown displays
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchEvents() async {
    _loading = true;
    notifyListeners();

    try {
      final res = await http.get(Uri.parse('$baseUrl/api/events/active'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final events = (data['events'] as List?) ?? [];
        _events = events.map((j) => EventData.fromJson(j)).toList();
      }
    } catch (e) {
      debugPrint('Events fetch error: $e');
    }

    _loading = false;
    notifyListeners();
  }

  /// Attempt an event. Returns EventReward on success, error string on failure.
  Future<(EventReward?, String?)> attemptEvent(
      String eventId, double coveragePercent) async {
    if (_userId == null) return (null, 'Not logged in');

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/events/$eventId/attempt'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': _userId,
          'coveragePercent': coveragePercent,
        }),
      );
      final data = json.decode(res.body);

      if (res.statusCode == 200 && data['success'] == true) {
        final reward = data['reward'];
        final remaining = data['attemptsRemaining'] as int? ?? 0;
        final eventReward = EventReward(
          instanceId: reward['instanceId'],
          itemTypeId: reward['itemTypeId'],
          rarity: reward['rarity'],
          attemptsRemaining: remaining,
        );

        _attemptsUsed[eventId] = (_attemptsUsed[eventId] ?? 0) + 1;
        notifyListeners();
        return (eventReward, null as String?);
      }
      return (null, (data['error'] as String?) ?? 'Attempt failed');
    } catch (e) {
      return (null, 'Network error: $e');
    }
  }
}
