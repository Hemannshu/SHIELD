import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:path_provider/path_provider.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: _selectedContact != null
            ? Text(
                _selectedContact!.displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Chats',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
        centerTitle: true,
        leading: _selectedContact != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: _handleBackButton,
              )
            : null,
        actions: [
          if (_selectedContact == null)
            IconButton(
              icon: Icon(
                _searching ? Icons.close : Icons.search,
                color: Colors.white,
              ),
              onPressed: _toggleSearch,
            ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFEC407A), Color(0xFFF06292)],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF5F7), Colors.white],
          ),
        ),
        child: Column(
          children: [
            if (_searching)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search contacts...',
                      prefixIcon: Icon(Icons.search, color: Color(0xFFEC407A)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
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
                child: EmojiPicker(
                  onEmojiSelected: (category, emoji) {
                    if (emoji != null) {
                      _messageController.text += emoji.emoji;
                    }
                  },
                  config: Config(
                    emojiViewConfig: EmojiViewConfig(
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
    if (_loadingContacts) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEC407A)),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _filteredContacts.length,
        itemBuilder: (context, index) {
          final contact = _filteredContacts[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFEC407A), Color(0xFFF06292)],
                  ),
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.transparent,
                  backgroundImage: contact.thumbnail != null
                      ? MemoryImage(contact.thumbnail!)
                      : null,
                  child: contact.thumbnail == null
                      ? Text(
                          contact.displayName.isNotEmpty 
                              ? contact.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
              ),
              title: Text(
                contact.displayName,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                contact.phones.isNotEmpty 
                    ? contact.phones.first.number 
                    : 'No phone number',
              ),
              onTap: () {
                setState(() {
                  _selectedContact = contact;
                  _searching = false;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatArea() {
    final user = _auth.currentUser;
    if (user == null) return const SizedBox();

    final contactPhone = _selectedContact!.phones.first.number;
    if (contactPhone.isEmpty) {
      return Center(
        child: Text(
          'No valid phone number for this contact',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    final userId = user.phoneNumber ?? user.email ?? user.uid;
    final chatId = _generateChatId(userId, contactPhone);

    return Expanded(
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/chat_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .orderBy('timestamp', descending: false)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEC407A)),
                )
              );
            }

            final messages = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(12),
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
                        maxWidth: MediaQuery.of(context).size.width * 0.8,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: isMe 
                              ? const LinearGradient(
                                  colors: [Color(0xFFEC407A), Color(0xFFF06292)],
                                )
                              : null,
                          color: isMe ? null : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: Radius.circular(isMe ? 12 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 12),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
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
    final textColor = isMe ? Colors.white : Colors.black87;
    
    switch (message['type']) {
      case 'image':
        final imagePath = message['imagePath'] as String?;
        if (imagePath == null) {
          return Text('Image not available', style: TextStyle(color: textColor));
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(File(imagePath), width: 200, height: 200),
        );
      case 'location':
        final lat = message['latitude'] as double?;
        final lng = message['longitude'] as double?;
        if (lat == null || lng == null) {
          return Text('Location not available', style: TextStyle(color: textColor));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.location_on, size: 40, color: isMe ? Colors.white : const Color(0xFFEC407A)),
            const SizedBox(height: 8),
            Text(
              'Shared Location',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            Text(
              '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
              style: TextStyle(color: textColor),
            ),
          ],
        );
      default:
        return Text(
          message['text']?.toString() ?? '',
          style: TextStyle(
            color: textColor,
            fontSize: 16,
          ),
        );
    }
  }

  Widget _buildMessageInput() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.emoji_emotions, color: Color(0xFFEC407A)),
            onPressed: () {
              setState(() {
                _showEmojiPicker = !_showEmojiPicker;
              });
            },
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.image, color: Color(0xFFEC407A)),
            onPressed: _sendImage,
          ),
          IconButton(
            icon: const Icon(Icons.location_on, color: Color(0xFFEC407A)),
            onPressed: _sendLocation,
          ),
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFEC407A), Color(0xFFF06292)],
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}