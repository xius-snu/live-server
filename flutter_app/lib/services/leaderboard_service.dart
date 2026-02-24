import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'user_service.dart';

/// A single entry in a leaderboard category.
class LeaderboardEntry {
  final int rank;
  final String userId;
  final String username;
  final double value;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    required this.value,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
        rank: j['rank'] as int? ?? 0,
        userId: j['userId'] as String? ?? '',
        username: j['username'] as String? ?? '',
        value: (j['value'] as num?)?.toDouble() ?? 0,
      );
}

/// Player's own stats + rank in each category.
class PlayerLeaderboardStats {
  final double avgCoverage;
  final double weeklyCoinsEarned;
  final int weeklyWallsPainted;
  final int avgCoverageRank;
  final int coinsRank;
  final int wallsRank;

  const PlayerLeaderboardStats({
    required this.avgCoverage,
    required this.weeklyCoinsEarned,
    required this.weeklyWallsPainted,
    required this.avgCoverageRank,
    required this.coinsRank,
    required this.wallsRank,
  });

  factory PlayerLeaderboardStats.fromJson(Map<String, dynamic> j) =>
      PlayerLeaderboardStats(
        avgCoverage: (j['avgCoverage'] as num?)?.toDouble() ?? 0,
        weeklyCoinsEarned: (j['weeklyCoinsEarned'] as num?)?.toDouble() ?? 0,
        weeklyWallsPainted: (j['weeklyWallsPainted'] as num?)?.toInt() ?? 0,
        avgCoverageRank: j['avgCoverageRank'] as int? ?? 0,
        coinsRank: j['coinsRank'] as int? ?? 0,
        wallsRank: j['wallsRank'] as int? ?? 0,
      );
}

class LeaderboardService extends ChangeNotifier {
  final UserService _userService;

  LeaderboardService(this._userService);

  // State
  bool _loading = false;
  bool _joining = false;
  bool _joined = false;
  String? _lastError;
  String _weekId = '';
  DateTime? _startsAt;
  DateTime? _endsAt;

  List<LeaderboardEntry> _avgCoverageBoard = [];
  List<LeaderboardEntry> _coinsBoard = [];
  List<LeaderboardEntry> _wallsBoard = [];
  PlayerLeaderboardStats? _playerStats;

  int _nextRefreshIn = 600; // seconds until server cache refreshes
  int _lastUpdatedAgo = 0;   // seconds since last server cache refresh
  Timer? _countdownTimer;

  // Getters
  bool get loading => _loading;
  bool get joining => _joining;
  bool get joined => _joined;
  String? get lastError => _lastError;
  String get weekId => _weekId;
  DateTime? get startsAt => _startsAt;
  DateTime? get endsAt => _endsAt;
  List<LeaderboardEntry> get avgCoverageBoard => _avgCoverageBoard;
  List<LeaderboardEntry> get coinsBoard => _coinsBoard;
  List<LeaderboardEntry> get wallsBoard => _wallsBoard;
  PlayerLeaderboardStats? get playerStats => _playerStats;
  int get nextRefreshIn => _nextRefreshIn;
  int get lastUpdatedAgo => _lastUpdatedAgo;

  String get _baseUrl => _userService.baseUrl;
  String? get _userId => _userService.userId;

  /// Check if user has joined this week.
  Future<void> checkStatus() async {
    if (_userId == null) return;
    try {
      final uri = Uri.parse('$_baseUrl/api/leaderboard/status?userId=$_userId');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        _joined = data['joined'] == true;
        _weekId = data['weekId'] as String? ?? '';
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Leaderboard status error: $e');
    }
  }

  /// Join the current week's leaderboard.
  Future<bool> joinWeek() async {
    if (_userId == null) {
      _lastError = 'Not signed in yet. Try again in a moment.';
      notifyListeners();
      return false;
    }
    _joining = true;
    _lastError = null;
    notifyListeners();

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/leaderboard/join'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': _userId}),
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        _joined = true;
        _joining = false;
        notifyListeners();
        // Fetch full data after joining
        await fetchLeaderboard();
        return true;
      }
      _lastError = 'Server error (${res.statusCode}). Try again.';
      _joining = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Leaderboard join error: $e');
      _lastError = 'Could not reach server. Check connection and retry.';
      _joining = false;
      notifyListeners();
      return false;
    }
  }

  /// Fetch full leaderboard data (cached on server).
  Future<void> fetchLeaderboard() async {
    if (_userId == null) return;
    _loading = true;
    notifyListeners();

    try {
      final uri = Uri.parse('$_baseUrl/api/leaderboard/current?userId=$_userId');
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        _weekId = data['weekId'] as String? ?? '';
        _startsAt = DateTime.tryParse(data['startsAt'] ?? '');
        _endsAt = DateTime.tryParse(data['endsAt'] ?? '');
        _nextRefreshIn = data['nextRefreshIn'] as int? ?? 600;
        _lastUpdatedAgo = data['lastUpdatedAgo'] as int? ?? 0;

        _avgCoverageBoard = _parseEntries(data['avgCoverage']);
        _coinsBoard = _parseEntries(data['coins']);
        _wallsBoard = _parseEntries(data['walls']);

        if (data['playerStats'] != null) {
          _playerStats = PlayerLeaderboardStats.fromJson(
              data['playerStats'] as Map<String, dynamic>);
          _joined = true;
        } else {
          _playerStats = null;
        }

        _startCountdown();
      }
    } catch (e) {
      debugPrint('Leaderboard fetch error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  List<LeaderboardEntry> _parseEntries(dynamic list) {
    if (list is! List) return [];
    return list
        .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Submit round stats (fire-and-forget, non-blocking).
  void submitRoundStats(double coverage, double coinsEarned) {
    if (_userId == null || !_joined) return;
    // Fire-and-forget
    http
        .post(
          Uri.parse('$_baseUrl/api/leaderboard/submit'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'userId': _userId,
            'coverage': coverage,
            'coinsEarned': coinsEarned,
          }),
        )
        .catchError((e) {
      debugPrint('Leaderboard submit error: $e');
      return http.Response('', 500);
    });
  }

  /// Countdown timer that ticks _nextRefreshIn and _lastUpdatedAgo each second.
  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_nextRefreshIn > 0) {
        _nextRefreshIn--;
        _lastUpdatedAgo++;
        notifyListeners();
      } else {
        // Auto-refresh when timer hits 0
        _countdownTimer?.cancel();
        fetchLeaderboard();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
