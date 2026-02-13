import 'dart:math';
import 'package:flutter/material.dart';

enum HouseType {
  dirtHouse,
  shack,
  trailer,
  cabin,
  bungalow,
  apartment,
  townhouse,
  duplex,
  cottage,
  villa,
  farmhouse,
  loft,
  mansion,
  penthouse,
  chateau,
  skyscraper,
  spaceStation,
  floatingPalace,
}

enum HouseRarity { common, uncommon, rare, epic, legendary }

class RoomDefinition {
  final String name;
  final Color wallColor;
  final Color dirtColor;
  final Color paintColor;

  const RoomDefinition({
    required this.name,
    required this.wallColor,
    required this.dirtColor,
    required this.paintColor,
  });
}

class HouseDefinition {
  final HouseType type;
  final String name;
  final String icon;
  final HouseRarity rarity;
  final int unlockPrestige;
  final List<RoomDefinition> rooms;

  const HouseDefinition({
    required this.type,
    required this.name,
    required this.icon,
    required this.rarity,
    required this.unlockPrestige,
    required this.rooms,
  });

  /// Wall scale derived from prestige level (exponential growth curve).
  static double wallScaleForPrestige(int prestigeLevel) {
    return 1.0 + 0.04 * pow(prestigeLevel, 1.6);
  }

  /// Base cash per wall scales with prestige so higher tiers reward more.
  static double baseCashForPrestige(int prestigeLevel) {
    return 10.0 * (1.0 + 0.5 * prestigeLevel);
  }

  /// Get a house definition by its type.
  static HouseDefinition getByType(HouseType type) {
    return all.firstWhere((h) => h.type == type);
  }

  /// Get all houses unlocked at a given prestige level.
  static List<HouseDefinition> unlockedAt(int prestigeLevel) {
    return all.where((h) => h.unlockPrestige <= prestigeLevel).toList();
  }

  /// Select a random house weighted toward recently-unlocked tiers.
  /// Higher-tier houses get exponentially more weight; lower-tier houses
  /// become increasingly rare but never fully disappear.
  static HouseDefinition selectRandomHouse(int prestigeLevel, Random rng) {
    final eligible = unlockedAt(prestigeLevel);
    if (eligible.isEmpty) return all.first;

    final maxUnlock = eligible.map((h) => h.unlockPrestige).reduce(max);

    final weights = <double>[];
    for (final house in eligible) {
      final distance = maxUnlock - house.unlockPrestige;
      // Exponential decay: each step below top multiplies by 0.6
      final weight = max(0.5, 10.0 * pow(0.6, distance)).toDouble();
      weights.add(weight);
    }

    final totalWeight = weights.reduce((a, b) => a + b);
    var roll = rng.nextDouble() * totalWeight;
    for (int i = 0; i < eligible.length; i++) {
      roll -= weights[i];
      if (roll <= 0) return eligible[i];
    }
    return eligible.last;
  }

  // ---------------------------------------------------------------------------
  // All 18 house definitions
  // ---------------------------------------------------------------------------
  static const List<HouseDefinition> all = [
    // ── Common (unlock at prestige 0) ──────────────────────────────────────
    HouseDefinition(
      type: HouseType.dirtHouse,
      name: 'Dirt House',
      icon: '\u{1F3DA}\u{FE0F}',
      rarity: HouseRarity.common,
      unlockPrestige: 0,
      rooms: [
        RoomDefinition(name: 'Mud Room', wallColor: Color(0xFF8B7355), dirtColor: Color(0xFF6B5340), paintColor: Color(0xFFA89070)),
        RoomDefinition(name: 'Crawl Space', wallColor: Color(0xFF7A6548), dirtColor: Color(0xFF5C4A33), paintColor: Color(0xFF9A8060)),
        RoomDefinition(name: 'Root Cellar', wallColor: Color(0xFF6E5B3E), dirtColor: Color(0xFF50412C), paintColor: Color(0xFF8E7555)),
        RoomDefinition(name: 'Sleeping Nook', wallColor: Color(0xFF8A7050), dirtColor: Color(0xFF6A5238), paintColor: Color(0xFFA58C68)),
        RoomDefinition(name: 'Fire Pit', wallColor: Color(0xFF7F6B4A), dirtColor: Color(0xFF5F4D35), paintColor: Color(0xFF9F8560)),
      ],
    ),
    HouseDefinition(
      type: HouseType.shack,
      name: 'Shack',
      icon: '\u{1FAB5}',
      rarity: HouseRarity.common,
      unlockPrestige: 0,
      rooms: [
        RoomDefinition(name: 'Main Room', wallColor: Color(0xFF9E8B6E), dirtColor: Color(0xFF7A6850), paintColor: Color(0xFFB8A585)),
        RoomDefinition(name: 'Storage Corner', wallColor: Color(0xFF917D60), dirtColor: Color(0xFF6F5E45), paintColor: Color(0xFFAB9878)),
        RoomDefinition(name: 'Lean-To', wallColor: Color(0xFF968268), dirtColor: Color(0xFF74634C), paintColor: Color(0xFFB09C80)),
        RoomDefinition(name: 'Porch', wallColor: Color(0xFFA28E72), dirtColor: Color(0xFF806C55), paintColor: Color(0xFFBCA88A)),
        RoomDefinition(name: 'Loft', wallColor: Color(0xFF8E7A5C), dirtColor: Color(0xFF6C5B42), paintColor: Color(0xFFA89472)),
      ],
    ),
    HouseDefinition(
      type: HouseType.trailer,
      name: 'Trailer',
      icon: '\u{1F690}',
      rarity: HouseRarity.common,
      unlockPrestige: 0,
      rooms: [
        RoomDefinition(name: 'Kitchen Nook', wallColor: Color(0xFFD0CBC0), dirtColor: Color(0xFFA8A090), paintColor: Color(0xFFE5E0D8)),
        RoomDefinition(name: 'Sleeping Area', wallColor: Color(0xFFC5C0B5), dirtColor: Color(0xFF9E9888), paintColor: Color(0xFFDDD8D0)),
        RoomDefinition(name: 'Bathroom', wallColor: Color(0xFFCCC8BE), dirtColor: Color(0xFFA5A095), paintColor: Color(0xFFE2DDD5)),
        RoomDefinition(name: 'Dinette', wallColor: Color(0xFFD2CCC2), dirtColor: Color(0xFFAAA498), paintColor: Color(0xFFE8E2DA)),
        RoomDefinition(name: 'Storage', wallColor: Color(0xFFC8C4BA), dirtColor: Color(0xFFA09C90), paintColor: Color(0xFFDCD8D0)),
      ],
    ),
    HouseDefinition(
      type: HouseType.cabin,
      name: 'Cabin',
      icon: '\u{1F3E0}',
      rarity: HouseRarity.common,
      unlockPrestige: 0,
      rooms: [
        RoomDefinition(name: 'Living Area', wallColor: Color(0xFFB89E78), dirtColor: Color(0xFF8E7858), paintColor: Color(0xFFD2B890)),
        RoomDefinition(name: 'Bedroom', wallColor: Color(0xFFAD9570), dirtColor: Color(0xFF857060), paintColor: Color(0xFFC8AF88)),
        RoomDefinition(name: 'Kitchen', wallColor: Color(0xFFB49A75), dirtColor: Color(0xFF8A7555), paintColor: Color(0xFFCEB48C)),
        RoomDefinition(name: 'Bathroom', wallColor: Color(0xFFA89068), dirtColor: Color(0xFF806B50), paintColor: Color(0xFFC2AA80)),
        RoomDefinition(name: 'Porch', wallColor: Color(0xFFBA9F7A), dirtColor: Color(0xFF907A5A), paintColor: Color(0xFFD4BA92)),
      ],
    ),
    HouseDefinition(
      type: HouseType.bungalow,
      name: 'Bungalow',
      icon: '\u{1F3E1}',
      rarity: HouseRarity.common,
      unlockPrestige: 0,
      rooms: [
        RoomDefinition(name: 'Living Room', wallColor: Color(0xFFD8CDB8), dirtColor: Color(0xFFB0A48C), paintColor: Color(0xFFF0E8D5)),
        RoomDefinition(name: 'Bedroom', wallColor: Color(0xFFCEC4AE), dirtColor: Color(0xFFA89C85), paintColor: Color(0xFFE8E0CC)),
        RoomDefinition(name: 'Kitchen', wallColor: Color(0xFFD4C8B2), dirtColor: Color(0xFFACA088), paintColor: Color(0xFFECE4D0)),
        RoomDefinition(name: 'Bath', wallColor: Color(0xFFD0C6B0), dirtColor: Color(0xFFA89E88), paintColor: Color(0xFFE8E0CE)),
        RoomDefinition(name: 'Patio', wallColor: Color(0xFFDCD0BA), dirtColor: Color(0xFFB4A890), paintColor: Color(0xFFF2EAD8)),
      ],
    ),

    // ── Uncommon (unlock at prestige 1-4) ──────────────────────────────────
    HouseDefinition(
      type: HouseType.apartment,
      name: 'Apartment',
      icon: '\u{1F3E2}',
      rarity: HouseRarity.uncommon,
      unlockPrestige: 1,
      rooms: [
        RoomDefinition(name: 'Living Room', wallColor: Color(0xFFE8DCC8), dirtColor: Color(0xFFC4A882), paintColor: Color(0xFFF5F0E8)),
        RoomDefinition(name: 'Bedroom', wallColor: Color(0xFFD5C4A1), dirtColor: Color(0xFFB89E6E), paintColor: Color(0xFFEDE5D4)),
        RoomDefinition(name: 'Kitchen', wallColor: Color(0xFFE0D5C0), dirtColor: Color(0xFFBFA87A), paintColor: Color(0xFFF2ECE0)),
        RoomDefinition(name: 'Bathroom', wallColor: Color(0xFFD8CEB5), dirtColor: Color(0xFFBCA57C), paintColor: Color(0xFFEFE8DA)),
        RoomDefinition(name: 'Hallway', wallColor: Color(0xFFDDD2BD), dirtColor: Color(0xFFC1AB83), paintColor: Color(0xFFF0EAE0)),
      ],
    ),
    HouseDefinition(
      type: HouseType.townhouse,
      name: 'Townhouse',
      icon: '\u{1F3D8}\u{FE0F}',
      rarity: HouseRarity.uncommon,
      unlockPrestige: 2,
      rooms: [
        RoomDefinition(name: 'Foyer', wallColor: Color(0xFFCDD5D0), dirtColor: Color(0xFF99A89E), paintColor: Color(0xFFE8F0EB)),
        RoomDefinition(name: 'Dining Room', wallColor: Color(0xFFD0C8C0), dirtColor: Color(0xFFA09488), paintColor: Color(0xFFEDE8E3)),
        RoomDefinition(name: 'Study', wallColor: Color(0xFFC5CDD5), dirtColor: Color(0xFF8E9EAA), paintColor: Color(0xFFE3EAF0)),
        RoomDefinition(name: 'Master Bed', wallColor: Color(0xFFD5CDD0), dirtColor: Color(0xFFA89CA0), paintColor: Color(0xFFF0EAED)),
        RoomDefinition(name: 'Garage', wallColor: Color(0xFFCCC8C5), dirtColor: Color(0xFF9A9590), paintColor: Color(0xFFE8E5E3)),
      ],
    ),
    HouseDefinition(
      type: HouseType.duplex,
      name: 'Duplex',
      icon: '\u{1F3E3}',
      rarity: HouseRarity.uncommon,
      unlockPrestige: 3,
      rooms: [
        RoomDefinition(name: 'Unit A Living', wallColor: Color(0xFFD5CCC5), dirtColor: Color(0xFFA89890), paintColor: Color(0xFFEDE5E0)),
        RoomDefinition(name: 'Unit A Bedroom', wallColor: Color(0xFFCBC2BB), dirtColor: Color(0xFF9E908A), paintColor: Color(0xFFE5DCD8)),
        RoomDefinition(name: 'Unit B Living', wallColor: Color(0xFFD0C8C2), dirtColor: Color(0xFFA49590), paintColor: Color(0xFFEAE2DD)),
        RoomDefinition(name: 'Unit B Bedroom', wallColor: Color(0xFFCEC5BE), dirtColor: Color(0xFFA09288), paintColor: Color(0xFFE8E0DA)),
        RoomDefinition(name: 'Shared Hall', wallColor: Color(0xFFD2CAC4), dirtColor: Color(0xFFA6988E), paintColor: Color(0xFFECE4DE)),
      ],
    ),
    HouseDefinition(
      type: HouseType.cottage,
      name: 'Cottage',
      icon: '\u{26FA}',
      rarity: HouseRarity.uncommon,
      unlockPrestige: 4,
      rooms: [
        RoomDefinition(name: 'Parlor', wallColor: Color(0xFFC8D5C8), dirtColor: Color(0xFF95A895), paintColor: Color(0xFFE2F0E2)),
        RoomDefinition(name: 'Bedroom', wallColor: Color(0xFFD0D8C8), dirtColor: Color(0xFF9EA890), paintColor: Color(0xFFEAF2E2)),
        RoomDefinition(name: 'Kitchen', wallColor: Color(0xFFCCD4C5), dirtColor: Color(0xFF98A590), paintColor: Color(0xFFE5EEE0)),
        RoomDefinition(name: 'Garden Room', wallColor: Color(0xFFC5D2C0), dirtColor: Color(0xFF90A288), paintColor: Color(0xFFE0EDD8)),
        RoomDefinition(name: 'Attic', wallColor: Color(0xFFD2D8CC), dirtColor: Color(0xFFA0AA95), paintColor: Color(0xFFECF2E6)),
      ],
    ),

    // ── Rare (unlock at prestige 6-10) ─────────────────────────────────────
    HouseDefinition(
      type: HouseType.villa,
      name: 'Villa',
      icon: '\u{1F3E8}',
      rarity: HouseRarity.rare,
      unlockPrestige: 6,
      rooms: [
        RoomDefinition(name: 'Grand Hall', wallColor: Color(0xFFE0D0C0), dirtColor: Color(0xFFB89E82), paintColor: Color(0xFFFFF5EB)),
        RoomDefinition(name: 'Library', wallColor: Color(0xFFD0C0B0), dirtColor: Color(0xFFA88E78), paintColor: Color(0xFFF0E5DA)),
        RoomDefinition(name: 'Sun Room', wallColor: Color(0xFFE5DDD0), dirtColor: Color(0xFFC0B098), paintColor: Color(0xFFFFF8F0)),
        RoomDefinition(name: 'Wine Cellar', wallColor: Color(0xFFC8BDB0), dirtColor: Color(0xFF9A8A78), paintColor: Color(0xFFE5DDD5)),
        RoomDefinition(name: 'Pool House', wallColor: Color(0xFFD0D8E0), dirtColor: Color(0xFF98A8B8), paintColor: Color(0xFFECF2F8)),
      ],
    ),
    HouseDefinition(
      type: HouseType.farmhouse,
      name: 'Farmhouse',
      icon: '\u{1F33E}',
      rarity: HouseRarity.rare,
      unlockPrestige: 8,
      rooms: [
        RoomDefinition(name: 'Kitchen', wallColor: Color(0xFFDDD0B8), dirtColor: Color(0xFFB5A488), paintColor: Color(0xFFF5ECD5)),
        RoomDefinition(name: 'Parlor', wallColor: Color(0xFFD5C8B0), dirtColor: Color(0xFFAD9C80), paintColor: Color(0xFFEDE4CC)),
        RoomDefinition(name: 'Master Bed', wallColor: Color(0xFFD8CCB5), dirtColor: Color(0xFFB0A085), paintColor: Color(0xFFF0E8D0)),
        RoomDefinition(name: 'Barn Room', wallColor: Color(0xFFC8B898), dirtColor: Color(0xFFA08C6C), paintColor: Color(0xFFE2D5B5)),
        RoomDefinition(name: 'Root Cellar', wallColor: Color(0xFFD0C4A8), dirtColor: Color(0xFFA89878), paintColor: Color(0xFFE8DEC2)),
      ],
    ),
    HouseDefinition(
      type: HouseType.loft,
      name: 'Loft',
      icon: '\u{1F306}',
      rarity: HouseRarity.rare,
      unlockPrestige: 10,
      rooms: [
        RoomDefinition(name: 'Main Space', wallColor: Color(0xFFCCCCD0), dirtColor: Color(0xFF9898A0), paintColor: Color(0xFFE5E5EA)),
        RoomDefinition(name: 'Mezzanine', wallColor: Color(0xFFC5C5CC), dirtColor: Color(0xFF929298), paintColor: Color(0xFFE0E0E6)),
        RoomDefinition(name: 'Kitchen', wallColor: Color(0xFFD0D0D5), dirtColor: Color(0xFF9C9CA2), paintColor: Color(0xFFE8E8EE)),
        RoomDefinition(name: 'Bath', wallColor: Color(0xFFC8C8D0), dirtColor: Color(0xFF9595A0), paintColor: Color(0xFFE2E2EA)),
        RoomDefinition(name: 'Rooftop', wallColor: Color(0xFFD2D2D8), dirtColor: Color(0xFFA0A0A5), paintColor: Color(0xFFEAEAF0)),
      ],
    ),

    // ── Epic (unlock at prestige 12-18) ────────────────────────────────────
    HouseDefinition(
      type: HouseType.mansion,
      name: 'Mansion',
      icon: '\u{1F3F0}',
      rarity: HouseRarity.epic,
      unlockPrestige: 12,
      rooms: [
        RoomDefinition(name: 'Ballroom', wallColor: Color(0xFFE8DDD0), dirtColor: Color(0xFFC0AA90), paintColor: Color(0xFFFFF8F0)),
        RoomDefinition(name: 'Theater', wallColor: Color(0xFFD0C0C8), dirtColor: Color(0xFFA08898), paintColor: Color(0xFFF0E5EB)),
        RoomDefinition(name: 'Gallery', wallColor: Color(0xFFE0E0D8), dirtColor: Color(0xFFB0B0A0), paintColor: Color(0xFFFAFAF5)),
        RoomDefinition(name: 'Observatory', wallColor: Color(0xFFC8D0D8), dirtColor: Color(0xFF90A0B0), paintColor: Color(0xFFE5ECF2)),
        RoomDefinition(name: 'Master Suite', wallColor: Color(0xFFE0D5D0), dirtColor: Color(0xFFB8A8A0), paintColor: Color(0xFFFFF5F0)),
      ],
    ),
    HouseDefinition(
      type: HouseType.penthouse,
      name: 'Penthouse',
      icon: '\u{1F320}',
      rarity: HouseRarity.epic,
      unlockPrestige: 15,
      rooms: [
        RoomDefinition(name: 'Living Suite', wallColor: Color(0xFFE8E0D0), dirtColor: Color(0xFFC0B498), paintColor: Color(0xFFFFF8E8)),
        RoomDefinition(name: 'Master Wing', wallColor: Color(0xFFE0D8C8), dirtColor: Color(0xFFB8AC90), paintColor: Color(0xFFFFF5E2)),
        RoomDefinition(name: 'Sky Terrace', wallColor: Color(0xFFDDD5C5), dirtColor: Color(0xFFB5A88C), paintColor: Color(0xFFF8F0E0)),
        RoomDefinition(name: 'Chef Kitchen', wallColor: Color(0xFFE2DACC), dirtColor: Color(0xFFBAB094), paintColor: Color(0xFFFAF4E5)),
        RoomDefinition(name: 'Spa Room', wallColor: Color(0xFFDED6C8), dirtColor: Color(0xFFB6AA90), paintColor: Color(0xFFF6F0E2)),
      ],
    ),
    HouseDefinition(
      type: HouseType.chateau,
      name: 'Chateau',
      icon: '\u{1F3EF}',
      rarity: HouseRarity.epic,
      unlockPrestige: 18,
      rooms: [
        RoomDefinition(name: 'Grand Foyer', wallColor: Color(0xFFD0C0B8), dirtColor: Color(0xFFA88E82), paintColor: Color(0xFFECDDD5)),
        RoomDefinition(name: 'Banquet Hall', wallColor: Color(0xFFC8B8B0), dirtColor: Color(0xFFA08878), paintColor: Color(0xFFE5D5CC)),
        RoomDefinition(name: 'Conservatory', wallColor: Color(0xFFCCC0B5), dirtColor: Color(0xFFA48C80), paintColor: Color(0xFFE8DCD2)),
        RoomDefinition(name: 'Tower Room', wallColor: Color(0xFFD2C4BA), dirtColor: Color(0xFFAA9085), paintColor: Color(0xFFEEE0D8)),
        RoomDefinition(name: 'Wine Cave', wallColor: Color(0xFFC5B5AB), dirtColor: Color(0xFF9C8578), paintColor: Color(0xFFE0D2C8)),
      ],
    ),

    // ── Legendary (unlock at prestige 22-30) ───────────────────────────────
    HouseDefinition(
      type: HouseType.skyscraper,
      name: 'Skyscraper',
      icon: '\u{1F3D9}\u{FE0F}',
      rarity: HouseRarity.legendary,
      unlockPrestige: 22,
      rooms: [
        RoomDefinition(name: 'Lobby', wallColor: Color(0xFFD8D8E0), dirtColor: Color(0xFFA0A0B0), paintColor: Color(0xFFF2F2F8)),
        RoomDefinition(name: 'Penthouse', wallColor: Color(0xFFE0D8D0), dirtColor: Color(0xFFB8A898), paintColor: Color(0xFFFFF5F0)),
        RoomDefinition(name: 'Rooftop Bar', wallColor: Color(0xFFD0D0D8), dirtColor: Color(0xFF9898A8), paintColor: Color(0xFFECECF5)),
        RoomDefinition(name: 'Executive Suite', wallColor: Color(0xFFD8D0C8), dirtColor: Color(0xFFA89888), paintColor: Color(0xFFF5F0E8)),
        RoomDefinition(name: 'Sky Garden', wallColor: Color(0xFFD0D8D0), dirtColor: Color(0xFF98A898), paintColor: Color(0xFFECF5EC)),
      ],
    ),
    HouseDefinition(
      type: HouseType.spaceStation,
      name: 'Space Station',
      icon: '\u{1F6F8}',
      rarity: HouseRarity.legendary,
      unlockPrestige: 26,
      rooms: [
        RoomDefinition(name: 'Command Bridge', wallColor: Color(0xFFC0C8D5), dirtColor: Color(0xFF8890A5), paintColor: Color(0xFFDDE4F0)),
        RoomDefinition(name: 'Crew Quarters', wallColor: Color(0xFFB8C0D0), dirtColor: Color(0xFF808AA0), paintColor: Color(0xFFD5DDEC)),
        RoomDefinition(name: 'Lab Module', wallColor: Color(0xFFC5CCD8), dirtColor: Color(0xFF8C94A8), paintColor: Color(0xFFE0E6F2)),
        RoomDefinition(name: 'Airlock Bay', wallColor: Color(0xFFBCC4D2), dirtColor: Color(0xFF848CA2), paintColor: Color(0xFFD8E0EE)),
        RoomDefinition(name: 'Observation Deck', wallColor: Color(0xFFC8D0DD), dirtColor: Color(0xFF9098AB), paintColor: Color(0xFFE4EAF5)),
      ],
    ),
    HouseDefinition(
      type: HouseType.floatingPalace,
      name: 'Floating Palace',
      icon: '\u{2601}\u{FE0F}',
      rarity: HouseRarity.legendary,
      unlockPrestige: 30,
      rooms: [
        RoomDefinition(name: 'Throne Room', wallColor: Color(0xFFE0E5F0), dirtColor: Color(0xFFB0B8CC), paintColor: Color(0xFFF5F8FF)),
        RoomDefinition(name: 'Cloud Garden', wallColor: Color(0xFFD8E0ED), dirtColor: Color(0xFFA8B2C5), paintColor: Color(0xFFF0F5FC)),
        RoomDefinition(name: 'Crystal Hall', wallColor: Color(0xFFDDE2F0), dirtColor: Color(0xFFADB5C8), paintColor: Color(0xFFF2F6FF)),
        RoomDefinition(name: 'Star Chamber', wallColor: Color(0xFFD5DCE8), dirtColor: Color(0xFFA5AEC0), paintColor: Color(0xFFEEF2FA)),
        RoomDefinition(name: 'Infinity Pool', wallColor: Color(0xFFDAE2F0), dirtColor: Color(0xFFAAB4C8), paintColor: Color(0xFFF0F5FE)),
      ],
    ),
  ];
}
