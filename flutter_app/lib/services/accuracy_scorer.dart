import 'dart:math';
import 'package:flutter/material.dart';

/// Result of accuracy scoring
class AccuracyScore {
  /// Percentage of target path covered by user points (0.0 to 1.0)
  final double coverage;

  /// How close user stayed to target path (1.0 = perfect, 0.0 = far away)
  final double precision;

  /// Combined score: coverage * precision
  double get combined => coverage * precision;

  const AccuracyScore({
    required this.coverage,
    required this.precision,
  });

  @override
  String toString() =>
      'AccuracyScore(coverage: ${(coverage * 100).toStringAsFixed(1)}%, '
      'precision: ${(precision * 100).toStringAsFixed(1)}%, '
      'combined: ${(combined * 100).toStringAsFixed(1)}%)';
}

/// Scores how accurately a user traced a target shape
class AccuracyScorer {
  /// Score the user's drawing against the target path
  ///
  /// [userPoints] - The points drawn by the user in screen coordinates
  /// [targetPoints] - The target shape points in screen coordinates
  /// [threshold] - Maximum distance (in pixels) to count as "on target"
  static AccuracyScore score({
    required List<Offset> userPoints,
    required List<Offset> targetPoints,
    double? guideSize,
    double threshold = 40.0,
  }) {
    if (userPoints.isEmpty || targetPoints.isEmpty) {
      return const AccuracyScore(coverage: 0.0, precision: 0.0);
    }

    // Calculate coverage: what % of target points have a user point nearby
    final coverage = _calculateCoverage(
      userPoints: userPoints,
      targetPoints: targetPoints,
      threshold: threshold,
    );

    // Calculate precision: how close user points are to the target on average
    final precision = _calculatePrecision(
      userPoints: userPoints,
      targetPoints: targetPoints,
      threshold: threshold,
    );

    return AccuracyScore(coverage: coverage, precision: precision);
  }

  /// Calculate what percentage of target points are covered by user points
  static double _calculateCoverage({
    required List<Offset> userPoints,
    required List<Offset> targetPoints,
    required double threshold,
  }) {
    int coveredCount = 0;

    for (final targetPoint in targetPoints) {
      // Check if any user point is within threshold of this target point
      bool isCovered = false;
      for (final userPoint in userPoints) {
        final distance = (targetPoint - userPoint).distance;
        if (distance <= threshold) {
          isCovered = true;
          break;
        }
      }
      if (isCovered) coveredCount++;
    }

    return coveredCount / targetPoints.length;
  }

  /// Calculate precision: average distance of user points from nearest target point
  /// Returns 1.0 for perfect precision, decreasing toward 0.0 as distance increases
  static double _calculatePrecision({
    required List<Offset> userPoints,
    required List<Offset> targetPoints,
    required double threshold,
  }) {
    double totalPrecision = 0.0;

    for (final userPoint in userPoints) {
      // Find minimum distance to any target point
      double minDistance = double.infinity;
      for (final targetPoint in targetPoints) {
        final distance = (userPoint - targetPoint).distance;
        if (distance < minDistance) {
          minDistance = distance;
        }
      }

      // Convert distance to precision score (1.0 at distance 0, 0.0 at threshold)
      final pointPrecision = max(0.0, 1.0 - (minDistance / threshold));
      totalPrecision += pointPrecision;
    }

    return totalPrecision / userPoints.length;
  }
}
