import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/game_config.dart';
import '../services/user_service.dart';
import '../services/game_service.dart';
import '../services/audio_service.dart';
import '../services/marketplace_service.dart';
import '../models/house.dart';
import '../models/marketplace_item.dart';
import '../theme/app_colors.dart';
import '../utils/format_utils.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this, initialIndex: 1);
    final user = Provider.of<UserService>(context, listen: false);
    _nameController.text = user.username ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _saveUsername() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    final user = Provider.of<UserService>(context, listen: false);
    final success = await user.setUsername(_nameController.text.trim());
    setState(() { _isSaving = false; _isEditing = false; });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Username updated!' : 'Failed to update'), duration: const Duration(seconds: 1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer3<UserService, GameService, MarketplaceService>(
        builder: (context, userService, gameService, mp, _) {
          final house = gameService.currentHouseDef;
          final itemCount = mp.inventory.length;

          return SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 14),
                // Centered profile icon + name
                _CenteredProfileHeader(
                  userService: userService,
                  gameService: gameService,
                  house: house,
                  isEditing: _isEditing,
                  isSaving: _isSaving,
                  nameController: _nameController,
                  onEditTap: () => setState(() => _isEditing = true),
                  onSave: _saveUsername,
                ),
                const SizedBox(height: 14),
                // Sub-tabs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.brownDark,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      labelColor: AppColors.brownDark,
                      unselectedLabelColor: AppColors.tabUnselected,
                      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                      unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      dividerColor: Colors.transparent,
                      isScrollable: false,
                      labelPadding: EdgeInsets.zero,
                      indicatorSize: TabBarIndicatorSize.tab,
                      splashFactory: NoSplash.splashFactory,
                      tabs: const [
                        Tab(height: 34, text: 'Stats'),
                        Tab(height: 34, text: 'Inventory'),
                        Tab(height: 34, text: 'Badges'),
                        Tab(height: 34, text: 'Friends'),
                        Tab(height: 34, text: 'Settings'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _StatsTab(gameService: gameService, house: house),
                      _InventoryTab(),
                      _BadgesTab(gameService: gameService, itemCount: itemCount),
                      _FriendsTab(),
                      _SettingsTab(gameService: gameService),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// CENTERED PROFILE HEADER
// =============================================================================
class _CenteredProfileHeader extends StatelessWidget {
  final UserService userService;
  final GameService gameService;
  final HouseDefinition house;
  final bool isEditing;
  final bool isSaving;
  final TextEditingController nameController;
  final VoidCallback onEditTap;
  final VoidCallback onSave;

  const _CenteredProfileHeader({
    required this.userService,
    required this.gameService,
    required this.house,
    required this.isEditing,
    required this.isSaving,
    required this.nameController,
    required this.onEditTap,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Large centered avatar
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.cardCream,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.brownDark, width: 3),
          ),
          child: const Center(
            child: Text('\u{1F3A8}', style: TextStyle(fontSize: 36)),
          ),
        ),
        const SizedBox(height: 10),
        // Username (centered)
        if (isEditing)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: nameController,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.brownDark, fontSize: 20, fontWeight: FontWeight.w800),
                    decoration: InputDecoration(
                      isDense: true,
                      border: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.brownLight)),
                    ),
                    onSubmitted: (_) => onSave(),
                  ),
                ),
                const SizedBox(width: 6),
                isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brownDark))
                    : IconButton(
                        icon: const Icon(Icons.check, color: AppColors.badgeGreen, size: 22),
                        onPressed: onSave,
                      ),
              ],
            ),
          )
        else
          GestureDetector(
            onTap: onEditTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  userService.username ?? 'Set Username',
                  style: TextStyle(
                    color: userService.username != null ? AppColors.brownDark : AppColors.brownLight,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.edit, color: AppColors.brownLight, size: 14),
              ],
            ),
          ),
        const SizedBox(height: 6),
        // Friend code
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (userService.friendCode != null) ...[
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: userService.friendCode!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Friend code copied!'), duration: Duration(seconds: 1)),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brownDark,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '#${userService.friendCode}',
                        style: const TextStyle(color: AppColors.tabUnselected, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.copy, size: 10, color: AppColors.tabUnselected),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// STATS TAB
// =============================================================================
class _StatsTab extends StatelessWidget {
  final GameService gameService;
  final HouseDefinition house;
  const _StatsTab({required this.gameService, required this.house});

  @override
  Widget build(BuildContext context) {
    final p = gameService.progress;
    final avgCov = p.averageCoverage * 100;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Currency cards
          Row(
            children: [
              Expanded(child: _StatCardWithIcon('assets/images/UI/coin250.png', 'Coins', fmtCommas(gameService.cash), AppColors.badgeGoldBrown)),
              const SizedBox(width: 8),
              Expanded(child: _StatCardWithIcon('assets/images/UI/diamond250.png', 'Gems', '${gameService.gems}', AppColors.badgePurple)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _StatCard(house.icon, 'House', p.houseDisplayName, AppColors.badgeBlue)),
              const SizedBox(width: 8),
              Expanded(child: _StatCard('\u{1F58C}\u{FE0F}', 'Roller', 'Lv.${p.rollerLevel}', AppColors.badgeGreen)),
            ],
          ),
          const SizedBox(height: 16),
          // Lifetime stats header
          const Text('LIFETIME STATS', style: TextStyle(color: AppColors.brownMid, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardCream,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderBrown, width: 1.5),
            ),
            child: Column(
              children: [
                _StatRow('Walls Painted', '${p.totalWallsPainted}'),
                _StatRow('Avg Coverage', '${avgCov.toStringAsFixed(1)}%'),
                _StatRow('Total Earned', '\$${fmtCommas(p.totalCashEarned)}'),
                _StatRow('Idle Income', '\$${p.idleIncomePerSecond.toStringAsFixed(0)}/sec'),
                _StatRow('Current Streak', '\u{1F525} ${p.streak}'),
                _StatRow('Rollers Owned', '${p.rollerInventory.length} variants', last: true),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color color;
  const _StatCard(this.emoji, this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardCream,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderBrown, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: AppColors.brownMid, fontSize: 11, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18)),
        ],
      ),
    );
  }
}

class _StatCardWithIcon extends StatelessWidget {
  final String asset;
  final String label;
  final String value;
  final Color color;
  const _StatCardWithIcon(this.asset, this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardCream,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderBrown, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Image.asset(asset, width: 18, height: 18),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: AppColors.brownMid, fontSize: 11, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18)),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final bool last;
  const _StatRow(this.label, this.value, {this.last = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.brownMid, fontSize: 13, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: AppColors.brownDark, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}

// =============================================================================
// INVENTORY TAB
// =============================================================================
class _InventoryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<MarketplaceService, GameService>(
      builder: (context, mp, gs, _) {
        final items = mp.inventory;
        final rollerItems = gs.rollerInventory.where((i) => i.count > 0).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Equipped roller
              const Text('EQUIPPED ROLLER', style: TextStyle(color: AppColors.brownMid, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2)),
              const SizedBox(height: 8),
              _EquippedRollerCard(gs: gs),
              const SizedBox(height: 16),

              // Roller inventory grid
              Text('ROLLER COLLECTION (${rollerItems.length})', style: const TextStyle(color: AppColors.brownMid, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2)),
              const SizedBox(height: 8),
              if (rollerItems.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('No rollers yet', style: TextStyle(color: AppColors.brownLight, fontSize: 12)),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: rollerItems.length,
                  itemBuilder: (context, index) {
                    final item = rollerItems[index];
                    final isEquipped = gs.equippedSkin == item.rollerId && gs.equippedColorId == item.colorId;
                    final tierColor = AppColors.colorForTier(item.colorTier);
                    final paintColor = Color(item.colorHex);
                    final skinDef = GameService.rollerSkinDefs.where((s) => s.id == item.rollerId).firstOrNull;

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        gs.equipRollerItem(item.rollerId, item.colorId);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isEquipped ? tierColor.withOpacity(0.12) : AppColors.cardCream,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isEquipped ? tierColor : tierColor.withOpacity(0.5),
                            width: isEquipped ? 2.5 : 1.5,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: skinDef != null
                                    ? Image.asset('assets/images/rollers/${skinDef.asset}', fit: BoxFit.contain)
                                    : Icon(Icons.brush, color: AppColors.brownLight),
                              ),
                            ),
                            Positioned(
                              right: 4, bottom: 4,
                              child: Container(
                                width: 12, height: 12,
                                decoration: BoxDecoration(
                                  color: paintColor,
                                  borderRadius: BorderRadius.circular(2),
                                  border: Border.all(color: AppColors.brownDark, width: 1),
                                ),
                              ),
                            ),
                            if (item.count > 1)
                              Positioned(
                                left: 3, top: 3,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.brownDark.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text('x${item.count}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                                ),
                              ),
                            if (isEquipped)
                              Positioned(
                                right: 3, top: 3,
                                child: Icon(Icons.check_circle, color: tierColor, size: 14),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              // Market items
              if (items.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('MARKET ITEMS (${items.length})', style: const TextStyle(color: AppColors.brownMid, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2)),
                const SizedBox(height: 8),
                ...items.map((item) => _InvItemRow(item: item)),
              ],
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }
}

class _EquippedRollerCard extends StatelessWidget {
  final GameService gs;
  const _EquippedRollerCard({required this.gs});

  @override
  Widget build(BuildContext context) {
    final skin = GameService.rollerSkinDefs.firstWhere((s) => s.id == gs.equippedSkin, orElse: () => GameService.rollerSkinDefs.first);
    final colorDef = getPaintColorById(gs.equippedColorId);
    final paintColor = gs.equippedPaintColor;
    final equippedItem = gs.rollerInventory.where(
      (i) => i.rollerId == gs.equippedSkin && i.colorId == gs.equippedColorId,
    ).firstOrNull;
    final tierColor = equippedItem != null ? AppColors.colorForTier(equippedItem.colorTier) : AppColors.rarityCommon;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardCream,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.brownDark, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderBrown, width: 1.5),
            ),
            child: Padding(padding: const EdgeInsets.all(6), child: Image.asset('assets/images/rollers/${skin.asset}', fit: BoxFit.contain)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(skin.name, style: const TextStyle(color: AppColors.brownDark, fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 4),
                Row(children: [
                  Container(width: 14, height: 14, decoration: BoxDecoration(color: paintColor, shape: BoxShape.circle, border: Border.all(color: AppColors.brownDark, width: 1))),
                  const SizedBox(width: 6),
                  Text(colorDef?.name ?? 'Paint Color', style: const TextStyle(color: AppColors.brownMid, fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 6),
                  if (equippedItem != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(color: tierColor.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                      child: Text(equippedItem.colorTier.name.toUpperCase(), style: TextStyle(color: tierColor, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InvItemRow extends StatelessWidget {
  final SerializedItem item;
  const _InvItemRow({required this.item});

  Color get _rc {
    switch (item.rarity) {
      case ItemRarity.common: return AppColors.brownMid;
      case ItemRarity.uncommon: return AppColors.badgeGreen;
      case ItemRarity.rare: return AppColors.badgeBlue;
      case ItemRarity.epic: return AppColors.badgePurple;
      case ItemRarity.legendary: return AppColors.badgeGoldBrown;
      case ItemRarity.mythic: return AppColors.rarityMythic;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = item.itemType?.name ?? item.itemTypeId;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardCream,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _rc, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: _rc,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(child: Text(_catIcon(item.itemType?.category), style: const TextStyle(fontSize: 14))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: const TextStyle(color: AppColors.brownDark, fontWeight: FontWeight.w700, fontSize: 12))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _rc,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(item.rarity.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
          ),
          if (item.isListed) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('LISTED', style: TextStyle(color: AppColors.brownDark, fontSize: 8, fontWeight: FontWeight.w800)),
            ),
          ],
        ],
      ),
    );
  }

  static String _catIcon(ItemCategory? cat) {
    switch (cat) {
      case ItemCategory.paint: return '\u{1F3A8}';
      case ItemCategory.rollerSkin: return '\u{1F31F}';
      case ItemCategory.consumable: return '\u{26A1}';
      case ItemCategory.collectible: return '\u{1F451}';
      case null: return '\u{1F4E6}';
    }
  }
}

// =============================================================================
// BADGES / ACHIEVEMENTS TAB
// =============================================================================
class _BadgesTab extends StatelessWidget {
  final GameService gameService;
  final int itemCount;
  const _BadgesTab({required this.gameService, required this.itemCount});

  @override
  Widget build(BuildContext context) {
    final p = gameService.progress;

    final badges = <_Badge>[
      _Badge('\u{1F3A8}', 'First Stroke', 'Paint your first wall', p.totalWallsPainted >= 1,
        current: p.totalWallsPainted.toDouble().clamp(0, 1), target: 1, progressLabel: '${p.totalWallsPainted.clamp(0, 1)} / 1 walls'),
      _Badge('\u{1F3AF}', 'Sharp Eye', 'Achieve 95%+ avg coverage (5+ walls)', p.averageCoverage >= 0.95 && p.totalWallsPainted >= 5,
        current: p.totalWallsPainted >= 5 ? (p.averageCoverage * 100).clamp(0, 100) : 0, target: 95, progressLabel: '${(p.averageCoverage * 100).toStringAsFixed(1)}% avg'),
      _Badge('\u{1F525}', 'On Fire', 'Reach a 5x streak', p.streak >= 5,
        current: p.streak.toDouble().clamp(0, 5), target: 5, progressLabel: '${p.streak} / 5 streak'),
      _Badge('\u{1F3E0}', 'Homeowner', 'Reach House Level 5', p.houseLevel >= 5,
        current: p.houseLevel.toDouble().clamp(0, 5), target: 5, progressLabel: 'Lv.${p.houseLevel} / 5'),
      _Badge('\u{1F3D7}\u{FE0F}', 'Builder', 'Reach House Level 10', p.houseLevel >= 10,
        current: p.houseLevel.toDouble().clamp(0, 10), target: 10, progressLabel: 'Lv.${p.houseLevel} / 10'),
      _Badge('\u{1F3F0}', 'Castle Lord', 'Reach House Level 20', p.houseLevel >= 20,
        current: p.houseLevel.toDouble().clamp(0, 20), target: 20, progressLabel: 'Lv.${p.houseLevel} / 20'),
      _Badge('\u{1F4B0}', 'First Thousand', 'Earn 1,000 coins total', p.totalCashEarned >= 1000,
        current: p.totalCashEarned.clamp(0, 1000), target: 1000, progressLabel: '${fmtCommas(p.totalCashEarned.clamp(0, 1000))} / 1K'),
      _Badge('\u{1F4B5}', 'Big Spender', 'Earn 100,000 coins total', p.totalCashEarned >= 100000,
        current: p.totalCashEarned.clamp(0, 100000), target: 100000, progressLabel: '${fmtCommas(p.totalCashEarned.clamp(0, 100000))} / 100K'),
      _Badge('\u{1F48E}', 'Gem Collector', 'Own 10+ gems', gameService.gems >= 10,
        current: gameService.gems.toDouble().clamp(0, 10), target: 10, progressLabel: '${gameService.gems.clamp(0, 10)} / 10 gems'),
      _Badge('\u{1F58C}\u{FE0F}', 'Fancy Roller', 'Own 3+ roller variants', p.rollerInventory.length >= 3,
        current: p.rollerInventory.length.toDouble().clamp(0, 3), target: 3, progressLabel: '${p.rollerInventory.length.clamp(0, 3)} / 3 rollers'),
      _Badge('\u{1F451}', 'Collector', 'Own 10+ market items', itemCount >= 10,
        current: itemCount.toDouble().clamp(0, 10), target: 10, progressLabel: '${itemCount.clamp(0, 10)} / 10 items'),
      _Badge('\u{1F3C6}', '100 Club', 'Paint 100 walls', p.totalWallsPainted >= 100,
        current: p.totalWallsPainted.toDouble().clamp(0, 100), target: 100, progressLabel: '${p.totalWallsPainted.clamp(0, 100)} / 100 walls'),
      _Badge('\u{1F30D}', 'Veteran', 'Paint 500 walls', p.totalWallsPainted >= 500,
        current: p.totalWallsPainted.toDouble().clamp(0, 500), target: 500, progressLabel: '${p.totalWallsPainted.clamp(0, 500)} / 500 walls'),
      _Badge('\u{1F680}', 'Millionaire', 'Earn 1,000,000 coins total', p.totalCashEarned >= 1000000,
        current: p.totalCashEarned.clamp(0, 1000000), target: 1000000, progressLabel: '${fmtCommas(p.totalCashEarned.clamp(0, 1000000))} / 1M'),
    ];

    final earned = badges.where((b) => b.earned).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Progress bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardCream,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderBrown, width: 1.5),
            ),
            child: Row(
              children: [
                Text('$earned / ${badges.length}', style: const TextStyle(color: AppColors.brownDark, fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: badges.isEmpty ? 0 : earned / badges.length,
                      minHeight: 10,
                      backgroundColor: AppColors.borderBrown,
                      valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Badge list
          ...badges.map((badge) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: badge.earned ? AppColors.debugGoldBg : AppColors.cardCream,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: badge.earned ? AppColors.gold : AppColors.borderBrown,
                width: badge.earned ? 2 : 1.5,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(badge.emoji, style: TextStyle(fontSize: 22, color: badge.earned ? null : AppColors.brownLight)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(badge.name, style: TextStyle(
                            color: badge.earned ? AppColors.brownDark : AppColors.brownLight,
                            fontWeight: FontWeight.w700, fontSize: 13,
                          )),
                          Text(badge.description, style: TextStyle(
                            color: badge.earned ? AppColors.brownMid : AppColors.brownLight,
                            fontSize: 11,
                          )),
                        ],
                      ),
                    ),
                    if (badge.earned)
                      const Text('\u2705', style: TextStyle(fontSize: 16))
                    else
                      const Icon(Icons.lock_outline, size: 16, color: AppColors.brownLight),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(width: 34),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: badge.progress,
                          minHeight: 6,
                          backgroundColor: badge.earned ? AppColors.gold.withOpacity(0.2) : AppColors.borderBrown,
                          valueColor: AlwaysStoppedAnimation(badge.earned ? AppColors.gold : AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(badge.progressLabel, style: TextStyle(
                      color: badge.earned ? AppColors.brownMid : AppColors.brownLight,
                      fontSize: 10, fontWeight: FontWeight.w600,
                    )),
                  ],
                ),
              ],
            ),
          )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _Badge {
  final String emoji;
  final String name;
  final String description;
  final bool earned;
  final double current;
  final double target;
  final String progressLabel;
  const _Badge(this.emoji, this.name, this.description, this.earned, {this.current = 0, this.target = 1, this.progressLabel = ''});

  double get progress => (current / target).clamp(0.0, 1.0);
}

// =============================================================================
// FRIENDS TAB
// =============================================================================
class _FriendsTab extends StatefulWidget {
  @override
  State<_FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<_FriendsTab> {
  List<Map<String, dynamic>> _friends = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    final us = Provider.of<UserService>(context, listen: false);
    final friends = await us.listFriends();
    if (mounted) setState(() { _friends = friends; _loading = false; });
  }

  void _showAddDialog() {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Add Friend', style: TextStyle(color: AppColors.brownDark, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your friend\'s code (shown on their profile)', style: TextStyle(color: AppColors.brownMid, fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: codeCtrl,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(color: AppColors.brownDark, fontWeight: FontWeight.w700, letterSpacing: 2),
              decoration: InputDecoration(
                hintText: 'e.g. ABC12345',
                hintStyle: TextStyle(color: AppColors.brownLight),
                prefixText: '# ',
                prefixStyle: const TextStyle(color: AppColors.brownDark, fontWeight: FontWeight.w700),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.brownMid)),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeCtrl.text.trim();
              if (code.isEmpty) return;
              Navigator.pop(ctx);
              await _addByCode(code);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _addByCode(String code) async {
    final us = Provider.of<UserService>(context, listen: false);
    final user = await us.lookupByFriendCode(code);
    if (!mounted) return;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user found with that code'), backgroundColor: AppColors.dangerRed),
      );
      return;
    }
    if (user['user_id'] == us.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That\'s your own code!'), backgroundColor: AppColors.dangerRed),
      );
      return;
    }
    final success = await us.addFriend(user['user_id']);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added ${user['username']}!'), backgroundColor: AppColors.badgeGreen),
      );
      _loadFriends();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add friend'), backgroundColor: AppColors.dangerRed),
      );
    }
  }

  void _showFriendProfile(Map<String, dynamic> friend) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _FriendProfileScreen(
        friendId: friend['user_id'] ?? '',
        friendName: friend['username'] ?? 'Unknown',
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Expanded(
                child: Text('FRIENDS', style: TextStyle(color: AppColors.brownMid, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2)),
              ),
              GestureDetector(
                onTap: _showAddDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_add, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('Add', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _friends.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people_outline, size: 48, color: AppColors.brownLight),
                            const SizedBox(height: 12),
                            Text('No friends yet', style: TextStyle(color: AppColors.brownLight, fontSize: 14, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('Add friends using their # code', style: TextStyle(color: AppColors.brownLight, fontSize: 12)),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadFriends,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _friends.length,
                        itemBuilder: (context, index) {
                          final friend = _friends[index];
                          return GestureDetector(
                            onTap: () => _showFriendProfile(friend),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.cardCream,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.borderBrown, width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40, height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.brownDark, width: 2),
                                    ),
                                    child: const Center(child: Text('\u{1F3A8}', style: TextStyle(fontSize: 18))),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          friend['username'] ?? 'Unknown',
                                          style: const TextStyle(color: AppColors.brownDark, fontWeight: FontWeight.w700, fontSize: 14),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '#${friend['friend_code'] ?? ''}',
                                          style: const TextStyle(color: AppColors.brownLight, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Image.asset('assets/images/UI/coin250.png', width: 12, height: 12),
                                          const SizedBox(width: 3),
                                          Text(
                                            fmtCommas((friend['cash'] ?? 0).toDouble()),
                                            style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${friend['total_walls_painted'] ?? 0} walls',
                                        style: const TextStyle(color: AppColors.brownLight, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.chevron_right, color: AppColors.brownLight, size: 18),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

// =============================================================================
// FRIEND PROFILE SCREEN (view a friend's profile)
// =============================================================================
class _FriendProfileScreen extends StatefulWidget {
  final String friendId;
  final String friendName;
  const _FriendProfileScreen({required this.friendId, required this.friendName});

  @override
  State<_FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<_FriendProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final us = Provider.of<UserService>(context, listen: false);
    final profile = await us.getUserProfile(widget.friendId);
    if (mounted) setState(() { _profile = profile; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.brownDark,
        foregroundColor: Colors.white,
        title: Text(widget.friendName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _profile == null
              ? const Center(child: Text('Could not load profile', style: TextStyle(color: AppColors.brownMid)))
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Avatar
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.cardCream,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.brownDark, width: 3),
                          ),
                          child: const Center(child: Text('\u{1F3A8}', style: TextStyle(fontSize: 36))),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _profile!['user']?['username'] ?? widget.friendName,
                          style: const TextStyle(color: AppColors.brownDark, fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                        if (_profile!['user']?['friend_code'] != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.brownDark, borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              '#${_profile!['user']['friend_code']}',
                              style: const TextStyle(color: AppColors.tabUnselected, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        // Stats
                        _buildStats(),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStats() {
    final prog = _profile!['progress'] ?? {};
    final cash = (prog['cash'] ?? 0).toDouble();
    final gems = prog['stars'] ?? 0;
    final walls = prog['total_walls_painted'] ?? 0;
    final totalEarned = (prog['total_cash_earned'] ?? 0).toDouble();
    final houseLevel = prog['prestige_level'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _StatCardWithIcon('assets/images/UI/coin250.png', 'Coins', fmtCommas(cash), AppColors.badgeGoldBrown)),
            const SizedBox(width: 8),
            Expanded(child: _StatCardWithIcon('assets/images/UI/diamond250.png', 'Gems', '$gems', AppColors.badgePurple)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _StatCard('\u{1F3E0}', 'House', 'Lv.$houseLevel', AppColors.badgeBlue)),
            const SizedBox(width: 8),
            Expanded(child: _StatCard('\u{1F3A8}', 'Walls', '$walls', AppColors.badgeGreen)),
          ],
        ),
        const SizedBox(height: 16),
        const Text('STATS', style: TextStyle(color: AppColors.brownMid, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardCream,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderBrown, width: 1.5),
          ),
          child: Column(
            children: [
              _StatRow('Walls Painted', '$walls'),
              _StatRow('Total Earned', '\$${fmtCommas(totalEarned)}'),
              _StatRow('House Level', 'Lv.$houseLevel', last: true),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// SETTINGS TAB
// =============================================================================
class _SettingsTab extends StatelessWidget {
  final GameService gameService;
  const _SettingsTab({required this.gameService});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioService>(
      builder: (context, audioService, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text('SETTINGS', style: TextStyle(color: AppColors.brownMid, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2)),
              const SizedBox(height: 12),
              _SettingsRow(
                icon: Icons.volume_up_outlined,
                label: 'Sound Effects',
                trailing: Switch(
                  value: audioService.sfxEnabled,
                  onChanged: (_) => audioService.toggleSfx(),
                  activeColor: AppColors.badgeGreen,
                  activeTrackColor: AppColors.switchActiveTrack,
                  inactiveThumbColor: AppColors.brownLight,
                  inactiveTrackColor: AppColors.borderBrown,
                ),
              ),
              _SettingsRow(
                icon: Icons.music_note_outlined,
                label: 'Background Music',
                trailing: Switch(
                  value: audioService.musicEnabled,
                  onChanged: (_) => audioService.toggleMusic(),
                  activeColor: AppColors.badgeGreen,
                  activeTrackColor: AppColors.switchActiveTrack,
                  inactiveThumbColor: AppColors.brownLight,
                  inactiveTrackColor: AppColors.borderBrown,
                ),
              ),
              _SettingsRow(
                icon: Icons.vibration,
                label: 'Haptic Feedback',
                trailing: Switch(
                  value: audioService.hapticEnabled,
                  onChanged: (_) => audioService.toggleHaptic(),
                  activeColor: AppColors.badgeGreen,
                  activeTrackColor: AppColors.switchActiveTrack,
                  inactiveThumbColor: AppColors.brownLight,
                  inactiveTrackColor: AppColors.borderBrown,
                ),
              ),
              const SizedBox(height: 20),
              const Text('DEBUG', style: TextStyle(color: AppColors.brownMid, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2)),
              const SizedBox(height: 12),
              _SettingsButton(
                icon: Icons.add_circle_outline,
                label: '+10,000 Coins',
                color: AppColors.badgeGoldBrown,
                bgColor: AppColors.debugGoldBg,
                onTap: () {
                  gameService.addDebugCoins(10000);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('+10,000 coins added!'), duration: Duration(seconds: 1)),
                  );
                },
              ),
              _SettingsButton(
                icon: Icons.delete_outline,
                label: 'Reset All Progress',
                color: AppColors.dangerRed,
                bgColor: AppColors.dangerBg,
                onTap: () => _showResetDialog(context, gameService),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text('v1.0.0', style: TextStyle(color: AppColors.brownLight, fontSize: 11)),
              ),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  void _showResetDialog(BuildContext context, GameService gameService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardCream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Reset All Progress?', style: TextStyle(color: AppColors.brownDark, fontWeight: FontWeight.w800)),
        content: const Text(
          'This will delete ALL progress including gems, upgrades, and inventory. Cannot be undone!',
          style: TextStyle(color: AppColors.brownMid),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.brownMid))),
          TextButton(
            onPressed: () { gameService.resetAll(); Navigator.pop(context); },
            child: const Text('Reset', style: TextStyle(color: AppColors.dangerRed, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  const _SettingsRow({required this.icon, required this.label, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.cardCream,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderBrown, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.brownDark),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(color: AppColors.brownDark, fontSize: 14, fontWeight: FontWeight.w600))),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;
  const _SettingsButton({required this.icon, required this.label, required this.color, required this.bgColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 12),
              Text(label, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
