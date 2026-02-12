import 'dart:math';

enum UpgradeType {
  widerRoller,
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

  double costForLevel(int level) {
    if (level >= maxLevel) return double.infinity;
    return (baseCost * pow(costMultiplier, level)).roundToDouble();
  }

  String cumulativeEffect(int level) {
    switch (type) {
      case UpgradeType.widerRoller:
        return '+${level * 2}% width';
      case UpgradeType.turboSpeed:
        return '+${level * 10}% cash';
      case UpgradeType.steadyHand:
        return '-${level * 7}% speed';
      case UpgradeType.autoPainter:
        return '\$${level * 2}/sec';
      case UpgradeType.extraStroke:
        return '+$level strokes';
      case UpgradeType.brokerLicense:
        return '${5 - level}% fee';
    }
  }

  static const List<UpgradeDefinition> all = [
    UpgradeDefinition(
      type: UpgradeType.widerRoller,
      name: 'Wider Roller',
      icon: '🖌️',
      description: 'Paint wider stripes',
      maxLevel: 10,
      baseCost: 50,
      costMultiplier: 1.8,
      effectPerLevel: '+2% width',
    ),
    UpgradeDefinition(
      type: UpgradeType.turboSpeed,
      name: 'Turbo Speed',
      icon: '⚡',
      description: 'Earn more cash per tap',
      maxLevel: 10,
      baseCost: 30,
      costMultiplier: 1.5,
      effectPerLevel: '+10% cash/tap',
    ),
    UpgradeDefinition(
      type: UpgradeType.steadyHand,
      name: 'Steady Hand',
      icon: '🎯',
      description: 'Slower roller for precision',
      maxLevel: 5,
      baseCost: 100,
      costMultiplier: 2.0,
      effectPerLevel: '-7% speed',
    ),
    UpgradeDefinition(
      type: UpgradeType.autoPainter,
      name: 'Auto-Painter',
      icon: '🤖',
      description: 'Earn cash while away',
      maxLevel: 10,
      baseCost: 150,
      costMultiplier: 2.0,
      effectPerLevel: '+\$2/sec idle',
    ),
    UpgradeDefinition(
      type: UpgradeType.extraStroke,
      name: 'Extra Stroke',
      icon: '➕',
      description: 'More taps per wall',
      maxLevel: 3,
      baseCost: 500,
      costMultiplier: 3.0,
      effectPerLevel: '+1 stroke',
    ),
    UpgradeDefinition(
      type: UpgradeType.brokerLicense,
      name: 'Broker License',
      icon: '📋',
      description: 'Lower marketplace fees',
      maxLevel: 3,
      baseCost: 300,
      costMultiplier: 2.5,
      effectPerLevel: '-1% fee',
    ),
  ];

  static UpgradeDefinition getDefinition(UpgradeType type) {
    return all.firstWhere((u) => u.type == type);
  }
}
