enum ItemCategory { paint, rollerSkin, consumable, collectible }

enum ItemRarity { common, uncommon, rare, epic, legendary }

class MarketplaceItemType {
  final String id;
  final String name;
  final ItemCategory category;
  final ItemRarity baseRarity;
  final String description;
  final String source;
  final int basePrice; // base star price for index calculation

  const MarketplaceItemType({
    required this.id,
    required this.name,
    required this.category,
    required this.baseRarity,
    required this.description,
    required this.source,
    this.basePrice = 1,
  });

  static const List<MarketplaceItemType> all = [
    MarketplaceItemType(
      id: 'basic_paint',
      name: 'Basic Paint Can',
      category: ItemCategory.paint,
      baseRarity: ItemRarity.common,
      description: 'Standard white paint.',
      source: 'Shop',
      basePrice: 1,
    ),
    MarketplaceItemType(
      id: 'premium_paint',
      name: 'Premium Paint Can',
      category: ItemCategory.paint,
      baseRarity: ItemRarity.uncommon,
      description: 'High-quality premium paint.',
      source: 'Shop (limited)',
      basePrice: 3,
    ),
    MarketplaceItemType(
      id: 'neon_paint',
      name: 'Neon Paint',
      category: ItemCategory.paint,
      baseRarity: ItemRarity.rare,
      description: 'Glowing neon paint. Event exclusive.',
      source: 'Event drop',
      basePrice: 10,
    ),
    MarketplaceItemType(
      id: 'glitter_finish',
      name: 'Glitter Finish',
      category: ItemCategory.paint,
      baseRarity: ItemRarity.rare,
      description: 'Sparkly glitter paint finish.',
      source: 'Event drop',
      basePrice: 12,
    ),
    MarketplaceItemType(
      id: 'gold_roller',
      name: 'Gold Roller Skin',
      category: ItemCategory.rollerSkin,
      baseRarity: ItemRarity.uncommon,
      description: 'A shiny golden paint roller.',
      source: 'Prestige reward',
      basePrice: 5,
    ),
    MarketplaceItemType(
      id: 'money_roller',
      name: 'Money Roller Skin',
      category: ItemCategory.rollerSkin,
      baseRarity: ItemRarity.epic,
      description: 'Roll in the dough. Literally.',
      source: 'Event drop',
      basePrice: 25,
    ),
    MarketplaceItemType(
      id: 'diamond_roller',
      name: 'Diamond Roller Skin',
      category: ItemCategory.rollerSkin,
      baseRarity: ItemRarity.legendary,
      description: 'The rarest roller. Marketplace only.',
      source: 'Marketplace',
      basePrice: 50,
    ),
    MarketplaceItemType(
      id: 'speed_boost',
      name: 'Speed Boost (1hr)',
      category: ItemCategory.consumable,
      baseRarity: ItemRarity.common,
      description: '2x cash for 1 hour.',
      source: 'Shop / Event',
      basePrice: 2,
    ),
    MarketplaceItemType(
      id: 'blueprint_penthouse',
      name: 'Blueprint: Penthouse',
      category: ItemCategory.collectible,
      baseRarity: ItemRarity.epic,
      description: 'Rare architectural blueprint.',
      source: 'Event drop',
      basePrice: 50,
    ),
    MarketplaceItemType(
      id: 'painters_crown',
      name: "Painter's Crown",
      category: ItemCategory.collectible,
      baseRarity: ItemRarity.legendary,
      description: 'Crown of the master painter.',
      source: 'Top prestige',
      basePrice: 100,
    ),
  ];

  static MarketplaceItemType? getById(String id) {
    try {
      return all.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }
}

class SerializedItem {
  final String instanceId;
  final String itemTypeId;
  final ItemRarity rarity;
  final DateTime mintedAt;
  String? ownerId;
  bool isListed;

  SerializedItem({
    required this.instanceId,
    required this.itemTypeId,
    required this.rarity,
    required this.mintedAt,
    this.ownerId,
    this.isListed = false,
  });

  MarketplaceItemType? get itemType => MarketplaceItemType.getById(itemTypeId);

  Map<String, dynamic> toJson() => {
        'instanceId': instanceId,
        'itemTypeId': itemTypeId,
        'rarity': rarity.name,
        'mintedAt': mintedAt.toIso8601String(),
        'ownerId': ownerId,
        'isListed': isListed,
      };

  factory SerializedItem.fromJson(Map<String, dynamic> json) {
    ItemRarity rarity = ItemRarity.common;
    try {
      rarity = ItemRarity.values.firstWhere((r) => r.name == json['rarity']);
    } catch (_) {}

    return SerializedItem(
      instanceId: json['instanceId'] ?? '',
      itemTypeId: json['itemTypeId'] ?? json['item_type_id'] ?? '',
      rarity: rarity,
      mintedAt: json['mintedAt'] != null
          ? DateTime.tryParse(json['mintedAt']) ?? DateTime.now()
          : DateTime.now(),
      ownerId: json['ownerId'] ?? json['owner_id'],
      isListed: json['isListed'] ?? json['is_listed'] ?? false,
    );
  }
}

class MarketplaceListing {
  final String listingId;
  final String sellerId;
  final String sellerName;
  final SerializedItem item;
  final int priceStars;
  final double feePercent;
  final DateTime listedAt;
  final String status; // 'active', 'sold', 'cancelled'

  MarketplaceListing({
    required this.listingId,
    required this.sellerId,
    required this.sellerName,
    required this.item,
    required this.priceStars,
    required this.feePercent,
    required this.listedAt,
    this.status = 'active',
  });

  int get feeStars => (priceStars * feePercent / 100).ceil();
  int get sellerReceives => priceStars - feeStars;

  factory MarketplaceListing.fromJson(Map<String, dynamic> json) {
    return MarketplaceListing(
      listingId: json['listingId'] ?? json['listing_id'] ?? '',
      sellerId: json['sellerId'] ?? json['seller_id'] ?? '',
      sellerName: json['sellerName'] ?? json['seller_name'] ?? 'Unknown',
      item: SerializedItem.fromJson(json['item'] ?? json),
      priceStars: json['priceStars'] ?? json['price_stars'] ?? 0,
      feePercent: (json['feePercent'] ?? json['listing_fee_percent'] ?? 5.0).toDouble(),
      listedAt: json['listedAt'] != null
          ? DateTime.tryParse(json['listedAt']) ?? DateTime.now()
          : DateTime.now(),
      status: json['status'] ?? 'active',
    );
  }
}
