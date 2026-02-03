import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_service.dart';
import 'main_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool isFirstLaunch;
  const ProfileScreen({super.key, this.isFirstLaunch = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserService>(context, listen: false);
    if (user.username != null) {
      _controller.text = user.username!;
    }
  }

  void _save(BuildContext context) async {
    if (_controller.text.isEmpty) return;

    setState(() => _isLoading = true);
    final userService = Provider.of<UserService>(context, listen: false);
    final success = await userService.setUsername(_controller.text);
    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      if (widget.isFirstLaunch) {
        // Navigate to MainScreen if this was a forced first launch
         Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username updated!')),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update username')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              widget.isFirstLaunch
                  ? 'Welcome! Please choose a username.'
                  : 'Update your username',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () => _save(context),
                    child: const Text('Save'),
                  ),
          ],
        ),
      ),
    );
  }
}
