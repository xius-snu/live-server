import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/user_service.dart';
import '../services/game_service.dart';
import '../services/audio_service.dart';
import '../services/marketplace_service.dart';
import '../models/house.dart';
import '../models/marketplace_item.dart';

// ── Warm game palette (matches home screen) ──
const _bgBeige = Color(0xFFE8D5B8);
const _cardCream = Color(0xFFF5E6D0);
const _brownDark = Color(0xFF6B5038);
const _brownMid = Color(0xFF8B7355);
const _brownLight = Color(0xFFB89E7A);
const _borderBrown = Color(0xFFC4A882);
const _gold = Color(0xFFF5C842);

String _playerTitle(GameService gs, int itemCount) {
  final p = gs.progress;
  final walls = p.totalWallsPainted;
  final avg = p.averageCoverage;
  final houseLevel = p.houseLevel;
  final streak = p.streak;
  final idle = p.idleIncomePerSecond;

  if (itemCount >= 10) return 'Collector';
  if (walls >= 10 && avg >= 0.95) return 'Perfectionist';
  if (houseLevel >= 10 && idle >= 20) return 'Tycoon';
  if (streak >= 8) return 'Streak Master';
  if (houseLevel >= 15) return 'Master Painter';
  if (walls >= 20 && avg >= 0.85) return 'Precision Roller';
  if (walls >= 50 && avg < 0.7) return 'Speed Roller';
  if (walls >= 30) return 'Veteran Painter';
  if (idle >= 10) return 'Idle Mogul';
  if (houseLevel >= 5) return 'Journeyman';
  if (walls >= 10) return 'Apprentice';
  if (walls >= 1) return 'Newcomer';
  return 'Fresh Paint';
}

Color _titleColor(String title) {
  switch (title) {
    case 'Collector': return const Color(0xFFD4880F);
    case 'Perfectionist': return const Color(0xFF8B3FC7);
    case 'Tycoon': return const Color(0xFF2E8B57);
    case 'Streak Master': return const Color(0xFFCC5522);
    case 'Master Painter': return const Color(0xFF2563EB);
    case 'Precision Roller': return const Color(0xFF2563EB);
    case 'Speed Roller': return const Color(0xFFCC5522);
    case 'Veteran Painter': return const Color(0xFFD4880F);
    case 'Idle Mogul': return const Color(0xFF2E8B57);
    case 'Journeyman': return const Color(0xFF2E8B57);
    case 'Apprentice': return _brownDark;
    case 'Newcomer': return _brownMid;
    default: return _brownLight;
  }
}

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
    _tabController = TabController(length: 4, vsync: this);
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

  static String _fmtCommas(double value) {
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
      backgroundColor: _bgBeige,
      body: Consumer3<UserService, GameService, MarketplaceService>(
        builder: (context, userService, gameService, mp, _) {
          final house = gameService.currentHouseDef;
          final itemCount = mp.inventory.length;
          final title = _playerTitle(gameService, itemCount);
          final tc = _titleColor(title);

          return SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 14),
                // Centered profile icon + name
                _CenteredProfileHeader(
                  userService: userService,
                  gameService: gameService,
                  house: house,
                  title: title,
                  titleColor: tc,
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
                      color: _brownDark,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: _gold,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      labelColor: _brownDark,
                      unselectedLabelColor: const Color(0xFFD4C4A8),
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
  final String title;
  final Color titleColor;
  final bool isEditing;
  final bool isSaving;
  final TextEditingController nameController;
  final VoidCallback onEditTap;
  final VoidCallback onSave;

  const _CenteredProfileHeader({
    required this.userService,
    required this.gameService,
    required this.house,
    required this.title,
    required this.titleColor,
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
            color: _cardCream,
            shape: BoxShape.circle,
            border: Border.all(color: _brownDark, width: 3),
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
                    style: const TextStyle(color: _brownDark, fontSize: 20, fontWeight: FontWeight.w800),
                    decoration: InputDecoration(
                      isDense: true,
                      border: UnderlineInputBorder(borderSide: BorderSide(color: _brownLight)),
                    ),
                    onSubmitted: (_) => onSave(),
                  ),
                ),
                const SizedBox(width: 6),
                isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _brownDark))
                    : IconButton(
                        icon: const Icon(Icons.check, color: Color(0xFF2E8B57), size: 22),
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
                    color: userService.username != null ? _brownDark : _brownLight,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.edit, color: _brownLight, size: 14),
              ],
            ),
          ),
        const SizedBox(height: 6),
        // Title badge + friend code
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: titleColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
            if (userService.friendCode != null) ...[
              const SizedBox(width: 8),
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
                    color: _brownDark,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '#${userService.friendCode}',
                        style: const TextStyle(color: Color(0xFFD4C4A8), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.copy, size: 10, color: Color(0xFFD4C4A8)),
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

  static String _fmtCommas(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

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
              Expanded(child: _StatCard('\u{1F4B0}', 'Coins', _fmtCommas(gameService.cash), const Color(0xFFD4880F))),
              const SizedBox(width: 8),
              Expanded(child: _StatCard('\u{1F48E}', 'Gems', '${gameService.gems}', const Color(0xFF8B3FC7))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _StatCard(house.icon, 'House', p.houseDisplayName, const Color(0xFF2563EB))),
              const SizedBox(width: 8),
              Expanded(child: _StatCard('\u{1F58C}\u{FE0F}', 'Roller', 'Lv.${p.rollerLevel}', const Color(0xFF2E8B57))),
            ],
          ),
          const SizedBox(height: 16),
          // Lifetime stats header
          const Text('LIFETIME STATS', style: TextStyle(color: _brownMid, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _cardCream,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _borderBrown, width: 1.5),
            ),
            child: Column(
              children: [
                _StatRow('Walls Painted', '${p.totalWallsPainted}'),
                _StatRow('Avg Coverage', '${avgCov.toStringAsFixed(1)}%'),
                _StatRow('Total Earned', '\$${_fmtCommas(p.totalCashEarned)}'),
                _StatRow('Idle Income', '\$${p.idleIncomePerSecond.toStringAsFixed(0)}/sec'),
                _StatRow('Current Streak', '\u{1F525} ${p.streak}'),
                _StatRow('Skins Owned', '${p.ownedSkins.length}/${GameService.rollerSkinDefs.length}', last: true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Performance grade
          _PerformanceGrade(avgCoverage: avgCov, wallsPainted: p.totalWallsPainted, streak: p.streak),
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
        color: _cardCream,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderBrown, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: _brownMid, fontSize: 11, fontWeight: FontWeight.w700)),
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
          Text(label, style: const TextStyle(color: _brownMid, fontSize: 13, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: _brownDark, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}

class _PerformanceGrade extends StatelessWidget {
  final double avgCoverage;
  final int wallsPainted;
  final int streak;
  const _PerformanceGrade({required this.avgCoverage, required this.wallsPainted, required this.streak});

  String get _grade {
    final score = avgCoverage * 0.5 + (wallsPainted.clamp(0, 100) / 100.0) * 30 + streak * 2;
    if (score >= 80) return 'S';
    if (score >= 60) return 'A';
    if (score >= 40) return 'B';
    if (score >= 20) return 'C';
    return 'D';
  }

  Color get _gradeColor {
    switch (_grade) {
      case 'S': return const Color(0xFFD4880F);
      case 'A': return const Color(0xFF2E8B57);
      case 'B': return const Color(0xFF2563EB);
      case 'C': return const Color(0xFFCC5522);
      default: return _brownMid;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardCream,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _gradeColor, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _gradeColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(_grade, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('PAINTER GRADE', style: TextStyle(color: _brownDark, fontSize: 13, fontWeight: FontWeight.w800)),
                SizedBox(height: 2),
                Text('Based on coverage, experience & streaks', style: TextStyle(color: _brownMid, fontSize: 11)),
              ],
            ),
          ),
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
        final skins = gs.ownedSkins;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Equipped roller
              const Text('EQUIPPED ROLLER', style: TextStyle(color: _brownMid, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2)),
              const SizedBox(height: 8),
              _EquippedRollerCard(gs: gs),
              const SizedBox(height: 16),

              // Owned skins
              Text('OWNED SKINS (${skins.length})', style: const TextStyle(color: _brownMid, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2)),
              const SizedBox(height: 8),
              ...GameService.rollerSkinDefs.where((s) => skins.contains(s.id)).map((skin) {
                final equipped = gs.equippedSkin == skin.id;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: equipped ? const Color(0xFFD9F2D9) : _cardCream,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: equipped ? const Color(0xFF2E8B57) : _borderBrown,
                      width: equipped ? 2 : 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: _bgBeige,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _borderBrown),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Image.asset('assets/images/rollers/${skin.asset}', fit: BoxFit.contain),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(skin.name, style: const TextStyle(color: _brownDark, fontWeight: FontWeight.w700, fontSize: 13))),
                      if (equipped)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E8B57),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Equipped', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                        )
                      else
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            gs.equipSkin(skin.id);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _gold,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Equip', style: TextStyle(color: _brownDark, fontSize: 11, fontWeight: FontWeight.w800)),
                          ),
                        ),
                    ],
                  ),
                );
              }),

              // Market items
              if (items.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('MARKET ITEMS (${items.length})', style: const TextStyle(color: _brownMid, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2)),
                const SizedBox(height: 8),
                ...items.map((item) => _InvItemRow(item: item)),
              ] else ...[
                const SizedBox(height: 16),
                Center(
                  child: Column(children: [
                    Icon(Icons.inventory_2_outlined, size: 40, color: _brownLight),
                    const SizedBox(height: 8),
                    const Text('No market items yet', style: TextStyle(color: _brownMid, fontSize: 12)),
                    const SizedBox(height: 4),
                    const Text('Win items from events or buy from the market!', style: TextStyle(color: _brownLight, fontSize: 11)),
                  ]),
                ),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardCream,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _brownDark, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: _bgBeige,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _borderBrown, width: 1.5),
            ),
            child: Padding(padding: const EdgeInsets.all(6), child: Image.asset('assets/images/rollers/${skin.asset}', fit: BoxFit.contain)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(skin.name, style: const TextStyle(color: _brownDark, fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 4),
                Row(children: [
                  Container(width: 14, height: 14, decoration: BoxDecoration(color: skin.paintColor, shape: BoxShape.circle, border: Border.all(color: _brownDark, width: 1))),
                  const SizedBox(width: 6),
                  const Text('Paint Color', style: TextStyle(color: _brownMid, fontSize: 11, fontWeight: FontWeight.w600)),
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
      case ItemRarity.common: return _brownMid;
      case ItemRarity.uncommon: return const Color(0xFF2E8B57);
      case ItemRarity.rare: return const Color(0xFF2563EB);
      case ItemRarity.epic: return const Color(0xFF8B3FC7);
      case ItemRarity.legendary: return const Color(0xFFD4880F);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = item.itemType?.name ?? item.itemTypeId;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _cardCream,
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
          Expanded(child: Text(name, style: const TextStyle(color: _brownDark, fontWeight: FontWeight.w700, fontSize: 12))),
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
                color: _gold,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('LISTED', style: TextStyle(color: _brownDark, fontSize: 8, fontWeight: FontWeight.w800)),
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
      _Badge('\u{1F3A8}', 'First Stroke', 'Paint your first wall', p.totalWallsPainted >= 1),
      _Badge('\u{1F3AF}', 'Sharp Eye', 'Achieve 95%+ coverage', p.averageCoverage >= 0.95 && p.totalWallsPainted >= 5),
      _Badge('\u{1F525}', 'On Fire', 'Reach a 5x streak', p.streak >= 5),
      _Badge('\u{1F3E0}', 'Homeowner', 'Reach House Level 5', p.houseLevel >= 5),
      _Badge('\u{1F3D7}\u{FE0F}', 'Builder', 'Reach House Level 10', p.houseLevel >= 10),
      _Badge('\u{1F3F0}', 'Castle Lord', 'Reach House Level 20', p.houseLevel >= 20),
      _Badge('\u{1F4B0}', 'First Thousand', 'Earn 1,000 coins total', p.totalCashEarned >= 1000),
      _Badge('\u{1F4B5}', 'Big Spender', 'Earn 100,000 coins total', p.totalCashEarned >= 100000),
      _Badge('\u{1F48E}', 'Gem Collector', 'Own 10+ gems', gameService.gems >= 10),
      _Badge('\u{1F58C}\u{FE0F}', 'Fancy Roller', 'Own 3+ roller skins', p.ownedSkins.length >= 3),
      _Badge('\u{1F451}', 'Collector', 'Own 10+ market items', itemCount >= 10),
      _Badge('\u{2B50}', 'Perfectionist', 'Paint 10 perfect walls', p.totalWallsPainted >= 10 && p.averageCoverage >= 0.95),
      _Badge('\u{1F3C6}', '100 Club', 'Paint 100 walls', p.totalWallsPainted >= 100),
      _Badge('\u{1F30D}', 'Veteran', 'Paint 500 walls', p.totalWallsPainted >= 500),
      _Badge('\u{1F680}', 'Millionaire', 'Earn 1,000,000 coins total', p.totalCashEarned >= 1000000),
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
              color: _cardCream,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _borderBrown, width: 1.5),
            ),
            child: Row(
              children: [
                Text('$earned / ${badges.length}', style: const TextStyle(color: _brownDark, fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: badges.isEmpty ? 0 : earned / badges.length,
                      minHeight: 10,
                      backgroundColor: _borderBrown,
                      valueColor: const AlwaysStoppedAnimation(_gold),
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
              color: badge.earned ? const Color(0xFFFFF3D0) : _cardCream,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: badge.earned ? _gold : _borderBrown,
                width: badge.earned ? 2 : 1.5,
              ),
            ),
            child: Row(
              children: [
                Text(badge.emoji, style: TextStyle(fontSize: 22, color: badge.earned ? null : _brownLight)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(badge.name, style: TextStyle(
                        color: badge.earned ? _brownDark : _brownLight,
                        fontWeight: FontWeight.w700, fontSize: 13,
                      )),
                      Text(badge.description, style: TextStyle(
                        color: badge.earned ? _brownMid : _brownLight,
                        fontSize: 11,
                      )),
                    ],
                  ),
                ),
                if (badge.earned)
                  const Text('\u2705', style: TextStyle(fontSize: 16))
                else
                  const Icon(Icons.lock_outline, size: 16, color: _brownLight),
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
  const _Badge(this.emoji, this.name, this.description, this.earned);
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
              const Text('SETTINGS', style: TextStyle(color: _brownMid, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2)),
              const SizedBox(height: 12),
              _SettingsRow(
                icon: Icons.volume_up_outlined,
                label: 'Sound Effects',
                trailing: Switch(
                  value: audioService.sfxEnabled,
                  onChanged: (_) => audioService.toggleSfx(),
                  activeColor: const Color(0xFF2E8B57),
                  activeTrackColor: const Color(0xFF90D5A0),
                  inactiveThumbColor: _brownLight,
                  inactiveTrackColor: _borderBrown,
                ),
              ),
              _SettingsRow(
                icon: Icons.music_note_outlined,
                label: 'Background Music',
                trailing: Switch(
                  value: audioService.musicEnabled,
                  onChanged: (_) => audioService.toggleMusic(),
                  activeColor: const Color(0xFF2E8B57),
                  activeTrackColor: const Color(0xFF90D5A0),
                  inactiveThumbColor: _brownLight,
                  inactiveTrackColor: _borderBrown,
                ),
              ),
              _SettingsRow(
                icon: Icons.vibration,
                label: 'Haptic Feedback',
                trailing: Switch(
                  value: audioService.hapticEnabled,
                  onChanged: (_) => audioService.toggleHaptic(),
                  activeColor: const Color(0xFF2E8B57),
                  activeTrackColor: const Color(0xFF90D5A0),
                  inactiveThumbColor: _brownLight,
                  inactiveTrackColor: _borderBrown,
                ),
              ),
              const SizedBox(height: 20),
              const Text('DEBUG', style: TextStyle(color: _brownMid, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2)),
              const SizedBox(height: 12),
              _SettingsButton(
                icon: Icons.add_circle_outline,
                label: '+10,000 Coins',
                color: const Color(0xFFD4880F),
                bgColor: const Color(0xFFFFF3D0),
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
                color: const Color(0xFFCC3333),
                bgColor: const Color(0xFFFDE8E8),
                onTap: () => _showResetDialog(context, gameService),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text('v1.0.0', style: TextStyle(color: _brownLight, fontSize: 11)),
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
        backgroundColor: _cardCream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Reset All Progress?', style: TextStyle(color: _brownDark, fontWeight: FontWeight.w800)),
        content: const Text(
          'This will delete ALL progress including gems, upgrades, and inventory. Cannot be undone!',
          style: TextStyle(color: _brownMid),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: _brownMid))),
          TextButton(
            onPressed: () { gameService.resetAll(); Navigator.pop(context); },
            child: const Text('Reset', style: TextStyle(color: Color(0xFFCC3333), fontWeight: FontWeight.w700)),
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
          color: _cardCream,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _borderBrown, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: _brownDark),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(color: _brownDark, fontSize: 14, fontWeight: FontWeight.w600))),
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
