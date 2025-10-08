import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../models/buddy_model.dart'; 
import '../../models/message_model.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/quick_reply_button.dart';

class ChatScreen extends StatefulWidget {
  final Buddy buddy;
  final String? initialMessage;

  const ChatScreen({
    Key? key,
    required this.buddy,
    this.initialMessage,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  final ScrollController _scrollController = ScrollController();
  List<QuickReply> _quickReplies = [];

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
    if (widget.initialMessage != null) {
      _addUserMessage(widget.initialMessage!);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_quickReplies.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      _quickReplies = [
        QuickReply(l10n.quickReplyTimeOff, 'HR'),
        QuickReply(l10n.quickReplyWifi, 'Technical'),
        QuickReply(l10n.quickReplyPortal, 'Technical'),
        QuickReply(l10n.quickReplyBenefits, 'HR'),
        QuickReply(l10n.quickReplyEmergencyContact, 'HR'),
      ];
    }
  }

  void _addWelcomeMessage() {
    _messages.add(Message(
      id: DateTime.now().toString(),
      senderId: widget.buddy.id,
      senderName: widget.buddy.name,
      text: _getWelcomeMessage(context),
      timestamp: DateTime.now(),
      isMe: false,
    ));
  }

  String _getWelcomeMessage(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (widget.buddy.department == 'HR') {
      return l10n.chatWelcomeHR(widget.buddy.name);
    } else {
      return l10n.chatWelcomeTechnical(widget.buddy.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(widget.buddy.imageUrl),
              radius: 18,
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.buddy.name),
                Text(
                  widget.buddy.isOnline ? AppLocalizations.of(context)!.online : AppLocalizations.of(context)!.offline,
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.phone),
            onPressed: _makePhoneCall,
          ),
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: _showOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick Replies Section
          if (_messages.length <= 2)
            Container(
              height: 80,
              padding: EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _quickReplies.length,
                itemBuilder: (context, index) {
                  final reply = _quickReplies[index];
                  if (reply.category == widget.buddy.department || 
                      reply.category == 'Both') {
                    return QuickReplyButton(
                      text: reply.text,
                      onTap: () => _sendQuickReply(reply.text),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
            ),

          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return MessageBubble(message: message);
              },
            ),
          ),

          // Input Section
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  offset: Offset(0, -2),
                  blurRadius: 4,
                  color: Colors.black12,
                ),
              ],
            ),
            child: Row(
              children: [
                // Attachment Button
                IconButton(
                  icon: Icon(Icons.attach_file),
                  onPressed: _attachFile,
                ),
                
                // Message Input
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.typeAMessage,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onSubmitted: (text) => _sendMessage(),
                  ),
                ),
                
                // Send Button
                IconButton(
                  icon: Icon(Icons.send),
                  color: Colors.blue[700],
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _messages.add(Message(
          id: DateTime.now().toString(),
          senderId: 'user',
          senderName: 'You',
          text: text,
          timestamp: DateTime.now(),
          isMe: true,
        ));
        _messageController.clear();
      });
      _scrollToBottom();
      
      // Simulate buddy reply after 1-3 seconds
      Future.delayed(Duration(seconds: 1 + (DateTime.now().millisecond % 3)), () {
        _addBuddyReply(text);
      });
    }
  }

  void _sendQuickReply(String text) {
    setState(() {
      _messages.add(Message(
        id: DateTime.now().toString(),
        senderId: 'user',
        senderName: 'You',
        text: text,
        timestamp: DateTime.now(),
        isMe: true,
      ));
    });
    _scrollToBottom();
    
    Future.delayed(Duration(seconds: 1), () {
      _addBuddyReply(text);
    });
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(Message(
        id: DateTime.now().toString(),
        senderId: 'user',
        senderName: 'You',
        text: text,
        timestamp: DateTime.now(),
        isMe: true,
      ));
    });
    _scrollToBottom();
  }

  void _addBuddyReply(String userMessage) {
    setState(() {
      _messages.add(Message(
        id: DateTime.now().toString(),
        senderId: widget.buddy.id,
        senderName: widget.buddy.name,
        text: _generateReply(userMessage, context),
        timestamp: DateTime.now(),
        isMe: false,
      ));
    });
    _scrollToBottom();
  }

  String _generateReply(String userMessage, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Simple AI-like response generation
    if (userMessage.toLowerCase().contains('password') || 
        userMessage.toLowerCase().contains('wifi')) {
      return l10n.chatReplyWifi;
    } else if (userMessage.toLowerCase().contains('time off') || 
               userMessage.toLowerCase().contains('leave')) {
      return l10n.chatReplyTimeOff;
    } else if (userMessage.toLowerCase().contains('benefit')) {
      return l10n.chatReplyBenefits;
    } else {
      return l10n.chatReplyDefault;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _makePhoneCall() {
    // Implement phone call functionality
  }

  void _attachFile() {
    // Implement file attachment functionality
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.history),
                title: Text(AppLocalizations.of(context)!.chatHistory),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to chat history
                },
              ),
              ListTile(
                leading: Icon(Icons.help),
                title: Text(AppLocalizations.of(context)!.faq),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to FAQ
                },
              ),
              ListTile(
                leading: Icon(Icons.report),
                title: Text(AppLocalizations.of(context)!.reportIssue),
                onTap: () {
                  Navigator.pop(context);
                  // Report issue functionality
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class QuickReply {
  final String text;
  final String category;

  QuickReply(this.text, this.category);
}