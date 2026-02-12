import 'dart:math';

class PaintStripe {
  final double center; // 0.0 to 1.0 across the wall
  final double halfWidth; // half the stripe width as fraction of wall

  const PaintStripe({required this.center, required this.halfWidth});

  double get left => (center - halfWidth).clamp(0.0, 1.0);
  double get right => (center + halfWidth).clamp(0.0, 1.0);
}

class GameRoundState {
  int strokesRemaining;
  final int maxStrokes;
  final List<PaintStripe> stripes = [];
  bool isActive = true;
  bool showingResults = false;
  double lastPayout = 0;
  int coverageBonusMultiplier = 1;

  GameRoundState({required this.maxStrokes}) : strokesRemaining = maxStrokes;

  double get coveragePercent => _calculateCoverage();

  int get strokesUsed => maxStrokes - strokesRemaining;

  void addStripe(double center, double halfWidth) {
    if (strokesRemaining <= 0 || !isActive) return;
    stripes.add(PaintStripe(center: center, halfWidth: halfWidth));
    strokesRemaining--;
    if (strokesRemaining <= 0) {
      isActive = false;
    }
  }

  void reset(int newMaxStrokes) {
    strokesRemaining = newMaxStrokes;
    stripes.clear();
    isActive = true;
    showingResults = false;
    lastPayout = 0;
    coverageBonusMultiplier = 1;
  }

  /// Calculate coverage using interval merge on the 1D wall [0, 1].
  double _calculateCoverage() {
    if (stripes.isEmpty) return 0.0;

    final intervals = stripes
        .map((s) => [s.left, s.right])
        .toList()
      ..sort((a, b) => a[0].compareTo(b[0]));

    double totalCoverage = 0;
    double currentStart = intervals[0][0];
    double currentEnd = intervals[0][1];

    for (int i = 1; i < intervals.length; i++) {
      if (intervals[i][0] <= currentEnd) {
        currentEnd = max(currentEnd, intervals[i][1]);
      } else {
        totalCoverage += currentEnd - currentStart;
        currentStart = intervals[i][0];
        currentEnd = intervals[i][1];
      }
    }
    totalCoverage += currentEnd - currentStart;

    return totalCoverage.clamp(0.0, 1.0);
  }

  int getCoverageBonus() {
    final coverage = coveragePercent;
    if (coverage >= 1.0) return 5;
    if (coverage >= 0.95) return 3;
    if (coverage >= 0.90) return 2;
    return 1;
  }
}
