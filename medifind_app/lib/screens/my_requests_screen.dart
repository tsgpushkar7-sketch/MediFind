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
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: fetchMyRequests,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : requests.isEmpty
              ? ListView(
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(child: Text('No requests yet.')),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final req = requests[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(req['itemText']),
                        subtitle: Text(req['category']),
                        trailing: Chip(
                          label: Text(
                            req['status'],
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: statusColor(req['status']),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RequestStatusScreen(
                                requestId: req['_id'],
                                itemText: req['itemText'],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}