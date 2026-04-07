import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'dart:io';

class MessagesPage extends StatefulWidget {
  final String parentEmail;
  final String childEmail;

  const MessagesPage({super.key, required this.parentEmail, required this.childEmail});

  @override
  _MessagesPageState createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  Location _location = Location();

  // Send message from child to parent
  void _sendMessage(String message) async {
    if (message.isNotEmpty) {
      try {
        await _firestore.collection('messages').add({
          'sender': widget.childEmail,
          'receiver': widget.parentEmail,
          'message': message,
          'timestamp': FieldValue.serverTimestamp(),
        });
        _controller.clear();  // Clear text field after sending
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send message')));
      }
    }
  }

  // Share location with parent
  Future<void> _shareLocation() async {
    try {
      var locationData = await _location.getLocation();
      _sendMessage('Location: Lat: ${locationData.latitude}, Lon: ${locationData.longitude}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to get location')));
    }
  }

  // Pick image from gallery
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        _sendMessage('Image: ${pickedFile.path}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick image')));
    }
  }

  // Capture image from camera
  Future<void> _captureImage() async {
    try {
      final XFile? capturedFile = await _picker.pickImage(source: ImageSource.camera);
      if (capturedFile != null) {
        _sendMessage('Image: ${capturedFile.path}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to capture image')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat with ${widget.parentEmail}"),
        backgroundColor: Colors.pink,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('messages')
                  .where('sender', isEqualTo: widget.childEmail)
                  .where('receiver', isEqualTo: widget.parentEmail)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No messages yet'));
                }

                final messages = snapshot.data!.docs;
                List<Widget> messageWidgets = [];
                for (var message in messages) {
                  final messageText = message['message'];
                  final messageSender = message['sender'];

                  // Check if the message is an image
                  if (messageText.startsWith('Image:')) {
                    final imagePath = messageText.replaceFirst('Image:', '').trim();
                    if (imagePath.startsWith('http') || imagePath.startsWith('https')) {
                      messageWidgets.add(
                        ListTile(
                          title: Image.network(imagePath),
                          subtitle: Text(messageSender),
                        ),
                      );
                    } else {
                      messageWidgets.add(
                        ListTile(
                          title: Image.file(File(imagePath)),
                          subtitle: Text(messageSender),
                        ),
                      );
                    }
                  } else {
                    messageWidgets.add(
                      ListTile(
                        title: Text(messageText),
                        subtitle: Text(messageSender),
                      ),
                    );
                  }
                }

                return ListView(
                  reverse: true, // Show the latest message at the bottom
                  children: messageWidgets,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.location_on),
                  onPressed: _shareLocation,
                ),
                IconButton(
                  icon: Icon(Icons.camera_alt),
                  onPressed: _captureImage,
                ),
                IconButton(
                  icon: Icon(Icons.photo_library),
                  onPressed: _pickImage,
                ),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    _sendMessage(_controller.text);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
