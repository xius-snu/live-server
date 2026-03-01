import '../config/game_config.dart';

class RollerInventoryItem {
  final String rollerId;
  final String colorId;
  final ColorTier colorTier;
  final int colorHex;
  int count;

  RollerInventoryItem({
    required this.rollerId,
    required this.colorId,
    required this.colorTier,
    required this.colorHex,
    this.count = 1,
  });

  /// Unique key for stacking: same roller + same color = same stack.
  String get stackKey => '${rollerId}_$colorId';

  Map<String, dynamic> toJson() => {
        'rollerId': rollerId,
        'colorId': colorId,
        'colorTier': colorTier.name,
        'colorHex': colorHex,
        'count': count,
      };

  factory RollerInventoryItem.fromJson(Map<String, dynamic> json) {
    ColorTier tier = ColorTier.common;
    try {
      tier = ColorTier.values.firstWhere((t) => t.name == json['colorTier']);
    } catch (_) {}
    return RollerInventoryItem(
      rollerId: json['rollerId'] as String? ?? 'default',
      colorId: json['colorId'] as String? ?? 'cherry_red',
      colorTier: tier,
      colorHex: json['colorHex'] as int? ?? 0xFFFF3B30,
      count: json['count'] as int? ?? 1,
    );
  }
}
