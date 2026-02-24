import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/game_service.dart';
import '../services/marketplace_service.dart';
import '../models/marketplace_item.dart';

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
      backgroundColor: const Color(0xFFE8D5B8),
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
                      color: Color(0xFF6B5038),
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
                          color: const Color(0xFF4ADE80),
                        ),
                        const SizedBox(width: 6),
                        _CurrencyChip(
                          label: '${gs.gems}',
                          color: const Color(0xFFA855F7),
                          prefix: '\u{1F48E} ',
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
                  color: const Color(0xFF6B5038),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: const Color(0xFFE8734A),
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
  final String prefix;
  const _CurrencyChip({required this.label, required this.color, this.prefix = ''});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$prefix$label',
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}

// =============================================================================
// ROLLER SKIN SHOP
// =============================================================================

class _DefaultShopTab extends StatelessWidget {
  static String _fmtCommas(double n) {
    final whole = n.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) buf.write(',');
      buf.write(whole[i]);
    }
    return buf.toString();
  }

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
                'Paint Rollers',
                style: TextStyle(color: const Color(0xFF6B5038).withOpacity(0.5), fontSize: 12),
              ),
            ),
            ...skins.map((skin) {
              final owned = gs.ownsSkin(skin.id);
              final equipped = gs.equippedSkin == skin.id;
              final canAfford = gs.cash >= skin.price;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B5038),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: equipped
                        ? const Color(0xFF4ADE80)
                        : const Color(0xFF8B6B4F),
                    width: equipped ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Roller image
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
                    // Name
                    Expanded(
                      child: Text(
                        skin.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    // Action button
                    if (equipped)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4ADE80).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Equipped',
                          style: TextStyle(
                            color: Color(0xFF4ADE80),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      )
                    else if (owned)
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          gs.equipSkin(skin.id);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5C842),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Equip',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: canAfford
                            ? () {
                                HapticFeedback.mediumImpact();
                                final success = gs.purchaseSkin(skin.id);
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Bought ${skin.name}!'),
                                      duration: const Duration(seconds: 1),
                                      backgroundColor: const Color(0xFF4ADE80),
                                    ),
                                  );
                                }
                              }
                            : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: canAfford
                                ? const Color(0xFF4ADE80)
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
                                _fmtCommas(skin.price),
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
}

// =============================================================================
// COMMUNITY AUCTION HOUSE
// =============================================================================

class _AuctionTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MarketplaceService>(
      builder: (context, mp, _) {
        if (mp.loading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFE8734A)));
        }
        final listings = mp.communityListings;
        if (listings.isEmpty) {
          return const _EmptyState(icon: Icons.storefront_outlined, title: 'No listings yet', subtitle: 'Be the first to list an item!');
        }
        return RefreshIndicator(
          onRefresh: () => mp.fetchCommunityListings(),
          color: const Color(0xFFE8734A),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: listings.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text('Player-listed items. Trade with gems.',
                      style: TextStyle(color: const Color(0xFF6B5038).withOpacity(0.5), fontSize: 12)),
                );
              }
              return _AuctionCard(listing: listings[index - 1]);
            },
          ),
        );
      },
    );
  }
}

class _AuctionCard extends StatelessWidget {
  final MarketplaceListing listing;
  const _AuctionCard({required this.listing});

  Color get _rc {
    switch (listing.item.rarity) {
      case ItemRarity.common: return Colors.grey;
      case ItemRarity.uncommon: return const Color(0xFF4ADE80);
      case ItemRarity.rare: return const Color(0xFF3B82F6);
      case ItemRarity.epic: return const Color(0xFFA855F7);
      case ItemRarity.legendary: return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemType = listing.item.itemType;
    final name = itemType?.name ?? listing.item.itemTypeId;
    final idx = context.read<MarketplaceService>().indexPrices[listing.item.itemTypeId];
    final diff = idx != null ? ((listing.priceGems - idx) / idx * 100) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF6B5038),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8B6B4F)),
      ),
      child: Row(
        children: [
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
                        style: TextStyle(color: diff >= 0 ? const Color(0xFF4ADE80) : const Color(0xFFE8734A), fontWeight: FontWeight.w600, fontSize: 11)),
                  ],
                ]),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _confirmBuy(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFF5C842), borderRadius: BorderRadius.circular(8)),
              child: Text('\u{1F48E}${listing.priceGems}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmBuy(BuildContext context) {
    final name = listing.item.itemType?.name ?? listing.item.itemTypeId;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF6B5038),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Purchase', style: TextStyle(color: Colors.white)),
        content: Text('Buy $name for \u{1F48E}${listing.priceGems} gems?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF5C842), foregroundColor: Colors.black),
            onPressed: () async {
              Navigator.pop(ctx);
              final mp = Provider.of<MarketplaceService>(context, listen: false);
              final err = await mp.buyListing(listing.listingId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(err ?? 'Purchased $name!'), backgroundColor: err == null ? const Color(0xFF4ADE80) : Colors.red, duration: const Duration(seconds: 2)),
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
// INVENTORY
// =============================================================================

class _InventoryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MarketplaceService>(
      builder: (context, mp, _) {
        if (mp.loading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFE8734A)));
        }
        final items = mp.inventory;
        if (items.isEmpty) {
          return const _EmptyState(icon: Icons.inventory_2_outlined, title: 'Inventory empty', subtitle: 'Buy from the Shop or win items in Events');
        }
        return RefreshIndicator(
          onRefresh: () => mp.fetchInventory(),
          color: const Color(0xFFE8734A),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            itemBuilder: (context, index) => _InvCard(item: items[index]),
          ),
        );
      },
    );
  }
}

class _InvCard extends StatelessWidget {
  final SerializedItem item;
  const _InvCard({required this.item});

  Color get _rc {
    switch (item.rarity) {
      case ItemRarity.common: return Colors.grey;
      case ItemRarity.uncommon: return const Color(0xFF4ADE80);
      case ItemRarity.rare: return const Color(0xFF3B82F6);
      case ItemRarity.epic: return const Color(0xFFA855F7);
      case ItemRarity.legendary: return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemType = item.itemType;
    final name = itemType?.name ?? item.itemTypeId;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF6B5038),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _rc.withOpacity(0.3)),
      ),
      child: Row(
        children: [
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
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(color: _rc.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                    child: Text(item.rarity.name.toUpperCase(), style: TextStyle(color: _rc, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                  if (item.isListed) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: const Color(0xFFF5C842).withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                      child: Text('LISTED', style: TextStyle(color: const Color(0xFFF5C842).withOpacity(0.8), fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ]),
              ],
            ),
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
// SELL TAB
// =============================================================================

class _SellTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MarketplaceService>(
      builder: (context, mp, _) {
        final myListings = mp.myListings;
        final sellable = mp.unlistedInventory;
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            if (myListings.isNotEmpty) ...[
              Text('YOUR LISTINGS', style: TextStyle(color: const Color(0xFF6B5038).withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const SizedBox(height: 8),
              ...myListings.map((l) => _MyListingCard(listing: l)),
              const SizedBox(height: 20),
            ],
            Text('AVAILABLE TO LIST', style: TextStyle(color: const Color(0xFF6B5038).withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 8),
            if (sellable.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: _EmptyState(icon: Icons.sell_outlined, title: 'Nothing to sell', subtitle: 'Earn items through events and prestige'),
              )
            else
              ...sellable.map((item) => _SellableCard(item: item)),
          ],
        );
      },
    );
  }
}

class _MyListingCard extends StatelessWidget {
  final MarketplaceListing listing;
  const _MyListingCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    final name = listing.item.itemType?.name ?? listing.item.itemTypeId;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF6B5038),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF5C842).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text('\u{1F48E}${listing.priceGems}  \u{2022}  Fee: ${listing.feePercent.toStringAsFixed(0)}%',
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
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
                  SnackBar(content: Text(err ?? 'Listing cancelled'), backgroundColor: err == null ? const Color(0xFF4ADE80) : Colors.red, duration: const Duration(seconds: 1)),
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
        color: const Color(0xFF6B5038),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8B6B4F)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text('Suggested: \u{1F48E}$base', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showListDialog(context, base),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFFA855F7).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: const Text('List', style: TextStyle(color: Color(0xFFA855F7), fontWeight: FontWeight.w600, fontSize: 12)),
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
        backgroundColor: const Color(0xFF6B5038),
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
                prefixText: '\u{1F48E} ',
                prefixStyle: const TextStyle(fontSize: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA855F7), foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final price = int.tryParse(ctrl.text) ?? suggested;
              final mp = Provider.of<MarketplaceService>(context, listen: false);
              final gs = Provider.of<GameService>(context, listen: false);
              final fee = gs.progress.marketplaceFeePercent;
              final err = await mp.listItem(item.instanceId, price, fee);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(err ?? 'Listed for \u{1F48E}$price!'), backgroundColor: err == null ? const Color(0xFF4ADE80) : Colors.red, duration: const Duration(seconds: 2)),
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
            color: Color(0xFF6B5038),
            border: Border(top: BorderSide(color: Color(0xFF8B6B4F))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: display.map((e) {
              final t = MarketplaceItemType.getById(e.key);
              final short = t?.name.split(' ').first ?? e.key;
              return Row(mainAxisSize: MainAxisSize.min, children: [
                Text(short, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11)),
                const SizedBox(width: 4),
                Text('\u{1F48E}${e.value.toStringAsFixed(0)}',
                    style: const TextStyle(color: Color(0xFFA855F7), fontWeight: FontWeight.w600, fontSize: 11)),
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
        color: Color(0xFF6B5038),
        border: Border(top: BorderSide(color: Color(0xFF8B6B4F))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((t) {
          return Row(mainAxisSize: MainAxisSize.min, children: [
            Text(t.$1, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11)),
            const SizedBox(width: 4),
            Text('\u{1F48E}${t.$2}', style: const TextStyle(color: Color(0xFFA855F7), fontWeight: FontWeight.w600, fontSize: 11)),
          ]);
        }).toList(),
      ),
    );
  }
}

// =============================================================================
// SHARED
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
          Icon(icon, size: 64, color: const Color(0xFF6B5038).withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(color: const Color(0xFF6B5038).withOpacity(0.5), fontSize: 15)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: const Color(0xFF6B5038).withOpacity(0.35), fontSize: 12)),
        ],
      ),
    );
  }
}
