import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as emoji_flutter;
import 'package:path_provider/path_provider.dart';
import 'package:title_proj/utils/app_theme.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  Contact? _selectedContact;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _showEmojiPicker = false;
  bool _loadingContacts = false;
  bool _searching = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.contacts.request();
    if (status.isGranted) {
      _fetchContacts();
    } else {
      _showSnackBar('Contacts permission denied');
    }
  }

  Future<void> _fetchContacts() async {
    setState(() => _loadingContacts = true);
    try {
      if (await FlutterContacts.requestPermission()) {
        final contacts = await FlutterContacts.getContacts(
          withProperties: true,
          withThumbnail: true,
        );
        setState(() {
          _contacts = contacts.where((c) => c.phones.isNotEmpty).toList();
          _filteredContacts = _contacts;
          _loadingContacts = false;
        });
      }
    } catch (e) {
      setState(() => _loadingContacts = false);
      _showSnackBar('Failed to fetch contacts: ${e.toString()}');
    }
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredContacts = _contacts.where((contact) {
        return contact.displayName.toLowerCase().contains(query) ||
            contact.phones.any((phone) => phone.number.contains(query));
      }).toList();
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: Color(0xFFEC407A),
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty || _selectedContact == null) return;

    final user = _auth.currentUser;
    if (user == null) return;

    final contactPhone = _selectedContact!.phones.first.number;
    if (contactPhone.isEmpty) return;

    final userId = user.phoneNumber ?? user.email ?? user.uid;
    final chatId = _generateChatId(userId, contactPhone);

    try {
      await _firestore.collection('chats').doc(chatId).collection('messages').add({
        'senderId': userId,
        'text': _messageController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
      });

      _messageController.clear();
    } catch (e) {
      _showSnackBar('Failed to send message: ${e.toString()}');
    }
  }

  Future<void> _sendImage() async {
    if (_selectedContact == null) return;

    final user = _auth.currentUser;
    if (user == null) return;

    final contactPhone = _selectedContact!.phones.first.number;
    if (contactPhone.isEmpty) {
      _showSnackBar('Contact has no valid phone number');
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final localPath = await _saveImageLocally(File(image.path));
      
      final userId = user.phoneNumber ?? user.email ?? user.uid;
      final chatId = _generateChatId(userId, contactPhone);

      await _firestore.collection('chats').doc(chatId).collection('messages').add({
        'senderId': userId,
        'imagePath': localPath,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'image',
      });
    } catch (e) {
      _showSnackBar('Failed to send image: ${e.toString()}');
    }
  }

  Future<void> _sendLocation() async {
    if (_selectedContact == null) return;

    final user = _auth.currentUser;
    if (user == null) return;

    final contactPhone = _selectedContact!.phones.first.number;
    if (contactPhone.isEmpty) {
      _showSnackBar('Contact has no valid phone number');
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      final userId = user.phoneNumber ?? user.email ?? user.uid;
      final chatId = _generateChatId(userId, contactPhone);

      await _firestore.collection('chats').doc(chatId).collection('messages').add({
        'senderId': userId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'location',
      });
    } catch (e) {
      _showSnackBar('Failed to send location: ${e.toString()}');
    }
  }

  Future<String> _saveImageLocally(File image) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${_uuid.v4()}.jpg';
      final localFile = File('${directory.path}/$fileName');
      await image.copy(localFile.path);
      return localFile.path;
    } catch (e) {
      throw Exception('Failed to save image locally: ${e.toString()}');
    }
  }

  String _generateChatId(String user1, String user2) {
    final ids = [user1, user2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  void _handleBackButton() {
    setState(() {
      _selectedContact = null;
    });
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _searchController.clear();
        _filterContacts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: _selectedContact != null
            ? Text(
                _selectedContact!.displayName,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700, fontSize: 18,
                  color: Colors.white,
                ),
              )
            : Text('Chats',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700, fontSize: 18,
                  color: Colors.white,
                ),
              ),
        centerTitle: true,
        leading: _selectedContact != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: _handleBackButton,
              )
            : null,
        actions: [
          if (_selectedContact == null)
            IconButton(
              icon: Icon(
                _searching ? Icons.close_rounded : Icons.search_rounded,
                color: Colors.white,
              ),
              onPressed: _toggleSearch,
            ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
        elevation: 0,
      ),
      body: Container(
        color: isDark ? AppTheme.darkBackground : AppTheme.neutralGrey50,
        child: Column(
          children: [
            if (_searching)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkElevated : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isDark ? [] : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.inter(
                      color: isDark ? Colors.white : AppTheme.neutralGrey900,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search contacts...',
                      hintStyle: GoogleFonts.inter(color: AppTheme.neutralGrey400),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryPink),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    ),
                  ),
                ),
              ),
            if (_selectedContact == null) _buildContactsList(),
            if (_selectedContact != null) _buildChatArea(),
            if (_selectedContact != null) _buildMessageInput(),
            if (_showEmojiPicker)
              SizedBox(
                height: 250,
                child: emoji_flutter.EmojiPicker(
                  onEmojiSelected: (category, emoji) {
                    if (emoji != null) {
                      _messageController.text += emoji.emoji;
                    }
                  },
                  config: emoji_flutter.Config(
                    emojiViewConfig: emoji_flutter.EmojiViewConfig(
                      columns: 7,
                      emojiSizeMax: 32.0,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactsList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_loadingContacts) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryPink),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filteredContacts.length,
        itemBuilder: (context, index) {
          final contact = _filteredContacts[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDark ? [] : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10, offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: contact.thumbnail != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.memory(contact.thumbnail!, fit: BoxFit.cover))
                      : Center(
                          child: Text(
                            contact.displayName.isNotEmpty
                                ? contact.displayName[0].toUpperCase() : '?',
                            style: GoogleFonts.inter(
                              fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                ),
                title: Text(contact.displayName,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, fontSize: 15,
                    color: isDark ? Colors.white : AppTheme.neutralGrey900,
                  ),
                ),
                subtitle: Text(
                  contact.phones.isNotEmpty ? contact.phones.first.number : 'No phone number',
                  style: GoogleFonts.inter(fontSize: 13, color: AppTheme.neutralGrey500),
                ),
                trailing: Icon(Icons.chevron_right_rounded,
                  color: isDark ? Colors.white24 : AppTheme.neutralGrey300),
                onTap: () => setState(() {
                  _selectedContact = contact;
                  _searching = false;
                }),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatArea() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = _auth.currentUser;
    if (user == null) {
      return Expanded(
        child: Center(
          child: Text('Please sign in to chat',
            style: GoogleFonts.inter(color: AppTheme.neutralGrey500)),
        ),
      );
    }

    if (_selectedContact!.phones.isEmpty) {
      return Expanded(
        child: Center(
          child: Text('No valid phone number for this contact',
            style: GoogleFonts.inter(color: AppTheme.neutralGrey500)),
        ),
      );
    }

    final contactPhone = _selectedContact!.phones.first.number;
    if (contactPhone.isEmpty) {
      return Expanded(
        child: Center(
          child: Text('No valid phone number for this contact',
            style: GoogleFonts.inter(color: AppTheme.neutralGrey500)),
        ),
      );
    }

    final userId = user.phoneNumber ?? user.email ?? user.uid;
    final chatId = _generateChatId(userId, contactPhone);

    return Expanded(
      child: Container(
        color: isDark ? AppTheme.darkBackground : AppTheme.neutralGrey50,
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .orderBy('timestamp', descending: false)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                        size: 48, color: AppTheme.neutralGrey300),
                      const SizedBox(height: 16),
                      Text('Start a conversation!',
                        style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : AppTheme.neutralGrey600,
                        )),
                      const SizedBox(height: 4),
                      Text('Send a message to begin chatting',
                        style: GoogleFonts.inter(
                          fontSize: 13, color: AppTheme.neutralGrey400)),
                    ],
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryPink),
                ),
              );
            }

            final messages = snapshot.data?.docs ?? [];

            if (messages.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                        size: 48, color: AppTheme.neutralGrey300),
                      const SizedBox(height: 16),
                      Text('No messages yet',
                        style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : AppTheme.neutralGrey600,
                        )),
                      const SizedBox(height: 4),
                      Text('Say hello!',
                        style: GoogleFonts.inter(
                          fontSize: 13, color: AppTheme.neutralGrey400)),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index].data() as Map<String, dynamic>;
                final isMe = message['senderId'] == userId;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: isMe ? AppTheme.primaryGradient : null,
                          color: isMe ? null : (isDark ? AppTheme.darkElevated : Colors.white),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(isMe ? 18 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 18),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 8, offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _buildMessageContent(message, isMe),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildMessageContent(Map<String, dynamic> message, bool isMe) {
    final textColor = isMe ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.neutralGrey900);
    
    switch (message['type']) {
      case 'image':
        final imagePath = message['imagePath'] as String?;
        if (imagePath == null) {
          return Text('Image not available', style: GoogleFonts.inter(color: textColor));
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(File(imagePath), width: 200, height: 200),
        );
      case 'location':
        final lat = message['latitude'] as double?;
        final lng = message['longitude'] as double?;
        if (lat == null || lng == null) {
          return Text('Location not available', style: GoogleFonts.inter(color: textColor));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.location_on_rounded, size: 32,
              color: isMe ? Colors.white : AppTheme.primaryPink),
            const SizedBox(height: 6),
            Text('Shared Location',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: textColor)),
            Text('${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
              style: GoogleFonts.inter(fontSize: 12, color: textColor)),
          ],
        );
      default:
        return Text(
          message['text']?.toString() ?? '',
          style: GoogleFonts.inter(color: textColor, fontSize: 15),
        );
    }
  }

  Widget _buildMessageInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkElevated : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.emoji_emotions_rounded,
              color: _showEmojiPicker ? AppTheme.primaryPink : AppTheme.neutralGrey400),
            onPressed: () => setState(() => _showEmojiPicker = !_showEmojiPicker),
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.white : AppTheme.neutralGrey900,
              ),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: GoogleFonts.inter(color: AppTheme.neutralGrey400, fontSize: 14),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.image_rounded, color: AppTheme.neutralGrey400, size: 22),
            onPressed: _sendImage,
          ),
          IconButton(
            icon: const Icon(Icons.location_on_rounded, color: AppTheme.neutralGrey400, size: 22),
            onPressed: _sendLocation,
          ),
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: AppTheme.primaryGradient,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}