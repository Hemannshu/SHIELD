import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:title_proj/child/bottom_screens/profile_page.dart';
import 'package:title_proj/child/bottom_screens/theme_provider.dart';
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
      body: Column(
        children: [
          _buildAppBar(context, isDarkMode, themeProvider, colors),
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Emergency Contacts Section
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    context,
                    title: "Emergency Contacts",
                    icon: Icons.emergency_outlined,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Emergency(
                    onSosPressed: () => _handleEmergency(context),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // SOS Button Section
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTapDown: (_) => setState(() => _isSosPressed = true),
                        onTapUp: (_) => setState(() => _isSosPressed = false),
                        onTapCancel: () => setState(() => _isSosPressed = false),
                        onTap: () => _handleEmergency(context),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: _isSosPressed ? 120 : 130,
                          height: _isSosPressed ? 140 : 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFEC407A),
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromARGB(255, 240, 56, 117),
                                blurRadius: 20,
                                spreadRadius: _isSosPressed ? 5 : 10,
                              )
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'SOS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // Explore Safety Features Section
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    context,
                    title: "Explore Safety Features",
                    icon: Icons.explore_outlined,
                  ),
                ),
                SliverToBoxAdapter(child: LiveSafe()),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // Your Safe Spaces Section
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    context,
                    title: "Your Safe Spaces",
                    icon: Icons.home_work_outlined,
                  ),
                ),
                SliverToBoxAdapter(child: SafeHome()),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDarkMode, ThemeProvider themeProvider, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors.primary, colors.secondary],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.security,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'SHEild',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  foreground: Paint()
                    ..shader = LinearGradient(
                      colors: [colors.primary, colors.secondary],
                    ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                ),
              ),
            ],
          ),
          Row(
            children: [
              // Bluetooth Button
              IconButton(
                icon: Icon(
                  _connectedDevice != null 
                    ? Icons.bluetooth_connected 
                    : Icons.bluetooth,
                  color: _connectedDevice != null 
                    ? Colors.blue 
                    : colors.onSurface,
                ),
                onPressed: () => _showBluetoothDialog(context),
              ),
              const SizedBox(width: 8),
              
              // Dark Mode Button
              IconButton(
                icon: Icon(
                  isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: colors.onSurface,
                ),
                onPressed: () {
                  themeProvider.toggleTheme(!isDarkMode);
                },
              ),
              const SizedBox(width: 8),
              
              // Profile Button
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                ),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        colors.primary.withOpacity(0.8),
                        colors.secondary.withOpacity(0.8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, {required String title, required IconData icon}) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: colors.secondary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
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