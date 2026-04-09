import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:title_proj/components/PrimaryButton.dart';
import 'package:title_proj/components/custom_textfield.dart';
import 'package:title_proj/utils/app_theme.dart';

class ReviewPage extends StatefulWidget {
  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final TextEditingController locationC = TextEditingController();
  final TextEditingController viewsC = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  bool isSaving = false;
  double? ratings;
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: isSaving
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Text('Reviews',
                      style: GoogleFonts.inter(
                        fontSize: 32, fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        color: isDark ? Colors.white : AppTheme.neutralGrey900,
                      ),
                    ),
                  ).animate().fadeIn(duration: 500.ms),

                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Rate and review locations for safety',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: isDark ? Colors.white54 : AppTheme.neutralGrey400,
                      ),
                    ),
                  ),

                  // Search
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkCard : AppTheme.neutralGrey100,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.06) : AppTheme.neutralGrey200,
                        ),
                      ),
                      child: TextField(
                        controller: searchController,
                        onChanged: updateSearchQuery,
                        style: TextStyle(color: isDark ? Colors.white : AppTheme.neutralGrey900),
                        decoration: InputDecoration(
                          hintText: 'Search locations...',
                          prefixIcon: Icon(Icons.search_rounded, color: AppTheme.primaryPink, size: 22),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

                  const SizedBox(height: 16),
                  // Reviews List
                  Expanded(
                    child: StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection('reviews')
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (BuildContext context,
                          AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.rate_review_outlined, size: 48,
                                  color: isDark ? Colors.white24 : AppTheme.neutralGrey400),
                                const SizedBox(height: 12),
                                Text('No reviews yet',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: isDark ? Colors.white54 : AppTheme.neutralGrey400,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        var filteredDocs = snapshot.data!.docs.where((doc) {
                          var data = doc.data() as Map<String, dynamic>?;
                          var location =
                              data?["location"]?.toString().toLowerCase() ?? "unknown";
                          return location.contains(searchQuery);
                        }).toList();

                        if (filteredDocs.isEmpty) {
                          return Center(
                            child: Text('No matching reviews',
                              style: GoogleFonts.inter(color: isDark ? Colors.white38 : AppTheme.neutralGrey400),
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemCount: filteredDocs.length,
                          itemBuilder: (context, index) {
                            final doc = filteredDocs[index];
                            final data = doc.data() as Map<String, dynamic>? ?? {};
                            String location = data["location"] ?? "Unknown";
                            String views = data["views"] ?? "No comments";
                            double rating = (data["ratings"] as num?)?.toDouble() ?? 1.0;
                            Timestamp? timestamp = data["timestamp"] as Timestamp?;
                            DateTime? date = timestamp?.toDate();

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.darkCard : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark ? Colors.white.withOpacity(0.06) : AppTheme.neutralGrey200,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(location,
                                          style: GoogleFonts.inter(
                                            fontSize: 16, fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.white : AppTheme.neutralGrey900,
                                          ),
                                        ),
                                      ),
                                      if (date != null)
                                        Text("${date.day}/${date.month}/${date.year}",
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: isDark ? Colors.white38 : AppTheme.neutralGrey400,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  RatingBarIndicator(
                                    rating: rating,
                                    itemBuilder: (context, _) => const Icon(Icons.star_rounded, color: Color(0xFFFFB300)),
                                    itemCount: 5, itemSize: 18,
                                    unratedColor: isDark ? Colors.white12 : AppTheme.neutralGrey200,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(views,
                                    style: GoogleFonts.inter(
                                      fontSize: 14, height: 1.4,
                                      color: isDark ? Colors.white70 : AppTheme.neutralGrey600,
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(delay: (80 * index).ms, duration: 400.ms);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: Container(
        decoration: AppTheme.gradientButton(radius: 16),
        child: FloatingActionButton(
          onPressed: () => showReviewDialog(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add_rounded, color: Colors.white),
        ),
      ),
    );
  }

  void showReviewDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Add Review",
          style: GoogleFonts.inter(fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppTheme.neutralGrey900),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(hintText: 'Location name', controller: locationC, prefixText: ''),
              const SizedBox(height: 14),
              CustomTextField(controller: viewsC, hintText: 'Your review', maxLines: 3, prefixText: ''),
              const SizedBox(height: 14),
              RatingBar.builder(
                initialRating: 1, minRating: 1,
                direction: Axis.horizontal, itemCount: 5,
                unratedColor: isDark ? Colors.white12 : AppTheme.neutralGrey200,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4),
                itemBuilder: (_, __) => const Icon(Icons.star_rounded, color: Color(0xFFFFB300)),
                onRatingUpdate: (rating) => setState(() => ratings = rating),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text("Cancel", style: GoogleFonts.inter(color: isDark ? Colors.white54 : AppTheme.neutralGrey400)),
            onPressed: () => Navigator.pop(context),
          ),
          Container(
            decoration: AppTheme.gradientButton(radius: 10),
            child: TextButton(
              onPressed: () { saveReview(); Navigator.pop(context); },
              child: Text("Submit", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> saveReview() async {
    if (locationC.text.isEmpty) {
      Fluttertoast.showToast(msg: 'Please enter a location');
      return;
    }

    setState(() => isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('reviews').add({
        'location': locationC.text,
        'views': viewsC.text,
        'ratings': ratings ?? 1.0,
        'timestamp': FieldValue.serverTimestamp(),
      });

      locationC.clear();
      viewsC.clear();
      setState(() => ratings = null);

      Fluttertoast.showToast(
        msg: 'Review submitted successfully',
        backgroundColor: Colors.green,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to submit review: ${e.toString()}',
        backgroundColor: Colors.red,
      );
    } finally {
      setState(() => isSaving = false);
    }
  }

  void updateSearchQuery(String query) {
    setState(() => searchQuery = query.toLowerCase());
  }
}
