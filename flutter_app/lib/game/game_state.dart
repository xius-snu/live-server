import 'dart:math';

class PaintStripe {
  final double left;  // 0.0 to 1.0, left edge on wall
  final double right; // 0.0 to 1.0, right edge on wall

  const PaintStripe({required this.left, required this.right});
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

  void addStripe(double left, double right) {
    if (!isActive) return;
    if (strokesRemaining <= 0) return;
    stripes.add(PaintStripe(left: left, right: right));
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

  /// Coverage bonus is now continuous — stored as percentage (0-100) for display.
  /// The actual reward scaling (coverage^1.5) is handled by GameService.
  int getCoverageDisplayPercent() {
    return (coveragePercent * 100).round();
  }
}
