import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/friend_service.dart';
import '../services/trade_service.dart';
import '../services/user_service.dart';
import '../services/shapes.dart';
import '../widgets/shape_icon.dart';

class TradeScreen extends StatefulWidget {
  final Friend friend;

  const TradeScreen({super.key, required this.friend});

  @override
  State<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends State<TradeScreen> {
  List<InventoryItem> _selectedOffer = [];
  List<TradeItem> _selectedRequest = [];
  List<Map<String, dynamic>> _friendInventory = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadFriendInventory();
  }

  Future<void> _loadFriendInventory() async {
    final friendService = Provider.of<FriendService>(context, listen: false);
    final inventory = await friendService.getFriendInventory(widget.friend.userId);
    setState(() {
      _friendInventory = inventory;
      _isLoading = false;
    });
  }

  void _toggleOfferItem(InventoryItem item) {
    setState(() {
      if (_selectedOffer.contains(item)) {
        _selectedOffer.remove(item);
      } else if (_selectedOffer.length < 3) {
        _selectedOffer.add(item);
      }
    });
  }

  void _toggleRequestItem(Map<String, dynamic> item) {
    final tradeItem = TradeItem(
      inventoryId: item['id'] ?? item['inventory_id'] ?? '',
      shapeType: item['shape_type'] ?? '',
      rarity: item['rarity'] ?? 'Common',
    );

    setState(() {
      final existingIndex = _selectedRequest.indexWhere(
        (r) => r.inventoryId == tradeItem.inventoryId,
      );
      if (existingIndex >= 0) {
        _selectedRequest.removeAt(existingIndex);
      } else if (_selectedRequest.length < 3) {
        _selectedRequest.add(tradeItem);
      }
    });
  }

  bool _isRequestItemSelected(Map<String, dynamic> item) {
    final id = item['id'] ?? item['inventory_id'] ?? '';
    return _selectedRequest.any((r) => r.inventoryId == id);
  }

  Future<void> _sendTradeRequest() async {
    if (_selectedOffer.isEmpty || _selectedRequest.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one item on each side'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    final tradeService = Provider.of<TradeService>(context, listen: false);
    final tradeId = await tradeService.createTradeRequest(
      toUserId: widget.friend.userId,
      offerItems: _selectedOffer,
      requestItems: _selectedRequest,
    );

    setState(() => _isSending = false);

    if (tradeId != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trade request sent!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tradeService.error ?? 'Failed to send trade request'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserService>(context);
    final myItems = userService.getAvailableItems();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text('Trade with ${widget.friend.username}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Trade Preview
                _buildTradePreview(),

                // Selection Areas
                Expanded(
                  child: Row(
                    children: [
                      // My Items (Offer)
                      Expanded(
                        child: _buildItemSelector(
                          title: 'YOUR OFFER',
                          subtitle: 'Select items to give',
                          items: myItems,
                          selectedCount: _selectedOffer.length,
                          accentColor: Colors.greenAccent,
                          isMyItems: true,
                        ),
                      ),
                      // Divider
                      Container(
                        width: 1,
                        color: Colors.white12,
                      ),
                      // Friend's Items (Request)
                      Expanded(
                        child: _buildItemSelector(
                          title: 'YOU WANT',
                          subtitle: "Select ${widget.friend.username}'s items",
                          items: _friendInventory,
                          selectedCount: _selectedRequest.length,
                          accentColor: Colors.redAccent,
                          isMyItems: false,
                        ),
                      ),
                    ],
                  ),
                ),

                // Send Button
                _buildSendButton(),
              ],
            ),
    );
  }

  Widget _buildTradePreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          // My offer
          Expanded(
            child: Column(
              children: [
                Text(
                  'YOU GIVE',
                  style: TextStyle(
                    color: Colors.greenAccent.withOpacity(0.7),
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPreviewSlots(_selectedOffer.map((i) => i.shapeType).toList(), Colors.greenAccent),
              ],
            ),
          ),
          // Swap icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
            ),
            child: const Icon(Icons.swap_horiz, color: Colors.white54),
          ),
          // I want
          Expanded(
            child: Column(
              children: [
                Text(
                  'YOU GET',
                  style: TextStyle(
                    color: Colors.cyanAccent.withOpacity(0.7),
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPreviewSlots(_selectedRequest.map((i) => i.shapeType).toList(), Colors.cyanAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSlots(List<String> shapes, Color accentColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final hasItem = index < shapes.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: hasItem ? accentColor.withOpacity(0.1) : Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasItem ? accentColor : Colors.white12,
              width: hasItem ? 2 : 1,
            ),
          ),
          child: hasItem
              ? Center(
                  child: ShapeIcon(
                    shape: shapes[index],
                    size: 24,
                    color: accentColor,
                    strokeWidth: 2,
                  ),
                )
              : Icon(Icons.add, color: Colors.white24, size: 20),
        );
      }),
    );
  }

  Widget _buildItemSelector({
    required String title,
    required String subtitle,
    required List items,
    required int selectedCount,
    required Color accentColor,
    required bool isMyItems,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '($selectedCount/3)',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    isMyItems ? 'No tradeable items' : 'Loading inventory...',
                    style: TextStyle(color: Colors.white.withOpacity(0.3)),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    if (isMyItems) {
                      final item = items[index] as InventoryItem;
                      final isSelected = _selectedOffer.contains(item);
                      return _buildItemCard(
                        shapeType: item.shapeType,
                        rarity: item.rarity,
                        isSelected: isSelected,
                        accentColor: accentColor,
                        onTap: () => _toggleOfferItem(item),
                      );
                    } else {
                      final item = items[index] as Map<String, dynamic>;
                      final isSelected = _isRequestItemSelected(item);
                      return _buildItemCard(
                        shapeType: item['shape_type'] ?? '',
                        rarity: item['rarity'] ?? 'Common',
                        isSelected: isSelected,
                        accentColor: accentColor,
                        onTap: () => _toggleRequestItem(item),
                      );
                    }
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildItemCard({
    required String shapeType,
    required String rarity,
    required bool isSelected,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final tierColor = ShapeRegistry.getColorForShape(shapeType);
    final rarityColor = _getRarityColor(rarity);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.15) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Tier indicator
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: tierColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            // Selected checkmark
            if (isSelected)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.black, size: 14),
                ),
              ),
            // Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShapeIcon(
                    shape: shapeType,
                    size: 36,
                    color: isSelected ? accentColor : Colors.white70,
                    strokeWidth: 2.5,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    shapeType,
                    style: TextStyle(
                      color: isSelected ? accentColor : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    rarity,
                    style: TextStyle(
                      color: rarityColor,
                      fontSize: 10,
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

  Color _getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'legendary':
        return Colors.amberAccent;
      case 'epic':
        return Colors.purpleAccent;
      case 'rare':
        return Colors.blueAccent;
      default:
        return Colors.white54;
    }
  }

  Widget _buildSendButton() {
    final canSend = _selectedOffer.isNotEmpty && _selectedRequest.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: canSend && !_isSending ? _sendTradeRequest : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black,
              disabledBackgroundColor: Colors.white12,
              disabledForegroundColor: Colors.white38,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.send),
                      const SizedBox(width: 8),
                      Text(
                        'SEND TRADE REQUEST',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
