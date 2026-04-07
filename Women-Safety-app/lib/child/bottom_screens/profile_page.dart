import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:another_telephony/telephony.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Switch between demo and real blockchain:
// import 'package:title_proj/services/blockchain_service.dart'; // Real blockchain
import 'package:title_proj/services/blockchain_service_demo.dart' as blockchain; // Demo blockchain
import 'package:title_proj/services/firebase_evidence_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emergencyContactController = TextEditingController();
  final TextEditingController _codeWordController = TextEditingController();

  String? _profileImageUrl;
  bool _isLoading = false;
  bool _notificationsEnabled = true;
  bool _shakeToAlertEnabled = false;

  Position? _currentPosition;
  final Telephony telephony = Telephony.instance;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  double _shakeThreshold = 15.0;
  int _minShakeCount = 3;
  int _shakeCount = 0;
  DateTime? _lastShakeTime;
  Duration _shakeWindow = Duration(milliseconds: 1000);
  bool _isInCooldown = false;
  DateTime? _lastSOSTime;
  final Duration _cooldownPeriod = Duration(seconds: 10);
  bool _isTestingMode = false;

  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePage();
    });
  }

  Future<void> _initializePage() async {
    try {
      setState(() => _isLoading = true);
      await _loadUserData();
      await _checkPermissions();
      
      if (_shakeToAlertEnabled) {
        await _startShakeDetection();
      }
    } catch (e) {
      debugPrint('Initialization error: $e');
      Fluttertoast.showToast(msg: 'Error initializing profile');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkPermissions() async {
    final statuses = await [
      Permission.location,
      Permission.microphone,
      Permission.sms,
    ].request();
    
    if (statuses[Permission.location]?.isDenied ?? true) {
      Fluttertoast.showToast(msg: 'Location permission required for emergency alerts');
    }
    if (statuses[Permission.sms]?.isDenied ?? true) {
      Fluttertoast.showToast(msg: 'SMS permission required for emergency alerts');
    }
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _emergencyContactController.dispose();
    _codeWordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        await _initializeUserData();
        return;
      }

      final data = doc.data() ?? {};

      setState(() {
        _nameController.text = data['name'] ?? '';
        _emailController.text = user.email ?? '';
        _phoneController.text = data['phone'] ?? '';
        _emergencyContactController.text = data['emergencyContact'] ?? '';
        _codeWordController.text = data['codeWord'] ?? '';
        _profileImageUrl = data['profileImageUrl'];
        _notificationsEnabled = data['notificationsEnabled'] ?? true;
        _shakeToAlertEnabled = data['shakeToAlertEnabled'] ?? false;
      });
    } catch (e) {
      debugPrint('Error loading user data: $e');
      Fluttertoast.showToast(msg: 'Error loading profile data');
      rethrow;
    }
  }

  Future<void> _initializeUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    
    await docRef.set({
      'name': user.displayName ?? '',
      'email': user.email ?? '',
      'phone': '',
      'emergencyContact': '',
      'codeWord': '',
      'notificationsEnabled': true,
      'shakeToAlertEnabled': false,
    }, SetOptions(merge: true));
  }

  Future<void> _startShakeDetection() async {
    _accelerometerSubscription?.cancel();
    
    // Enter test mode first when enabling
    if (!_isTestingMode) {
      await _enterTestMode();
      return;
    }

    _accelerometerSubscription = accelerometerEvents.listen((event) {
      final double acceleration = (event.x * event.x + event.y * event.y + event.z * event.z);

      if (acceleration > _shakeThreshold) {
        final now = DateTime.now();
        
        if (_lastShakeTime == null || now.difference(_lastShakeTime!) > _shakeWindow) {
          _shakeCount = 1;
        } else {
          _shakeCount++;
        }
        
        _lastShakeTime = now;

        if (_shakeCount >= _minShakeCount) {
          _shakeCount = 0;
          if (!_isInCooldown) {
            debugPrint('Shake detected! Triggering SOS');
            _triggerSOS();
          } else {
            debugPrint('Shake detected but in cooldown period');
          }
        }
      }
    });
  }

  Future<void> _enterTestMode() async {
    setState(() => _isTestingMode = true);
    Fluttertoast.showToast(
      msg: 'Test Mode: Shake your phone $_minShakeCount times to test',
      toastLength: Toast.LENGTH_LONG,
    );
    
    // Start shake detection after a brief delay
    await Future.delayed(Duration(seconds: 1));
    _startShakeDetection();
    
    // Auto-exit test mode after 10 seconds
    await Future.delayed(Duration(seconds: 10));
    
    if (mounted) {
      setState(() => _isTestingMode = false);
      Fluttertoast.showToast(
        msg: 'Shake detection is now active!',
        backgroundColor: Colors.green,
      );
    }
  }

  Future<void> _triggerSOS() async {
    if (_nameController.text.isEmpty || 
        (_emergencyContactController.text.isEmpty && _phoneController.text.isEmpty)) {
      Fluttertoast.showToast(msg: 'Please set your name and emergency contact first');
      return;
    }

    // Check cooldown
    if (_lastSOSTime != null && 
        DateTime.now().difference(_lastSOSTime!) < _cooldownPeriod) {
      Fluttertoast.showToast(
        msg: 'Please wait ${_cooldownPeriod.inSeconds - DateTime.now().difference(_lastSOSTime!).inSeconds} seconds before next alert',
        backgroundColor: Colors.orange,
      );
      return;
    }

    setState(() {
      _isInCooldown = true;
      _isLoading = true;
    });
    
    try {
      try {
        _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        );
      } catch (e) {
        debugPrint('Location error: $e');
        _currentPosition = null;
      }

      final recipient = _emergencyContactController.text.isNotEmpty 
          ? _emergencyContactController.text 
          : _phoneController.text;

      final success = await _sendEmergencySMS(recipient);
      if (success) {
        // Create incident ID for evidence storage
        final incidentId = DateTime.now().millisecondsSinceEpoch.toString();
        final user = FirebaseAuth.instance.currentUser;
        
        // Store incident in Firestore
        if (user != null) {
          final timestamp = DateTime.now();
          
          await FirebaseFirestore.instance.collection('incidents').doc(incidentId).set({
            'userId': user.uid,
            'location': _currentPosition != null 
                ? GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude)
                : null,
            'timestamp': FieldValue.serverTimestamp(),
            'type': 'SOS',
          });

          // Store incident hash on blockchain (automatic, tamper-proof)
          try {
            final blockchainService = blockchain.BlockchainServiceDemo();
            final incidentHash = blockchain.BlockchainServiceDemo.generateIncidentHash(
              incidentId: incidentId,
              userId: user.uid,
              timestamp: timestamp,
              latitude: _currentPosition?.latitude,
              longitude: _currentPosition?.longitude,
              description: 'SOS Emergency',
            );

            // Store hash in Firestore
            await FirebaseFirestore.instance.collection('incidents').doc(incidentId).update({
              'blockchainHash': incidentHash,
              'blockchainRecorded': false,
            });

            // Record on blockchain (async, non-blocking)
            blockchainService.recordIncidentOnChain(
              incidentId: incidentId,
              userId: user.uid,
              timestamp: timestamp,
              latitude: _currentPosition?.latitude,
              longitude: _currentPosition?.longitude,
              description: 'SOS Emergency',
              privateKey: null, // TODO: Get from user settings if enabled
            ).then((txHash) {
              if (txHash != null) {
                FirebaseFirestore.instance.collection('incidents').doc(incidentId).update({
                  'blockchainTxHash': txHash,
                  'blockchainRecorded': true,
                  'blockchainRecordedAt': FieldValue.serverTimestamp(),
                });
              }
            }).catchError((e) {
              print('⚠️ Blockchain recording failed (non-critical): $e');
            });
          } catch (e) {
            print('⚠️ Blockchain service error (non-critical): $e');
          }
        }
        
        Fluttertoast.showToast(
          msg: 'Emergency alert sent!',
          backgroundColor: Colors.green,
        );
        _lastSOSTime = DateTime.now();
        
        // Show evidence capture dialog
        _showEvidenceCaptureDialog(context, incidentId);
        
        // Start cooldown timer
        Future.delayed(_cooldownPeriod, () {
          if (mounted) {
            setState(() => _isInCooldown = false);
          }
        });
      } else {
        throw Exception('Failed to send emergency alert');
      }
    } catch (e) {
      debugPrint('SOS Error: $e');
      Fluttertoast.showToast(
        msg: 'Failed to send alert: ${e.toString()}',
        backgroundColor: Colors.red,
      );
      setState(() => _isInCooldown = false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _sendEmergencySMS(String recipient) async {
    try {
      final locationInfo = _currentPosition != null
          ? 'https://maps.google.com/?q=${_currentPosition!.latitude},${_currentPosition!.longitude}'
          : 'Location unavailable';
      
      final message = 'EMERGENCY! ${_nameController.text} needs help!\n'
          'Location: $locationInfo\n'
          'Codeword: ${_codeWordController.text.isNotEmpty ? _codeWordController.text : "Not set"}';

      final hasPermission = await telephony.requestSmsPermissions;
      if (hasPermission != true) {
        throw Exception('SMS permission not granted');
      }

      await telephony.sendSms(to: recipient, message: message);
      return true;
    } catch (e) {
      debugPrint('SMS sending error: $e');
      return false;
    }
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.isEmpty) {
      Fluttertoast.showToast(msg: 'Name cannot be empty');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final prefs = await SharedPreferences.getInstance();
      
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'name': _nameController.text,
        'phone': _phoneController.text,
        'emergencyContact': _emergencyContactController.text,
        'codeWord': _codeWordController.text,
        'notificationsEnabled': _notificationsEnabled,
        'shakeToAlertEnabled': _shakeToAlertEnabled,
      });

      await prefs.setBool('shakeToAlertEnabled', _shakeToAlertEnabled);

      if (_shakeToAlertEnabled) {
        await _startShakeDetection();
      } else {
        _accelerometerSubscription?.cancel();
        setState(() => _isTestingMode = false);
      }

      Fluttertoast.showToast(msg: 'Profile updated successfully');
    } catch (e) {
      debugPrint('Update error: $e');
      Fluttertoast.showToast(msg: 'Failed to update profile');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfilePicture() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => _isLoading = true);
      _profileImageUrl = image.path;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({'profileImageUrl': _profileImageUrl});

      Fluttertoast.showToast(msg: 'Profile picture updated');
    } catch (e) {
      debugPrint('Image error: $e');
      Fluttertoast.showToast(msg: 'Failed to update picture');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      Fluttertoast.showToast(msg: 'Stopped listening for code word');
      return;
    }

    if (_codeWordController.text.isEmpty) {
      Fluttertoast.showToast(msg: 'Please set a code word first');
      return;
    }

    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      Fluttertoast.showToast(msg: 'Microphone permission required');
      return;
    }

    final available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      Fluttertoast.showToast(
        msg: 'Listening for code word... Say "${_codeWordController.text}"',
        toastLength: Toast.LENGTH_LONG,
      );
      
      _speech.listen(
        listenMode: stt.ListenMode.dictation,
        onResult: (result) {
          final spoken = result.recognizedWords.toLowerCase();
          final codeWord = _codeWordController.text.toLowerCase();
          
          if (spoken.contains(codeWord)) {
            Fluttertoast.showToast(msg: 'Code word detected! Sending SOS');
            _triggerSOS();
          }
        },
        cancelOnError: true,
        partialResults: true,
      );
    } else {
      Fluttertoast.showToast(msg: 'Speech recognition not available');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Settings'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.pinkAccent, Colors.pink],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _updateProfile,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Colors.purple, Colors.pink],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _updateProfilePicture,
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.transparent,
                            backgroundImage: _profileImageUrl != null
                                ? _profileImageUrl!.startsWith('http')
                                    ? NetworkImage(_profileImageUrl!)
                                    : FileImage(File(_profileImageUrl!)) as ImageProvider
                                : null,
                            child: _profileImageUrl == null
                                ? const Icon(Icons.person, size: 60, color: Colors.white)
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildProfileForm(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildSafetyFeatures(),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProfileForm() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Full Name',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          style: TextStyle(color: Colors.black87),
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          style: TextStyle(color: Colors.black87),
          readOnly: true,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: 'Phone',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          style: TextStyle(color: Colors.black87),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emergencyContactController,
          decoration: InputDecoration(
            labelText: 'Emergency Contact',
            hintText: '+1234567890',
            prefixIcon: Icon(Icons.emergency),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          style: TextStyle(color: Colors.black87),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Required for emergency alerts';
            if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(value!)) {
              return 'Enter a valid phone number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSafetyFeatures() {
    return Column(
      children: [
        TextFormField(
          controller: _codeWordController,
          decoration: InputDecoration(
            labelText: 'Emergency Code Word',
            hintText: 'e.g. "help me"',
            prefixIcon: Icon(Icons.security),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          style: TextStyle(color: Colors.black87),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: Icon(_isListening ? Icons.mic_off : Icons.mic,
          color: const Color.fromARGB(255, 255, 255, 255),
          ),
          label: Text(_isListening ? 'Stop Listening' : 'Start Code Word Listener',
          style: TextStyle(
      color: const Color.fromARGB(255, 255, 255, 255), // Added black text color
    ),

          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pinkAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: _toggleListening,
        ),
        if (_isListening) ...[
          const SizedBox(height: 8),
          Text(
            'Listening for code word...', 
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 24),
        SwitchListTile(
          title: Text(
            'Enable Notifications',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('Receive important safety alerts'),
          value: _notificationsEnabled,
          onChanged: (value) => setState(() => _notificationsEnabled = value),
          activeColor: Colors.pink,
        ),
        SwitchListTile(
          title: Text(
            'Shake to Alert',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(_isTestingMode 
              ? 'Test Mode: Shake phone to test feature'
              : 'Shake phone $_minShakeCount times to send emergency alert'),
          value: _shakeToAlertEnabled,
          onChanged: (value) async {
            setState(() => _shakeToAlertEnabled = value);
            if (value) {
              await _startShakeDetection();
            } else {
              _accelerometerSubscription?.cancel();
              setState(() => _isTestingMode = false);
            }
          },
          activeColor: Colors.pink,
        ),
        if (_isInCooldown) ...[
          const SizedBox(height: 16),
          Text(
            'Alert cooldown: ${_cooldownPeriod.inSeconds - DateTime.now().difference(_lastSOSTime!).inSeconds}s remaining',
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'Emergency alerts will include your location and code word',
          style: TextStyle(color: Colors.grey[700], fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Show evidence capture dialog after emergency
  Future<void> _showEvidenceCaptureDialog(BuildContext context, String incidentId) async {
    final result = await showDialog<String>(
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

    if (result != null && result != 'skip') {
      await _captureEvidence(context, incidentId, result);
    }
  }

  /// Capture evidence
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
}