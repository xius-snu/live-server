import 'dart:async';
import 'package:flutter/material.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  int _attemptsUsed = 0;
  Timer? _countdownTimer;
  int _secondsRemaining = 18 * 60 + 42; // Placeholder countdown

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SingleChildScrollView(
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
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),

                // Event banner
                _buildEventBanner(),
                const SizedBox(height: 24),

                // Drop table
                _buildDropTable(),
                const SizedBox(height: 16),

                // Attempts
                _buildAttempts(),
                const SizedBox(height: 12),

                // Market impact note
                _buildMarketNote(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFA855F7), Color(0xFFE94560)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Column(
            children: [
              const Text('🎨✨', style: TextStyle(fontSize: 36)),
              const SizedBox(height: 10),
              const Text(
                'NEON NIGHTS DROP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Paint the neon wall for exclusive drops!',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),

              // Countdown
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCountdownUnit(_secondsRemaining ~/ 3600, 'HR'),
                  const SizedBox(width: 12),
                  _buildCountdownUnit((_secondsRemaining % 3600) ~/ 60, 'MIN'),
                  const SizedBox(width: 12),
                  _buildCountdownUnit(_secondsRemaining % 60, 'SEC'),
                ],
              ),
              const SizedBox(height: 20),

              // Enter button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _attemptsUsed < 3
                      ? () {
                          setState(() => _attemptsUsed++);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Event gameplay coming soon!'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFE94560),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _attemptsUsed >= 3 ? 'NO ATTEMPTS LEFT' : 'ENTER EVENT',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownUnit(int value, String label) {
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDropTable() {
    final drops = [
      ('Speed Boost', 'Common', '60%', Colors.grey),
      ('Neon Paint', 'Rare', '25%', const Color(0xFF3B82F6)),
      ('Money Roller Skin', 'Epic', '10%', const Color(0xFFA855F7)),
      ('Diamond Roller Skin', 'Legendary', '5%', const Color(0xFFF59E0B)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DROP TABLE',
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        ...drops.map((d) {
          final (name, rarity, rate, color) = d;
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2A3A5E)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    rarity,
                    style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 40,
                  child: Text(
                    rate,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAttempts() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A3A5E)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Attempts',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  '3 attempts per event',
                  style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11),
                ),
              ],
            ),
          ),
          Row(
            children: List.generate(3, (i) {
              final isUsed = i < _attemptsUsed;
              return Container(
                width: 30,
                height: 30,
                margin: const EdgeInsets.only(left: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isUsed
                      ? const Color(0xFF2A3A5E)
                      : const Color(0xFFE94560).withOpacity(0.2),
                  border: Border.all(
                    color: isUsed ? Colors.white24 : const Color(0xFFE94560),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isUsed
                      ? const Icon(Icons.check, color: Colors.white38, size: 14)
                      : Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: Color(0xFFE94560),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketNote() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5C842).withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF5C842).withOpacity(0.15)),
      ),
      child: Row(
        children: [
          const Text('📊', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Event items are entering the market — expect index prices to dip during the event then rise after.',
              style: TextStyle(
                color: const Color(0xFFF5C842).withOpacity(0.7),
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
