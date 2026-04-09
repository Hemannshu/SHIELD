import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:title_proj/db/db_services.dart';
import 'package:title_proj/model/contactsm.dart';
import 'package:title_proj/utils/app_theme.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Trusted\nContacts',
                    style: GoogleFonts.inter(
                      fontSize: 32, fontWeight: FontWeight.w800,
                      letterSpacing: -1, height: 1.1,
                      color: isDark ? Colors.white : AppTheme.neutralGrey900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Your emergency safety network',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: isDark ? Colors.white54 : AppTheme.neutralGrey400,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms),

            const SizedBox(height: 16),

            // Info card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [AppTheme.darkCard, AppTheme.darkElevated]
                        : [const Color(0xFFFFF0F3), const Color(0xFFFCE4EC)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.primaryPink.withOpacity(isDark ? 0.15 : 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPink.withOpacity(isDark ? 0.15 : 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.shield_rounded, color: AppTheme.primaryPink, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'These contacts will receive your location during emergencies',
                        style: GoogleFonts.inter(
                          fontSize: 13, height: 1.4,
                          color: isDark ? Colors.white70 : AppTheme.neutralGrey600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

            const SizedBox(height: 16),

            // Add button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity, height: 50,
                child: InkWell(
                  onTap: pickContact,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    decoration: AppTheme.gradientButton(radius: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text('Add Trusted Contact',
                          style: GoogleFonts.inter(
                            fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 500.ms),

            const SizedBox(height: 16),

            // Contact list
            Expanded(
              child: count == 0
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.05) : AppTheme.neutralGrey100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.people_outline_rounded, size: 48,
                              color: isDark ? Colors.white24 : AppTheme.neutralGrey400),
                          ),
                          const SizedBox(height: 16),
                          Text('No contacts yet',
                            style: GoogleFonts.inter(
                              fontSize: 18, fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white54 : AppTheme.neutralGrey600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Add your trusted contacts above',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: isDark ? Colors.white38 : AppTheme.neutralGrey400,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                      itemCount: count,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? Colors.white.withOpacity(0.06) : AppTheme.neutralGrey200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    contactList![index].name.isNotEmpty
                                        ? contactList![index].name[0].toUpperCase()
                                        : '?',
                                    style: GoogleFonts.inter(
                                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(contactList![index].name,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600, fontSize: 15,
                                        color: isDark ? Colors.white : AppTheme.neutralGrey900,
                                      ),
                                    ),
                                    Text(contactList![index].number,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: isDark ? Colors.white38 : AppTheme.neutralGrey400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.call_rounded, color: Colors.green[400], size: 22),
                                onPressed: () async {
                                  await FlutterContacts.openExternalEdit(
                                      contactList![index].id.toString());
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline_rounded,
                                  color: isDark ? Colors.red[300] : Colors.red[400], size: 22),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: Text('Remove Contact'),
                                      content: Text('Remove ${contactList![index].name}?'),
                                      actions: [
                                        TextButton(child: Text('Cancel'), onPressed: () => Navigator.pop(context)),
                                        TextButton(
                                          child: Text('Remove', style: TextStyle(color: Colors.red)),
                                          onPressed: () { deleteContact(contactList![index]); Navigator.pop(context); },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: (100 * index).ms, duration: 400.ms);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
