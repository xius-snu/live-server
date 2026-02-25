import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/game_service.dart';
import '../models/house.dart';

class UpgradesScreen extends StatelessWidget {
  const UpgradesScreen({super.key});

  static String _formatWithCommas(double value) {
    final whole = value.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) buf.write(',');
      buf.write(whole[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8D5B8),
      body: Consumer<GameService>(
        builder: (context, gameService, _) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Upgrades',
                              style: TextStyle(
                                color: Color(0xFF6B5038),
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Spacer(),
                            // Coin balance
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFF111111), width: 1.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/images/UI/coin250.png',
                                    width: 18,
                                    height: 18,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _formatWithCommas(gameService.cash),
                                    style: const TextStyle(
                                      color: Color(0xFFF5C842),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Gem balance
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFF111111), width: 1.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/images/UI/diamond250.png',
                                    width: 18,
                                    height: 18,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _formatWithCommas(gameService.gems.toDouble()),
                                    style: const TextStyle(
                                      color: Color(0xFFDA70D6),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
              // House Level + Roller Level cards
              SliverToBoxAdapter(
                child: _ProgressionCards(gameService: gameService),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }
}

class _ProgressionCards extends StatelessWidget {
  final GameService gameService;
  const _ProgressionCards({required this.gameService});

  @override
  Widget build(BuildContext context) {
    final progress = gameService.progress;
    final houseCost = progress.houseUpgradeCost;
    final rollerCost = progress.rollerUpgradeCost;
    final canAffordHouse = gameService.canAffordHouseUpgrade;
    final canAffordRoller = gameService.canAffordRollerUpgrade;
    final houseBlocked = gameService.houseLevelBlocked;
    final rollerBlocked = gameService.rollerLevelBlocked;
    // Current house info
    final currentHouseDef = gameService.currentHouseDef;
    final currentCycleLevel = HouseDefinition.cycleLevelFor(progress.houseLevel);
    final currentWallArea = HouseDefinition.wallAreaDisplay(progress.houseLevel);

    // Next house info
    final nextHouseLevel = progress.houseLevel + 1;
    final nextHouseDef = HouseDefinition.getForHouseLevel(nextHouseLevel);
    final nextCycleLevel = HouseDefinition.cycleLevelFor(nextHouseLevel);
    final nextWallArea = HouseDefinition.wallAreaDisplay(nextHouseLevel);

    // Current roller info
    final currentRollerWidth = HouseDefinition.rollerWidthDisplay(
      progress.rollerLevel, progress.houseLevel,
    );
    final nextRollerWidth = HouseDefinition.rollerWidthDisplay(
      progress.rollerLevel + 1, progress.houseLevel,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // House Level card
          _ProgressionCard(
            title: 'HOUSE LEVEL',
            icon: currentHouseDef.icon,
            level: progress.houseLevel,
            currentName: '${currentHouseDef.name} ${HouseDefinition.toRoman(currentCycleLevel)}',
            currentSize: currentWallArea,
            nextName: '${nextHouseDef.name} ${HouseDefinition.toRoman(nextCycleLevel)}',
            nextSize: nextWallArea,
            cost: houseCost,
            canAfford: canAffordHouse,
            isBlocked: houseBlocked,
            blockedMessage: 'Roller too far behind (max ${HouseDefinition.maxLevelDiff} lvl diff)',
            onUpgrade: () {
              HapticFeedback.heavyImpact();
              gameService.upgradeHouse();
            },
            accentColor: const Color(0xFFF5C842),
          ),
          const SizedBox(height: 12),
          // Roller Level card
          _ProgressionCard(
            title: 'ROLLER SIZE',
            icon: '\u{1F58C}\u{FE0F}',
            level: progress.rollerLevel,
            currentName: '',
            currentSize: currentRollerWidth,
            nextName: '',
            nextSize: nextRollerWidth,
            cost: rollerCost,
            canAfford: canAffordRoller,
            isBlocked: rollerBlocked,
            blockedMessage: 'House too far behind (max ${HouseDefinition.maxLevelDiff} lvl diff)',
            onUpgrade: () {
              HapticFeedback.heavyImpact();
              gameService.upgradeRoller();
            },
            accentColor: const Color(0xFF3B82F6),
          ),
        ],
      ),
    );
  }
}

class _ProgressionCard extends StatelessWidget {
  final String title;
  final String icon;
  final int level;
  final String currentName; // e.g. "Townhouse II" or empty for roller
  final String currentSize; // e.g. "46m²" or "0.8m"
  final String nextName;
  final String nextSize;
  final double cost;
  final bool canAfford;
  final bool isBlocked;
  final String blockedMessage;
  final VoidCallback onUpgrade;
  final Color accentColor;

  const _ProgressionCard({
    required this.title,
    required this.icon,
    required this.level,
    required this.currentName,
    required this.currentSize,
    required this.nextName,
    required this.nextSize,
    required this.cost,
    required this.canAfford,
    required this.isBlocked,
    required this.blockedMessage,
    required this.onUpgrade,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isHouse = currentName.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF5A4230),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.35)),
      ),
      child: Column(
        children: [
          // Title row with level and size
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + Level
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Lv. $level',
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // House name (if house) + size
                    if (isHouse)
                      Row(
                        children: [
                          Text(
                            currentName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              currentSize,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        currentSize,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Next level preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.arrow_upward_rounded, size: 16, color: accentColor.withOpacity(0.7)),
                const SizedBox(width: 8),
                Text(
                  'Next:',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 6),
                if (isHouse && nextName.isNotEmpty) ...[
                  Text(
                    nextName,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  nextSize,
                  style: TextStyle(
                    color: accentColor.withOpacity(0.8),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Text(
                  'Lv. ${level + 1}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Blocked warning
          if (isBlocked)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.lock_outline, size: 14, color: Colors.red.shade300),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      blockedMessage,
                      style: TextStyle(
                        color: Colors.red.shade300,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Upgrade button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canAfford ? onUpgrade : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.black,
                disabledBackgroundColor: accentColor.withOpacity(0.20),
                disabledForegroundColor: Colors.white38,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/UI/coin250.png',
                    width: 20,
                    height: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatCost(cost),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCost(double cost) {
    final whole = cost.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) buf.write(',');
      buf.write(whole[i]);
    }
    return buf.toString();
  }
}
