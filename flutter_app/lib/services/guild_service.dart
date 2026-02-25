import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// -- Models --

class Guild {
  final String id;
  final String name;
  final String tag; // 3-4 chars
  final String motto;
  final int memberCount;
  final int level;
  final int totalXP;
  final int weeklyXP;
  final DateTime createdAt;
  final String leaderId;
  final String leaderName;

  const Guild({
    required this.id,
    required this.name,
    required this.tag,
    required this.motto,
    required this.memberCount,
    required this.level,
    required this.totalXP,
    required this.weeklyXP,
    required this.createdAt,
    required this.leaderId,
    required this.leaderName,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'tag': tag,
        'motto': motto,
        'memberCount': memberCount,
        'level': level,
        'totalXP': totalXP,
        'weeklyXP': weeklyXP,
        'createdAt': createdAt.toIso8601String(),
        'leaderId': leaderId,
        'leaderName': leaderName,
      };

  factory Guild.fromJson(Map<String, dynamic> j) => Guild(
        id: j['id'] as String,
        name: j['name'] as String,
        tag: j['tag'] as String,
        motto: j['motto'] as String? ?? '',
        memberCount: j['memberCount'] as int? ?? 1,
        level: j['level'] as int? ?? 1,
        totalXP: j['totalXP'] as int? ?? 0,
        weeklyXP: j['weeklyXP'] as int? ?? 0,
        createdAt: DateTime.parse(j['createdAt'] as String),
        leaderId: j['leaderId'] as String,
        leaderName: j['leaderName'] as String? ?? 'Unknown',
      );

  Guild copyWith({
    int? memberCount,
    int? level,
    int? totalXP,
    int? weeklyXP,
  }) =>
      Guild(
        id: id,
        name: name,
        tag: tag,
        motto: motto,
        memberCount: memberCount ?? this.memberCount,
        level: level ?? this.level,
        totalXP: totalXP ?? this.totalXP,
        weeklyXP: weeklyXP ?? this.weeklyXP,
        createdAt: createdAt,
        leaderId: leaderId,
        leaderName: leaderName,
      );
}

enum GuildRole { leader, officer, member }

class GuildMember {
  final String userId;
  final String username;
  final GuildRole role;
  final DateTime joinedAt;
  final int weeklyContribution;

  const GuildMember({
    required this.userId,
    required this.username,
    required this.role,
    required this.joinedAt,
    this.weeklyContribution = 0,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'username': username,
        'role': role.name,
        'joinedAt': joinedAt.toIso8601String(),
        'weeklyContribution': weeklyContribution,
      };

  factory GuildMember.fromJson(Map<String, dynamic> j) => GuildMember(
        userId: j['userId'] as String,
        username: j['username'] as String,
        role: GuildRole.values.byName(j['role'] as String? ?? 'member'),
        joinedAt: DateTime.parse(j['joinedAt'] as String),
        weeklyContribution: j['weeklyContribution'] as int? ?? 0,
      );
}

// -- Guild perk calculation --

class GuildPerks {
  final double cashBonus; // e.g. 0.06 = +6%

  const GuildPerks({this.cashBonus = 0});

  /// +2% cash bonus per guild level, capped at level 10 (+20%).
  factory GuildPerks.forLevel(int guildLevel) {
    final capped = guildLevel.clamp(0, 10);
    return GuildPerks(cashBonus: 0.02 * capped);
  }

  static const none = GuildPerks();
}

// -- XP thresholds per guild level --

int _xpForLevel(int level) => 500 * level * level; // 500, 2000, 4500, 8000...

int guildLevelFromXP(int totalXP) {
  int lvl = 0;
  while (_xpForLevel(lvl + 1) <= totalXP) {
    lvl++;
  }
  return lvl.clamp(0, 10);
}

// -- Service --

class GuildService extends ChangeNotifier {
  static const _prefsKey = 'guild_membership';

  Guild? _currentGuild;
  List<GuildMember> _members = [];
  List<Guild> _guildLeaderboard = [];
  bool _initialized = false;

  Guild? get currentGuild => _currentGuild;
  List<GuildMember> get members => List.unmodifiable(_members);
  List<Guild> get guildLeaderboard => List.unmodifiable(_guildLeaderboard);
  bool get isInGuild => _currentGuild != null;
  bool get initialized => _initialized;

  GuildPerks get guildPerks =>
      _currentGuild != null ? GuildPerks.forLevel(_currentGuild!.level) : GuildPerks.none;

  Future<void> init() async {
    await _loadLocally();
    _guildLeaderboard = _generateMockLeaderboard();
    _initialized = true;
    notifyListeners();
  }

  // -- Create guild (costs 500 gems, deducted by caller) --

  Future<bool> createGuild({
    required String name,
    required String tag,
    required String motto,
    required String userId,
    required String username,
  }) async {
    if (tag.length < 3 || tag.length > 4) return false;
    if (name.trim().isEmpty) return false;

    final now = DateTime.now();
    _currentGuild = Guild(
      id: 'guild_${now.millisecondsSinceEpoch}',
      name: name.trim(),
      tag: tag.toUpperCase(),
      motto: motto.trim(),
      memberCount: 1,
      level: 1,
      totalXP: 0,
      weeklyXP: 0,
      createdAt: now,
      leaderId: userId,
      leaderName: username,
    );
    _members = [
      GuildMember(
        userId: userId,
        username: username,
        role: GuildRole.leader,
        joinedAt: now,
      ),
    ];

    await _saveLocally();
    notifyListeners();
    return true;
  }

  // -- Join by invite code (mock: always succeeds) --

  Future<bool> joinGuild({
    required String inviteCode,
    required String userId,
    required String username,
  }) async {
    if (_currentGuild != null) return false;

    // Mock: generate a guild from the invite code
    final rng = Random(inviteCode.hashCode);
    final mockNames = ['BrushBros', 'RollSquad', 'PaintKings', 'CoatCrew', 'WallStars'];
    final mockTags = ['BRB', 'RSQ', 'PKG', 'CCW', 'WST'];
    final idx = rng.nextInt(mockNames.length);
    final now = DateTime.now();

    final memberCount = 5 + rng.nextInt(20);
    final totalXP = 1000 + rng.nextInt(15000);
    final level = guildLevelFromXP(totalXP);

    _currentGuild = Guild(
      id: 'guild_$inviteCode',
      name: mockNames[idx],
      tag: mockTags[idx],
      motto: 'Paint it forward!',
      memberCount: memberCount + 1,
      level: level,
      totalXP: totalXP,
      weeklyXP: rng.nextInt(3000),
      createdAt: now.subtract(Duration(days: 30 + rng.nextInt(180))),
      leaderId: 'leader_$inviteCode',
      leaderName: 'Captain${rng.nextInt(999)}',
    );
    _members = _generateMockMembers(memberCount, rng)
      ..add(GuildMember(
        userId: userId,
        username: username,
        role: GuildRole.member,
        joinedAt: now,
      ));

    await _saveLocally();
    notifyListeners();
    return true;
  }

  // -- Leave guild --

  Future<void> leaveGuild() async {
    _currentGuild = null;
    _members = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    notifyListeners();
  }

  // -- Contribute XP (called when a wall is painted) --

  void contributeXP(int xp) {
    if (_currentGuild == null) return;
    final newTotalXP = _currentGuild!.totalXP + xp;
    final newLevel = guildLevelFromXP(newTotalXP);
    _currentGuild = _currentGuild!.copyWith(
      totalXP: newTotalXP,
      weeklyXP: _currentGuild!.weeklyXP + xp,
      level: newLevel,
    );
    _saveLocally();
    notifyListeners();
  }

  // -- Persistence --

  Future<void> _loadLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_prefsKey);
    if (json != null) {
      try {
        final data = jsonDecode(json) as Map<String, dynamic>;
        _currentGuild = Guild.fromJson(data['guild'] as Map<String, dynamic>);
        _members = (data['members'] as List)
            .map((m) => GuildMember.fromJson(m as Map<String, dynamic>))
            .toList();
      } catch (_) {
        // Corrupted data, start fresh
        _currentGuild = null;
        _members = [];
      }
    }
  }

  Future<void> _saveLocally() async {
    if (_currentGuild == null) return;
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode({
      'guild': _currentGuild!.toJson(),
      'members': _members.map((m) => m.toJson()).toList(),
    });
    await prefs.setString(_prefsKey, data);
  }

  // -- Mock data generators --

  List<Guild> _generateMockLeaderboard() {
    final rng = Random(42);
    final names = [
      'RollMasters', 'BrushElite', 'CoatLegends', 'PaintForce',
      'WallBreakers', 'ColorStorm', 'PrimerSquad', 'GlossGang',
      'StrokeKings', 'FinishLine',
    ];
    final tags = ['RLM', 'BRE', 'CTL', 'PNF', 'WBK', 'CST', 'PRS', 'GLG', 'STK', 'FNL'];

    return List.generate(10, (i) {
      final totalXP = 20000 - i * 1500 + rng.nextInt(500);
      return Guild(
        id: 'mock_guild_$i',
        name: names[i],
        tag: tags[i],
        motto: 'We paint to win!',
        memberCount: 10 + rng.nextInt(40),
        level: guildLevelFromXP(totalXP),
        totalXP: totalXP,
        weeklyXP: 1000 + rng.nextInt(5000),
        createdAt: DateTime.now().subtract(Duration(days: 60 + rng.nextInt(300))),
        leaderId: 'mock_leader_$i',
        leaderName: 'Leader${rng.nextInt(9999)}',
      );
    });
  }

  List<GuildMember> _generateMockMembers(int count, Random rng) {
    final adjectives = ['Swift', 'Bold', 'Chill', 'Epic', 'Pro', 'Neon', 'Dark', 'Lil'];
    final nouns = ['Brush', 'Roller', 'Coat', 'Drip', 'Stroke', 'Paint', 'Wall', 'Hue'];

    return List.generate(min(count, 30), (i) {
      final isOfficer = i < 3;
      return GuildMember(
        userId: 'mock_user_$i',
        username: '${adjectives[rng.nextInt(adjectives.length)]}${nouns[rng.nextInt(nouns.length)]}${rng.nextInt(99)}',
        role: i == 0 ? GuildRole.leader : (isOfficer ? GuildRole.officer : GuildRole.member),
        joinedAt: DateTime.now().subtract(Duration(days: rng.nextInt(180))),
        weeklyContribution: rng.nextInt(2000),
      );
    });
  }
}
