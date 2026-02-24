import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/user_service.dart';
import '../services/game_service.dart';
import '../services/marketplace_service.dart';
import '../models/house.dart';

/// Derive a player title from their stats. Different playstyles earn different titles.
String _playerTitle(GameService gs, int itemCount) {
  final p = gs.progress;
  final walls = p.totalWallsPainted;
  final avg = p.averageCoverage;
  final houseLevel = p.houseLevel;
  final streak = p.streak;
  final idle = p.idleIncomePerSecond;

  // Collector
  if (itemCount >= 10) return 'Collector';
  // Perfectionist: high average coverage
  if (walls >= 10 && avg >= 0.95) return 'Perfectionist';
  // Tycoon: high house level + idle income
  if (houseLevel >= 10 && idle >= 20) return 'Tycoon';
  // Streak Master
  if (streak >= 8) return 'Streak Master';
  // High-level grinder
  if (houseLevel >= 15) return 'Master Painter';
  // Coverage focused
  if (walls >= 20 && avg >= 0.85) return 'Precision Roller';
  // Speed runner: lots of walls, lower coverage
  if (walls >= 50 && avg < 0.7) return 'Speed Roller';
  // Active player
  if (walls >= 30) return 'Veteran Painter';
  // Idle focused
  if (idle >= 10) return 'Idle Mogul';
  // Mid-level
  if (houseLevel >= 5) return 'Journeyman';
  // Beginner milestones
  if (walls >= 10) return 'Apprentice';
  if (walls >= 1) return 'Newcomer';
  return 'Fresh Paint';
}

Color _titleColor(String title) {
  switch (title) {
    case 'Collector': return const Color(0xFFF59E0B);
    case 'Perfectionist': return const Color(0xFFA855F7);
    case 'Tycoon': return const Color(0xFF4ADE80);
    case 'Streak Master': return const Color(0xFFE8734A);
    case 'Master Painter': return const Color(0xFF3B82F6);
    case 'Precision Roller': return const Color(0xFF3B82F6);
    case 'Speed Roller': return const Color(0xFFE8734A);
    case 'Veteran Painter': return const Color(0xFFF5C842);
    case 'Idle Mogul': return const Color(0xFF4ADE80);
    case 'Journeyman': return const Color(0xFF4ADE80);
    case 'Apprentice': return Colors.white;
    case 'Newcomer': return Colors.white70;
    default: return Colors.white54;
  }
}

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
      backgroundColor: const Color(0xFFE8D5B8),
      body: Consumer3<UserService, GameService, MarketplaceService>(
        builder: (context, userService, gameService, mp, _) {
          final house = gameService.currentHouseDef;
          final itemCount = mp.inventory.length;
          final title = _playerTitle(gameService, itemCount);
          final tc = _titleColor(title);

          return SingleChildScrollView(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Avatar with house border
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            house.borderColor.withOpacity(0.3),
                            const Color(0xFFA855F7).withOpacity(0.3),
                          ],
                        ),
                        border: Border.all(
                          color: house.borderColor.withOpacity(0.6),
                          width: 3,
                        ),
                      ),
                      child: const Center(
                        child: Text('\u{1F3A8}', style: TextStyle(fontSize: 42)),
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
                              style: const TextStyle(color: Color(0xFF6B5038), fontSize: 22, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                isDense: true,
                                border: UnderlineInputBorder(borderSide: BorderSide(color: const Color(0xFF6B5038).withOpacity(0.3))),
                              ),
                              onSubmitted: (_) => _saveUsername(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _isSaving
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : IconButton(icon: const Icon(Icons.check, color: Color(0xFF4ADE80)), onPressed: _saveUsername),
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
                                color: userService.username != null ? const Color(0xFF6B5038) : const Color(0xFF6B5038).withOpacity(0.4),
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.edit, color: const Color(0xFF6B5038).withOpacity(0.3), size: 18),
                          ],
                        ),
                      ),

                    const SizedBox(height: 6),

                    // Player title badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: tc.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: tc.withOpacity(0.3)),
                      ),
                      child: Text(
                        title,
                        style: TextStyle(color: tc, fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.5),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Friend code
                    if (userService.friendCode != null)
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: userService.friendCode!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Friend code copied!'), duration: Duration(seconds: 1)),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B5038).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Friend Code: ${userService.friendCode}',
                                style: TextStyle(color: const Color(0xFF6B5038).withOpacity(0.5), fontSize: 12, letterSpacing: 1),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.copy, size: 14, color: const Color(0xFF6B5038).withOpacity(0.4)),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 32),

                    _buildStatsSection(gameService, house, itemCount),
                    const SizedBox(height: 24),
                    _buildProgressionSection(gameService),
                    const SizedBox(height: 24),

                    TextButton(
                      onPressed: () => _showResetDialog(gameService),
                      child: Text('Reset All Progress', style: TextStyle(color: Colors.redAccent.withOpacity(0.5), fontSize: 12)),
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

  Widget _buildStatsSection(GameService gameService, HouseDefinition house, int itemCount) {
    final progress = gameService.progress;
    final stats = [
      ('Gems', '\u{1F48E} ${gameService.gems}', const Color(0xFFA855F7)),
      ('House', '${house.icon} ${progress.houseDisplayName}', const Color(0xFF3B82F6)),
      ('Wall', HouseDefinition.wallAreaDisplay(progress.houseLevel), house.borderColor),
      ('Roller', 'Lv.${progress.rollerLevel} (${HouseDefinition.rollerWidthDisplay(progress.rollerLevel, progress.houseLevel)})', const Color(0xFF3B82F6)),
      ('Inventory', '$itemCount items', const Color(0xFFF5C842)),
      ('Streak', '\u{1F525} ${gameService.streak}', const Color(0xFFE8734A)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('STATS', style: TextStyle(color: const Color(0xFF6B5038).withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
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
                color: const Color(0xFF6B5038),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF8B6B4F)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                  Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
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
    final avgCoverage = progress.averageCoverage * 100;
    final stats = [
      ('Walls Painted', '${progress.totalWallsPainted}'),
      ('Avg. Coverage', '${avgCoverage.toStringAsFixed(1)}%'),
      ('Idle Income', '\$${progress.idleIncomePerSecond.toStringAsFixed(0)}/sec'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('LIFETIME', style: TextStyle(color: const Color(0xFF6B5038).withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
        const SizedBox(height: 12),
        ...stats.map((s) {
          final (label, value) = s;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: TextStyle(color: const Color(0xFF6B5038).withOpacity(0.5), fontSize: 13)),
                Text(value, style: const TextStyle(color: Color(0xFF6B5038), fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _showResetDialog(GameService gameService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF6B5038),
        title: const Text('Reset All Progress?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will delete ALL progress including gems, prestige, and upgrades. Cannot be undone!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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
