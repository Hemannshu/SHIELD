import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:title_proj/db/db_services.dart';
import 'package:title_proj/model/contactsm.dart';

class ContactsPage extends StatefulWidget {
  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<TContact>? contactList;
  int count = 0;

  void showList() {
    _databaseHelper.getContactList().then((value) {
      setState(() {
        contactList = value;
        count = value.length;
      });
    });
  }

  void deleteContact(TContact contact) async {
    int result = await _databaseHelper.deleteContact(contact.id);
    if (result != 0) {
      Fluttertoast.showToast(
        msg: "Contact removed successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      showList();
    }
  }

  Future<void> pickContact() async {
    if (await FlutterContacts.requestPermission()) {
      final contact = await FlutterContacts.openExternalPick();
      if (contact != null && contact.phones.isNotEmpty) {
        String phoneNumber = contact.phones.first.number;

        bool exists = await _databaseHelper.contactExists(phoneNumber);
        if (exists) {
          Fluttertoast.showToast(
            msg: "Contact already exists",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.orange,
            textColor: Colors.white,
          );
          return;
        }

        TContact newContact = TContact(phoneNumber, contact.displayName);
        await _databaseHelper.insertContact(newContact);
        showList();
      }
    } else {
      Fluttertoast.showToast(
        msg: "Permission denied",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    showList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Trusted Contacts',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20)),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurpleAccent, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(12),
              child: ListTile(
                contentPadding: EdgeInsets.all(16),
                leading: Icon(Icons.shield, color: Colors.deepPurple),
                title: Text('Trusted Contacts',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Text(
                    'These contacts will receive your emergency location.'),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: pickContact,
              icon: Icon(Icons.person_add_alt_1, size: 20),
              label: Text('ADD TRUSTED CONTACT',
                  style: TextStyle(fontSize: 14, letterSpacing: 1)),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color.fromARGB(255, 183, 58, 141),
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 5,
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: count == 0
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.group_off,
                            size: 80, color: Colors.grey[300]),
                        SizedBox(height: 16),
                        Text('No trusted contacts',
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey[700])),
                        SizedBox(height: 6),
                        Text('Add some contacts to get started',
                            style: TextStyle(color: Colors.grey[500])),
                      ], 
                    )
                  : ListView.separated(
                      itemCount: count,
                      separatorBuilder: (_, __) => SizedBox(height: 12),
                      itemBuilder: (BuildContext context, int index) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              )
                            ],
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            leading: CircleAvatar(
                              backgroundColor: Colors.purple[100],
                              child: Icon(Icons.person,
                                  color: Colors.deepPurple),
                            ),
                            title: Text(contactList![index].name,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 16)),
                            subtitle: Text(contactList![index].number),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.call,
                                      color: Colors.green.shade600),
                                  onPressed: () async {
                                    await FlutterContacts.openExternalEdit(
                                        contactList![index].id.toString());
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete,
                                      color: Colors.red.shade600),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: Text('Remove Contact'),
                                        content: Text(
                                            'Are you sure you want to remove ${contactList![index].name}?'),
                                        actions: [
                                          TextButton(
                                            child: Text('Cancel'),
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                          ),
                                          TextButton(
                                            child: Text('Remove',
                                                style: TextStyle(
                                                    color: Colors.red)),
                                            onPressed: () {
                                              deleteContact(contactList![index]);
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Add your "get location" function here
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text(
                      'GET LOCATION',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 1),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Add your "send alert" function here
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text(
                      'SEND ALERT',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 1),
                    ),
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
