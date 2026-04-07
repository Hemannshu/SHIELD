import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:latlong2/latlong.dart';

class CrimeMapPage extends StatefulWidget {
  @override
  _CrimeMapPageState createState() => _CrimeMapPageState();
}

class _CrimeMapPageState extends State<CrimeMapPage> {
  List<dynamic> crimeData = [];
  Set<Marker> _markers = {};
  LatLng? _userLocation;
  String _userRiskLevel = "Safe Zone";

  @override
  void initState() {
    super.initState();
    _requestLocationPermissionAndInit();
  }

  Future<void> _requestLocationPermissionAndInit() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Location permission denied. Cannot fetch zone info."),
        ));
        return;
      }
    }

    _loadCrimeData();
    _getUserLocation();
  }

  Future<void> _loadCrimeData() async {
    try {
      String jsonString = await rootBundle.loadString('assets/crime.json');
      List<dynamic> data = jsonDecode(jsonString);

      for (var entry in data) {
        entry['risk_level'] = _categorizeRisk(entry['total_crimes'].toInt());
      }

      setState(() {
        crimeData = data;
        _addMarkers();
      });
    } catch (e) {
      print("Error loading data: $e");
    }
  }

  String _categorizeRisk(int totalCrimes) {
    if (totalCrimes > 5000) return 'Extremely Risky';
    if (totalCrimes > 1000) return 'High Risk';
    if (totalCrimes > 500) return 'Medium Risk';
    return 'Low Risk';
  }

  void _addMarkers() {
    _markers.clear();
    for (var entry in crimeData) {
      _markers.add(
        Marker(
          point: LatLng(entry['Latitude'], entry['Longitude']),
          width: 40.0,
          height: 40.0,
          child: Icon(
            Icons.location_on,
            color: _getMarkerColor(entry['risk_level']),
            size: 40,
          ),
        ),
      );
    }
    setState(() {});
  }

  Color _getMarkerColor(String riskLevel) {
    switch (riskLevel) {
      case 'Extremely Risky':
        return Colors.purple;
      case 'High Risk':
        return Colors.red;
      case 'Medium Risk':
        return Colors.orange;
      case 'Low Risk':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  Future<void> _getUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
      _checkZoneAndShowAlert();
    } catch (e) {
      print("Error getting user location: $e");
    }
  }

  void _checkZoneAndShowAlert() {
    if (_userLocation == null || crimeData.isEmpty) return;

    double radius = 5000;
    String zone = "Safe Zone";

    for (var entry in crimeData) {
      double distance = Geolocator.distanceBetween(
        _userLocation!.latitude,
        _userLocation!.longitude,
        entry['Latitude'],
        entry['Longitude'],
      );

      if (distance <= radius) {
        switch (entry['risk_level']) {
          case 'Extremely Risky':
            zone = 'Extremely Risky Zone';
            break;
          case 'High Risk':
            if (zone != 'Extremely Risky Zone') zone = 'High Risk Zone';
            break;
          case 'Medium Risk':
            if (zone == 'Safe Zone') zone = 'Medium Risk Zone';
            break;
          case 'Low Risk':
            if (zone == 'Safe Zone') zone = 'Low Risk Zone';
            break;
        }
      }
    }

    setState(() {
      _userRiskLevel = zone;
    });

    _showZoneAlert(zone);
  }

  void _showZoneAlert(String zone) {
    IconData icon;
    Color color;

    switch (zone) {
      case 'Extremely Risky Zone':
        icon = Icons.dangerous;
        color = Colors.purple;
        break;
      case 'High Risk Zone':
        icon = Icons.warning_amber;
        color = Colors.red;
        break;
      case 'Medium Risk Zone':
        icon = Icons.report_problem;
        color = Colors.orange;
        break;
      case 'Low Risk Zone':
        icon = Icons.info;
        color = Colors.green;
        break;
      default:
        icon = Icons.check_circle;
        color = Colors.blue;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: color),
            SizedBox(width: 10),
            Text("Zone Alert"),
          ],
        ),
        content: Text("You are currently in a $zone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Crime Map"),
        backgroundColor: Color.fromRGBO(255, 33, 117, 1),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _userLocation ?? LatLng(20.5937, 78.9629),
              initialZoom: 5.0,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              ),
              if (_userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userLocation!,
                      width: 40,
                      height: 40,
                      child: Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
                    ),
                    ..._markers.toList(),
                  ],
                ),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning, color: _getMarkerColor(_userRiskLevel)),
                  SizedBox(width: 8),
                  Text(
                    "Zone: $_userRiskLevel",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getMarkerColor(_userRiskLevel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
