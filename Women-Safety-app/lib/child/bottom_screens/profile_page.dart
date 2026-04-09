import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:title_proj/services/native_sms_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:title_proj/services/blockchain_service.dart';
import 'package:title_proj/services/auto_evidence_capture_service.dart';
import 'package:title_proj/services/firebase_evidence_service.dart';
import 'package:title_proj/utils/app_theme.dart';

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
  Timer? _sosCancelTimer;
  bool _sosPending = false;
  int _cancelCountdown = 0;
  final AutoEvidenceCaptureService _autoEvidence = AutoEvidenceCaptureService();

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
    _sosCancelTimer?.cancel();
    _autoEvidence.stopCapture();
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
            debugPrint('Shake detected! Starting 5s countdown...');
            _startSosCancelCountdown(5);
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

  /// Cancel countdown before SOS fires. Paper: 3s for voice, 5s for shake.
  void _startSosCancelCountdown(int seconds) {
    if (_sosPending) return;
    _sosPending = true;
    _cancelCountdown = seconds;

    Fluttertoast.showToast(
      msg: 'SOS in $_cancelCountdown seconds — shake again to cancel',
      backgroundColor: Colors.orange,
      toastLength: Toast.LENGTH_LONG,
    );

    _sosCancelTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _cancelCountdown--;
      if (_cancelCountdown <= 0) {
        timer.cancel();
        _sosPending = false;
        _triggerSOS();
      }
    });
  }

  void cancelPendingSOS() {
    _sosCancelTimer?.cancel();
    _sosPending = false;
    _cancelCountdown = 0;
    Fluttertoast.showToast(
      msg: 'SOS cancelled',
      backgroundColor: Colors.grey,
    );
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

          // Store incident hash on blockchain (real Polygon Amoy)
          try {
            final blockchainService = BlockchainService();
            final incidentHash = BlockchainService.generateIncidentHash(
              incidentId: incidentId,
              userId: user.uid,
              timestamp: timestamp,
              latitude: _currentPosition?.latitude,
              longitude: _currentPosition?.longitude,
              description: 'SOS Emergency',
            );

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

          // Start automatic evidence capture (photo + GPS logging)
          try {
            _autoEvidence.startCapture(incidentId: incidentId);
          } catch (e) {
            print('⚠️ Auto evidence capture error: $e');
          }
        }
        
        Fluttertoast.showToast(
          msg: 'Emergency alert sent!',
          backgroundColor: Colors.green,
        );
        _lastSOSTime = DateTime.now();
        
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

      return await NativeSmsService.sendSms(phone: recipient, message: message);
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
            Fluttertoast.showToast(msg: 'Code word detected! SOS in 3 seconds...');
            _startSosCancelCountdown(3);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded, color: Colors.white),
            onPressed: _updateProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Avatar
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppTheme.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryPink.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _updateProfilePicture,
                        child: CircleAvatar(
                          radius: 52,
                          backgroundColor: Colors.transparent,
                          backgroundImage: _profileImageUrl != null
                              ? _profileImageUrl!.startsWith('http')
                                  ? NetworkImage(_profileImageUrl!)
                                  : FileImage(File(_profileImageUrl!)) as ImageProvider
                              : null,
                          child: _profileImageUrl == null
                              ? const Icon(Icons.person_rounded, size: 50, color: Colors.white)
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkCard : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.primaryPink, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 18, color: AppTheme.primaryPink),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Profile form card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.06) : AppTheme.neutralGrey200,
                      ),
                    ),
                    child: _buildProfileForm(isDark),
                  ),

                  const SizedBox(height: 16),

                  // Safety features card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.06) : AppTheme.neutralGrey200,
                      ),
                    ),
                    child: _buildSafetyFeatures(isDark),
                  ),

                  const SizedBox(height: 32),

                  // Logout
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
                      },
                      icon: Icon(Icons.logout_rounded,
                        color: isDark ? Colors.red[300] : Colors.red[400]),
                      label: Text('Sign Out',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.red[300] : Colors.red[400],
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: isDark ? Colors.red[300]! : Colors.red[400]!),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Personal Info',
          style: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppTheme.neutralGrey900,
          ),
        ),
        const SizedBox(height: 16),
        _buildFormField(_nameController, 'Full Name', Icons.person_rounded, isDark),
        const SizedBox(height: 12),
        _buildFormField(_emailController, 'Email', Icons.email_rounded, isDark, readOnly: true),
        const SizedBox(height: 12),
        _buildFormField(_phoneController, 'Phone', Icons.phone_rounded, isDark,
            keyboardType: TextInputType.phone),
        const SizedBox(height: 12),
        _buildFormField(_emergencyContactController, 'Emergency Contact',
            Icons.emergency_rounded, isDark, keyboardType: TextInputType.phone),
      ],
    );
  }

  Widget _buildFormField(TextEditingController controller, String label,
      IconData icon, bool isDark, {bool readOnly = false, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : AppTheme.neutralGrey900),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon,
          color: isDark ? Colors.white38 : AppTheme.neutralGrey400, size: 20),
        filled: true,
        fillColor: isDark ? AppTheme.darkElevated.withOpacity(0.5) : AppTheme.neutralGrey100,
      ),
    );
  }

  Widget _buildSafetyFeatures(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Safety Features',
          style: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppTheme.neutralGrey900,
          ),
        ),
        const SizedBox(height: 16),
        _buildFormField(_codeWordController, 'Emergency Code Word',
            Icons.security_rounded, isDark),
        const SizedBox(height: 16),
        // Voice listener button
        SizedBox(
          width: double.infinity, height: 50,
          child: InkWell(
            onTap: _toggleListening,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: _isListening
                  ? BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    )
                  : AppTheme.gradientButton(radius: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_isListening ? Icons.mic_off_rounded : Icons.mic_rounded,
                    color: _isListening ? Colors.red : Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _isListening ? 'Stop Listening' : 'Start Code Word Listener',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: _isListening ? Colors.red : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isListening) ...[
          const SizedBox(height: 8),
          Text(
            'Listening for code word...',
            style: GoogleFonts.inter(
              color: Colors.green, fontWeight: FontWeight.w600, fontSize: 13,
            ),
          ),
        ],
        const SizedBox(height: 20),
        // Notifications toggle
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkElevated.withOpacity(0.5) : AppTheme.neutralGrey100,
            borderRadius: BorderRadius.circular(14),
          ),
          child: SwitchListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            title: Text('Enable Notifications',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600, fontSize: 14,
                color: isDark ? Colors.white : AppTheme.neutralGrey900,
              ),
            ),
            subtitle: Text('Receive important safety alerts',
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.neutralGrey500),
            ),
            value: _notificationsEnabled,
            onChanged: (value) => setState(() => _notificationsEnabled = value),
            activeColor: AppTheme.primaryPink,
          ),
        ),
        const SizedBox(height: 12),
        // Shake to alert toggle
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkElevated.withOpacity(0.5) : AppTheme.neutralGrey100,
            borderRadius: BorderRadius.circular(14),
          ),
          child: SwitchListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            title: Text('Shake to Alert',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600, fontSize: 14,
                color: isDark ? Colors.white : AppTheme.neutralGrey900,
              ),
            ),
            subtitle: Text(
              _isTestingMode
                  ? 'Test Mode: Shake phone to test feature'
                  : 'Shake phone $_minShakeCount times to send emergency alert',
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.neutralGrey500),
            ),
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
            activeColor: AppTheme.primaryPink,
          ),
        ),
        if (_isInCooldown) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Text(
              'Alert cooldown: ${_cooldownPeriod.inSeconds - DateTime.now().difference(_lastSOSTime!).inSeconds}s remaining',
              style: GoogleFonts.inter(color: Colors.orange, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'Emergency alerts will include your location and code word',
          style: GoogleFonts.inter(
            color: isDark ? AppTheme.neutralGrey400 : AppTheme.neutralGrey500,
            fontStyle: FontStyle.italic, fontSize: 12,
          ),
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