import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import 'request_status_screen.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  List<dynamic> requests = [];
  bool isLoading = true;

  static const Color primary = Color(0xFF16B8B0);
  static const Color primaryDark = Color(0xFF087F82);
  static const Color background = Color(0xFFF5F9FA);
  static const Color textDark = Color(0xFF173042);
  static const Color textLight = Color(0xFF71828D);

  @override
  void initState() {
    super.initState();
    fetchMyRequests();
  }

  Future<void> fetchMyRequests() async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final customerId = prefs.getString('userId');

    if (customerId == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final result = await ApiService.getMyRequests(customerId);

    if (result['success']) {
      setState(() {
        requests = result['data'];
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Color statusColor(String status) {
    switch (status) {
      case 'open':
        return const Color(0xFFE89B35);
      case 'resolved':
        return const Color(0xFF2DAA68);
      case 'cancelled':
        return const Color(0xFF8A969D);
      default:
        return textLight;
    }
  }

  Color statusBackground(String status) {
    switch (status) {
      case 'open':
        return const Color(0xFFFFF5E7);
      case 'resolved':
        return const Color(0xFFEAF8F0);
      case 'cancelled':
        return const Color(0xFFF0F2F3);
      default:
        return const Color(0xFFF0F2F3);
    }
  }

  IconData statusIcon(String status) {
    switch (status) {
      case 'open':
        return Icons.access_time_rounded;
      case 'resolved':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }

  String formatStatus(String status) {
    if (status.isEmpty) return status;

    return status[0].toUpperCase() +
        status.substring(1);
  }

  IconData categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'medical':
        return Icons.medication_rounded;
      case 'grocery':
        return Icons.shopping_basket_rounded;
      case 'hardware':
        return Icons.handyman_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  Color categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'medical':
        return primary;
      case 'grocery':
        return const Color(0xFF22A85A);
      case 'hardware':
        return const Color(0xFFE59A38);
      default:
        return const Color(0xFF6376D8);
    }
  }

  void openRequest(dynamic req) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RequestStatusScreen(
          requestId: req['_id'],
          itemText: req['itemText'],
        ),
      ),
    );
  }

  Widget buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        12,
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  primary,
                  primaryDark,
                ],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'My Requests',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Track all your requests in one place',
                  style: TextStyle(
                    color: textLight,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSummaryCard() {
    final openCount = requests
        .where((request) => request['status'] == 'open')
        .length;

    final resolvedCount = requests
        .where(
          (request) => request['status'] == 'resolved',
        )
        .length;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        18,
      ),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF087F82),
            Color(0xFF16B8B0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _summaryItem(
              value: '${requests.length}',
              label: 'Total',
              icon: Icons.list_alt_rounded,
            ),
          ),

          Container(
            height: 45,
            width: 1,
            color: Colors.white.withOpacity(0.22),
          ),

          Expanded(
            child: _summaryItem(
              value: '$openCount',
              label: 'Active',
              icon: Icons.access_time_rounded,
            ),
          ),

          Container(
            height: 45,
            width: 1,
            color: Colors.white.withOpacity(0.22),
          ),

          Expanded(
            child: _summaryItem(
              value: '$resolvedCount',
              label: 'Resolved',
              icon: Icons.check_circle_outline_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.85),
          size: 19,
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.75),
            fontSize: 9.5,
          ),
        ),
      ],
    );
  }

  Widget buildRequestCard(dynamic req) {
    final String category =
        req['category']?.toString() ?? '';

    final String status =
        req['status']?.toString() ?? '';

    final Color catColor =
        categoryColor(category);

    final Color statColor =
        statusColor(status);

    return GestureDetector(
      onTap: () => openRequest(req),
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          12,
        ),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE4ECEE),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.025),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: catColor.withOpacity(0.11),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                categoryIcon(category),
                color: catColor,
                size: 26,
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    req['itemText']?.toString() ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Icon(
                        Icons.category_outlined,
                        color: textLight,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        category.isEmpty
                            ? 'Request'
                            : category[0].toUpperCase() +
                                category.substring(1),
                        style: const TextStyle(
                          color: textLight,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusBackground(status),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon(status),
                        color: statColor,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formatStatus(status),
                        style: TextStyle(
                          color: statColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                Container(
                  height: 27,
                  width: 27,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F6F7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: textLight,
                    size: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 85),

        Center(
          child: Container(
            height: 90,
            width: 90,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: primaryDark,
              size: 42,
            ),
          ),
        ),

        const SizedBox(height: 20),

        const Center(
          child: Text(
            'No requests yet',
            style: TextStyle(
              color: textDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),

        const SizedBox(height: 7),

        const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 55,
          ),
          child: Text(
            'Your medicine and shopping requests will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textLight,
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryDark,
          onRefresh: fetchMyRequests,
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: primaryDark,
                    strokeWidth: 2.5,
                  ),
                )
              : requests.isEmpty
                  ? buildEmptyState()
                  : ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      children: [
                        buildHeader(),
                        buildSummaryCard(),

                        const Padding(
                          padding: EdgeInsets.fromLTRB(
                            18,
                            0,
                            18,
                            12,
                          ),
                          child: Text(
                            'Your Requests',
                            style: TextStyle(
                              color: textDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),

                        ...requests.map(
                          (req) => buildRequestCard(req),
                        ),

                        const SizedBox(height: 10),
                      ],
                    ),
        ),
      ),
    );
  }
}