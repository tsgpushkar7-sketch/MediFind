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
  State<ShopkeeperHomeScreen> createState() =>
      _ShopkeeperHomeScreenState();
}

class _ShopkeeperHomeScreenState
    extends State<ShopkeeperHomeScreen> {
  int selectedIndex = 0;

  Map<String, dynamic>? shop;
  List requests = [];

  bool isLoading = true;
  String? errorMessage;

  static const Color primary = Color(0xFF16B8B0);
  static const Color primaryDark = Color(0xFF087F82);
  static const Color background = Color(0xFFF5F9FA);
  static const Color textDark = Color(0xFF173042);
  static const Color textLight = Color(0xFF71828D);

  @override
  void initState() {
    super.initState();
    loadShopAndRequests();
  }

  Future<void> handleBlockCustomer(
    String customerId,
    String itemText,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Block this customer?',
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const Text(
          'You will no longer receive requests from this customer. '
          'This can be undone later.',
          style: TextStyle(
            color: textLight,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: textLight),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Block',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await ApiService.blockCustomer(
      shop!['_id'],
      customerId,
    );

    if (result['success']) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer blocked'),
        ),
      );

      loadShopAndRequests();
    }
  }

  Future<void> handleToggleOpen() async {
    final result =
        await ApiService.toggleShopOpen(shop!['_id']);

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

    final shopResult =
        await ApiService.getShopByOwner(userId!);

    if (!shopResult['success']) {
      setState(() {
        isLoading = false;
        errorMessage = shopResult['error'];
      });
      return;
    }

    shop = shopResult['data'];

    await prefs.setString(
      'shopId',
      shop!['_id'],
    );

    final requestsResult =
        await ApiService.getRequestsForShop(
      shop!['_id'],
    );

    setState(() {
      isLoading = false;

      if (requestsResult['success']) {
        requests = requestsResult['data'];
      }
    });
  }

  Future<void> handleAccept(
    String requestId,
    String itemText,
  ) async {
    final result = await ApiService.acceptRequest(
      requestId,
      shop!['_id'],
      null,
    );

    if (result['success']) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Accepted "$itemText"'),
        ),
      );

      loadShopAndRequests();
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error']),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: selectedIndex == 0
                  ? buildRequestsTab()
                  : selectedIndex == 1
                      ? const AnalyticsDashboardScreen()
                      : const ProfileScreen(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // ------------------------------------------------------------
  // HEADER
  // ------------------------------------------------------------

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        14,
        20,
        12,
      ),
      child: Row(
        children: [
          // Shop icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primary, primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primary.withOpacity(0.22),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),

          const SizedBox(width: 12),

          // Shop name
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'MediFind',
                  style: TextStyle(
                    color: primaryDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  shop != null
                      ? shop!['shopName']
                      : 'Shopkeeper',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          if (shop != null)
            ShopStatusToggle(
              isOpen: shop!['isOpen'],
              onTap: handleToggleOpen,
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // REQUESTS TAB
  // ------------------------------------------------------------

  Widget buildRequestsTab() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: primary,
        ),
      );
    }

    if (errorMessage != null) {
      return ShopRegistrationScreen(
        onRegistered: loadShopAndRequests,
      );
    }

    return RefreshIndicator(
      color: primary,
      onRefresh: loadShopAndRequests,
      child: requests.isEmpty
          ? _buildEmptyRequests()
          : _buildRequestsList(),
    );
  }

  // ------------------------------------------------------------
  // EMPTY REQUESTS
  // ------------------------------------------------------------

  Widget _buildEmptyRequests() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        10,
        20,
        30,
      ),
      children: [
        const SizedBox(height: 8),

        // Welcome / status card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [primary, primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.20),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'You’re all caught up!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'New customer requests will appear here.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.78),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.inbox_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 65),

        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            color: const Color(0xFFE7F9F8),
            borderRadius: BorderRadius.circular(27),
          ),
          child: const Icon(
            Icons.mark_email_read_outlined,
            color: primaryDark,
            size: 39,
          ),
        ),

        const SizedBox(height: 18),

        const Text(
          'No open requests',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textDark,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'No open requests nearby right now.\nPull down to refresh.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textLight,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // REQUEST LIST
  // ------------------------------------------------------------

  Widget _buildRequestsList() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        8,
        20,
        30,
      ),
      itemCount: requests.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildRequestsHeader();
        }

        final req = requests[index - 1];

        return _buildRequestCard(req);
      },
    );
  }

  Widget _buildRequestsHeader() {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 16,
        top: 2,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nearby Requests',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${requests.length} request${requests.length == 1 ? '' : 's'} waiting for you',
                  style: const TextStyle(
                    color: textLight,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE7F9F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_active_outlined,
                  color: primaryDark,
                  size: 17,
                ),
                const SizedBox(width: 6),
                Text(
                  '${requests.length}',
                  style: const TextStyle(
                    color: primaryDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // REQUEST CARD
  // ------------------------------------------------------------

  Widget _buildRequestCard(dynamic req) {
    final bool hasImage =
        req['itemImageUrl'] != null;

    final bool alreadyResponded =
        req['alreadyResponded'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // Request image
                GestureDetector(
                  onTap: hasImage
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ImageViewScreen(
                                imageUrl:
                                    req['itemImageUrl'],
                              ),
                            ),
                          );
                        }
                      : null,
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7F9F8),
                      borderRadius:
                          BorderRadius.circular(17),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: hasImage
                        ? Image.network(
                            req['itemImageUrl'],
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) {
                              return const Icon(
                                Icons.image_not_supported_outlined,
                                color: primaryDark,
                                size: 28,
                              );
                            },
                          )
                        : const Icon(
                            Icons.shopping_bag_outlined,
                            color: primaryDark,
                            size: 29,
                          ),
                  ),
                ),

                const SizedBox(width: 13),

                // Request details
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            requestId: req['_id'],
                            shopName:
                                shop!['shopName'],
                            senderRole: 'shopkeeper',
                          ),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          req['itemText'],
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: textDark,
                            fontSize: 15.5,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFF0F5F6),
                            borderRadius:
                                BorderRadius.circular(
                              8,
                            ),
                          ),
                          child: Text(
                            req['category'],
                            style: const TextStyle(
                              color: textLight,
                              fontSize: 10.5,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Block button
                GestureDetector(
                  onTap: () => handleBlockCustomer(
                    req['customerId'],
                    req['itemText'],
                  ),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6F7),
                      borderRadius:
                          BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.block_rounded,
                      color: textLight,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // Divider
            Divider(
              height: 1,
              color: Colors.grey.shade200,
            ),

            const SizedBox(height: 14),

            // Bottom action
            Row(
              children: [
                if (alreadyResponded)
                  Expanded(
                    child: Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F7EC),
                        borderRadius:
                            BorderRadius.circular(13),
                      ),
                      child: const Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Colors.green,
                            size: 18,
                          ),
                          SizedBox(width: 7),
                          Text(
                            'Accepted',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12.5,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ChatScreen(
                              requestId: req['_id'],
                              shopName:
                                  shop!['shopName'],
                              senderRole:
                                  'shopkeeper',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 17,
                      ),
                      label: const Text('Chat'),
                      style:
                          OutlinedButton.styleFrom(
                        foregroundColor:
                            primaryDark,
                        side: const BorderSide(
                          color: primary,
                        ),
                        minimumSize:
                            const Size(0, 45),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            13,
                          ),
                        ),
                        textStyle:
                            const TextStyle(
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          handleAccept(
                        req['_id'],
                        req['itemText'],
                      ),
                      icon: const Icon(
                        Icons.check_rounded,
                        size: 18,
                      ),
                      label: const Text('Accept'),
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            primaryDark,
                        foregroundColor:
                            Colors.white,
                        elevation: 0,
                        minimumSize:
                            const Size(0, 45),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            13,
                          ),
                        ),
                        textStyle:
                            const TextStyle(
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // BOTTOM NAVIGATION
  // ------------------------------------------------------------

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            12,
            8,
            12,
            8,
          ),
          child: Row(
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.inbox_rounded,
                label: 'Requests',
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.bar_chart_rounded,
                label: 'Insights',
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.person_rounded,
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected =
        selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFE7F9F8)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected
                    ? primaryDark
                    : textLight,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? primaryDark
                      : textLight,
                  fontSize: 10.5,
                  fontWeight: isSelected
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}