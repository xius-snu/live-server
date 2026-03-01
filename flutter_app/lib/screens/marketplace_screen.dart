import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/game_config.dart';
import '../services/game_service.dart';
import '../services/marketplace_service.dart';
import '../models/marketplace_item.dart';
import '../models/roller_inventory_item.dart';
import '../theme/app_colors.dart';
import '../utils/format_utils.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mp = Provider.of<MarketplaceService>(context, listen: false);
      mp.loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const Text(
                    'Market',
                    style: TextStyle(
                      color: AppColors.brownDark,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Consumer<GameService>(
                    builder: (context, gs, _) => Row(
                      children: [
                        _CurrencyChip(
                          label: '\$${_fmt(gs.cash)}',
                          color: AppColors.secondary,
                          iconAsset: 'assets/images/UI/coin250.png',
                        ),
                        const SizedBox(width: 6),
                        _CurrencyChip(
                          label: '${gs.gems}',
                          color: AppColors.purpleAccent,
                          iconAsset: 'assets/images/UI/diamond250.png',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.brownDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white38,
                  labelStyle:
                      const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  dividerColor: Colors.transparent,
                  isScrollable: false,
                  labelPadding: EdgeInsets.zero,
                  tabs: const [
                    Tab(text: 'Shop'),
                    Tab(text: 'Auction'),
                    Tab(text: 'Inventory'),
                    Tab(text: 'Sell'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _DefaultShopTab(),
                  _AuctionTab(),
                  _InventoryTab(),
                  _SellTab(),
                ],
              ),
            ),
            _IndexTicker(),
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

class _CurrencyChip extends StatelessWidget {
  final String label;
  final Color color;
  final String iconAsset;
  const _CurrencyChip({required this.label, required this.color, required this.iconAsset});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.hudDark,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.hudBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x44000000), offset: Offset(0, 2), blurRadius: 0),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(iconAsset, width: 18, height: 18),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// ROLLER SKIN SHOP (buy rollers, get random color)
// =============================================================================

class _DefaultShopTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final skins = GameService.rollerSkinDefs;
    return Consumer<GameService>(
      builder: (context, gs, _) {
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Buy rollers to get a random paint color!',
                style: TextStyle(color: AppColors.brownDark.withOpacity(0.5), fontSize: 12),
              ),
            ),
            ...skins.map((skin) {
              final canAfford = gs.cash >= skin.price;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.brownDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.progressionBrown, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Image.asset(
                          'assets/images/rollers/${skin.asset}',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            skin.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Random paint color',
                            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: canAfford
                          ? () {
                              HapticFeedback.mediumImpact();
                              final result = gs.purchaseRoller(skin.id);
                              if (result != null) {
                                _showRevealDialog(context, skin, result, gs);
                              }
                            }
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: canAfford
                              ? AppColors.secondary
                              : Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/images/UI/coin250.png',
                              width: 16,
                              height: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              fmtCommas(skin.price),
                              style: TextStyle(
                                color: canAfford ? Colors.black : Colors.white38,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  void _showRevealDialog(BuildContext context, RollerSkinDef skin, RollerInventoryItem item, GameService gs) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _RollerRevealDialog(skin: skin, item: item, gs: gs),
    );
  }
}

// =============================================================================
// CARD REVEAL POPUP
// =============================================================================

class _RollerRevealDialog extends StatefulWidget {
  final RollerSkinDef skin;
  final RollerInventoryItem item;
  final GameService gs;

  const _RollerRevealDialog({required this.skin, required this.item, required this.gs});

  @override
  State<_RollerRevealDialog> createState() => _RollerRevealDialogState();
}

class _RollerRevealDialogState extends State<_RollerRevealDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tierColor = AppColors.colorForTier(widget.item.colorTier);
    final colorDef = getPaintColorById(widget.item.colorId);
    final colorName = colorDef?.name ?? widget.item.colorId;
    final paintColor = Color(widget.item.colorHex);

    return ScaleTransition(
      scale: _scaleAnim,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.brownDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tierColor, width: 3),
            boxShadow: [
              BoxShadow(color: tierColor.withOpacity(0.3), blurRadius: 20, spreadRadius: 2),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tier label
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: tierColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.item.colorTier.name.toUpperCase(),
                  style: TextStyle(
                    color: tierColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Roller image
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    'assets/images/rollers/${widget.skin.asset}',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Paint color circle
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: paintColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(color: paintColor.withOpacity(0.4), blurRadius: 8),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Color name
              Text(
                colorName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              // Roller name
              Text(
                widget.skin.name,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        widget.gs.equipRollerItem(widget.item.rollerId, widget.item.colorId);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text(
                            'Equip',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: const Center(
                          child: Text(
                            'OK',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// COMMUNITY AUCTION HOUSE
// =============================================================================

class _AuctionTab extends StatefulWidget {
  @override
  State<_AuctionTab> createState() => _AuctionTabState();
}

class _AuctionTabState extends State<_AuctionTab> {
  String _filterCategory = 'all';
  String _sortBy = 'newest';

  @override
  Widget build(BuildContext context) {
    return Consumer<MarketplaceService>(
      builder: (context, mp, _) {
        if (mp.loading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        var listings = mp.communityListings.toList();

        // Apply filter
        if (_filterCategory == 'roller') {
          listings = listings.where((l) => l.item.isRollerItem || l.item.itemType?.category == ItemCategory.rollerSkin).toList();
        } else if (_filterCategory == 'paint') {
          listings = listings.where((l) => l.item.itemType?.category == ItemCategory.paint).toList();
        } else if (_filterCategory == 'other') {
          listings = listings.where((l) => !l.item.isRollerItem && l.item.itemType?.category != ItemCategory.rollerSkin && l.item.itemType?.category != ItemCategory.paint).toList();
        }

        // Apply sort
        switch (_sortBy) {
          case 'price_low':
            listings.sort((a, b) => a.priceGems.compareTo(b.priceGems));
            break;
          case 'price_high':
            listings.sort((a, b) => b.priceGems.compareTo(a.priceGems));
            break;
          case 'rarity':
            listings.sort((a, b) => b.item.rarity.index.compareTo(a.item.rarity.index));
            break;
          default: // newest
            listings.sort((a, b) => b.listedAt.compareTo(a.listedAt));
        }

        return Column(
          children: [
            // Filter/sort bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _FilterChip(label: 'All', selected: _filterCategory == 'all', onTap: () => setState(() => _filterCategory = 'all')),
                  const SizedBox(width: 6),
                  _FilterChip(label: 'Rollers', selected: _filterCategory == 'roller', onTap: () => setState(() => _filterCategory = 'roller')),
                  const SizedBox(width: 6),
                  _FilterChip(label: 'Paint', selected: _filterCategory == 'paint', onTap: () => setState(() => _filterCategory = 'paint')),
                  const SizedBox(width: 6),
                  _FilterChip(label: 'Other', selected: _filterCategory == 'other', onTap: () => setState(() => _filterCategory = 'other')),
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: (val) => setState(() => _sortBy = val),
                    icon: Icon(Icons.sort, color: AppColors.brownDark.withOpacity(0.6), size: 20),
                    color: AppColors.brownDark,
                    itemBuilder: (_) => [
                      _sortItem('newest', 'Newest'),
                      _sortItem('price_low', 'Price: Low'),
                      _sortItem('price_high', 'Price: High'),
                      _sortItem('rarity', 'Rarity'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: listings.isEmpty
                  ? const _EmptyState(icon: Icons.storefront_outlined, title: 'No listings', subtitle: 'Be the first to list an item!')
                  : RefreshIndicator(
                      onRefresh: () => mp.fetchCommunityListings(),
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: listings.length,
                        itemBuilder: (context, index) => _AuctionCard(listing: listings[index]),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  PopupMenuItem<String> _sortItem(String value, String label) {
    return PopupMenuItem(
      value: value,
      child: Text(label, style: TextStyle(
        color: _sortBy == value ? AppColors.primary : Colors.white,
        fontSize: 13,
      )),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.brownDark.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.brownDark.withOpacity(0.6),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _AuctionCard extends StatelessWidget {
  final MarketplaceListing listing;
  const _AuctionCard({required this.listing});

  Color get _rc {
    switch (listing.item.rarity) {
      case ItemRarity.common: return AppColors.rarityCommon;
      case ItemRarity.uncommon: return AppColors.secondary;
      case ItemRarity.rare: return AppColors.rarityRare;
      case ItemRarity.epic: return AppColors.purpleAccent;
      case ItemRarity.legendary: return AppColors.rarityLegendary;
      case ItemRarity.mythic: return AppColors.rarityMythic;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRoller = listing.item.isRollerItem;
    final itemType = listing.item.itemType;
    final name = isRoller
        ? _rollerDisplayName(listing.item.rollerId!, listing.item.colorId)
        : (itemType?.name ?? listing.item.itemTypeId);
    final idx = context.read<MarketplaceService>().indexPrices[listing.item.itemTypeId];
    final diff = idx != null ? ((listing.priceGems - idx) / idx * 100) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.brownDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.progressionBrown),
      ),
      child: Row(
        children: [
          // Icon / roller image
          if (isRoller)
            _RollerIconBadge(
              rollerId: listing.item.rollerId!,
              colorHex: listing.item.colorHex,
              tierColor: _rc,
              size: 42,
            )
          else
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: _rc.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _rc.withOpacity(0.4), width: 2),
              ),
              child: Center(child: Text(_catIcon(itemType?.category), style: const TextStyle(fontSize: 18))),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(color: _rc.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                    child: Text(listing.item.rarity.name.toUpperCase(), style: TextStyle(color: _rc, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ]),
                const SizedBox(height: 3),
                Row(children: [
                  Text(listing.sellerName, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11)),
                  if (diff != null) ...[
                    const SizedBox(width: 8),
                    Text('${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(0)}%',
                        style: TextStyle(color: diff >= 0 ? AppColors.secondary : AppColors.primary, fontWeight: FontWeight.w600, fontSize: 11)),
                  ],
                ]),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _confirmBuy(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/UI/diamond250.png', width: 14, height: 14),
                  const SizedBox(width: 4),
                  Text('${listing.priceGems}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmBuy(BuildContext context) {
    final isRoller = listing.item.isRollerItem;
    final name = isRoller
        ? _rollerDisplayName(listing.item.rollerId!, listing.item.colorId)
        : (listing.item.itemType?.name ?? listing.item.itemTypeId);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.brownDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Purchase', style: TextStyle(color: Colors.white)),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Buy $name for ', style: const TextStyle(color: Colors.white70)),
            Image.asset('assets/images/UI/diamond250.png', width: 16, height: 16),
            Text('${listing.priceGems} gems?', style: const TextStyle(color: Colors.white70)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: Colors.black),
            onPressed: () async {
              Navigator.pop(ctx);
              final mp = Provider.of<MarketplaceService>(context, listen: false);
              final err = await mp.buyListing(listing.listingId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(err ?? 'Purchased $name!'), backgroundColor: err == null ? AppColors.secondary : Colors.red, duration: const Duration(seconds: 2)),
                );
              }
            },
            child: const Text('Buy'),
          ),
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
// INVENTORY (grid of roller items)
// =============================================================================

class _InventoryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<GameService>(
      builder: (context, gs, _) {
        final items = gs.rollerInventory.where((i) => i.count > 0).toList();
        if (items.isEmpty) {
          return const _EmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'Inventory empty',
            subtitle: 'Buy rollers from the Shop to get started',
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.0,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final isEquipped = gs.equippedSkin == item.rollerId && gs.equippedColorId == item.colorId;
            return _InventoryCell(item: item, isEquipped: isEquipped);
          },
        );
      },
    );
  }
}

class _InventoryCell extends StatelessWidget {
  final RollerInventoryItem item;
  final bool isEquipped;
  const _InventoryCell({required this.item, required this.isEquipped});

  @override
  Widget build(BuildContext context) {
    final tierColor = AppColors.colorForTier(item.colorTier);
    final paintColor = Color(item.colorHex);
    final skinDef = GameService.rollerSkinDefs.where((s) => s.id == item.rollerId).firstOrNull;

    return GestureDetector(
      onTap: () => _showItemSheet(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.brownDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isEquipped ? tierColor : tierColor.withOpacity(0.5),
            width: isEquipped ? 2.5 : 1.5,
          ),
        ),
        child: Stack(
          children: [
            // Roller image
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: skinDef != null
                    ? Image.asset(
                        'assets/images/rollers/${skinDef.asset}',
                        fit: BoxFit.contain,
                      )
                    : const Icon(Icons.brush, color: Colors.white38),
              ),
            ),
            // Color swatch (bottom-right)
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: paintColor,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: Colors.white, width: 1),
                ),
              ),
            ),
            // Count badge (top-left)
            if (item.count > 1)
              Positioned(
                left: 3,
                top: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'x${item.count}',
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            // Equipped indicator (top-right)
            if (isEquipped)
              Positioned(
                right: 3,
                top: 3,
                child: Icon(Icons.check_circle, color: tierColor, size: 14),
              ),
          ],
        ),
      ),
    );
  }

  void _showItemSheet(BuildContext context) {
    final gs = Provider.of<GameService>(context, listen: false);
    final tierColor = AppColors.colorForTier(item.colorTier);
    final paintColor = Color(item.colorHex);
    final colorDef = getPaintColorById(item.colorId);
    final skinDef = GameService.rollerSkinDefs.where((s) => s.id == item.rollerId).firstOrNull;
    final isEquipped = gs.equippedSkin == item.rollerId && gs.equippedColorId == item.colorId;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.brownDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (skinDef != null)
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Image.asset('assets/images/rollers/${skinDef.asset}', fit: BoxFit.contain),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(skinDef?.name ?? item.rollerId, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 4),
                      Row(children: [
                        Container(
                          width: 14, height: 14,
                          decoration: BoxDecoration(color: paintColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1)),
                        ),
                        const SizedBox(width: 6),
                        Text(colorDef?.name ?? item.colorId, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(color: tierColor.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                          child: Text(item.colorTier.name.toUpperCase(), style: TextStyle(color: tierColor, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ]),
                    ],
                  ),
                ),
                Text('x${item.count}', style: const TextStyle(color: Colors.white38, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: isEquipped
                        ? null
                        : () {
                            HapticFeedback.mediumImpact();
                            gs.equipRollerItem(item.rollerId, item.colorId);
                            Navigator.pop(ctx);
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isEquipped ? AppColors.secondary.withOpacity(0.15) : AppColors.secondary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          isEquipped ? 'Equipped' : 'Equip',
                          style: TextStyle(
                            color: isEquipped ? AppColors.secondary : Colors.black,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: (isEquipped && item.count <= 1)
                        ? null
                        : () {
                            Navigator.pop(ctx);
                            _showSellDialog(context, item);
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: (isEquipped && item.count <= 1)
                            ? Colors.white.withOpacity(0.05)
                            : AppColors.purpleAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'Sell',
                          style: TextStyle(
                            color: (isEquipped && item.count <= 1)
                                ? Colors.white24
                                : AppColors.purpleAccent,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSellDialog(BuildContext context, RollerInventoryItem item) {
    final ctrl = TextEditingController(text: '10');
    bool useGems = true;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.brownDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('List on Market', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Set your price:', style: TextStyle(color: Colors.white.withOpacity(0.7))),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _FilterChip(label: 'Gems', selected: useGems, onTap: () => setDialogState(() => useGems = true)),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Coins', selected: !useGems, onTap: () => setDialogState(() => useGems = false)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 4),
                    child: Image.asset(
                      useGems ? 'assets/images/UI/diamond250.png' : 'assets/images/UI/coin250.png',
                      width: 20, height: 20,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.purpleAccent, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(ctx);
                final price = int.tryParse(ctrl.text) ?? 10;
                final gs = Provider.of<GameService>(context, listen: false);
                final mp = Provider.of<MarketplaceService>(context, listen: false);
                final fee = gs.progress.marketplaceFeePercent;

                // Decrement local inventory
                final removed = gs.removeRollerItem(item.rollerId, item.colorId);
                if (!removed) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to list item'), backgroundColor: Colors.red),
                    );
                  }
                  return;
                }

                final err = await mp.listRollerItem(
                  rollerId: item.rollerId,
                  colorId: item.colorId,
                  priceGems: price,
                  feePercent: fee,
                  colorTier: item.colorTier.name,
                  colorHex: item.colorHex,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(err ?? 'Listed for ${useGems ? "gems" : "coins"} $price!'),
                      backgroundColor: err == null ? AppColors.secondary : Colors.red,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text('List'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SELL TAB
// =============================================================================

class _SellTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<GameService, MarketplaceService>(
      builder: (context, gs, mp, _) {
        final myListings = mp.myListings;
        final rollerItems = gs.rollerInventory.where((i) => i.count > 0).toList();
        final sellable = mp.unlistedInventory;

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            if (myListings.isNotEmpty) ...[
              Text('YOUR LISTINGS', style: TextStyle(color: AppColors.brownDark.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const SizedBox(height: 8),
              ...myListings.map((l) => _MyListingCard(listing: l)),
              const SizedBox(height: 20),
            ],
            Text('ROLLER INVENTORY', style: TextStyle(color: AppColors.brownDark.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 8),
            if (rollerItems.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 20),
                child: Text('No rollers to sell', style: TextStyle(color: AppColors.brownDark.withOpacity(0.35), fontSize: 12)),
              )
            else
              ...rollerItems.map((item) {
                final isEquipped = gs.equippedSkin == item.rollerId && gs.equippedColorId == item.colorId;
                final canSell = !(isEquipped && item.count <= 1);
                return _RollerSellCard(item: item, canSell: canSell);
              }),
            const SizedBox(height: 20),
            if (sellable.isNotEmpty) ...[
              Text('OTHER ITEMS', style: TextStyle(color: AppColors.brownDark.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const SizedBox(height: 8),
              ...sellable.map((item) => _SellableCard(item: item)),
            ],
          ],
        );
      },
    );
  }
}

class _RollerSellCard extends StatelessWidget {
  final RollerInventoryItem item;
  final bool canSell;
  const _RollerSellCard({required this.item, required this.canSell});

  @override
  Widget build(BuildContext context) {
    final tierColor = AppColors.colorForTier(item.colorTier);
    final paintColor = Color(item.colorHex);
    final skinDef = GameService.rollerSkinDefs.where((s) => s.id == item.rollerId).firstOrNull;
    final colorDef = getPaintColorById(item.colorId);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.brownDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tierColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          _RollerIconBadge(rollerId: item.rollerId, colorHex: item.colorHex, tierColor: tierColor, size: 42),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${skinDef?.name ?? item.rollerId} - ${colorDef?.name ?? item.colorId}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(color: tierColor.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                    child: Text(item.colorTier.name.toUpperCase(), style: TextStyle(color: tierColor, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 6),
                  Text('x${item.count}', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                ]),
              ],
            ),
          ),
          GestureDetector(
            onTap: canSell ? () => _showListDialog(context) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: canSell ? AppColors.purpleAccent.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                canSell ? 'List' : 'Equipped',
                style: TextStyle(
                  color: canSell ? AppColors.purpleAccent : Colors.white24,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showListDialog(BuildContext context) {
    final ctrl = TextEditingController(text: '10');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.brownDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('List on Market', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Set your gem price:', style: TextStyle(color: Colors.white.withOpacity(0.7))),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 4),
                  child: Image.asset('assets/images/UI/diamond250.png', width: 20, height: 20),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.purpleAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final price = int.tryParse(ctrl.text) ?? 10;
              final gs = Provider.of<GameService>(context, listen: false);
              final mp = Provider.of<MarketplaceService>(context, listen: false);
              final fee = gs.progress.marketplaceFeePercent;

              final removed = gs.removeRollerItem(item.rollerId, item.colorId);
              if (!removed) return;

              final err = await mp.listRollerItem(
                rollerId: item.rollerId,
                colorId: item.colorId,
                priceGems: price,
                feePercent: fee,
                colorTier: item.colorTier.name,
                colorHex: item.colorHex,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(err ?? 'Listed!'),
                    backgroundColor: err == null ? AppColors.secondary : Colors.red,
                  ),
                );
              }
            },
            child: const Text('List'),
          ),
        ],
      ),
    );
  }
}

class _MyListingCard extends StatelessWidget {
  final MarketplaceListing listing;
  const _MyListingCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    final isRoller = listing.item.isRollerItem;
    final name = isRoller
        ? _rollerDisplayName(listing.item.rollerId!, listing.item.colorId)
        : (listing.item.itemType?.name ?? listing.item.itemTypeId);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.brownDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Image.asset('assets/images/UI/diamond250.png', width: 12, height: 12),
                    const SizedBox(width: 3),
                    Text('${listing.priceGems}  \u{2022}  Fee: ${listing.feePercent.toStringAsFixed(0)}%',
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              HapticFeedback.lightImpact();
              final mp = Provider.of<MarketplaceService>(context, listen: false);
              final err = await mp.cancelListing(listing.listingId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(err ?? 'Listing cancelled'), backgroundColor: err == null ? AppColors.secondary : Colors.red, duration: const Duration(seconds: 1)),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: const Text('Cancel', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SellableCard extends StatelessWidget {
  final SerializedItem item;
  const _SellableCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final name = item.itemType?.name ?? item.itemTypeId;
    final base = item.itemType?.basePrice ?? 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.brownDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.progressionBrown),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text('Suggested: ', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                    Image.asset('assets/images/UI/diamond250.png', width: 12, height: 12),
                    const SizedBox(width: 2),
                    Text('$base', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showListDialog(context, base),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: AppColors.purpleAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: const Text('List', style: TextStyle(color: AppColors.purpleAccent, fontWeight: FontWeight.w600, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  void _showListDialog(BuildContext context, int suggested) {
    final ctrl = TextEditingController(text: '$suggested');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.brownDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('List on Market', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Set your gem price:', style: TextStyle(color: Colors.white.withOpacity(0.7))),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 4),
                  child: Image.asset('assets/images/UI/diamond250.png', width: 20, height: 20),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.purpleAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final price = int.tryParse(ctrl.text) ?? suggested;
              final mp = Provider.of<MarketplaceService>(context, listen: false);
              final gs = Provider.of<GameService>(context, listen: false);
              final fee = gs.progress.marketplaceFeePercent;
              final err = await mp.listItem(item.instanceId, price, fee);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: err != null
                        ? Text(err)
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Listed for '),
                              Image.asset('assets/images/UI/diamond250.png', width: 14, height: 14),
                              Text('$price!'),
                            ],
                          ),
                    backgroundColor: err == null ? AppColors.secondary : Colors.red,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('List'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// INDEX TICKER
// =============================================================================

class _IndexTicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MarketplaceService>(
      builder: (context, mp, _) {
        final prices = mp.indexPrices;
        final display = prices.entries.take(4).toList();
        if (display.isEmpty) {
          return _staticTicker();
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: AppColors.brownDark,
            border: Border(top: BorderSide(color: AppColors.progressionBrown)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: display.map((e) {
              final t = MarketplaceItemType.getById(e.key);
              final short = t?.name.split(' ').first ?? e.key;
              return Row(mainAxisSize: MainAxisSize.min, children: [
                Text(short, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11)),
                const SizedBox(width: 4),
                Image.asset('assets/images/UI/diamond250.png', width: 10, height: 10),
                const SizedBox(width: 2),
                Text(e.value.toStringAsFixed(0),
                    style: const TextStyle(color: AppColors.purpleAccent, fontWeight: FontWeight.w600, fontSize: 11)),
              ]);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _staticTicker() {
    const items = [('Neon', '10'), ('Gold', '5'), ('Money', '25'), ('Crown', '100')];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.brownDark,
        border: Border(top: BorderSide(color: AppColors.progressionBrown)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((t) {
          return Row(mainAxisSize: MainAxisSize.min, children: [
            Text(t.$1, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11)),
            const SizedBox(width: 4),
            Image.asset('assets/images/UI/diamond250.png', width: 10, height: 10),
            const SizedBox(width: 2),
            Text(t.$2, style: const TextStyle(color: AppColors.purpleAccent, fontWeight: FontWeight.w600, fontSize: 11)),
          ]);
        }).toList(),
      ),
    );
  }
}

// =============================================================================
// SHARED WIDGETS
// =============================================================================

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.brownDark.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(color: AppColors.brownDark.withOpacity(0.5), fontSize: 15)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: AppColors.brownDark.withOpacity(0.35), fontSize: 12)),
        ],
      ),
    );
  }
}

/// Small icon showing a roller image with a color swatch dot.
class _RollerIconBadge extends StatelessWidget {
  final String rollerId;
  final int? colorHex;
  final Color tierColor;
  final double size;
  const _RollerIconBadge({required this.rollerId, this.colorHex, required this.tierColor, this.size = 42});

  @override
  Widget build(BuildContext context) {
    final skinDef = GameService.rollerSkinDefs.where((s) => s.id == rollerId).firstOrNull;
    return SizedBox(
      width: size, height: size,
      child: Stack(
        children: [
          Container(
            width: size, height: size,
            decoration: BoxDecoration(
              color: tierColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: tierColor.withOpacity(0.4), width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: skinDef != null
                  ? Image.asset('assets/images/rollers/${skinDef.asset}', fit: BoxFit.contain)
                  : const Icon(Icons.brush, color: Colors.white38, size: 20),
            ),
          ),
          if (colorHex != null)
            Positioned(
              right: 1, bottom: 1,
              child: Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  color: Color(colorHex!),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _rollerDisplayName(String rollerId, String? colorId) {
  final skinDef = GameService.rollerSkinDefs.where((s) => s.id == rollerId).firstOrNull;
  final colorDef = colorId != null ? getPaintColorById(colorId) : null;
  final skinName = skinDef?.name ?? rollerId;
  final colorName = colorDef?.name ?? colorId ?? '';
  return '$skinName - $colorName';
}
