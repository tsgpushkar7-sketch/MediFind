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

  static const Color primary = Color(0xFF16B8B0);
  static const Color primaryDark = Color(0xFF087F82);
  static const Color background = Color(0xFFF5F9FA);
  static const Color textDark = Color(0xFF173042);
  static const Color textLight = Color(0xFF71828D);

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

  Widget buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 10, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE7EFF1),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: textDark,
            ),
          ),

          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primary, primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.local_pharmacy_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.shopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      height: 7,
                      width: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2BCB74),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Pharmacy',
                      style: TextStyle(
                        color: textLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.more_vert_rounded,
              color: textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget requestBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary.withOpacity(0.10),
            const Color(0xFFEAF8F8),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: primary.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.13),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.medication_rounded,
              color: primaryDark,
              size: 21,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Medicine Request',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Discuss availability and details',
                  style: TextStyle(
                    color: textLight,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'REQUEST',
              style: TextStyle(
                color: primaryDark,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget messageBubble(dynamic msg, bool isMe) {
    return Align(
      alignment:
          isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        margin: const EdgeInsets.symmetric(
          vertical: 5,
          horizontal: 16,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          gradient: isMe
              ? const LinearGradient(
                  colors: [
                    Color(0xFF087F82),
                    Color(0xFF16B8B0),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isMe ? null : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 5),
            bottomRight: Radius.circular(isMe ? 5 : 18),
          ),
          border: isMe
              ? null
              : Border.all(
                  color: const Color(0xFFE5EEF0),
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.025),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          msg['message'],
          style: TextStyle(
            color: isMe ? Colors.white : textDark,
            fontSize: 14,
            height: 1.35,
          ),
        ),
      ),
    );
  }

  Widget quickReplySection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: const Color(0xFFE7EFF1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: [
                Icon(
                  Icons.bolt_rounded,
                  color: primary,
                  size: 19,
                ),
                SizedBox(width: 5),
                Text(
                  'Quick Replies',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: quickReplies.map((reply) {
                return Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => sendMessage(reply),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F8F8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: primary.withOpacity(0.18),
                        ),
                      ),
                      child: Text(
                        reply,
                        style: const TextStyle(
                          color: primaryDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget messageComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F6F7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_rounded,
              color: textDark,
              size: 25,
            ),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F8F9),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: const Color(0xFFE1EAEC),
                ),
              ),
              child: TextField(
                controller: messageController,
                textInputAction: TextInputAction.send,
                onSubmitted: sendMessage,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 13,
                ),
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    color: textLight,
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 17,
                    vertical: 13,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 9),

          GestureDetector(
            onTap: () => sendMessage(messageController.text),
            child: Container(
              height: 48,
              width: 48,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF087F82),
                    Color(0xFF16B8B0),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            buildHeader(),

            requestBanner(),

            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: primary,
                      ),
                    )
                  : messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                height: 70,
                                width: 70,
                                decoration: BoxDecoration(
                                  color: primary.withOpacity(0.10),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: primary,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'No messages yet',
                                style: TextStyle(
                                  color: textDark,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'Start the conversation',
                                style: TextStyle(
                                  color: textLight,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];

                            final isMe =
                                msg['senderRole'] == widget.senderRole;

                            return messageBubble(msg, isMe);
                          },
                        ),
            ),

            quickReplySection(),

            messageComposer(),
          ],
        ),
      ),
    );
  }
}