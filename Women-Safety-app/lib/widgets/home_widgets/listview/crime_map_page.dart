import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'dart:math';
import 'package:latlong2/latlong.dart';

class CrimeMapPage extends StatefulWidget {
  @override
  _CrimeMapPageState createState() => _CrimeMapPageState();
}

class _CrimeMapPageState extends State<CrimeMapPage> with SingleTickerProviderStateMixin {
  List<dynamic> crimeData = [];
  List<Marker> _markers = [];
  List<CircleMarker> _heatCircles = [];
  LatLng? _userLocation;
  String _userRiskLevel = "Calculating...";
  double _safetyScore = 100;
  bool _isLoading = true;
  bool _showHeatMap = true;
  String _selectedFilter = 'All';
  dynamic _selectedZone;
  final MapController _mapController = MapController();
  late AnimationController _pulseController;

  final List<String> _filters = ['All', 'Extremely Risky', 'High Risk', 'Medium Risk', 'Low Risk'];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _requestLocationPermissionAndInit();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _requestLocationPermissionAndInit() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Location permission denied."),
          ));
        }
        setState(() => _isLoading = false);
        return;
      }
    }
    await _loadCrimeData();
    await _getUserLocation();
    setState(() => _isLoading = false);
  }

  Future<void> _loadCrimeData() async {
    try {
      String jsonString = await rootBundle.loadString('assets/crime.json');
      List<dynamic> data = jsonDecode(jsonString);
      for (var entry in data) {
        entry['risk_level'] = _categorizeRisk(entry['total_crimes'].toInt());
        entry['safety_index'] = _computeSafetyIndex(entry['total_crimes'].toDouble());
      }
      setState(() {
        crimeData = data;
        _buildMapLayers();
      });
    } catch (e) {
      debugPrint("Error loading data: $e");
    }
  }

  String _categorizeRisk(int totalCrimes) {
    if (totalCrimes > 5000) return 'Extremely Risky';
    if (totalCrimes > 1000) return 'High Risk';
    if (totalCrimes > 500) return 'Medium Risk';
    return 'Low Risk';
  }

  /// DSIM-inspired safety index: Safety = 100 * e^(-crimeScore / k)
  double _computeSafetyIndex(double totalCrimes) {
    const k = 5000.0;
    return 100 * exp(-totalCrimes / k);
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel) {
      case 'Extremely Risky': return const Color(0xFFD32F2F);
      case 'High Risk': return const Color(0xFFFF5722);
      case 'Medium Risk': return const Color(0xFFFFA726);
      case 'Low Risk': return const Color(0xFF66BB6A);
      default: return const Color(0xFF42A5F5);
    }
  }

  IconData _getRiskIcon(String riskLevel) {
    switch (riskLevel) {
      case 'Extremely Risky': return Icons.dangerous_rounded;
      case 'High Risk': return Icons.warning_amber_rounded;
      case 'Medium Risk': return Icons.info_rounded;
      case 'Low Risk': return Icons.check_circle_rounded;
      default: return Icons.shield_rounded;
    }
  }

  void _buildMapLayers() {
    _markers.clear();
    _heatCircles.clear();

    for (var entry in crimeData) {
      final risk = entry['risk_level'] as String;
      if (_selectedFilter != 'All' && risk != _selectedFilter) continue;

      final point = LatLng(entry['Latitude'], entry['Longitude']);
      final color = _getRiskColor(risk);
      final crimes = entry['total_crimes'].toInt();

      // Heat map circles — radius scales with crime count
      if (_showHeatMap) {
        final radius = (log(crimes + 1) * 3).clamp(5.0, 30.0);
        _heatCircles.add(CircleMarker(
          point: point,
          radius: radius,
          color: color.withOpacity(0.25),
          borderColor: color.withOpacity(0.5),
          borderStrokeWidth: 1.5,
        ));
      }

      // Pin markers
      _markers.add(Marker(
        point: point,
        width: 32,
        height: 32,
        child: GestureDetector(
          onTap: () => _showZoneDetails(entry),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6, spreadRadius: 1)],
            ),
            child: Icon(_getRiskIcon(risk), color: Colors.white, size: 16),
          ),
        ),
      ));
    }
    setState(() {});
  }

  Future<void> _getUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
      _computeUserSafety();
    } catch (e) {
      debugPrint("Error getting user location: $e");
    }
  }

  void _computeUserSafety() {
    if (_userLocation == null || crimeData.isEmpty) return;

    double worstScore = 100;
    String zone = "Safe Zone";

    for (var entry in crimeData) {
      double distance = Geolocator.distanceBetween(
        _userLocation!.latitude, _userLocation!.longitude,
        entry['Latitude'], entry['Longitude'],
      );

      if (distance <= 5000) {
        double entryScore = entry['safety_index'] as double;
        if (entryScore < worstScore) {
          worstScore = entryScore;
          switch (entry['risk_level']) {
            case 'Extremely Risky': zone = 'Extremely Risky Zone'; break;
            case 'High Risk': zone = 'High Risk Zone'; break;
            case 'Medium Risk': zone = 'Medium Risk Zone'; break;
            case 'Low Risk': zone = 'Low Risk Zone'; break;
          }
        }
      }
    }

    setState(() {
      _safetyScore = worstScore;
      _userRiskLevel = zone;
    });
  }

  void _showZoneDetails(dynamic entry) {
    setState(() => _selectedZone = entry);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildZoneSheet(entry),
    );
  }

  Widget _buildZoneSheet(dynamic entry) {
    final risk = entry['risk_level'] as String;
    final color = _getRiskColor(risk);
    final crimes = entry['total_crimes'].toInt();
    final score = (entry['safety_index'] as double).toStringAsFixed(1);
    final district = entry['district_name'] ?? 'Unknown';
    final state = entry['state_name'] ?? '';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(_getRiskIcon(risk), color: color, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(district, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(state.toString().toUpperCase(), style: TextStyle(color: Colors.grey[600], fontSize: 12, letterSpacing: 0.5)),
              ],
            )),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(risk, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            _statCard("Total Crimes", crimes.toString(), Colors.red[400]!),
            const SizedBox(width: 12),
            _statCard("Safety Index", "$score%", color),
            const SizedBox(width: 12),
            _statCard("Years of Data", entry['year'].toString(), Colors.blue[400]!),
          ]),
          const SizedBox(height: 16),
          // Safety bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (entry['safety_index'] as double) / 100,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Dangerous", style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              Text("Safe", style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600]), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  void _centerOnUser() {
    if (_userLocation != null) {
      _mapController.move(_userLocation!, 10);
    }
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = _getRiskColor(
      _safetyScore > 80 ? 'Low Risk' :
      _safetyScore > 40 ? 'Medium Risk' :
      _safetyScore > 13 ? 'High Risk' : 'Extremely Risky'
    );

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFEC407A)))
        : Stack(
            children: [
              // --- Map ---
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _userLocation ?? LatLng(20.5937, 78.9629),
                  initialZoom: _userLocation != null ? 8.0 : 5.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.example.title_proj',
                    maxZoom: 20,
                  ),
                  if (_showHeatMap) CircleLayer(circles: _heatCircles),
                  MarkerLayer(markers: [
                    if (_userLocation != null)
                      Marker(
                        point: _userLocation!,
                        width: 48,
                        height: 48,
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (_, __) {
                            final pulse = _pulseController.value;
                            return Stack(alignment: Alignment.center, children: [
                              Container(
                                width: 48 * (0.6 + pulse * 0.4),
                                height: 48 * (0.6 + pulse * 0.4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFEC407A).withOpacity(0.2 * (1 - pulse)),
                                ),
                              ),
                              Container(
                                width: 20, height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFEC407A),
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                ),
                              ),
                            ]);
                          },
                        ),
                      ),
                    ..._markers,
                  ]),
                ],
              ),

              // --- Top Bar: Back + Title ---
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 12, right: 12,
                child: Row(children: [
                  _circleButton(Icons.arrow_back_rounded, () => Navigator.pop(context)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                      ),
                      child: Row(children: [
                        Icon(Icons.shield_rounded, color: riskColor, size: 20),
                        const SizedBox(width: 8),
                        const Text("Risk Analysis", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: riskColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "${_safetyScore.toStringAsFixed(0)}%",
                            style: TextStyle(color: riskColor, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ]),
              ),

              // --- Filter Chips ---
              Positioned(
                top: MediaQuery.of(context).padding.top + 62,
                left: 0, right: 0,
                child: SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (_, i) {
                      final f = _filters[i];
                      final active = f == _selectedFilter;
                      final chipColor = f == 'All' ? const Color(0xFFEC407A) : _getRiskColor(f);
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedFilter = f);
                          _buildMapLayers();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: active ? chipColor : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: active ? chipColor : Colors.grey[300]!),
                            boxShadow: active ? [BoxShadow(color: chipColor.withOpacity(0.3), blurRadius: 4)] : null,
                          ),
                          child: Text(f, style: TextStyle(
                            color: active ? Colors.white : Colors.grey[700],
                            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 12,
                          )),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // --- Bottom Safety Card ---
              Positioned(
                bottom: 24, left: 16, right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4))],
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Row(children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: riskColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(_getRiskIcon(_userRiskLevel.replaceAll(' Zone', '')), color: riskColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Your Current Zone", style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(_userRiskLevel, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: riskColor)),
                        ],
                      )),
                      Text("${_safetyScore.toStringAsFixed(0)}%",
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: riskColor)),
                    ]),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: _safetyScore / 100,
                        minHeight: 6,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation(riskColor),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      _legendDot(const Color(0xFFD32F2F), "Extreme"),
                      _legendDot(const Color(0xFFFF5722), "High"),
                      _legendDot(const Color(0xFFFFA726), "Medium"),
                      _legendDot(const Color(0xFF66BB6A), "Low"),
                      const Spacer(),
                      Text("${crimeData.length} zones", style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                    ]),
                  ]),
                ),
              ),

              // --- FAB controls ---
              Positioned(
                right: 16,
                bottom: 200,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  _circleButton(
                    _showHeatMap ? Icons.layers_rounded : Icons.layers_outlined,
                    () { setState(() => _showHeatMap = !_showHeatMap); _buildMapLayers(); },
                  ),
                  const SizedBox(height: 8),
                  _circleButton(Icons.my_location_rounded, _centerOnUser),
                ]),
              ),
            ],
          ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ]),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Icon(icon, size: 20, color: Colors.grey[800]),
      ),
    );
  }
}
