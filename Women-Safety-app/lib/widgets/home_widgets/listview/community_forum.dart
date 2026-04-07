import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path_helper;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class CommunityForum extends StatefulWidget {
  @override
  _CommunityForumState createState() => _CommunityForumState();
}

class ForumPost {
  final int? id;
  final String title;
  final String author;
  final String authorInitial;
  final int replies;
  final int views;
  final DateTime timestamp;
  final String? imagePath;
  final String category;
  final bool isPinned;

  ForumPost({
    this.id,
    required this.title,
    required this.author,
    required this.authorInitial,
    this.replies = 0,
    this.views = 0,
    required this.timestamp,
    this.imagePath,
    required this.category,
    this.isPinned = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'authorInitial': authorInitial,
      'replies': replies,
      'views': views,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'imagePath': imagePath,
      'category': category,
      'isPinned': isPinned ? 1 : 0,
    };
  }

  factory ForumPost.fromMap(Map<String, dynamic> map) {
    return ForumPost(
      id: map['id'],
      title: map['title'],
      author: map['author'],
      authorInitial: map['authorInitial'],
      replies: map['replies'],
      views: map['views'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      imagePath: map['imagePath'],
      category: map['category'],
      isPinned: map['isPinned'] == 1,
    );
  }
}

class _CommunityForumState extends State<CommunityForum> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _postController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  late Database _database;
  bool _isDbInitialized = false;

  // Define the primary color and its variants
  final Color primaryColor = Color.fromARGB(255, 55, 167, 60);
  final Color primaryLightColor = Color.fromARGB(255, 83, 182, 84);
  final Color primaryDarkColor = Color(0xFF338A3E);
  final Color backgroundColor = Color(0xFFF5F5F5);

  final List<ForumCategory> _categories = [
    ForumCategory(name: "All", icon: Iconsax.category),
    ForumCategory(name: "Career", icon: Iconsax.briefcase),
    ForumCategory(name: "Health", icon: Iconsax.health),
    ForumCategory(name: "General", icon: Iconsax.message),
    ForumCategory(name: "Relationships", icon: Iconsax.heart),
    ForumCategory(name: "Safety", icon: Iconsax.shield),
    ForumCategory(name: "Parenting", icon: Iconsax.man),
    ForumCategory(name: "Legal", icon: Iconsax.document),
  ];

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = path_helper.join(documentsDirectory.path, 'community_forum.db');

    _database = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE posts(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            author TEXT,
            authorInitial TEXT,
            replies INTEGER,
            views INTEGER,
            timestamp INTEGER,
            imagePath TEXT,
            category TEXT,
            isPinned INTEGER
          )
        ''');
        
        await _insertSamplePosts(db);
      },
    );
    
    setState(() {
      _isDbInitialized = true;
    });
  }

  Future<void> _insertSamplePosts(Database db) async {
    final samplePosts = [
      ForumPost(
        title: "Dealing with workplace discrimination",
        author: "Priya K.",
        authorInitial: "P",
        replies: 24,
        views: 156,
        timestamp: DateTime.now().subtract(Duration(hours: 2)),
        category: "Career",
        isPinned: true,
      ),
      ForumPost(
        title: "How to handle unsolicited advice about marriage?",
        author: "Ananya S.",
        authorInitial: "A",
        replies: 42,
        views: 289,
        timestamp: DateTime.now().subtract(Duration(hours: 5)),
        category: "Relationships",
      ),
      ForumPost(
        title: "Self-defense workshops in Bangalore",
        author: "Meera P.",
        authorInitial: "M",
        replies: 15,
        views: 103,
        timestamp: DateTime.now().subtract(Duration(days: 1)),
        category: "Safety",
      ),
      ForumPost(
        title: "Balancing motherhood and career",
        author: "Deepika R.",
        authorInitial: "D",
        replies: 37,
        views: 210,
        timestamp: DateTime.now().subtract(Duration(days: 1)),
        isPinned: true,
        category: "Parenting",
      ),
      ForumPost(
        title: "Best gynecologists in Mumbai",
        author: "Sneha M.",
        authorInitial: "S",
        replies: 28,
        views: 175,
        timestamp: DateTime.now().subtract(Duration(days: 2)),
        category: "Health",
      ),
    ];

    for (var post in samplePosts) {
      await db.insert('posts', post.toMap());
    }
  }

  Future<void> _createPost() async {
    if (_postController.text.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      String? imagePath;
      if (_imageFile != null) {
        final directory = await getApplicationDocumentsDirectory();
        final imageName = 'post_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage = await _imageFile!.copy('${directory.path}/$imageName');
        imagePath = savedImage.path;
      }

      final newPost = ForumPost(
        title: _postController.text,
        author: "You",
        authorInitial: "Y",
        timestamp: DateTime.now(),
        imagePath: imagePath,
        category: _selectedCategory,
      );

      await _database.insert('posts', newPost.toMap());

      _postController.clear();
      setState(() {
        _imageFile = null;
      });
      Navigator.pop(context);
      Navigator.pop(context);
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create post: $e'),
          backgroundColor: primaryDarkColor,
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<List<ForumPost>> _getPosts() async {
    if (!_isDbInitialized) return [];

    List<Map<String, dynamic>> maps;
    if (_searchQuery.isNotEmpty) {
      maps = await _database.query(
        'posts',
        where: 'title LIKE ?',
        whereArgs: ['%$_searchQuery%'],
        orderBy: 'isPinned DESC, timestamp DESC',
      );
    } else if (_selectedCategory != 'All') {
      maps = await _database.query(
        'posts',
        where: 'category = ?',
        whereArgs: [_selectedCategory],
        orderBy: 'isPinned DESC, timestamp DESC',
      );
    } else {
      maps = await _database.query(
        'posts',
        orderBy: 'isPinned DESC, timestamp DESC',
      );
    }

    return maps.map((map) => ForumPost.fromMap(map)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Community Forum',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Iconsax.notification, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello there!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryDarkColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'What would you like to discuss today?',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search topics or ask a question...',
                      prefixIcon: Icon(Iconsax.search_normal, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            ),

            Container(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 16 : 8,
                      right: index == _categories.length - 1 ? 16 : 0,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category.name;
                        });
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: _selectedCategory == category.name
                                  ? primaryLightColor
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              category.icon,
                              color: _selectedCategory == category.name
                                  ? primaryDarkColor
                                  : Colors.grey[700],
                              size: 24,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            category.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: _selectedCategory == category.name
                                  ? primaryDarkColor
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryLightColor, primaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Community Resources',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Access helpful resources, guides, and support services',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Iconsax.arrow_right, color: Colors.white),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Discussions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryDarkColor,
                    ),
                  ),
                ],
              ),
            ),
            FutureBuilder<List<ForumPost>>(
              future: _getPosts(),
              builder: (context, snapshot) {
                if (!_isDbInitialized) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error loading posts'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No posts yet. Be the first to start a discussion!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final posts = snapshot.data!;
                return ListView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8),
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            // Navigate to post detail
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (post.isPinned) ...[
                                  Row(
                                    children: [
                                      Icon(Iconsax.woman, size: 16, color: primaryColor),
                                      SizedBox(width: 4),
                                      Text(
                                        'Pinned',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                ],
                                Text(
                                  post.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[900],
                                  ),
                                ),
                                if (post.imagePath != null) ...[
                                  SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(post.imagePath!),
                                      width: double.infinity,
                                      height: 150,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ],
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        post.category,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: primaryDarkColor,
                                        ),
                                      ),
                                    ),
                                    Spacer(),
                                    Icon(Iconsax.message, size: 16, color: Colors.grey),
                                    SizedBox(width: 4),
                                    Text(
                                      post.replies.toString(),
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Iconsax.eye, size: 16, color: Colors.grey),
                                    SizedBox(width: 4),
                                    Text(
                                      post.views.toString(),
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: primaryLightColor,
                                      child: Text(
                                        post.authorInitial,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: primaryDarkColor,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      post.author,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      '•',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      DateFormat('MMM d, h:mm a')
                                          .format(post.timestamp),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) {
              return Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Container(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _postController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'What would you like to share?',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 16),
                      if (_imageFile != null)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _imageFile!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                icon: Icon(Icons.close, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _imageFile = null;
                                  });
                                  Navigator.pop(context);
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (context) => _buildPostBottomSheet(),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Iconsax.gallery_add, color: primaryColor),
                            onPressed: _pickImage,
                          ),
                          DropdownButton<String>(
                            value: _selectedCategory == 'All'
                                ? 'General'
                                : _selectedCategory,
                            items: _categories
                                .where((c) =>
                                    c.name !=
                                    'All')
                                .map((category) {
                              return DropdownMenuItem<String>(
                                value: category.name,
                                child: Text(category.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value!;
                              });
                            },
                          ),
                          Spacer(),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                            ),
                            onPressed: _createPost,
                            child: Text('Post',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        backgroundColor: primaryColor,
        child: Icon(Iconsax.edit, color: Colors.white),
      ),
    );
  }

  Widget _buildPostBottomSheet() {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _postController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'What would you like to share?',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            if (_imageFile != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _imageFile!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _imageFile = null;
                        });
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => _buildPostBottomSheet(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  icon: Icon(Iconsax.gallery_add, color: primaryColor),
                  onPressed: _pickImage,
                ),
                DropdownButton<String>(
                  value: _selectedCategory == 'All'
                      ? 'General'
                      : _selectedCategory,
                  items: _categories
                      .where(
                          (c) => c.name != 'All')
                      .map((category) {
                    return DropdownMenuItem<String>(
                      value: category.name,
                      child: Text(category.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
                Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                  ),
                  onPressed: _createPost,
                  child: Text('Post', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ForumCategory {
  final String name;
  final IconData icon;

  ForumCategory({
    required this.name,
    required this.icon,
  });
}