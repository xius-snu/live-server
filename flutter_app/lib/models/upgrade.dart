import 'dart:math';

enum UpgradeType {
  widerRoller, // kept for save migration, not shown in UI
  turboSpeed,
  steadyHand,
  autoPainter,
  extraStroke,
  brokerLicense,
}

class UpgradeDefinition {
  final UpgradeType type;
  final String name;
  final String icon;
  final String description;
  /// Max level. -1 means uncapped (infinite).
  final int maxLevel;
  final double baseCost;
  final double costMultiplier;
  final String effectPerLevel;

  const UpgradeDefinition({
    required this.type,
    required this.name,
    required this.icon,
    required this.description,
    required this.maxLevel,
    required this.baseCost,
    required this.costMultiplier,
    required this.effectPerLevel,
  });

  bool get isUncapped => maxLevel == -1;

  bool isMaxed(int level) => !isUncapped && level >= maxLevel;

  double costForLevel(int level) {
    if (!isUncapped && level >= maxLevel) return double.infinity;
    return (baseCost * pow(costMultiplier, level)).roundToDouble();
  }

  String cumulativeEffect(int level) {
    switch (type) {
      case UpgradeType.widerRoller:
        return '+${level * 2}% width';
      case UpgradeType.turboSpeed:
        return '+${level * 10}% cash';
      case UpgradeType.steadyHand:
        final reduction = (level * 7).clamp(0, 70);
        return '-$reduction% speed';
      case UpgradeType.autoPainter:
        return '\$${level * 2}/sec';
      case UpgradeType.extraStroke:
        return '+$level strokes';
      case UpgradeType.brokerLicense:
        return '${5 - level}% fee';
    }
  }

  /// All upgrades shown in the UI (excludes widerRoller which is now
  /// the separate roller level system).
  static const List<UpgradeDefinition> all = [
    UpgradeDefinition(
      type: UpgradeType.turboSpeed,
      name: 'Turbo Speed',
      icon: '\u26A1',
      description: 'Earn more cash per tap',
      maxLevel: -1,
      baseCost: 30,
      costMultiplier: 1.5,
      effectPerLevel: '+10% cash/tap',
    ),
    UpgradeDefinition(
      type: UpgradeType.steadyHand,
      name: 'Steady Hand',
      icon: '\u{1F3AF}',
      description: 'Slower roller for precision',
      maxLevel: -1,
      baseCost: 100,
      costMultiplier: 2.0,
      effectPerLevel: '-7% speed',
    ),
    UpgradeDefinition(
      type: UpgradeType.autoPainter,
      name: 'Auto-Painter',
      icon: '\u{1F916}',
      description: 'Earn cash while away',
      maxLevel: -1,
      baseCost: 150,
      costMultiplier: 2.0,
      effectPerLevel: '+\$2/sec idle',
    ),
    UpgradeDefinition(
      type: UpgradeType.extraStroke,
      name: 'Extra Stroke',
      icon: '\u2795',
      description: 'More taps per wall',
      maxLevel: 3,
      baseCost: 500,
      costMultiplier: 3.0,
      effectPerLevel: '+1 stroke',
    ),
    UpgradeDefinition(
      type: UpgradeType.brokerLicense,
      name: 'Broker License',
      icon: '\u{1F4CB}',
      description: 'Lower marketplace fees',
      maxLevel: 3,
      baseCost: 300,
      costMultiplier: 2.5,
      effectPerLevel: '-1% fee',
    ),
  ];

  /// Keep full list for migration/lookup (includes widerRoller).
  static const UpgradeDefinition _widerRollerDef = UpgradeDefinition(
    type: UpgradeType.widerRoller,
    name: 'Wider Roller',
    icon: '\u{1F58C}\u{FE0F}',
    description: 'Paint wider stripes',
    maxLevel: -1,
    baseCost: 50,
    costMultiplier: 1.8,
    effectPerLevel: '+2% width',
  );

  static UpgradeDefinition getDefinition(UpgradeType type) {
    if (type == UpgradeType.widerRoller) return _widerRollerDef;
    return all.firstWhere((u) => u.type == type);
  }
}
