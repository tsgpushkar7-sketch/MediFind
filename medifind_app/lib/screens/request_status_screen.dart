import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'chat_screen.dart';
import 'rating_screen.dart';

class RequestStatusScreen extends StatefulWidget {
  final String requestId;
  final String itemText;

  const RequestStatusScreen({
    super.key,
    required this.requestId,
    required this.itemText,
  });

  @override
  State<RequestStatusScreen> createState() => _RequestStatusScreenState();
}

class _RequestStatusScreenState extends State<RequestStatusScreen> {
  List<dynamic> responses = [];
  bool isLoading = true;
  String? statusMessage;

  @override
  void initState() {
    super.initState();
    fetchResponses();
  }

  Future<void> fetchResponses() async {
    setState(() {
      isLoading = true;
    });

    final result = await ApiService.getResponsesForRequest(widget.requestId);

    if (result['success']) {
      final data = result['data'];
      setState(() {
        responses = data['responses'] ?? [];
        statusMessage = data['message'];
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

 Future<void> handleSelectShop(String shopId, String shopName) async {
    final result = await ApiService.selectShop(widget.requestId, shopId);

    if (result['success']) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RatingScreen(
              requestId: widget.requestId,
              shopId: shopId,
              shopName: shopName,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Request: ${widget.itemText}')),
      body: RefreshIndicator(
        onRefresh: fetchResponses,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : statusMessage != null
                ? Center(child: Text(statusMessage!))
                : responses.isEmpty
                    ? ListView(
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(40.0),
                            child: Center(
                              child: Text(
                                'No shops have responded yet.\nPull down to refresh.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        itemCount: responses.length,
                        itemBuilder: (context, index) {
                          final res = responses[index];
                          final shop = res['shopId'];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              title: Text(shop['shopName']),
                              subtitle: Text(
                                '${shop['address']}\n${res['priceInfo'] ?? 'Price not shared'}',
                              ),
                              isThreeLine: true,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                   builder: (context) => ChatScreen(
                                      requestId: widget.requestId,
                                      shopName: shop['shopName'],
                                      senderRole: 'customer',
                                    ),
                                  ),
                                );
                              },
                              trailing: ElevatedButton(
                                onPressed: () => handleSelectShop(shop['_id'], shop['shopName']),
                                child: const Text('Select'),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}