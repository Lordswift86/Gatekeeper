import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/security_service.dart';
import '../models/data_models.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  List<ChatMessage> _messages = [];
  User? _currentUser;
  User? _chatUser;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, User>;
    _currentUser = args['currentUser'];
    _chatUser = args['chatUser'];
    _loadMessages();
  }

  void _loadMessages() {
    if (_currentUser == null || _chatUser == null) return;
    setState(() {
      _messages = SecurityService().getMessages(_currentUser!.id, _chatUser!.id);
    });
  }

  void _sendMessage() {
    if (_msgController.text.trim().isEmpty) return;
    SecurityService().sendMessage(_currentUser!.id, _chatUser!.id, _msgController.text);
    _msgController.clear();
    _loadMessages();
  }

  @override
  Widget build(BuildContext context) {
    if (_chatUser == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_chatUser!.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text("Unit ${_chatUser!.unitNumber}", style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg.fromId == _currentUser!.id;
                final time = DateFormat.jm().format(DateTime.fromMillisecondsSinceEpoch(msg.timestamp));

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.indigo : Colors.grey.shade200,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                        bottomRight: isMe ? Radius.zero : const Radius.circular(16)
                      )
                    ),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(msg.content, style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
                        const SizedBox(height: 4),
                        Text(time, style: TextStyle(color: isMe ? Colors.white70 : Colors.black54, fontSize: 10))
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Theme.of(context).cardColor, border: Border(top: BorderSide(color: Colors.grey.shade200))),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: InputDecoration(
                       hintText: "Type a message...",
                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                       filled: true,
                       fillColor: Colors.grey.shade100,
                       contentPadding: const EdgeInsets.symmetric(horizontal: 20)
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sendMessage,
                  icon: const Icon(LucideIcons.send),
                  style: IconButton.styleFrom(backgroundColor: Colors.indigo),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
