import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'messages.dart';  // Import MessagesPage instead of ChatPage

class GuardianChildrenPage extends StatelessWidget {
  final String guardianEmail;

  const GuardianChildrenPage({super.key, required this.guardianEmail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Children of Guardian"),
        backgroundColor: Colors.pink,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('guardiantEmail', isEqualTo: guardianEmail)
            .where('type', isEqualTo: 'child')  // Only fetch children documents
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final children = snapshot.data!.docs;

          if (children.isEmpty) {
            return Center(child: Text("No children found for this guardian."));
          }

          return ListView.builder(
            itemCount: children.length,
            itemBuilder: (context, index) {
              final child = children[index];
              final childName = child['name'];
              final childEmail = child['childEmail'];  // Assuming childEmail is stored in the child document

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  color: Colors.pink[100],  // Child card color
                  child: ListTile(
                    title: Text(childName),
                    onTap: () {
                      // Navigate to the messages page (chat) when the child is selected
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MessagesPage(  // Navigate to MessagesPage
                            parentEmail: guardianEmail,  // Pass the guardian's email
                            childEmail: childEmail,      // Pass the child's email
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
