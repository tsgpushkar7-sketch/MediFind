import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'shop_registration_screen.dart';
import 'image_view_screen.dart';
import '../widgets/shop_status_toggle.dart';
import 'analytics_dashboard_screen.dart';

class ShopkeeperHomeScreen extends StatefulWidget {
  const ShopkeeperHomeScreen({super.key});

  @override
  State<ShopkeeperHomeScreen> createState() => _ShopkeeperHomeScreenState();
}

class _ShopkeeperHomeScreenState extends State<ShopkeeperHomeScreen> {
  int selectedIndex = 0;

  Map<String, dynamic>? shop;
  List requests = [];

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadShopAndRequests();
  }
  Future<void> handleBlockCustomer(String customerId, String itemText) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block this customer?'),
        content: const Text(
          'You will no longer receive requests from this customer. This can be undone later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Block', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await ApiService.blockCustomer(shop!['_id'], customerId);

    if (result['success']) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer blocked')),
      );
      loadShopAndRequests();
    }
  }
  Future<void> handleToggleOpen() async {
    final result = await ApiService.toggleShopOpen(shop!['_id']);
    if (result['success']) {
      setState(() {
        shop = result['data'];
      });
    }
  }

  Future<void> loadShopAndRequests() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    final shopResult = await ApiService.getShopByOwner(userId!);

    if (!shopResult['success']) {
      setState(() {
        isLoading = false;
        errorMessage = shopResult['error'];
      });
      return;
    }

    shop = shopResult['data'];

    await prefs.setString('shopId', shop!['_id']);

    final requestsResult = await ApiService.getRequestsForShop(shop!['_id']);

    setState(() {
      isLoading = false;

      if (requestsResult['success']) {
        requests = requestsResult['data'];
      }
    });
  }

  Future<void> handleAccept(String requestId, String itemText) async {
    final result = await ApiService.acceptRequest(
      requestId,
      shop!['_id'],
      null,
    );

    if (result['success']) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Accepted "$itemText"')));

      loadShopAndRequests();
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result['error'])));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          shop != null ? shop!['shopName'] : 'Shopkeeper',
        ),
        actions: [
          if (shop != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: ShopStatusToggle(
                  isOpen: shop!['isOpen'],
                  onTap: handleToggleOpen,
                ),
              ),
            ),
        ],
      ),
     body: selectedIndex == 0
          ? buildRequestsTab()
          : selectedIndex == 1
              ? const AnalyticsDashboardScreen()
              : const ProfileScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
       items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inbox),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Insights',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget buildRequestsTab() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return ShopRegistrationScreen(onRegistered: loadShopAndRequests);
    }

    if (requests.isEmpty) {
      return RefreshIndicator(
        onRefresh: loadShopAndRequests,
        child: ListView(
          children: const [
            SizedBox(height: 150),
            Center(child: Text('No open requests nearby right now.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadShopAndRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final req = requests[index];

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: req['itemImageUrl'] != null
                  ? GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ImageViewScreen(imageUrl: req['itemImageUrl']),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          req['itemImageUrl'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  : const Icon(Icons.shopping_bag, size: 40),
              title: Text(req['itemText']),
              subtitle: Text(req['category']),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      requestId: req['_id'],
                      shopName: shop!['shopName'],
                      senderRole: 'shopkeeper',
                    ),
                  ),
                );
              },

              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  req['alreadyResponded'] == true
                      ? const Chip(
                          label: Text('Accepted'),
                          backgroundColor: Colors.green,
                          labelStyle: TextStyle(color: Colors.white),
                        )
                      : ElevatedButton(
                          onPressed: () => handleAccept(
                            req['_id'],
                            req['itemText'],
                          ),
                          child: const Text('Accept'),
                        ),
                  IconButton(
                    icon: const Icon(Icons.block, color: Colors.grey, size: 20),
                    onPressed: () => handleBlockCustomer(req['customerId'], req['itemText']),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
