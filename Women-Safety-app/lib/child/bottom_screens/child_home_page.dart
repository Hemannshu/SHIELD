import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:title_proj/child/bottom_screens/profile_page.dart';
import 'package:title_proj/child/bottom_screens/theme_provider.dart';
import 'package:title_proj/utils/app_theme.dart';
import 'package:title_proj/widgets/home_widgets/SOSButton/emergency_service.dart';
import 'package:title_proj/widgets/home_widgets/emergency.dart';
import 'package:title_proj/widgets/home_widgets/safehome/SafeHome.dart';
import 'package:title_proj/widgets/live_safe.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:title_proj/widgets/bluetooth_sos_demo_widget.dart';
import 'package:title_proj/services/firebase_evidence_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSosPressed = false;
  final EmergencyService _emergencyService = EmergencyService();
  BluetoothDevice? _connectedDevice;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildAppBar(context, isDarkMode, themeProvider, colors)
                .animate()
                .fadeIn(duration: 500.ms),
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Status banner
                  SliverToBoxAdapter(
                    child: _buildStatusBanner(isDarkMode)
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 500.ms)
                        .slideY(begin: 0.1),
                  ),

                  // SOS Button Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: _buildSOSButton(context, isDarkMode)),
                    ).animate().fadeIn(delay: 300.ms, duration: 600.ms).scale(
                      begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),
                  ),

                  // Emergency Contacts Section
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      context,
                      title: "Quick Emergency",
                      icon: Icons.emergency_rounded,
                      isDark: isDarkMode,
                    ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
                  ),
                  SliverToBoxAdapter(
                    child: Emergency(
                      onSosPressed: () => _handleEmergency(context),
                    ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),

                  // Explore Safety Features Section
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      context,
                      title: "Nearby Safety",
                      icon: Icons.location_on_rounded,
                      isDark: isDarkMode,
                    ).animate().fadeIn(delay: 600.ms, duration: 500.ms),
                  ),
                  SliverToBoxAdapter(
                    child: LiveSafe()
                        .animate().fadeIn(delay: 700.ms, duration: 500.ms),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),

                  // Your Safe Spaces Section
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      context,
                      title: "Safe Spaces",
                      icon: Icons.home_rounded,
                      isDark: isDarkMode,
                    ).animate().fadeIn(delay: 800.ms, duration: 500.ms),
                  ),
                  SliverToBoxAdapter(
                    child: SafeHome()
                        .animate().fadeIn(delay: 900.ms, duration: 500.ms),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1B3A26), const Color(0xFF1A2E1A)]
              : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.green.withOpacity(0.2) : Colors.green.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green[400],
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.4),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Protection Active',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.green[300] : Colors.green[800],
            ),
          ),
          const Spacer(),
          Text(
            'All systems operational',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? Colors.green[400]!.withOpacity(0.7) : Colors.green[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSOSButton(BuildContext context, bool isDark) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isSosPressed = true),
      onTapUp: (_) => setState(() => _isSosPressed = false),
      onTapCancel: () => setState(() => _isSosPressed = false),
      onTap: () => _handleEmergency(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: _isSosPressed ? 130 : 140,
        height: _isSosPressed ? 130 : 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppTheme.sosGradient,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF1744).withOpacity(_isSosPressed ? 0.5 : 0.35),
              blurRadius: _isSosPressed ? 30 : 24,
              spreadRadius: _isSosPressed ? 4 : 8,
            ),
            BoxShadow(
              color: const Color(0xFFFF1744).withOpacity(0.15),
              blurRadius: 50,
              spreadRadius: 15,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'SOS',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'TAP FOR HELP',
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.8),
                fontSize: 9,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDarkMode, ThemeProvider themeProvider, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryPink.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.shield_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'SHEild',
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  foreground: Paint()
                    ..shader = AppTheme.primaryGradient
                        .createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildIconBtn(
                _connectedDevice != null ? Icons.bluetooth_connected_rounded : Icons.bluetooth_rounded,
                _connectedDevice != null ? Colors.blue : (isDarkMode ? Colors.white54 : AppTheme.neutralGrey400),
                isDarkMode,
                () => _showBluetoothDialog(context),
              ),
              const SizedBox(width: 8),
              _buildIconBtn(
                isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                isDarkMode ? Colors.amber : AppTheme.neutralGrey400,
                isDarkMode,
                () => themeProvider.toggleTheme(!isDarkMode),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProfilePage())),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryPink.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconBtn(IconData icon, Color iconColor, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.06) : AppTheme.neutralGrey100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : AppTheme.neutralGrey200,
          ),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, {required String title, required IconData icon, required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryPink.withOpacity(isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryPink, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppTheme.neutralGrey900,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleEmergency(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Getting your location...'),
            ],
          ),
        ),
      );

      final permissionStatus = await Permission.location.request();
      if (!permissionStatus.isGranted) {
        Navigator.pop(context);
        _showPermissionDeniedDialog(context);
        return;
      }

      final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationEnabled) {
        Navigator.pop(context);
        _showLocationServicesDialog(context);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 15));

      final incidentId = await _emergencyService.handleEmergency(position);

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Show evidence capture dialog after emergency
      final captureEvidence = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.camera_alt, color: Colors.pink),
              SizedBox(width: 8),
              Text('Capture Evidence'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Would you like to capture evidence (photo/video) for this emergency?',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, 'camera'),
                    icon: Icon(Icons.camera_alt),
                    label: Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, 'gallery'),
                    icon: Icon(Icons.photo_library),
                    label: Text('Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'skip'),
              child: Text('Skip'),
            ),
          ],
        ),
      );

      // Handle evidence capture
      if (captureEvidence != null && captureEvidence != 'skip') {
        await _captureEvidence(context, incidentId, captureEvidence);
      }
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency alert sent successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Note: Bluetooth fallback is now handled automatically in EmergencyService
      // when network is unavailable or SMS fails
    } on TimeoutException {
      Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location timeout - please try again in an open area'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send alert: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Capture evidence after emergency
  Future<void> _captureEvidence(BuildContext context, String incidentId, String source) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Storing evidence...'),
            ],
          ),
        ),
      );

      final evidenceService = FirebaseEvidenceService();
      final imageSource = source == 'camera' ? ImageSource.camera : ImageSource.gallery;

      final evidence = await evidenceService.storeEvidence(
        incidentId: incidentId,
        description: 'Emergency evidence',
        source: imageSource,
      );

      Navigator.pop(context); // Close loading dialog

      if (mounted) {
        // Check if upload failed (downloadUrl is empty)
        if (evidence.downloadUrl.isEmpty) {
          Fluttertoast.showToast(
            msg: '⚠️ Evidence hash stored, but file upload failed.\nEnable Firebase Storage in console.',
            backgroundColor: Colors.orange,
            toastLength: Toast.LENGTH_LONG,
          );
        } else {
          Fluttertoast.showToast(
            msg: '✅ Evidence stored securely!\nHash: ${evidence.fileHash.substring(0, 16)}...',
            backgroundColor: Colors.green,
            toastLength: Toast.LENGTH_LONG,
          );
        }
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      if (mounted) {
        String errorMsg = 'Failed to store evidence';
        if (e.toString().contains('object not found') || 
            e.toString().contains('bucket')) {
          errorMsg = 'Firebase Storage not enabled.\nEnable it in Firebase Console.';
        } else {
          errorMsg = 'Error: ${e.toString().length > 50 ? e.toString().substring(0, 50) + "..." : e.toString()}';
        }
        
        Fluttertoast.showToast(
          msg: errorMsg,
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    }
  }

  Future<void> _showBluetoothDialog(BuildContext context) async {
    // Check Bluetooth permissions
    final status = await Permission.bluetooth.request();
    if (!status.isGranted) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Bluetooth Permission Required'),
            content: const Text('Please enable Bluetooth permissions to use this feature'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => openAppSettings(),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
      return;
    }

    // Show Bluetooth options
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bluetooth Safety'),
        content: _connectedDevice != null
            ? Text('Connected to ${_connectedDevice!.name}')
            : const Text('Connect to nearby devices to share your location when network is unavailable'),
        actions: [
          if (_connectedDevice != null)
            TextButton(
              onPressed: () {
                _disconnectDevice();
                Navigator.pop(context);
              },
              child: const Text('Disconnect'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToBluetoothScreen(context);
            },
            child: Text(_connectedDevice != null ? 'Manage' : 'Scan Devices'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToBluetoothScreen(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BluetoothScreen(connectedDevice: _connectedDevice),
        fullscreenDialog: true,
      ),
    );

    if (result != null && result is BluetoothDevice) {
      setState(() {
        _connectedDevice = result;
      });
    } else if (result == 'disconnected') {
      setState(() {
        _connectedDevice = null;
      });
    }
  }

  Future<void> _disconnectDevice() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      setState(() {
        _connectedDevice = null;
      });
    }
  }

  Future<void> _sendLocationViaBluetooth(Position position) async {
    if (_connectedDevice == null || !_connectedDevice!.isConnected) return;

    try {
      // Convert position to string format
      final locationData = 'EMERGENCY|${position.latitude},${position.longitude}|${DateTime.now().toIso8601String()}';
      
      // Discover services
      final services = await _connectedDevice!.discoverServices();
      
      // Find the service and characteristic (replace with your actual UUIDs)
      for (final service in services) {
        for (final characteristic in service.characteristics) {
          if (characteristic.properties.write) {
            await characteristic.write(locationData.codeUnits);
            debugPrint('Location data sent via BLE');
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('Error sending location via BLE: $e');
      // Attempt to reconnect if there was an error
      if (_connectedDevice != null) {
        await _connectedDevice!.connect(autoConnect: false);
      }
    }
  }

  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text('Please enable location permissions in app settings'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => openAppSettings(),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showLocationServicesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text('Please enable location services'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Geolocator.openLocationSettings(),
            child: const Text('Enable Location'),
          ),
        ],
      ),
    );
  }
}

class BluetoothScreen extends StatefulWidget {
  final BluetoothDevice? connectedDevice;

  const BluetoothScreen({super.key, this.connectedDevice});

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
 final FlutterBluePlus _flutterBlue = FlutterBluePlus();

  List<ScanResult> _devices = [];
  bool _isScanning = false;
  BluetoothDevice? _connectedDevice;

  @override
  void initState() {
    super.initState();
    _connectedDevice = widget.connectedDevice;
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    await Permission.bluetooth.request();
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothScan.request();
    await Permission.location.request();
  }

 Future<void> _scanDevices() async {
  setState(() {
    _isScanning = true;
    _devices = [];
  });

  try {
    // Start scanning
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    // Listen to scan results
    FlutterBluePlus.onScanResults.listen((results) {
      setState(() {
        _devices = results;
      });
    });
  } finally {
    // Stop scanning after timeout
    Future.delayed(const Duration(seconds: 10), () async {
      await FlutterBluePlus.stopScan();
      setState(() {
        _isScanning = false;
      });
    });
  }
}

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      setState(() {
        _isScanning = false;
      });
      await FlutterBluePlus.stopScan();
      
      await device.connect(autoConnect: false);
      setState(() {
        _connectedDevice = device;
      });
      
      Navigator.pop(context, device);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect: ${e.toString()}')),
      );
    }
  }

  Future<void> _disconnectDevice() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      setState(() {
        _connectedDevice = null;
      });
      Navigator.pop(context, 'disconnected');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Devices'),
        actions: [
          if (_connectedDevice != null)
            IconButton(
              icon: const Icon(Icons.link_off),
              onPressed: _disconnectDevice,
              tooltip: 'Disconnect',
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _isScanning ? null : _scanDevices,
              child: _isScanning
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 8),
                        Text('Scanning...'),
                      ],
                    )
                  : const Text('Scan for Devices'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final device = _devices[index].device;
                return ListTile(
                  title: Text(device.name.isEmpty ? 'Unknown Device' : device.name),
                  subtitle: Text(device.id.toString()),
                  trailing: _connectedDevice?.id == device.id
                      ? const Icon(Icons.check, color: Colors.green)
                      : ElevatedButton(
                          onPressed: () => _connectToDevice(device),
                          child: const Text('Connect'),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}