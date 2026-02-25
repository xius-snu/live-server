import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/event_service.dart';
import '../services/marketplace_service.dart';
import '../services/leaderboard_service.dart';
import '../services/user_service.dart';
import '../services/game_service.dart';
import 'minigame_speed_paint.dart';
import 'minigame_bullseye.dart';
import 'minigame_color_match.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final es = Provider.of<EventService>(context, listen: false);
      es.fetchEvents();
      es.startAutoRefresh();
      final lb = Provider.of<LeaderboardService>(context, listen: false);
      lb.checkStatus();
      lb.fetchLeaderboard();
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8D5B8),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const Text(
                    'Social',
                    style: TextStyle(
                      color: Color(0xFF6B5038),
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Consumer<GameService>(
                    builder: (context, gs, _) => Row(
                      children: [
                        _HudChip(
                          icon: 'assets/images/UI/coin250.png',
                          value: _fmt(gs.cash),
                          color: const Color(0xFFF5C842),
                        ),
                        const SizedBox(width: 6),
                        _HudChip(
                          icon: 'assets/images/UI/diamond250.png',
                          value: '${gs.gems}',
                          color: const Color(0xFFDA70D6),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Tab bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B5038),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: const Color(0xFFFF6B6B),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  dividerColor: Colors.transparent,
                  isScrollable: false,
                  labelPadding: EdgeInsets.zero,
                  indicatorSize: TabBarIndicatorSize.tab,
                  splashFactory: NoSplash.splashFactory,
                  tabs: const [
                    Tab(height: 36, text: 'Leaderboard'),
                    Tab(height: 36, text: 'Events'),
                    Tab(height: 36, text: 'Guild'),
                    Tab(height: 36, text: 'Mini'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _LeaderboardTab(),
                  _EventsTab(),
                  _GuildTab(),
                  _MinigamesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(double n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
  }
}

// =============================================================================
// HUD CHIP (reusable currency display)
// =============================================================================
class _HudChip extends StatelessWidget {
  final String icon;
  final String value;
  final Color color;
  const _HudChip({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF111111), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(icon, width: 18, height: 18),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// LEADERBOARD TAB — Painter's Cup
// =============================================================================
class _LeaderboardTab extends StatefulWidget {
  @override
  State<_LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<_LeaderboardTab> {
  int _selectedCat = 0;
  static const _catLabels = ['Avg Coverage', 'Coins', 'Walls'];

  @override
  Widget build(BuildContext context) {
    return Consumer<LeaderboardService>(
      builder: (context, lb, _) {
        final board = _selectedCat == 0
            ? lb.avgCoverageBoard
            : _selectedCat == 1
                ? lb.coinsBoard
                : lb.wallsBoard;

        String weekDates = '';
        if (lb.startsAt != null && lb.endsAt != null) {
          weekDates =
              '${_fmtDate(lb.startsAt!)} - ${_fmtDate(lb.endsAt!.subtract(const Duration(days: 1)))}';
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // Trophy header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF3B82F6).withOpacity(0.15),
                      const Color(0xFFF5C842).withOpacity(0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    const Text('\u{1F3C6}', style: TextStyle(fontSize: 42)),
                    const SizedBox(height: 6),
                    const Text(
                      "PAINTER'S CUP",
                      style: TextStyle(
                        color: Color(0xFF6B5038),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    if (weekDates.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        weekDates,
                        style: TextStyle(color: const Color(0xFF6B5038).withOpacity(0.5), fontSize: 12),
                      ),
                    ],
                    if (lb.endsAt != null) ...[
                      const SizedBox(height: 6),
                      Builder(builder: (_) {
                        final remaining = lb.endsAt!.difference(DateTime.now());
                        if (remaining.isNegative) return const SizedBox.shrink();
                        final days = remaining.inDays;
                        final hours = remaining.inHours % 24;
                        final mins = remaining.inMinutes % 60;
                        final secs = remaining.inSeconds % 60;
                        String timeStr;
                        if (days > 0) {
                          timeStr = '${days}d ${hours}h ${mins}m';
                        } else if (hours > 0) {
                          timeStr = '${hours}h ${mins}m ${secs}s';
                        } else {
                          timeStr = '${mins}m ${secs}s';
                        }
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8734A).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE8734A).withOpacity(0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.timer_outlined, size: 14, color: const Color(0xFFE8734A).withOpacity(0.8)),
                              const SizedBox(width: 5),
                              Text(
                                'Resets in $timeStr',
                                style: TextStyle(
                                  color: const Color(0xFFE8734A).withOpacity(0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: 12),
                    // Join button
                    if (!lb.joined)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: lb.joining ? null : () async {
                            final ok = await lb.joinWeek();
                            if (!ok && context.mounted && lb.lastError != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(lb.lastError!), backgroundColor: Colors.red.shade700),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF5C842),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(lb.joining ? 'JOINING...' : 'JOIN LEADERBOARD',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4ADE80).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF4ADE80).withOpacity(0.3)),
                        ),
                        child: const Center(
                          child: Text('\u2705  PARTICIPATING',
                              style: TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Category selector
              Row(
                children: List.generate(3, (i) {
                  final sel = i == _selectedCat;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedCat = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        margin: EdgeInsets.only(left: i == 0 ? 0 : 4, right: i == 2 ? 0 : 4),
                        decoration: BoxDecoration(
                          color: sel ? const Color(0xFF3B82F6) : const Color(0xFF6B5038).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            _catLabels[i],
                            style: TextStyle(
                              color: sel ? Colors.white : const Color(0xFF6B5038).withOpacity(0.6),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),

              // Board
              if (lb.loading && board.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: CircularProgressIndicator(color: Color(0xFF3B82F6), strokeWidth: 2),
                )
              else if (board.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Text(
                    lb.joined ? 'No entries yet. Paint some walls!' : 'Join to see the leaderboard',
                    style: TextStyle(color: const Color(0xFF6B5038).withOpacity(0.5), fontSize: 13),
                  ),
                )
              else
                ...board.take(20).map((entry) {
                  final isMe = _isCurrentUser(context, entry.userId);
                  return _RankRow(
                    rank: entry.rank,
                    username: entry.username,
                    value: _formatValue(entry.value, _selectedCat),
                    isMe: isMe,
                    tab: _selectedCat,
                  );
                }),

              // Own rank below top 20
              if (lb.joined && lb.playerStats != null)
                Builder(builder: (_) {
                  final rank = _selectedCat == 0
                      ? lb.playerStats!.avgCoverageRank
                      : _selectedCat == 1
                          ? lb.playerStats!.coinsRank
                          : lb.playerStats!.wallsRank;
                  final val = _selectedCat == 0
                      ? lb.playerStats!.avgCoverage
                      : _selectedCat == 1
                          ? lb.playerStats!.weeklyCoinsEarned
                          : lb.playerStats!.weeklyWallsPainted.toDouble();
                  if (rank <= 20 && board.length >= rank) return const SizedBox.shrink();
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('\u2022 \u2022 \u2022',
                            style: TextStyle(color: const Color(0xFF6B5038).withOpacity(0.3))),
                      ),
                      _RankRow(rank: rank, username: 'You', value: _formatValue(val, _selectedCat), isMe: true, tab: _selectedCat),
                    ],
                  );
                }),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  bool _isCurrentUser(BuildContext context, String userId) {
    try {
      return Provider.of<UserService>(context, listen: false).userId == userId;
    } catch (_) {
      return false;
    }
  }

  static String _fmtDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.day}';
  }

  static String _formatValue(double value, int tab) {
    if (tab == 0) return '${(value * 100).toStringAsFixed(1)}%';
    if (tab == 1) return _fmtCommas(value);
    return value.toInt().toString();
  }

  static String _fmtCommas(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _RankRow extends StatelessWidget {
  final int rank;
  final String username;
  final String value;
  final bool isMe;
  final int tab;
  const _RankRow({required this.rank, required this.username, required this.value, required this.isMe, required this.tab});

  @override
  Widget build(BuildContext context) {
    const medals = ['\u{1F947}', '\u{1F948}', '\u{1F949}'];
    final rankDisplay = rank <= 3 ? medals[rank - 1] : '$rank.';
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe
              ? const Color(0xFF3B82F6).withOpacity(0.15)
              : rank == 1
                  ? const Color(0xFFF5C842).withOpacity(0.08)
                  : const Color(0xFF6B5038).withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border: isMe ? Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)) : null,
        ),
        child: Row(
          children: [
            SizedBox(width: 30, child: Text(rankDisplay, style: TextStyle(fontSize: rank <= 3 ? 16 : 13, color: const Color(0xFF6B5038).withOpacity(0.7), fontWeight: FontWeight.w600))),
            const SizedBox(width: 6),
            Expanded(child: Text(username, style: TextStyle(color: isMe ? const Color(0xFF3B82F6) : const Color(0xFF6B5038), fontSize: 13, fontWeight: isMe ? FontWeight.w700 : FontWeight.w500), overflow: TextOverflow.ellipsis)),
            if (tab == 1) ...[
              Image.asset('assets/images/UI/coin250.png', width: 14, height: 14),
              const SizedBox(width: 4),
            ],
            Text(value, style: TextStyle(color: const Color(0xFF6B5038).withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// EVENTS TAB
// =============================================================================
class _EventsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<EventService>(
      builder: (context, es, _) {
        final active = es.activeEvents;
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (active.isNotEmpty)
                ...active.map((event) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _LiveEventCard(event: event),
                    ))
              else ...[
                _NoEventsCard(),
                const SizedBox(height: 16),
              ],
              _DailyLotteryCard(),
              const SizedBox(height: 16),
              _CommunityGoalCard(),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }
}

// =============================================================================
// LIVE EVENT CARD
// =============================================================================
class _LiveEventCard extends StatelessWidget {
  final EventData event;
  const _LiveEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final es = context.watch<EventService>();
    final remaining = event.timeRemaining;
    final attemptsLeft = es.attemptsRemainingFor(event);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFA855F7), Color(0xFFE8734A)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 50),
              const Text('\u{1F3A8}\u{2728}', style: TextStyle(fontSize: 32)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(6)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  const Text('LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(event.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(event.description, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12), textAlign: TextAlign.center),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CountdownUnit(value: remaining.inHours, label: 'HR'),
              const SizedBox(width: 10),
              _CountdownUnit(value: remaining.inMinutes % 60, label: 'MIN'),
              const SizedBox(width: 10),
              _CountdownUnit(value: remaining.inSeconds % 60, label: 'SEC'),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: attemptsLeft > 0 ? () => _attemptEvent(context, event) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFE8734A),
                disabledBackgroundColor: Colors.white.withOpacity(0.3),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                attemptsLeft <= 0 ? 'NO ATTEMPTS LEFT' : 'ENTER ($attemptsLeft left)',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _attemptEvent(BuildContext context, EventData event) async {
    HapticFeedback.heavyImpact();
    final es = Provider.of<EventService>(context, listen: false);
    final (reward, err) = await es.attemptEvent(event.eventId, 0.85);
    if (!context.mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red));
      return;
    }
    if (reward != null) {
      final mp = Provider.of<MarketplaceService>(context, listen: false);
      mp.fetchInventory();
      _showRewardDialog(context, reward);
    }
  }

  void _showRewardDialog(BuildContext context, EventReward reward) {
    final name = reward.itemType?.name ?? reward.itemTypeId;
    final rc = _rarityColor(reward.rarity);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF6B5038),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Item Drop!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70, height: 70,
              decoration: BoxDecoration(color: rc.withOpacity(0.15), shape: BoxShape.circle, border: Border.all(color: rc.withOpacity(0.5), width: 3)),
              child: Center(child: Text(_rarityIcon(reward.rarity), style: const TextStyle(fontSize: 30))),
            ),
            const SizedBox(height: 12),
            Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: rc.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
              child: Text(reward.rarity.toUpperCase(), style: TextStyle(color: rc, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: rc, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('Nice!', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  static Color _rarityColor(String r) {
    switch (r) {
      case 'common': return Colors.grey;
      case 'uncommon': return const Color(0xFF4ADE80);
      case 'rare': return const Color(0xFF3B82F6);
      case 'epic': return const Color(0xFFA855F7);
      case 'legendary': return const Color(0xFFF59E0B);
      default: return Colors.grey;
    }
  }

  static String _rarityIcon(String r) {
    switch (r) {
      case 'common': return '\u{1F4E6}';
      case 'uncommon': return '\u{2728}';
      case 'rare': return '\u{1F3A8}';
      case 'epic': return '\u{1F48E}';
      case 'legendary': return '\u{1F451}';
      default: return '\u{1F4E6}';
    }
  }
}

class _CountdownUnit extends StatelessWidget {
  final int value;
  final String label;
  const _CountdownUnit({required this.value, required this.label});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
        child: Text(value.toString().padLeft(2, '0'), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'monospace')),
      ),
      const SizedBox(height: 3),
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.bold)),
    ]);
  }
}

class _NoEventsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF6B5038).withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        const Text('\u{23F3}', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 10),
        const Text('No Live Events', style: TextStyle(color: Color(0xFF6B5038), fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Check back soon!', style: TextStyle(color: const Color(0xFF6B5038).withOpacity(0.5), fontSize: 12)),
      ]),
    );
  }
}

// =============================================================================
// COMMUNITY GOAL — collective target all players work toward
// =============================================================================
class _CommunityGoalCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF4ADE80).withOpacity(0.1), const Color(0xFF3B82F6).withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF4ADE80).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('\u{1F30D}', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            const Text('COMMUNITY GOAL', style: TextStyle(color: Color(0xFF4ADE80), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
          ]),
          const SizedBox(height: 10),
          const Text('Paint 1,000,000 walls this week!', style: TextStyle(color: Color(0xFF6B5038), fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 0.42,
              minHeight: 10,
              backgroundColor: const Color(0xFF6B5038).withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF4ADE80)),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('420,000 / 1,000,000', style: TextStyle(color: const Color(0xFF6B5038).withOpacity(0.5), fontSize: 11)),
              Text('Reward: \u{1F48E}5 Gems', style: TextStyle(color: const Color(0xFFA855F7).withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// DAILY LOTTERY
// =============================================================================
class _DailyLotteryCard extends StatefulWidget {
  @override
  State<_DailyLotteryCard> createState() => _DailyLotteryCardState();
}

class _DailyLotteryCardState extends State<_DailyLotteryCard> {
  bool _spinning = false;
  String? _result;

  static const _prizes = [
    ('\u{1F4B0}', '+\$50 Cash', 0.40),
    ('\u{1F48E}', '+1 Gem', 0.25),
    ('\u{26A1}', 'Speed Boost', 0.15),
    ('\u{1F525}', '+2 Streak', 0.12),
    ('\u{1F3A8}', 'Rare Paint', 0.06),
    ('\u{1F451}', 'Mystery Item', 0.02),
  ];

  void _spin() {
    if (_spinning) return;
    HapticFeedback.heavyImpact();
    setState(() { _spinning = true; _result = null; });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      final roll = DateTime.now().millisecondsSinceEpoch % 100 / 100.0;
      double cumulative = 0;
      String prize = _prizes.first.$2;
      String icon = _prizes.first.$1;
      for (final p in _prizes) {
        cumulative += p.$3;
        if (roll < cumulative) { icon = p.$1; prize = p.$2; break; }
      }
      setState(() { _spinning = false; _result = '$icon $prize'; });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFFF5C842).withOpacity(0.12), const Color(0xFFE8734A).withOpacity(0.12)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF5C842).withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Text(_spinning ? '\u{1F3B0}' : (_result != null ? _result!.split(' ').first : '\u{1F3B2}'), style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          if (_result != null && !_spinning)
            Text(_result!, style: const TextStyle(color: Color(0xFFF5C842), fontWeight: FontWeight.w700, fontSize: 16))
          else if (_spinning)
            const Text('Spinning...', style: TextStyle(color: Color(0xFFE8734A), fontWeight: FontWeight.w600, fontSize: 13))
          else
            Text('Spin for a free daily reward!', style: TextStyle(color: const Color(0xFF6B5038).withOpacity(0.6), fontSize: 12)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6, runSpacing: 3, alignment: WrapAlignment.center,
            children: _prizes.map((p) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFF6B5038).withOpacity(0.06), borderRadius: BorderRadius.circular(5)),
              child: Text('${p.$1} ${(p.$3 * 100).toStringAsFixed(0)}%', style: TextStyle(color: const Color(0xFF6B5038).withOpacity(0.5), fontSize: 9)),
            )).toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _spinning ? null : _spin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5C842),
                foregroundColor: Colors.black,
                disabledBackgroundColor: const Color(0xFFF5C842).withOpacity(0.3),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(_spinning ? 'SPINNING...' : 'FREE SPIN', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// GUILD TAB
// =============================================================================
class _GuildTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Guild search / create
          _GuildOverview(),
          const SizedBox(height: 14),
          _GuildLeaderboard(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _GuildOverview extends StatelessWidget {
  // Mock data for guild - replace with GuildService when backend ready
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFFE8734A).withOpacity(0.12), const Color(0xFFA855F7).withOpacity(0.12)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8734A).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Text('\u{1F3F0}', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 10),
          const Text('PAINTER\'S GUILD', style: TextStyle(color: Color(0xFFE8734A), fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1)),
          const SizedBox(height: 6),
          Text('Team up with other painters for bonus rewards!', style: TextStyle(color: const Color(0xFF6B5038).withOpacity(0.6), fontSize: 12), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          // Guild perks preview
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              _PerkChip('\u{1F4B0}', '+2% Cash/Lv'),
              _PerkChip('\u{1F3C6}', 'Guild Leaderboard'),
              _PerkChip('\u{1F381}', 'Weekly Rewards'),
              _PerkChip('\u{1F91D}', 'Trade Bonus'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showCreateDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8734A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('CREATE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showJoinDialog(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE8734A),
                    side: const BorderSide(color: Color(0xFFE8734A)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('JOIN', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final tagCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFF5E8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Create Guild', style: TextStyle(color: Color(0xFF6B5038), fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Color(0xFF6B5038)),
              decoration: InputDecoration(
                labelText: 'Guild Name',
                labelStyle: TextStyle(color: const Color(0xFF6B5038).withOpacity(0.5)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: tagCtrl,
              maxLength: 4,
              style: const TextStyle(color: Color(0xFF6B5038)),
              decoration: InputDecoration(
                labelText: 'Tag (3-4 chars)',
                labelStyle: TextStyle(color: const Color(0xFF6B5038).withOpacity(0.5)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 6),
            Row(children: [
              Image.asset('assets/images/UI/diamond250.png', width: 16, height: 16),
              const SizedBox(width: 4),
              Text('Cost: 500 gems', style: TextStyle(color: const Color(0xFFA855F7).withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B5038)))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Guild creation coming soon!'), backgroundColor: Color(0xFFE8734A)),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE8734A), foregroundColor: Colors.white),
            child: const Text('Create', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showJoinDialog(BuildContext context) {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFF5E8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Join Guild', style: TextStyle(color: Color(0xFF6B5038), fontWeight: FontWeight.w800)),
        content: TextField(
          controller: codeCtrl,
          style: const TextStyle(color: Color(0xFF6B5038)),
          decoration: InputDecoration(
            labelText: 'Invite Code',
            labelStyle: TextStyle(color: const Color(0xFF6B5038).withOpacity(0.5)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B5038)))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Guild joining coming soon!'), backgroundColor: Color(0xFFE8734A)),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE8734A), foregroundColor: Colors.white),
            child: const Text('Join', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _PerkChip extends StatelessWidget {
  final String emoji;
  final String label;
  const _PerkChip(this.emoji, this.label);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF6B5038).withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: const Color(0xFF6B5038).withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _GuildLeaderboard extends StatelessWidget {
  // Mock top guilds
  static const _mockGuilds = [
    ('Paint Lords', 'PLRD', 15, 48200),
    ('Roller Mafia', 'RMAF', 12, 35600),
    ('Color Crew', 'CREW', 10, 28400),
    ('Wall Street', 'WALL', 8, 22100),
    ('Brush Rush', 'RUSH', 7, 18900),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TOP GUILDS', style: TextStyle(color: const Color(0xFF6B5038).withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
        const SizedBox(height: 8),
        ..._mockGuilds.asMap().entries.map((e) {
          final i = e.key;
          final g = e.value;
          final medals = ['\u{1F947}', '\u{1F948}', '\u{1F949}'];
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: i == 0 ? const Color(0xFFF5C842).withOpacity(0.08) : const Color(0xFF6B5038).withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                SizedBox(width: 28, child: Text(i < 3 ? medals[i] : '${i + 1}.', style: TextStyle(fontSize: i < 3 ? 16 : 13, color: const Color(0xFF6B5038).withOpacity(0.7)))),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(color: const Color(0xFFE8734A).withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                  child: Text('[${g.$2}]', style: const TextStyle(color: Color(0xFFE8734A), fontSize: 10, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 6),
                Expanded(child: Text(g.$1, style: const TextStyle(color: Color(0xFF6B5038), fontSize: 13, fontWeight: FontWeight.w600))),
                Text('${g.$3} members', style: TextStyle(color: const Color(0xFF6B5038).withOpacity(0.4), fontSize: 10)),
                const SizedBox(width: 8),
                Text('${(g.$4 / 1000).toStringAsFixed(1)}K XP', style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// =============================================================================
// MINIGAMES TAB
// =============================================================================
class _MinigamesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _MinigameCard(
            title: 'Speed Paint',
            emoji: '\u{26A1}',
            description: 'Paint as many walls as you can in 60 seconds!',
            reward: '+\$500 Cash',
            color: const Color(0xFFE8734A),
            cooldown: 'Ready',
            onPlay: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpeedPaintMinigame())),
          ),
          const SizedBox(height: 10),
          _MinigameCard(
            title: 'Bullseye',
            emoji: '\u{1F3AF}',
            description: 'Hit exactly the target coverage percentage.',
            reward: '+2 Gems',
            color: const Color(0xFF3B82F6),
            cooldown: 'Ready',
            onPlay: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BullseyeMinigame())),
          ),
          const SizedBox(height: 10),
          _MinigameCard(
            title: 'Color Match',
            emoji: '\u{1F308}',
            description: 'Match paint colors in order from memory.',
            reward: 'Rare Item',
            color: const Color(0xFFA855F7),
            cooldown: 'Ready',
            onPlay: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ColorMatchMinigame())),
          ),
          const SizedBox(height: 10),
          _MinigameCard(
            title: 'Guild Relay',
            emoji: '\u{1F3C3}',
            description: 'Each guild member paints one stripe. Best total wins!',
            reward: 'Guild XP',
            color: const Color(0xFF4ADE80),
            cooldown: 'Needs Guild',
            onPlay: null,
          ),
          const SizedBox(height: 14),
          // Minigame leaderboard
          _MinigameLeaderboard(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  static void _showMinigameDialog(BuildContext context, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFF5E8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(name, style: const TextStyle(color: Color(0xFF6B5038), fontWeight: FontWeight.w800)),
        content: Text('Minigame "$name" coming soon! Stay tuned for competitive challenges.',
            style: TextStyle(color: const Color(0xFF6B5038).withOpacity(0.7))),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE8734A), foregroundColor: Colors.white),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _MinigameCard extends StatelessWidget {
  final String title;
  final String emoji;
  final String description;
  final String reward;
  final Color color;
  final String cooldown;
  final VoidCallback? onPlay;

  const _MinigameCard({
    required this.title,
    required this.emoji,
    required this.description,
    required this.reward,
    required this.color,
    required this.cooldown,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(reward, style: TextStyle(color: color.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: 3),
                Text(description, style: TextStyle(color: const Color(0xFF6B5038).withOpacity(0.55), fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onPlay,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: onPlay != null ? color : const Color(0xFF6B5038).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                onPlay != null ? 'PLAY' : cooldown,
                style: TextStyle(
                  color: onPlay != null ? Colors.white : const Color(0xFF6B5038).withOpacity(0.4),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MinigameLeaderboard extends StatelessWidget {
  static const _mockEntries = [
    ('SpeedKing', 'Speed Paint', '42 walls', '\u{26A1}'),
    ('BullseyePro', 'Bullseye', '99.8%', '\u{1F3AF}'),
    ('MemoryMstr', 'Color Match', 'Lv.12', '\u{1F308}'),
    ('PaintLord', 'Speed Paint', '38 walls', '\u{26A1}'),
    ('Sniper99', 'Bullseye', '99.5%', '\u{1F3AF}'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('MINIGAME RECORDS', style: TextStyle(color: const Color(0xFF6B5038).withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
        const SizedBox(height: 8),
        ..._mockEntries.asMap().entries.map((e) {
          final i = e.key;
          final r = e.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF6B5038).withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text('${i + 1}.', style: TextStyle(color: const Color(0xFF6B5038).withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Expanded(child: Text(r.$1, style: const TextStyle(color: Color(0xFF6B5038), fontSize: 12, fontWeight: FontWeight.w600))),
                Text(r.$4, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(r.$2, style: TextStyle(color: const Color(0xFF6B5038).withOpacity(0.4), fontSize: 10)),
                const SizedBox(width: 8),
                Text(r.$3, style: const TextStyle(color: Color(0xFFE8734A), fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
          );
        }),
      ],
    );
  }
}
