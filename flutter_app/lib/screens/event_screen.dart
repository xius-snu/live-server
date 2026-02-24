import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/event_service.dart';
import '../services/marketplace_service.dart';
import '../services/leaderboard_service.dart';
import '../services/user_service.dart';
import '../models/marketplace_item.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final es = Provider.of<EventService>(context, listen: false);
      es.fetchEvents();
      es.startAutoRefresh();
      // Init leaderboard
      final lb = Provider.of<LeaderboardService>(context, listen: false);
      lb.checkStatus();
      lb.fetchLeaderboard();
    });
    // Tick UI countdown every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8D5B8),
      body: Consumer<EventService>(
        builder: (context, es, _) {
          if (es.loading && es.events.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE8734A)),
            );
          }

          final active = es.activeEvents;

          return RefreshIndicator(
            onRefresh: () => es.fetchEvents(),
            color: const Color(0xFFE8734A),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        'Events',
                        style: TextStyle(
                          color: Color(0xFF6B5038),
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (active.isNotEmpty)
                        ...active.map((event) => Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: _LiveEventCard(event: event),
                            ))
                      else ...[
                        _NoEventsCard(),
                        const SizedBox(height: 20),
                      ],

                      // Daily lottery section (client-side, always available)
                      _DailyLotteryCard(),
                      const SizedBox(height: 20),

                      // Weekly Leaderboard
                      _LeaderboardCard(),
                      const SizedBox(height: 16),

                      // Market impact note
                      _MarketNote(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// LIVE EVENT CARD — connected to backend
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFA855F7), Color(0xFFE8734A)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Live badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 50),
              const Text('\u{1F3A8}\u{2728}', style: TextStyle(fontSize: 36)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  const Text('LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            event.name.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            event.description,
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Countdown
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CountdownUnit(value: remaining.inHours, label: 'HR'),
              const SizedBox(width: 12),
              _CountdownUnit(value: remaining.inMinutes % 60, label: 'MIN'),
              const SizedBox(width: 12),
              _CountdownUnit(value: remaining.inSeconds % 60, label: 'SEC'),
            ],
          ),
          const SizedBox(height: 20),

          // Drop table
          ...event.dropTable.entries.map((e) {
            final rarity = e.key;
            final rate = (e.value * 100).toStringAsFixed(0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: _rarityColor(rarity), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${rarity[0].toUpperCase()}${rarity.substring(1)}',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  Text('$rate%', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),

          // Attempts
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(event.maxAttempts, (i) {
              final used = i >= attemptsLeft;
              return Container(
                width: 30, height: 30,
                margin: const EdgeInsets.only(left: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: used ? const Color(0xFFD5C4A8) : const Color(0xFFE8734A).withOpacity(0.2),
                  border: Border.all(color: used ? Colors.white24 : const Color(0xFFE8734A), width: 2),
                ),
                child: Center(
                  child: used
                      ? const Icon(Icons.check, color: Colors.white38, size: 14)
                      : Text('${i + 1}', style: const TextStyle(color: Color(0xFFE8734A), fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Enter button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: attemptsLeft > 0
                  ? () => _attemptEvent(context, event)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFE8734A),
                disabledBackgroundColor: Colors.white.withOpacity(0.3),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                attemptsLeft <= 0 ? 'NO ATTEMPTS LEFT' : 'ENTER EVENT',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
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

    // Use average coverage as the coverage percent for the attempt
    // In a real flow you'd play a special event round first
    final (reward, err) = await es.attemptEvent(event.eventId, 0.85);

    if (!context.mounted) return;

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.red),
      );
      return;
    }

    if (reward != null) {
      // Refresh inventory
      final mp = Provider.of<MarketplaceService>(context, listen: false);
      mp.fetchInventory();

      _showRewardDialog(context, reward);
    }
  }

  void _showRewardDialog(BuildContext context, EventReward reward) {
    final itemType = reward.itemType;
    final name = itemType?.name ?? reward.itemTypeId;
    final rc = _rarityColor(reward.rarity);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF6B5038),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Item Drop!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: rc.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: rc.withOpacity(0.5), width: 3),
              ),
              child: Center(child: Text(_rarityIcon(reward.rarity), style: const TextStyle(fontSize: 36))),
            ),
            const SizedBox(height: 16),
            Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: rc.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
              child: Text(reward.rarity.toUpperCase(), style: TextStyle(color: rc, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            const SizedBox(height: 8),
            Text('${reward.attemptsRemaining} attempts remaining',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: rc,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Nice!', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  static Color _rarityColor(String rarity) {
    switch (rarity) {
      case 'common': return Colors.grey;
      case 'uncommon': return const Color(0xFF4ADE80);
      case 'rare': return const Color(0xFF3B82F6);
      case 'epic': return const Color(0xFFA855F7);
      case 'legendary': return const Color(0xFFF59E0B);
      default: return Colors.grey;
    }
  }

  static String _rarityIcon(String rarity) {
    switch (rarity) {
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
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, fontFamily: 'monospace'),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// =============================================================================
// NO EVENTS PLACEHOLDER
// =============================================================================

class _NoEventsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF6B5038).withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text('\u{23F3}', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text('No Live Events', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Check back soon for the next drop event!',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// =============================================================================
// DAILY LOTTERY — always available, client-side fun spin
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
    setState(() {
      _spinning = true;
      _result = null;
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      // Weighted random pick
      final roll = DateTime.now().millisecondsSinceEpoch % 100 / 100.0;
      double cumulative = 0;
      String prize = _prizes.first.$2;
      String icon = _prizes.first.$1;
      for (final p in _prizes) {
        cumulative += p.$3;
        if (roll < cumulative) {
          icon = p.$1;
          prize = p.$2;
          break;
        }
      }
      setState(() {
        _spinning = false;
        _result = '$icon $prize';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DAILY LOTTERY',
          style: TextStyle(
            color: const Color(0xFF6B5038).withOpacity(0.5),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFF5C842).withOpacity(0.15),
                const Color(0xFFE8734A).withOpacity(0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF5C842).withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text(
                _spinning ? '\u{1F3B0}' : (_result != null ? _result!.split(' ').first : '\u{1F3B2}'),
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 12),
              if (_result != null && !_spinning)
                Text(_result!, style: const TextStyle(color: Color(0xFFF5C842), fontWeight: FontWeight.w700, fontSize: 18))
              else if (_spinning)
                const Text('Spinning...', style: TextStyle(color: Color(0xFFE8734A), fontWeight: FontWeight.w600, fontSize: 14))
              else
                Text('Spin for a free daily reward!', style: TextStyle(color: const Color(0xFF6B5038).withOpacity(0.6), fontSize: 13)),
              const SizedBox(height: 16),
              // Prize table
              Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: _prizes.map((p) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B5038).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${p.$1} ${(p.$3 * 100).toStringAsFixed(0)}%',
                      style: TextStyle(color: const Color(0xFF6B5038).withOpacity(0.5), fontSize: 10),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _spinning ? null : _spin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5C842),
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: const Color(0xFFF5C842).withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    _spinning ? 'SPINNING...' : 'FREE SPIN',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// LEADERBOARD CARD — weekly competitive leaderboard (server-backed)
// =============================================================================

class _LeaderboardCard extends StatefulWidget {
  @override
  State<_LeaderboardCard> createState() => _LeaderboardCardState();
}

class _LeaderboardCardState extends State<_LeaderboardCard> {
  int _selectedTab = 0; // 0=coverage, 1=coins, 2=walls
  static const _tabLabels = ['Coverage', 'Coins', 'Walls'];

  @override
  Widget build(BuildContext context) {
    return Consumer<LeaderboardService>(
      builder: (context, lb, _) {
        final board = _selectedTab == 0
            ? lb.coverageBoard
            : _selectedTab == 1
                ? lb.coinsBoard
                : lb.wallsBoard;

        // Week date range display
        String weekDates = '';
        if (lb.startsAt != null && lb.endsAt != null) {
          weekDates =
              '${_fmtDate(lb.startsAt!)} - ${_fmtDate(lb.endsAt!.subtract(const Duration(days: 1)))}';
        }

        // Refresh info
        final updatedAgo = lb.lastUpdatedAgo;
        final nextIn = lb.nextRefreshIn;
        final updatedStr = updatedAgo < 60
            ? 'Updated just now'
            : 'Updated ${updatedAgo ~/ 60}m ago';
        final nextStr = 'Next update in ${nextIn ~/ 60}m';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "PAINTER'S CUP",
              style: TextStyle(
                color: const Color(0xFF6B5038).withOpacity(0.5),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF6B5038),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFF3B82F6).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  // Trophy + title
                  const Text('\u{1F3C6}', style: TextStyle(fontSize: 42)),
                  const SizedBox(height: 8),
                  const Text(
                    "PAINTER'S CUP",
                    style: TextStyle(
                      color: Color(0xFF3B82F6),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  if (weekDates.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      weekDates,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),

                  // Join / Participating button
                  if (!lb.joined)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: lb.joining ? null : () async {
                          final ok = await lb.joinWeek();
                          if (!ok && context.mounted && lb.lastError != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(lb.lastError!),
                                backgroundColor: Colors.red.shade700,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF5C842),
                          foregroundColor: Colors.black,
                          disabledBackgroundColor:
                              const Color(0xFFF5C842).withOpacity(0.3),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          lb.joining
                              ? 'JOINING...'
                              : 'JOIN LEADERBOARD',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4ADE80).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                const Color(0xFF4ADE80).withOpacity(0.4)),
                      ),
                      child: const Center(
                        child: Text(
                          '\u2705  PARTICIPATING',
                          style: TextStyle(
                            color: Color(0xFF4ADE80),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Info row: updated / next refresh
                  if (lb.joined)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.access_time,
                            size: 12,
                            color: Colors.white.withOpacity(0.35)),
                        const SizedBox(width: 4),
                        Text(
                          '$updatedStr  \u2022  $nextStr',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.35),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 14),

                  // Category tabs
                  Row(
                    children: List.generate(3, (i) {
                      final sel = i == _selectedTab;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = i),
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            margin: EdgeInsets.only(
                                left: i == 0 ? 0 : 4,
                                right: i == 2 ? 0 : 4),
                            decoration: BoxDecoration(
                              color: sel
                                  ? const Color(0xFF3B82F6)
                                  : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                _tabLabels[i],
                                style: TextStyle(
                                  color: sel
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.5),
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
                  const SizedBox(height: 12),

                  // Leaderboard list
                  if (lb.loading && board.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: CircularProgressIndicator(
                          color: Color(0xFF3B82F6), strokeWidth: 2),
                    )
                  else if (board.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        lb.joined
                            ? 'No entries yet. Paint some walls!'
                            : 'Join to see the leaderboard',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 13,
                        ),
                      ),
                    )
                  else
                    ...board.take(20).map((entry) {
                      final isMe = lb.playerStats != null &&
                          entry.userId.isNotEmpty &&
                          _isCurrentUser(context, entry.userId);
                      return _LeaderboardRow(
                        rank: entry.rank,
                        username: entry.username,
                        value: _formatValue(entry.value, _selectedTab),
                        isMe: isMe,
                        tab: _selectedTab,
                      );
                    }),

                  // Player's own rank if outside top 20
                  if (lb.joined && lb.playerStats != null) ...[
                    Builder(builder: (_) {
                      final rank = _selectedTab == 0
                          ? lb.playerStats!.coverageRank
                          : _selectedTab == 1
                              ? lb.playerStats!.coinsRank
                              : lb.playerStats!.wallsRank;
                      final val = _selectedTab == 0
                          ? lb.playerStats!.weeklyCoverage
                          : _selectedTab == 1
                              ? lb.playerStats!.weeklyCoinsEarned
                              : lb.playerStats!.weeklyWallsPainted
                                  .toDouble();
                      if (rank <= 20 && board.length >= rank) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4),
                            child: Text('\u2022 \u2022 \u2022',
                                style: TextStyle(
                                    color:
                                        Colors.white.withOpacity(0.2))),
                          ),
                          _LeaderboardRow(
                            rank: rank,
                            username: 'You',
                            value:
                                _formatValue(val, _selectedTab),
                            isMe: true,
                            tab: _selectedTab,
                          ),
                        ],
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  bool _isCurrentUser(BuildContext context, String oderId) {
    try {
      final userService =
          Provider.of<UserService>(context, listen: false);
      return userService.userId == oderId;
    } catch (_) {
      return false;
    }
  }

  static String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  static String _formatValue(double value, int tab) {
    if (tab == 0) {
      // Coverage: show as percentage with 1 decimal
      return '${(value * 100).toStringAsFixed(1)}%';
    } else if (tab == 1) {
      // Coins: comma-formatted integer
      return _fmtCommas(value);
    } else {
      // Walls: integer
      return value.toInt().toString();
    }
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

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final String username;
  final String value;
  final bool isMe;
  final int tab;

  const _LeaderboardRow({
    required this.rank,
    required this.username,
    required this.value,
    required this.isMe,
    required this.tab,
  });

  @override
  Widget build(BuildContext context) {
    const medals = ['\u{1F947}', '\u{1F948}', '\u{1F949}'];
    final rankDisplay =
        rank <= 3 ? medals[rank - 1] : '$rank.';

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe
              ? const Color(0xFF3B82F6).withOpacity(0.18)
              : rank == 1
                  ? const Color(0xFFF5C842).withOpacity(0.1)
                  : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: isMe
              ? Border.all(
                  color: const Color(0xFF3B82F6).withOpacity(0.4))
              : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Text(
                rankDisplay,
                style: TextStyle(
                  fontSize: rank <= 3 ? 16 : 13,
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                username,
                style: TextStyle(
                  color: isMe ? const Color(0xFF3B82F6) : Colors.white,
                  fontSize: 13,
                  fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (tab == 1) ...[
              Image.asset(
                'assets/images/UI/coin250.png',
                width: 14,
                height: 14,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              value,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// MARKET NOTE
// =============================================================================

class _MarketNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5C842).withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF5C842).withOpacity(0.15)),
      ),
      child: Row(
        children: [
          const Text('\u{1F4CA}', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Event items enter the market during drops. Index prices may fluctuate. Tournament winners earn exclusive titles.',
              style: TextStyle(color: const Color(0xFFF5C842).withOpacity(0.7), fontSize: 11, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
