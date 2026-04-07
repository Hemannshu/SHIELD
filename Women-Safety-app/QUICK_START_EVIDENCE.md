# Quick Start: FREE Evidence Storage

## ✅ What You Have

I've created **2 free evidence storage services** for you:

1. **`firebase_evidence_service.dart`** ⭐ **RECOMMENDED**
   - Uses Firebase Storage (already in your project)
   - Free tier: 5GB storage, 1GB/day downloads
   - Easiest to implement
   - No new accounts needed

2. **`free_evidence_storage_service.dart`**
   - Uses IPFS (decentralized storage)
   - Completely free, no limits
   - More complex setup

---

## 🚀 Quick Implementation (5 Minutes)

### Step 1: Use Firebase Service (Easiest)

**File:** `lib/services/firebase_evidence_service.dart`

✅ Already created! Just use it.

### Step 2: Add to Emergency Service

**File:** `lib/widgets/home_widgets/SOSButton/emergency_service.dart`

Add this import:
```dart
import 'package:title_proj/services/firebase_evidence_service.dart';
```

Add evidence capture after emergency:
```dart
class EmergencyService {
  final FirebaseEvidenceService _evidenceService = FirebaseEvidenceService();
  
  Future<void> handleEmergency(Position position, {String? customMessage}) async {
    try {
      // ... existing SMS sending code ...
      
      // Create incident ID
      final incidentId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Store incident
      await _firestore.collection('incidents').doc(incidentId).set({
        'userId': _auth.currentUser!.uid,
        'location': GeoPoint(position.latitude, position.longitude),
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'SOS',
      });
      
      // NEW: Show dialog to capture evidence (optional)
      // You can add this UI later
      
    } catch (e) {
      // ... error handling ...
    }
  }
}
```

### Step 3: Create Simple UI Widget

**File:** `lib/widgets/evidence_capture_button.dart`

```dart
import 'package:flutter/material.dart';
import 'package:title_proj/services/firebase_evidence_service.dart';

class EvidenceCaptureButton extends StatelessWidget {
  final String incidentId;
  
  const EvidenceCaptureButton({required this.incidentId});
  
  @override
  Widget build(BuildContext context) {
    final evidenceService = FirebaseEvidenceService();
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Capture Evidence', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _captureEvidence(context, evidenceService, ImageSource.camera),
                  icon: Icon(Icons.camera_alt),
                  label: Text('Camera'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _captureEvidence(context, evidenceService, ImageSource.gallery),
                  icon: Icon(Icons.photo_library),
                  label: Text('Gallery'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _captureEvidence(
    BuildContext context,
    FirebaseEvidenceService service,
    ImageSource source,
  ) async {
    try {
      final evidence = await service.storeEvidence(
        incidentId: incidentId,
        description: 'Emergency evidence',
        source: source,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Evidence stored securely'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

---

## 💰 Cost: $0.00

### Firebase Storage Free Tier:
- ✅ **5GB storage** - FREE
- ✅ **1GB/day downloads** - FREE
- ✅ **No credit card needed**
- ✅ **Already configured**

### For Your App:
- Average photo: ~2MB
- 5GB = **~2,500 photos**
- More than enough!

---

## 📝 Example Usage

```dart
// 1. Store evidence
final evidenceService = FirebaseEvidenceService();

final evidence = await evidenceService.storeEvidence(
  incidentId: 'incident_123',
  description: 'Emergency photo',
  source: ImageSource.camera,
);

print('✅ Stored: ${evidence.downloadUrl}');
print('Hash: ${evidence.fileHash}');

// 2. Get evidence for incident
final evidenceList = await evidenceService.getIncidentEvidence('incident_123');

// 3. Verify evidence (check if file was tampered)
final verified = await evidenceService.verifyEvidence(
  evidence.fileHash,
  evidence.downloadUrl,
);

print('Verified: $verified');
```

---

## ✅ What You Get

- ✅ **Completely FREE** - No money needed
- ✅ **Hash verification** - Tamper-proof
- ✅ **Easy to use** - Simple API
- ✅ **Already configured** - Uses your Firebase
- ✅ **Secure** - Only user can access their evidence
- ✅ **Scalable** - 5GB free storage

---

## 🎯 Next Steps

1. ✅ Service is ready: `firebase_evidence_service.dart`
2. Add UI widget (example above)
3. Integrate with emergency flow
4. Test with a photo
5. Done!

**Total time: 10-15 minutes** ⚡

---

## 📚 Full Documentation

See `FREE_EVIDENCE_STORAGE_GUIDE.md` for:
- Detailed implementation
- Alternative storage options
- Advanced features
- Security considerations

---

## 🆘 Need Help?

The service is ready to use! Just:
1. Import it
2. Call `storeEvidence()`
3. Done!

All completely FREE! 🎉

