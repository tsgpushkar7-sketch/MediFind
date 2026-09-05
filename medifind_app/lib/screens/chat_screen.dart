import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final String requestId;
  final String shopName;
  final String senderRole;

  const ChatScreen({
    super.key,
    required this.requestId,
    required this.shopName,
    required this.senderRole,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController = TextEditingController();

  List messages = [];
  bool isLoading = true;
  String? userId;

  List<String> get quickReplies {
    if (widget.senderRole == 'shopkeeper') {
      return [
        "Yes, it's available",
        "Sorry, out of stock",
        "Please come in 10 mins",
      ];
    } else {
      return ["What's the price?", "I need 2", "Is it available now?"];
    }
  }

  @override
  void initState() {
    super.initState();
    loadUserAndMessages();
  }

  Future<void> loadUserAndMessages() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId');
    await fetchMessages();
  }

  Future<void> fetchMessages() async {
    final result = await ApiService.getChatMessages(widget.requestId);

    if (result['success']) {
      setState(() {
        messages = result['data'];
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || userId == null) return;

    messageController.clear();

    await ApiService.sendChatMessage(
      widget.requestId,
      userId!,
      widget.senderRole,
      text.trim(),
    );

    await fetchMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat with ${widget.shopName}')),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                ? const Center(child: Text('No messages yet. Say hi!'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];

                      final isMe = msg['senderRole'] == widget.senderRole;

                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? Colors.teal.shade100
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(msg['message']),
                        ),
                      );
                    },
                  ),
          ),

          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: quickReplies.map((reply) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ActionChip(
                    label: Text(reply),
                    onPressed: () => sendMessage(reply),
                  ),
                );
              }).toList(),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: sendMessage,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => sendMessage(messageController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
