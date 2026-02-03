import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/friend_service.dart';
import '../services/user_service.dart';
import '../widgets/shape_icon.dart';
import 'trade_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFriends();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    final friendService = Provider.of<FriendService>(context, listen: false);
    await friendService.loadFriends();
    await friendService.loadPendingRequests();
  }

  Future<void> _sendFriendRequest() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    final friendService = Provider.of<FriendService>(context, listen: false);
    final success = await friendService.sendFriendRequest(query);

    setState(() {
      _isSearching = false;
      if (success) {
        _searchController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend request sent!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _searchError = friendService.error ?? 'Could not find user';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Friends", style: TextStyle(letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Consumer<FriendService>(
        builder: (context, friendService, child) {
          return RefreshIndicator(
            onRefresh: _loadFriends,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // My Friend Code
                  _buildFriendCodeCard(userService),
                  const SizedBox(height: 24),

                  // Add Friend
                  _buildAddFriendSection(),
                  const SizedBox(height: 24),

                  // Pending Requests
                  if (friendService.pendingRequests.isNotEmpty) ...[
                    _buildPendingRequestsSection(friendService),
                    const SizedBox(height: 24),
                  ],

                  // Friend List
                  _buildFriendList(friendService),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFriendCodeCard(UserService userService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.cyanAccent.withOpacity(0.1),
            Colors.blueAccent.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.qr_code, color: Colors.cyanAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                'MY FRIEND CODE',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  letterSpacing: 1,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  userService.friendCode ?? 'Loading...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, color: Colors.cyanAccent),
                onPressed: () {
                  if (userService.friendCode != null) {
                    Clipboard.setData(ClipboardData(text: userService.friendCode!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Friend code copied!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Share this code with friends to connect',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddFriendSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ADD FRIEND',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Username or Friend Code',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => _sendFriendRequest(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isSearching ? null : _sendFriendRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSearching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.person_add),
            ),
          ],
        ),
        if (_searchError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _searchError!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildPendingRequestsSection(FriendService friendService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'FRIEND REQUESTS',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orangeAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${friendService.pendingRequests.length}',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...friendService.pendingRequests.map((request) => _buildRequestCard(request, friendService)),
      ],
    );
  }

  Widget _buildRequestCard(FriendRequest request, FriendService friendService) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Profile shape or default icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
            ),
            child: Center(
              child: request.fromProfileShape != null
                  ? ShapeIcon(
                      shape: request.fromProfileShape!,
                      size: 24,
                      color: Colors.white70,
                      strokeWidth: 2,
                    )
                  : const Icon(Icons.person, color: Colors.white54),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.fromUsername,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Wants to be friends',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.greenAccent),
            onPressed: () async {
              await friendService.acceptFriendRequest(request.id);
            },
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.redAccent),
            onPressed: () async {
              await friendService.declineFriendRequest(request.id);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFriendList(FriendService friendService) {
    final friends = friendService.acceptedFriends;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FRIENDS (${friends.length})',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (friends.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.people_outline, size: 48, color: Colors.white.withOpacity(0.2)),
                  const SizedBox(height: 12),
                  Text(
                    'No friends yet',
                    style: TextStyle(color: Colors.white.withOpacity(0.5)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add friends using their username or code',
                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          ...friends.map((friend) => _buildFriendCard(friend, friendService)),
      ],
    );
  }

  Widget _buildFriendCard(Friend friend, FriendService friendService) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Stack(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
                border: Border.all(
                  color: friend.isOnline ? Colors.greenAccent : Colors.white24,
                  width: 2,
                ),
              ),
              child: Center(
                child: friend.profileShape != null
                    ? ShapeIcon(
                        shape: friend.profileShape!,
                        size: 26,
                        color: Colors.white70,
                        strokeWidth: 2,
                      )
                    : const Icon(Icons.person, color: Colors.white54),
              ),
            ),
            if (friend.isOnline)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF121212), width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          friend.username,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          friend.isOnline ? 'Online' : 'Offline',
          style: TextStyle(
            color: friend.isOnline ? Colors.greenAccent : Colors.white38,
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.swap_horiz, color: Colors.cyanAccent),
              tooltip: 'Trade',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TradeScreen(friend: friend),
                  ),
                );
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white54),
              color: const Color(0xFF1E1E1E),
              onSelected: (value) async {
                if (value == 'remove') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF1E1E1E),
                      title: const Text('Remove Friend?', style: TextStyle(color: Colors.white)),
                      content: Text(
                        'Remove ${friend.username} from your friends?',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Remove', style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await friendService.removeFriend(friend.userId);
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.person_remove, color: Colors.redAccent, size: 20),
                      SizedBox(width: 8),
                      Text('Remove Friend', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
