import 'package:flutter/material.dart';

enum HouseTier {
  apartment,
  townhouse,
  villa,
  mansion,
  skyscraper,
}

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
  final HouseTier tier;
  final String name;
  final String icon;
  final double baseCashPerWall;
  final List<RoomDefinition> rooms;

  const HouseDefinition({
    required this.tier,
    required this.name,
    required this.icon,
    required this.baseCashPerWall,
    required this.rooms,
  });

  static const List<HouseDefinition> all = [
    HouseDefinition(
      tier: HouseTier.apartment,
      name: 'Apartment',
      icon: '🏢',
      baseCashPerWall: 10,
      rooms: [
        RoomDefinition(name: 'Living Room', wallColor: Color(0xFFE8DCC8), dirtColor: Color(0xFFC4A882), paintColor: Color(0xFFF5F0E8)),
        RoomDefinition(name: 'Bedroom', wallColor: Color(0xFFD5C4A1), dirtColor: Color(0xFFB89E6E), paintColor: Color(0xFFEDE5D4)),
        RoomDefinition(name: 'Kitchen', wallColor: Color(0xFFE0D5C0), dirtColor: Color(0xFFBFA87A), paintColor: Color(0xFFF2ECE0)),
        RoomDefinition(name: 'Bathroom', wallColor: Color(0xFFD8CEB5), dirtColor: Color(0xFFBCA57C), paintColor: Color(0xFFEFE8DA)),
        RoomDefinition(name: 'Hallway', wallColor: Color(0xFFDDD2BD), dirtColor: Color(0xFFC1AB83), paintColor: Color(0xFFF0EAE0)),
      ],
    ),
    HouseDefinition(
      tier: HouseTier.townhouse,
      name: 'Townhouse',
      icon: '🏠',
      baseCashPerWall: 25,
      rooms: [
        RoomDefinition(name: 'Foyer', wallColor: Color(0xFFCDD5D0), dirtColor: Color(0xFF99A89E), paintColor: Color(0xFFE8F0EB)),
        RoomDefinition(name: 'Dining Room', wallColor: Color(0xFFD0C8C0), dirtColor: Color(0xFFA09488), paintColor: Color(0xFFEDE8E3)),
        RoomDefinition(name: 'Study', wallColor: Color(0xFFC5CDD5), dirtColor: Color(0xFF8E9EAA), paintColor: Color(0xFFE3EAF0)),
        RoomDefinition(name: 'Master Bed', wallColor: Color(0xFFD5CDD0), dirtColor: Color(0xFFA89CA0), paintColor: Color(0xFFF0EAED)),
        RoomDefinition(name: 'Garage', wallColor: Color(0xFFCCC8C5), dirtColor: Color(0xFF9A9590), paintColor: Color(0xFFE8E5E3)),
      ],
    ),
    HouseDefinition(
      tier: HouseTier.villa,
      name: 'Villa',
      icon: '🏡',
      baseCashPerWall: 60,
      rooms: [
        RoomDefinition(name: 'Grand Hall', wallColor: Color(0xFFE0D0C0), dirtColor: Color(0xFFB89E82), paintColor: Color(0xFFFFF5EB)),
        RoomDefinition(name: 'Library', wallColor: Color(0xFFD0C0B0), dirtColor: Color(0xFFA88E78), paintColor: Color(0xFFF0E5DA)),
        RoomDefinition(name: 'Sun Room', wallColor: Color(0xFFE5DDD0), dirtColor: Color(0xFFC0B098), paintColor: Color(0xFFFFF8F0)),
        RoomDefinition(name: 'Wine Cellar', wallColor: Color(0xFFC8BDB0), dirtColor: Color(0xFF9A8A78), paintColor: Color(0xFFE5DDD5)),
        RoomDefinition(name: 'Pool House', wallColor: Color(0xFFD0D8E0), dirtColor: Color(0xFF98A8B8), paintColor: Color(0xFFECF2F8)),
      ],
    ),
    HouseDefinition(
      tier: HouseTier.mansion,
      name: 'Mansion',
      icon: '🏰',
      baseCashPerWall: 150,
      rooms: [
        RoomDefinition(name: 'Ballroom', wallColor: Color(0xFFE8DDD0), dirtColor: Color(0xFFC0AA90), paintColor: Color(0xFFFFF8F0)),
        RoomDefinition(name: 'Theater', wallColor: Color(0xFFD0C0C8), dirtColor: Color(0xFFA08898), paintColor: Color(0xFFF0E5EB)),
        RoomDefinition(name: 'Gallery', wallColor: Color(0xFFE0E0D8), dirtColor: Color(0xFFB0B0A0), paintColor: Color(0xFFFAFAF5)),
        RoomDefinition(name: 'Observatory', wallColor: Color(0xFFC8D0D8), dirtColor: Color(0xFF90A0B0), paintColor: Color(0xFFE5ECF2)),
        RoomDefinition(name: 'Master Suite', wallColor: Color(0xFFE0D5D0), dirtColor: Color(0xFFB8A8A0), paintColor: Color(0xFFFFF5F0)),
      ],
    ),
    HouseDefinition(
      tier: HouseTier.skyscraper,
      name: 'Skyscraper',
      icon: '🏙️',
      baseCashPerWall: 400,
      rooms: [
        RoomDefinition(name: 'Lobby', wallColor: Color(0xFFD8D8E0), dirtColor: Color(0xFFA0A0B0), paintColor: Color(0xFFF2F2F8)),
        RoomDefinition(name: 'Penthouse', wallColor: Color(0xFFE0D8D0), dirtColor: Color(0xFFB8A898), paintColor: Color(0xFFFFF5F0)),
        RoomDefinition(name: 'Rooftop Bar', wallColor: Color(0xFFD0D0D8), dirtColor: Color(0xFF9898A8), paintColor: Color(0xFFECECF5)),
        RoomDefinition(name: 'Executive Suite', wallColor: Color(0xFFD8D0C8), dirtColor: Color(0xFFA89888), paintColor: Color(0xFFF5F0E8)),
        RoomDefinition(name: 'Sky Garden', wallColor: Color(0xFFD0D8D0), dirtColor: Color(0xFF98A898), paintColor: Color(0xFFECF5EC)),
      ],
    ),
  ];

  static HouseDefinition getDefinition(HouseTier tier) {
    return all.firstWhere((h) => h.tier == tier);
  }

  static HouseTier? nextTier(HouseTier current) {
    final idx = HouseTier.values.indexOf(current);
    if (idx >= HouseTier.values.length - 1) return null;
    return HouseTier.values[idx + 1];
  }
}
