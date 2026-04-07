import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:title_proj/widgets/home_widgets/listview/SelfDefence.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:title_proj/widgets/home_widgets/CustomCarouel.dart';
import 'package:title_proj/widgets/home_widgets/listview/DetectCamera.dart';
import 'package:title_proj/widgets/home_widgets/listview/MagnetometerPage.dart';
import 'package:title_proj/widgets/home_widgets/listview/RiskAnalysis.dart';
import 'package:title_proj/widgets/home_widgets/listview/SelfDefencePage.dart';
import 'package:title_proj/widgets/home_widgets/listview/community_forum.dart';
import 'package:title_proj/widgets/home_widgets/listview/crime_map_page.dart';
import 'package:title_proj/widgets/home_widgets/listview/mental_health_chat.dart';
import 'package:title_proj/widgets/home_widgets/listview/period_tracker.dart';

class ExploreMorePage extends StatefulWidget {
  @override
  _ExploreMorePageState createState() => _ExploreMorePageState();
}

class _ExploreMorePageState extends State<ExploreMorePage> {
  String _locationMessage = "Getting your location...";
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationMessage = "Enable location services to see nearby services";
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationMessage = "Location permissions denied";
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationMessage = "Location permissions permanently denied";
          _isLoadingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _locationMessage = "Location services active";
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _locationMessage = "Error getting location";
        _isLoadingLocation = false;
      });
    }
  }

  static Future<void> openMap(String location) async {
    String googleUrl = 'https://www.google.com/maps/search/$location';
    final Uri _url = Uri.parse(googleUrl);
    try {
      if (!await launchUrl(_url)) {
        throw 'Could not launch $_url';
      }
    } catch (e) {
      print('Error launching map: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Explore Safety',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Your comprehensive safety toolkit',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 15,
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFFEC407A),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate([
              // Custom Carousel
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                child: CustomCarouel(),
              ),

              // Rest of your existing content...
              // Safety Tools Section
              Padding(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Safety Tools',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      height: 160,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          SizedBox(width: 5),
                          _buildSafetyTool(
                            context,
                            Icons.camera_alt,
                            'Detect Camera',
                            Color(0xFFEC407A),
                            MagnetometerPage(),
                          ),
                          SizedBox(width: 15),
                          _buildSafetyTool(
                            context,
                            Icons.analytics,
                            'Risk Analysis',
                            Color(0xFFAB47BC),
                            CrimeMapPage(),
                          ),
                          SizedBox(width: 5),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Health & Wellbeing Section
              Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Health & Wellbeing',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    SizedBox(height: 10),
                    GridView.count(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 1.1,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      padding: EdgeInsets.zero,
                      children: [
                        _buildResourceCard(
                          context,
                          Icons.calendar_today,
                          'Period Tracker',
                          Color(0xFFF06292),
                          PeriodTrackerPage(),
                        ),
                        _buildResourceCard(
                          context,
                          Icons.psychology,
                          'Mental Health',
                          Color(0xFF26C6DA),
                          MentalHealthChat(),
                        ),
                        _buildResourceCard(
                          context,
                          Icons.forum,
                          'Community',
                          Color(0xFF66BB6A),
                          CommunityForum(),
                        ),
                        _buildResourceCard(
                          context,
                          Icons.security,
                          'Self Defence',
                          Color(0xFF7E57C2),
                          SelfDefencePage(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Nearby Services Section
              Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nearby Services',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    SizedBox(height: 10),
                    _isLoadingLocation
                        ? Row(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(width: 10),
                              Text("Finding your location..."),
                            ],
                          )
                        : Text(
                            _locationMessage,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                    SizedBox(height: 15),
                    _buildNearbyService(
                      'Police Stations',
                      Icons.local_police,
                      Color(0xFFEC407A),
                    ),
                    SizedBox(height: 10),
                    _buildNearbyService(
                      'Hospitals',
                      Icons.local_hospital,
                      Color(0xFFAB47BC),
                    ),
                    SizedBox(height: 10),
                    _buildNearbyService(
                      'Women\'s Shelters',
                      Icons.security,
                      Color(0xFF7E57C2),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTool(BuildContext context, IconData icon, String title, Color color, Widget page) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        ),
        child: Container(
          width: 140,
          padding: EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResourceCard(BuildContext context, IconData icon, String title, Color color, Widget page) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        ),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNearbyService(String title, IconData icon, Color color) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        onTap: () => openMap('$title near me'),
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text('View nearby locations', style: TextStyle(fontSize: 12)),
        trailing: Icon(Icons.arrow_forward, color: color, size: 20),
      ),
    );
  }
}