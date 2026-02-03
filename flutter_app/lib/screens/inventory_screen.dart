import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/user_service.dart';
import '../services/shapes.dart';
import '../widgets/shape_icon.dart';

class InventoryScreen extends StatefulWidget {
  final bool showBackButton;

  const InventoryScreen({super.key, this.showBackButton = true});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  bool _showCollectionView = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Collection", style: TextStyle(letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: widget.showBackButton,
        actions: [
          // Toggle between inventory and collection view
          IconButton(
            icon: Icon(
              _showCollectionView ? Icons.grid_view : Icons.collections_bookmark,
              color: Colors.white70,
            ),
            onPressed: () {
              setState(() {
                _showCollectionView = !_showCollectionView;
              });
            },
            tooltip: _showCollectionView ? 'Show Inventory' : 'Show Collection Progress',
          ),
          // Clear inventory (debug)
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _showClearInventoryDialog(context),
            tooltip: 'Clear Inventory',
          ),
        ],
      ),
      body: Consumer<UserService>(
        builder: (context, userService, child) {
          final inventory = userService.inventory;
          final username = userService.username ?? 'Anonymous';
          final profileShape = userService.profileShape;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Header
                _buildProfileHeader(username, profileShape, userService),
                const SizedBox(height: 24),

                // Collection Progress (Tier completion)
                _buildCollectionProgress(userService),
                const SizedBox(height: 24),

                // Inventory Section or Collection View
                if (_showCollectionView)
                  _buildCollectionSetsView(userService)
                else
                  _buildInventorySection(inventory, profileShape, userService),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCollectionProgress(UserService userService) {
    final collected = userService.collectedShapes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "COLLECTION PROGRESS",
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: ShapeTier.values.map((tier) {
            final shapesInTier = ShapeRegistry.getShapesByTier(tier);
            final collectedInTier = shapesInTier.where((s) => collected.contains(s)).length;
            final total = shapesInTier.length;
            final isComplete = collectedInTier == total;

            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isComplete ? tier.color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isComplete ? tier.color : Colors.white24,
                    width: isComplete ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'T${tier.level}',
                      style: TextStyle(
                        color: tier.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$collectedInTier/$total',
                      style: TextStyle(
                        color: isComplete ? tier.color : Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    if (isComplete)
                      Icon(Icons.check_circle, color: tier.color, size: 16),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCollectionSetsView(UserService userService) {
    final collected = userService.collectedShapes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: ShapeTier.values.map((tier) {
        final shapesInTier = ShapeRegistry.getShapesByTier(tier);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: tier.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _getTierName(tier),
                  style: TextStyle(
                    color: tier.color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: shapesInTier.map((shape) {
                final hasShape = collected.contains(shape);
                return Container(
                  width: 70,
                  height: 80,
                  decoration: BoxDecoration(
                    color: hasShape ? tier.color.withOpacity(0.1) : Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: hasShape ? tier.color.withOpacity(0.5) : Colors.white12,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      hasShape
                          ? ShapeIcon(
                              shape: shape,
                              size: 30,
                              color: tier.color,
                              strokeWidth: 2,
                            )
                          : Icon(
                              Icons.help_outline,
                              color: Colors.white24,
                              size: 30,
                            ),
                      const SizedBox(height: 4),
                      Text(
                        hasShape ? shape : '???',
                        style: TextStyle(
                          color: hasShape ? Colors.white70 : Colors.white24,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        );
      }).toList(),
    );
  }

  String _getTierName(ShapeTier tier) {
    switch (tier) {
      case ShapeTier.tier1:
        return 'BASIC';
      case ShapeTier.tier2:
        return 'INTERMEDIATE';
      case ShapeTier.tier3:
        return 'ADVANCED';
      case ShapeTier.tier4:
        return 'EXPERT';
    }
  }

  Widget _buildProfileHeader(String username, String? profileShape, UserService userService) {
    return Column(
      children: [
        // Profile Picture
        GestureDetector(
          onLongPress: profileShape != null
              ? () => _showClearProfileDialog(userService)
              : null,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
              border: Border.all(
                color: profileShape != null ? Colors.cyanAccent : Colors.white24,
                width: 3,
              ),
              boxShadow: profileShape != null
                  ? [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.3),
                        blurRadius: 16,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: profileShape != null
                  ? ShapeIcon(
                      shape: profileShape,
                      size: 50,
                      color: Colors.cyanAccent,
                      strokeWidth: 3,
                    )
                  : const Icon(
                      Icons.person_outline,
                      size: 50,
                      color: Colors.white24,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Username
        Text(
          username,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          profileShape != null
              ? 'Long-press profile to clear'
              : 'Long-press a shape to set as profile',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildInventorySection(
      Map<String, int> inventory, String? profileShape, UserService userService) {
    if (inventory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            Icon(Icons.category_outlined, size: 64, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(
              "No shapes collected yet.",
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
            const SizedBox(height: 8),
            Text(
              "Draw shapes to collect them!",
              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
            ),
          ],
        ),
      );
    }

    // Convert inventory map to list and sort
    final items = inventory.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "MY COLLECTION",
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final shape = items[index].key;
            final quantity = items[index].value;
            final isProfileShape = shape == profileShape;

            return _buildShapeCard(shape, quantity, isProfileShape, userService);
          },
        ),
      ],
    );
  }

  Widget _buildShapeCard(
      String shape, int quantity, bool isProfileShape, UserService userService) {
    // Check if any items of this shape are pending in trade
    final pendingCount = userService.inventoryItems
        .where((item) => item.shapeType == shape && item.isLocked)
        .length;
    final hasPending = pendingCount > 0;

    final color = isProfileShape ? Colors.cyanAccent : Colors.white;
    final tierColor = ShapeRegistry.getColorForShape(shape);

    return GestureDetector(
      onLongPress: () => _setAsProfile(shape, userService),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(isProfileShape ? 0.1 : 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isProfileShape
                ? Colors.cyanAccent
                : (hasPending ? Colors.orangeAccent : Colors.white24),
            width: isProfileShape ? 2 : 1,
          ),
          boxShadow: isProfileShape
              ? [
                  BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Tier indicator
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: tierColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            // Pending trade indicator
            if (hasPending)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock, color: Colors.orangeAccent, size: 10),
                      const SizedBox(width: 2),
                      Text(
                        '$pendingCount',
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShapeIcon(
                    shape: shape,
                    size: 40,
                    color: color,
                    strokeWidth: 2.5,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    shape,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasPending ? '$quantity ($pendingCount pending)' : '$quantity',
                    style: TextStyle(
                      color: hasPending ? Colors.orangeAccent : color.withOpacity(0.6),
                      fontSize: hasPending ? 10 : 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setAsProfile(String shape, UserService userService) {
    HapticFeedback.mediumImpact();
    userService.setProfileShape(shape);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$shape set as profile picture'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.cyanAccent.withOpacity(0.8),
      ),
    );
  }

  void _showClearInventoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Clear Inventory?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will delete ALL your collected shapes and reset your progress. This cannot be undone!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final userService = Provider.of<UserService>(context, listen: false);
              await userService.clearInventory();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Inventory cleared'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showClearProfileDialog(UserService userService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Clear Profile Picture?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Remove the shape from your profile picture?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              userService.setProfileShape(null);
              Navigator.pop(context);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
