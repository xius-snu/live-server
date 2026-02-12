import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_service.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const Text(
                    'Marketplace',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Consumer<GameService>(
                    builder: (context, gs, _) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5C842).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('⭐', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(
                            '${gs.stars}',
                            style: const TextStyle(
                              color: Color(0xFFF5C842),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: const Color(0xFFE94560),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white38,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Browse'),
                    Tab(text: 'My Listings'),
                    Tab(text: 'Sell'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _BrowseTab(),
                  _MyListingsTab(),
                  _SellTab(),
                ],
              ),
            ),

            // Index ticker
            _IndexTicker(),
          ],
        ),
      ),
    );
  }
}

class _BrowseTab extends StatelessWidget {
  // Placeholder listings for prototype
  static final _mockListings = [
    _MockListing('Neon Paint', 'Rare', 'Player#429', 12, 10, '+20%'),
    _MockListing('Gold Roller Skin', 'Uncommon', 'Player#812', 4, 5, '-15%'),
    _MockListing('Speed Boost (1hr)', 'Common', 'Player#001', 2, 2, '0%'),
    _MockListing('Money Roller Skin', 'Epic', 'Player#055', 30, 25, '+18%'),
    _MockListing('Blueprint: Penthouse', 'Epic', 'Player#199', 55, 50, '+10%'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _mockListings.length,
      itemBuilder: (context, index) {
        final listing = _mockListings[index];
        return _ListingCard(listing: listing);
      },
    );
  }
}

class _MockListing {
  final String name;
  final String rarity;
  final String seller;
  final int price;
  final int indexPrice;
  final String trend;

  _MockListing(this.name, this.rarity, this.seller, this.price, this.indexPrice, this.trend);
}

class _ListingCard extends StatelessWidget {
  final _MockListing listing;
  const _ListingCard({required this.listing});

  Color get _rarityColor {
    switch (listing.rarity) {
      case 'Common': return Colors.grey;
      case 'Uncommon': return const Color(0xFF4ADE80);
      case 'Rare': return const Color(0xFF3B82F6);
      case 'Epic': return const Color(0xFFA855F7);
      case 'Legendary': return const Color(0xFFF59E0B);
      default: return Colors.grey;
    }
  }

  String get _icon {
    switch (listing.rarity) {
      case 'Common': return '⏩';
      case 'Uncommon': return '✨';
      case 'Rare': return '🎨';
      case 'Epic': return '💎';
      case 'Legendary': return '👑';
      default: return '📦';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A3A5E)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _rarityColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _rarityColor.withOpacity(0.4), width: 2),
            ),
            child: Center(child: Text(_icon, style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      listing.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: _rarityColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        listing.rarity,
                        style: TextStyle(
                          color: _rarityColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      '${listing.seller}  •  Index: ⭐${listing.indexPrice}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      listing.trend,
                      style: TextStyle(
                        color: listing.trend.startsWith('+')
                            ? const Color(0xFF4ADE80)
                            : listing.trend.startsWith('-')
                                ? const Color(0xFFE94560)
                                : Colors.white38,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Marketplace coming soon! Needs server connection.'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5C842),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '⭐${listing.price}',
                style: const TextStyle(
                  color: Colors.black,
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
}

class _MyListingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.storefront_outlined, size: 64, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 16),
          Text(
            'No active listings',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            'List items from the Sell tab',
            style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SellTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sell_outlined, size: 64, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 16),
          Text(
            'No items to sell',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            'Earn items through events and prestige',
            style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _IndexTicker extends StatelessWidget {
  static final _tickers = [
    ('Neon', 10, '+2'),
    ('Gold Skin', 5, '-1'),
    ('Money Skin', 25, '+4'),
    ('Blueprint', 50, '+5'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        border: Border(top: BorderSide(color: const Color(0xFF2A3A5E))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _tickers.map((t) {
          final (name, price, change) = t;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11)),
              const SizedBox(width: 4),
              Text('⭐$price', style: const TextStyle(color: Color(0xFFF5C842), fontWeight: FontWeight.w600, fontSize: 11)),
              const SizedBox(width: 3),
              Text(
                change,
                style: TextStyle(
                  color: change.startsWith('+') ? const Color(0xFF4ADE80) : const Color(0xFFE94560),
                  fontSize: 11,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
