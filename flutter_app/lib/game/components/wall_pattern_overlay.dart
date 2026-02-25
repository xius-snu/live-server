import 'package:flame/components.dart';
import 'wall_component.dart';

/// Draws only the pattern shape outlines on top of paint stripes,
/// so the black strokes stay visible through the paint.
/// This component must share position/size with its WallComponent.
class WallPatternOverlay extends PositionComponent {
  final WallComponent wall;

  WallPatternOverlay({required this.wall});

  @override
  void render(canvas) {
    // Re-render only the shape outlines (strokes) from the wall
    wall.renderPatternOutlines(canvas);
  }
}
