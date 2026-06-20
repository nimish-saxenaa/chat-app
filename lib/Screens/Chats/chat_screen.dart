import 'dart:io';
import 'package:chat_app/functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.userUid,
    required this.chatId,
    required this.otherUid,
    required this.otherUsername,
    required this.profilePic,
  });
  final String userUid;
  final String otherUid;
  final String chatId;
  final String otherUsername;
  final String? profilePic;
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Controllers & focus
  final TextEditingController controller = TextEditingController();
  final FocusNode textFieldFocus = FocusNode();
  final fire = FirebaseFirestore.instance;
  final storage = FirebaseStorage.instance;
  final picker = ImagePicker();
  // Selection state
  final Set<String> _selectedIds = {};
  final Set<String> _readMessageIds = {};
  bool get _isSelecting => _selectedIds.isNotEmpty;
  // Track image upload in progress
  bool _isUploading = false;

  // Toggle a message in/out of the selection set
  void _toggleSelection(String messageId) {
    setState(() {
      if (_selectedIds.contains(messageId)) {
        _selectedIds.remove(messageId);
      } else {
        _selectedIds.add(messageId);
      }
    });
  }

  // Exit selection mode
  void _clearSelection() {
    setState(() => _selectedIds.clear());
  }

  // Show confirmation dialog then batch-delete selected messages from Firestore
  Future<void> _deleteSelected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Messages'),
        content: Text(
          'Delete ${_selectedIds.length} message${_selectedIds.length == 1 ? '' : 's'}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xffbb6dce)),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final batch = fire.batch();
    final messagesRef = fire
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages');
    for (final id in _selectedIds) {
      batch.delete(messagesRef.doc(id));
    }
    await batch.commit();
    _clearSelection();
  }

  // Reset the unread counter on the chat document for the current user
  Future<void> readChat() async {
    fire.collection('chats').doc(widget.chatId).update({
      'unReadCount.${widget.userUid}': 0,
    });
  }

  // Mark a single message as read (called once per message using _readMessageIds)
  Future<void> readUnread(String messageId) async {
    await fire
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc(messageId)
        .update({'isRead': true});
  }

  // Batch-write a text message and update the parent chat document atomically
  Future<void> saveAndUpdate() async {
    if (controller.text.trim().isEmpty) return;
    final WriteBatch batch = fire.batch();
    final chatRef = fire.collection('chats').doc(widget.chatId);
    final messageRef = chatRef.collection('messages').doc();
    batch.set(messageRef, {
      'type': 'text',
      'text': controller.text,
      'imageUrl': null,
      'whoSent': widget.userUid,
      'timeStamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });
    batch.set(chatRef, {
      'lastMessage': controller.text,
      'lastTime': FieldValue.serverTimestamp(),
      'lastSender': widget.userUid,
      'unReadCount': {widget.otherUid: FieldValue.increment(1)},
    }, SetOptions(merge: true));
    await batch.commit();
  }

  // Upload image to Firebase Storage then save message document with the download URL
  Future<void> sendImage(ImageSource source) async {
    final XFile? picked = await picker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (picked == null) return;
    setState(() => _isUploading = true);
    try {
      // Upload to storage under chats/<chatId>/<timestamp>.jpg
      final ref = storage
          .ref()
          .child('chats')
          .child(widget.chatId)
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(File(picked.path));
      final imageUrl = await ref.getDownloadURL();
      // Save message document with type 'image' and the download URL
      final WriteBatch batch = fire.batch();
      final chatRef = fire.collection('chats').doc(widget.chatId);
      final messageRef = chatRef.collection('messages').doc();
      batch.set(messageRef, {
        'type': 'image',
        'text': null,
        'imageUrl': imageUrl,
        'whoSent': widget.userUid,
        'timeStamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      batch.set(chatRef, {
        'lastMessage': 'Photo',
        'lastTime': FieldValue.serverTimestamp(),
        'lastSender': widget.userUid,
        'unReadCount': {widget.otherUid: FieldValue.increment(1)},
      }, SetOptions(merge: true));
      await batch.commit();
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    textFieldFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar switches between normal view and selection mode
      appBar: AppBar(
        leading: _isSelecting
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearSelection,
              )
            : null,
        title: _isSelecting
            ? Text(
                '${_selectedIds.length} selected',
                style: const TextStyle(fontSize: 18),
              )
            : Row(
                children: [
                  // Other user's profile picture
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: Image.network(
                      widget.profilePic ?? '',
                      height: kToolbarHeight - 10,
                      fit: BoxFit.fill,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/profile.jpg',
                          height: kToolbarHeight - 10,
                          fit: BoxFit.fill,
                        );
                      },
                    ),
                  ),
                  Text('   ${widget.otherUsername}'),
                ],
              ),
        actions: _isSelecting
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete selected',
                  onPressed: _deleteSelected,
                ),
              ]
            : null,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.white.withAlpha(30), height: 0.5),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Upload progress indicator
            if (_isUploading)
              const LinearProgressIndicator(
                color: Color(0xffbb6dce),
                backgroundColor: Colors.transparent,
              ),
            // Live message stream
            StreamBuilder(
              stream: fire
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timeStamp', descending: true)
                  .snapshots(),
              builder: (context, messageSnapshot) {
                if (messageSnapshot.hasData) {
                  final texts = messageSnapshot.data?.docs;
                  if (texts!.isNotEmpty) {
                    readChat();
                    return Expanded(
                      child: ListView.builder(
                        reverse: true,
                        itemCount: texts.length,
                        itemBuilder: (context, index) {
                          final messageId = texts[index].id;
                          final String whoSent = texts[index]['whoSent'];
                          final bool isUs = whoSent == widget.userUid;
                          final bool isSelected = _selectedIds.contains(
                            messageId,
                          );
                          // Determine bubble grouping with neighbours
                          final bool isNext = index != 0
                              ? texts[index - 1]['whoSent'] == whoSent
                              : false;
                          final bool wasPrev = index != texts.length - 1
                              ? texts[index + 1]['whoSent'] == whoSent
                              : false;
                          final bool areSameDay = isSameDay(
                            now: texts[index]['timeStamp'] ?? Timestamp.now(),
                            prev:
                                texts[index < texts.length - 1
                                    ? index + 1
                                    : index]['timeStamp'] ??
                                Timestamp.now(),
                          );
                          // Mark incoming messages as read once per session
                          if (!isUs &&
                              !(texts[index]['isRead'] ?? false) &&
                              !_readMessageIds.contains(messageId)) {
                            _readMessageIds.add(messageId);
                            readUnread(messageId);
                          }
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Date separator — shown when this message is from a different day than the one below
                              if (!areSameDay)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        DateFormat('d/M/y').format(
                                          (texts[index]['timeStamp'] ??
                                                  Timestamp.now())
                                              .toDate(),
                                        ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              GestureDetector(
                                onLongPress: () => _toggleSelection(messageId),
                                onTap: _isSelecting
                                    ? () => _toggleSelection(messageId)
                                    : null,
                                child: ChatBubble(
                                  type: texts[index]['type'] ?? 'text',
                                  text: texts[index]['text'],
                                  imageUrl: texts[index]['imageUrl'],
                                  isUs: isUs,
                                  isNext: isNext,
                                  wasPrev: wasPrev,
                                  timeStamp:
                                      texts[index]['timeStamp'] ??
                                      Timestamp.now(),
                                  isSameDay: areSameDay,
                                  isRead: texts[index]['isRead'] ?? false,
                                  isSelected: isSelected,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  }
                  // Empty state
                  return const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('No Messages...', style: TextStyle(fontSize: 20)),
                      ],
                    ),
                  );
                }
                return const CircularProgressIndicator(color: Colors.red);
              },
            ),
            // Message input bar
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 60,
                    margin: const EdgeInsets.only(
                      left: 15,
                      top: 5,
                      right: 5,
                      bottom: 5,
                    ),
                    padding: const EdgeInsets.only(
                      left: 25,
                      top: 5,
                      right: 15,
                      bottom: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(20),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(100),
                      ),
                    ),
                    child: TextField(
                      focusNode: textFieldFocus,
                      controller: controller,
                      onSubmitted: (String value) async {
                        await saveAndUpdate();
                        controller.clear();
                        textFieldFocus.requestFocus();
                      },
                      decoration: const InputDecoration(
                        hintText: 'Type Your Message...',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                // Gallery picker button
                _MediaButton(
                  icon: Icons.photo_outlined,
                  onTap: _isUploading
                      ? null
                      : () => sendImage(ImageSource.gallery),
                ),
                // Camera button
                _MediaButton(
                  icon: Icons.camera_alt_outlined,
                  onTap: _isUploading
                      ? null
                      : () => sendImage(ImageSource.camera),
                ),
                // Send button
                GestureDetector(
                  onTap: () async {
                    await saveAndUpdate();
                    controller.clear();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 15, left: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: const Color(0xffbb6dce),
                    ),
                    width: 60,
                    height: 60,
                    child: const Icon(Icons.send, size: 30),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Small icon button used for camera and gallery
class _MediaButton extends StatelessWidget {
  const _MediaButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Colors.white.withAlpha(20),
        ),
        width: 48,
        height: 48,
        child: Icon(
          icon,
          size: 24,
          color: onTap == null ? Colors.grey : Colors.white,
        ),
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.type,
    required this.text,
    required this.imageUrl,
    required this.isUs,
    required this.isNext,
    required this.wasPrev,
    required this.timeStamp,
    required this.isSameDay,
    required this.isRead,
    required this.isSelected,
  });
  final String type;
  final String? text;
  final String? imageUrl;
  final bool isSameDay;
  final bool isUs;
  final bool isNext;
  final bool wasPrev;
  final Timestamp timeStamp;
  final bool isRead;
  final bool isSelected;
  final Radius yesRound = const Radius.circular(18);
  final Radius noRound = const Radius.circular(2);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final double imageSize = width / 1.8;
    final borderRadius = isUs
        ? BorderRadius.only(
            bottomRight: isNext
                ? noRound
                : wasPrev
                ? yesRound
                : noRound,
            topRight: wasPrev ? noRound : yesRound,
            topLeft: yesRound,
            bottomLeft: yesRound,
          )
        : BorderRadius.only(
            bottomLeft: isNext
                ? noRound
                : wasPrev
                ? yesRound
                : noRound,
            topLeft: wasPrev ? noRound : yesRound,
            topRight: yesRound,
            bottomRight: yesRound,
          );
    // Dim bubble color when selected
    final bubbleColor = isSelected
        ? (isUs
              ? const Color(0xffbb6dce).withAlpha(160)
              : const Color(0xff282c34).withAlpha(160))
        : (isUs ? const Color(0xffbb6dce) : const Color(0xff282c34));
    // Timestamp + read receipt row, reused by both content types
    final timeRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          DateFormat('h:mm a').format(timeStamp.toDate()),
          style: const TextStyle(fontSize: 10),
        ),
        if (isUs)
          Padding(
            padding: const EdgeInsets.only(left: 3),
            child: Icon(isRead ? Icons.done_all : Icons.done, size: 15),
          ),
      ],
    );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      // Highlight row background when selected
      color: isSelected ? Colors.white.withAlpha(15) : Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
        child: Column(
          crossAxisAlignment: isUs
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (type == 'image' && imageUrl != null)
              // Image bubble — square crop, same width cap and color as text bubble
              Material(
                borderRadius: borderRadius,
                color: bubbleColor,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          PageRouteBuilder(
                            opaque:
                                false, // lets the route underneath show through
                            barrierColor: Colors.transparent,
                            pageBuilder: (_, __, ___) =>
                                FullScreenImage(imageUrl: imageUrl!),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageUrl!,
                            width: imageSize,
                            height: imageSize,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return SizedBox(
                                width: imageSize,
                                height: imageSize,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white54,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return SizedBox(
                                width: imageSize,
                                height: imageSize,
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.white54,
                                    size: 40,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      timeRow,
                    ],
                  ),
                ),
              )
            else
              // Text bubble
              Material(
                borderRadius: borderRadius,
                color: bubbleColor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 12,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: width / 1.8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Message text
                        Text(
                          (text ?? '').trim(),
                          style: const TextStyle(fontSize: 20),
                          overflow: TextOverflow.visible,
                        ),
                        // Timestamp and read receipt
                        timeRow,
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class FullScreenImage extends StatelessWidget {
  const FullScreenImage({super.key, required this.imageUrl});
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Transparent scaffold so the chat shows through
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Semi-transparent dark overlay as the background
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(color: Colors.black.withAlpha(180)),
          ),
          // Image centered and full width
          Center(
            child: InteractiveViewer(
              maxScale: 4,
              child: Image.network(
                imageUrl,
                width: MediaQuery.sizeOf(context).width,
                fit: BoxFit.fitWidth,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white54),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                      size: 60,
                    ),
                  );
                },
              ),
            ),
          ),
          // Close button
          Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(120),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.close, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
