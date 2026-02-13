import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/game_service.dart';
import '../models/upgrade.dart';
import '../models/house.dart';

class UpgradesScreen extends StatelessWidget {
  const UpgradesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
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
                        const Text(
                          'Upgrades',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Star multiplier: ${gameService.progress.starMultiplier.toStringAsFixed(1)}x  •  Wall scale: ${gameService.progress.wallScale.toStringAsFixed(1)}x',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index < UpgradeDefinition.all.length) {
                        final def = UpgradeDefinition.all[index];
                        return _UpgradeTile(
                          definition: def,
                          gameService: gameService,
                        );
                      }
                      return null;
                    },
                    childCount: UpgradeDefinition.all.length,
                  ),
                ),
              ),
              // Prestige section
              if (gameService.canPrestige)
                SliverToBoxAdapter(
                  child: _PrestigeCard(gameService: gameService),
                ),
              // House progress
              SliverToBoxAdapter(
                child: _HouseProgress(gameService: gameService),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }
}

class _UpgradeTile extends StatelessWidget {
  final UpgradeDefinition definition;
  final GameService gameService;

  const _UpgradeTile({required this.definition, required this.gameService});

  @override
  Widget build(BuildContext context) {
    final level = gameService.progress.getUpgradeLevel(definition.type);
    final isMaxed = definition.isMaxed(level);
    final cost = isMaxed ? 0.0 : definition.costForLevel(level);
    final canAfford = gameService.canAffordUpgrade(definition.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMaxed
              ? const Color(0xFFF5C842).withOpacity(0.3)
              : const Color(0xFF2A3A5E),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(definition.icon, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      definition.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      definition.isUncapped ? 'Lv.$level' : 'Lv.$level/${definition.maxLevel}',
                      style: TextStyle(
                        color: isMaxed
                            ? const Color(0xFFF5C842)
                            : Colors.white.withOpacity(0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Progress bar (for capped upgrades only)
                if (!definition.isUncapped)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: level / definition.maxLevel,
                      backgroundColor: const Color(0xFF2A3A5E),
                      valueColor: AlwaysStoppedAnimation(
                        isMaxed
                            ? const Color(0xFFF5C842)
                            : const Color(0xFF3B82F6),
                      ),
                      minHeight: 4,
                    ),
                  ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isMaxed ? 'MAXED' : 'Next: ${definition.effectPerLevel}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 11,
                      ),
                    ),
                    if (level > 0)
                      Text(
                        'Total: ${definition.cumulativeEffect(level)}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.35),
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Buy button
          GestureDetector(
            onTap: canAfford
                ? () {
                    HapticFeedback.mediumImpact();
                    gameService.purchaseUpgrade(definition.type);
                  }
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMaxed
                    ? const Color(0xFFF5C842).withOpacity(0.15)
                    : canAfford
                        ? const Color(0xFF4ADE80)
                        : const Color(0xFF2A3A5E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isMaxed ? 'MAX' : '\$${_formatCost(cost)}',
                style: TextStyle(
                  color: isMaxed
                      ? const Color(0xFFF5C842)
                      : canAfford
                          ? Colors.black
                          : Colors.white.withOpacity(0.3),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCost(double cost) {
    if (cost >= 1000000) return '${(cost / 1000000).toStringAsFixed(1)}M';
    if (cost >= 1000) return '${(cost / 1000).toStringAsFixed(1)}K';
    return cost.toStringAsFixed(0);
  }
}

class _PrestigeCard extends StatelessWidget {
  final GameService gameService;
  const _PrestigeCard({required this.gameService});

  @override
  Widget build(BuildContext context) {
    final nextPrestige = gameService.prestigeLevel + 1;
    final nextScale = HouseDefinition.wallScaleForPrestige(nextPrestige);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFF5C842).withOpacity(0.12),
              const Color(0xFFE94560).withOpacity(0.12),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF5C842).withOpacity(0.3)),
        ),
        child: Column(
          children: [
            const Text(
              'PRESTIGE AVAILABLE',
              style: TextStyle(
                color: Color(0xFFF5C842),
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Earn 1 star (+10% cash) • Next house: ${nextScale.toStringAsFixed(1)}x walls',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  gameService.prestige();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5C842),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'NEXT HOUSE',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HouseProgress extends StatelessWidget {
  final GameService gameService;
  const _HouseProgress({required this.gameService});

  @override
  Widget build(BuildContext context) {
    final prestige = gameService.prestigeLevel;
    final currentDef = gameService.currentHouseDef;
    final currentName = currentDef.name;
    final wallScale = HouseDefinition.wallScaleForPrestige(prestige);
    final roomProgress = '${gameService.currentRoom + 1}/${currentDef.rooms.length}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROGRESSION',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A3A5E)),
            ),
            child: Row(
              children: [
                Text(currentDef.icon, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Room $roomProgress  •  Wall scale ${wallScale.toStringAsFixed(2)}x  •  Prestige $prestige',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
