import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:title_proj/components/PrimaryButton.dart';
import 'package:title_proj/components/custom_textfield.dart';

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

  // Colors
  final Color primaryColor = Color(0xFFEC407A);
  final Color backgroundColor = Color(0xFFF5F5F5);
  final Color cardColor = Colors.white;
  final Color textColor = Color(0xFF333333);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Location Reviews',
        style: TextStyle(
      color: Colors.white, // Added black text color
    ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: isSaving
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: searchController,
                      onChanged: updateSearchQuery,
                      decoration: InputDecoration(
                        hintText: 'Search locations...',
                        prefixIcon: Icon(Icons.search, color: primaryColor),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20),
                      ),
                    ),
                  ),
                ),
                // Title
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Recent Reviews",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
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
                        return Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            "No reviews yet",
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      var filteredDocs = snapshot.data!.docs.where((doc) {
                        var data = doc.data() as Map<String, dynamic>?;
                        var location =
                            data?["location"]?.toString().toLowerCase() ??
                                "unknown";
                        return location.contains(searchQuery);
                      }).toList();

                      if (filteredDocs.isEmpty) {
                        return Center(
                          child: Text(
                            "No matching reviews found",
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: EdgeInsets.all(16),
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 12),
                        itemCount: filteredDocs.length,
                        itemBuilder: (BuildContext context, int index) {
                          final doc = filteredDocs[index];
                          final data = doc.data() as Map<String, dynamic>? ?? {};

                          String location = data["location"] ?? "Unknown";
                          String views = data["views"] ?? "No comments";
                          double rating =
                              (data["ratings"] as num?)?.toDouble() ?? 1.0;
                          Timestamp? timestamp =
                              data["timestamp"] as Timestamp?;
                          DateTime? date = timestamp?.toDate();

                          return Container(
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          location,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                      if (date != null)
                                        Text(
                                          "${date.day}/${date.month}/${date.year}",
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  RatingBarIndicator(
                                    rating: rating,
                                    itemBuilder: (context, index) => Icon(
                                      Icons.star,
                                      color: primaryColor,
                                    ),
                                    itemCount: 5,
                                    itemSize: 20,
                                    unratedColor: Colors.grey.shade300,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    views,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: textColor.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: () => showReviewDialog(context),
        child: Icon(Icons.add, color: Colors.white),
        elevation: 4,
      ),
    );
  }

  void showReviewDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          "Add Your Review",
          style: TextStyle(color: primaryColor),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                hintText: 'Location name',
                controller: locationC, prefixText: '',
              ),
              SizedBox(height: 16),
              CustomTextField(
                controller: viewsC,
                hintText: 'Your review comments',
                maxLines: 3, prefixText: '',
              ),
              SizedBox(height: 16),
              RatingBar.builder(
                initialRating: 1,
                minRating: 1,
                direction: Axis.horizontal,
                itemCount: 5,
                unratedColor: Colors.grey.shade300,
                itemPadding: EdgeInsets.symmetric(horizontal: 4),
                itemBuilder: (context, _) =>
                    Icon(Icons.star, color: primaryColor),
                onRatingUpdate: (rating) => setState(() => ratings = rating),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text("CANCEL", style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(context),
          ),
          PrimaryButton(
            title: "SUBMIT",
            onPressed: () {
              saveReview();
              Navigator.pop(context);
            },
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
