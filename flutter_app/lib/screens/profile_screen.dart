import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/user_service.dart';
import '../services/game_service.dart';
import '../models/house.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserService>(context, listen: false);
    _nameController.text = user.username ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveUsername() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);

    final user = Provider.of<UserService>(context, listen: false);
    final success = await user.setUsername(_nameController.text.trim());

    setState(() {
      _isSaving = false;
      _isEditing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Username updated!' : 'Failed to update'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Consumer2<UserService, GameService>(
        builder: (context, userService, gameService, _) {
          final house = HouseDefinition.getByType(gameService.currentHouse);

          return SingleChildScrollView(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Profile avatar
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF3B82F6).withOpacity(0.3),
                            const Color(0xFFA855F7).withOpacity(0.3),
                          ],
                        ),
                        border: Border.all(
                          color: const Color(0xFF3B82F6).withOpacity(0.5),
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '🎨',
                          style: const TextStyle(fontSize: 42),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Username
                    if (_isEditing)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 200,
                            child: TextField(
                              controller: _nameController,
                              autofocus: true,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                border: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                ),
                              ),
                              onSubmitted: (_) => _saveUsername(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.check, color: Color(0xFF4ADE80)),
                                  onPressed: _saveUsername,
                                ),
                        ],
                      )
                    else
                      GestureDetector(
                        onTap: () => setState(() => _isEditing = true),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              userService.username ?? 'Set Username',
                              style: TextStyle(
                                color: userService.username != null ? Colors.white : Colors.white38,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.edit, color: Colors.white.withOpacity(0.3), size: 18),
                          ],
                        ),
                      ),

                    const SizedBox(height: 8),

                    // Friend code
                    if (userService.friendCode != null)
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: userService.friendCode!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Friend code copied!'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Friend Code: ${userService.friendCode}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 12,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.copy, size: 14, color: Colors.white.withOpacity(0.3)),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 32),

                    // Stats
                    _buildStatsSection(gameService, house),
                    const SizedBox(height: 24),

                    // Progression
                    _buildProgressionSection(gameService),
                    const SizedBox(height: 24),

                    // Debug reset
                    TextButton(
                      onPressed: () => _showResetDialog(gameService),
                      child: Text(
                        'Reset All Progress',
                        style: TextStyle(color: Colors.redAccent.withOpacity(0.5), fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsSection(GameService gameService, HouseDefinition house) {
    final stats = [
      ('Stars', '⭐ ${gameService.stars}', const Color(0xFFF5C842)),
      ('Prestige', 'Lv.${gameService.prestigeLevel}', const Color(0xFFA855F7)),
      ('House', '${house.icon} ${house.name}', const Color(0xFF3B82F6)),
      ('Room', '${gameService.currentRoom + 1}/5', Colors.white54),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STATS',
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.5,
          children: stats.map((s) {
            final (label, value, color) = s;
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A3A5E)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11),
                  ),
                  Text(
                    value,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildProgressionSection(GameService gameService) {
    final progress = gameService.progress;
    final stats = [
      ('Walls Painted', '${progress.totalWallsPainted}'),
      ('Total Cash Earned', '\$${_formatNumber(progress.totalCashEarned)}'),
      ('Idle Income', '\$${progress.idleIncomePerSecond.toStringAsFixed(0)}/sec'),
      ('Marketplace Fee', '${progress.marketplaceFeePercent.toStringAsFixed(0)}%'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LIFETIME',
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        ...stats.map((s) {
          final (label, value) = s;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
                Text(value, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _formatNumber(double n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
  }

  void _showResetDialog(GameService gameService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Reset All Progress?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will delete ALL progress including stars, prestige, and upgrades. Cannot be undone!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              gameService.resetAll();
              Navigator.pop(context);
            },
            child: const Text('Reset', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
