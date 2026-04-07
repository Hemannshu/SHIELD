# FREE Evidence Storage Implementation Guide

## 🎯 Completely Free Solution

This implementation uses **100% free services** with no credit card or payment required:

1. **IPFS (InterPlanetary File System)** - Decentralized, free storage
2. **Firebase Firestore** - Free tier (already in your project)
3. **Hash Verification** - No blockchain transactions needed

---

## 📦 Free Storage Options

### Option 1: Web3.Storage (Recommended - Easiest) ⭐

**Free Tier:**
- ✅ 5GB storage
- ✅ Unlimited requests
- ✅ No credit card needed
- ✅ No expiration
- ✅ IPFS-based (decentralized)

**Setup:**
1. Visit: https://web3.storage/
2. Sign up with email (free)
3. Get API token
4. Use in code

**Cost:** $0.00 (completely free)

---

### Option 2: NFT.Storage (Also Free) ⭐

**Free Tier:**
- ✅ Unlimited storage
- ✅ No credit card needed
- ✅ IPFS + Filecoin
- ✅ Permanent storage

**Setup:**
1. Visit: https://nft.storage/
2. Sign up (free)
3. Get API key
4. Use in code

**Cost:** $0.00 (completely free)

---

### Option 3: Firebase Storage (You Already Have This) ⭐⭐

**Free Tier:**
- ✅ 5GB storage
- ✅ 1GB/day downloads
- ✅ Already configured in your project
- ✅ Easy integration

**Cost:** $0.00 (free tier)

**Note:** This is the easiest since you already have Firebase set up!

---

### Option 4: IPFS Public Gateways (No Account Needed)

**Free:**
- ✅ Completely free
- ✅ No account needed
- ✅ Decentralized
- ⚠️ Slower (public gateways)
- ⚠️ Files may not persist forever

**Cost:** $0.00 (completely free)

---

## 🚀 Recommended Implementation

### **Use Firebase Storage (Easiest)**

Since you already have Firebase configured, this is the simplest approach:

1. ✅ No new accounts needed
2. ✅ Already integrated
3. ✅ Free tier: 5GB storage
4. ✅ Fast and reliable
5. ✅ Add hash verification for integrity

---

## 📝 Implementation Steps

### Step 1: Add Firebase Storage Dependency

Your `pubspec.yaml` already has:
```yaml
firebase_storage: ^12.4.4
```

✅ Already done!

---

### Step 2: Create Free Evidence Storage Service

I've created `lib/services/free_evidence_storage_service.dart` for you.

**Features:**
- ✅ Completely free
- ✅ Uses Firebase Storage (free tier)
- ✅ Hash verification (no blockchain needed)
- ✅ IPFS option available
- ✅ Easy to use

---

### Step 3: Integrate with Emergency Service

**File:** `lib/widgets/home_widgets/SOSButton/emergency_service.dart`

Add evidence capture after emergency:

```dart
import 'package:title_proj/services/free_evidence_storage_service.dart';

class EmergencyService {
  final FreeEvidenceStorageService _evidenceStorage = FreeEvidenceStorageService();
  
  Future<void> handleEmergency(Position position, {String? customMessage}) async {
    try {
      // ... existing SMS sending code ...
      
      // Create incident ID
      final incidentId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Store incident in Firestore
      await _firestore.collection('incidents').doc(incidentId).set({
        'userId': _auth.currentUser!.uid,
        'location': GeoPoint(position.latitude, position.longitude),
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'SOS',
      });
      
      // NEW: Offer to capture evidence
      // (You can show a dialog asking user if they want to take photo)
      
    } catch (e) {
      // ... error handling ...
    }
  }
}
```

---

### Step 4: Create Evidence Capture UI

**File:** `lib/widgets/evidence_capture_widget.dart`

```dart
import 'package:flutter/material.dart';
import 'package:title_proj/services/free_evidence_storage_service.dart';

class EvidenceCaptureWidget extends StatefulWidget {
  final String incidentId;
  
  const EvidenceCaptureWidget({required this.incidentId});
  
  @override
  _EvidenceCaptureWidgetState createState() => _EvidenceCaptureWidgetState();
}

class _EvidenceCaptureWidgetState extends State<EvidenceCaptureWidget> {
  final FreeEvidenceStorageService _evidenceStorage = FreeEvidenceStorageService();
  bool _uploading = false;
  
  Future<void> _captureEvidence(ImageSource source) async {
    setState(() => _uploading = true);
    
    try {
      final evidence = await _evidenceStorage.storeEvidence(
        incidentId: widget.incidentId,
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
    } finally {
      setState(() => _uploading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Capture Evidence',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _uploading 
                      ? null 
                      : () => _captureEvidence(ImageSource.camera),
                  icon: Icon(Icons.camera_alt),
                  label: Text('Camera'),
                ),
                ElevatedButton.icon(
                  onPressed: _uploading 
                      ? null 
                      : () => _captureEvidence(ImageSource.gallery),
                  icon: Icon(Icons.photo_library),
                  label: Text('Gallery'),
                ),
              ],
            ),
            if (_uploading)
              Padding(
                padding: EdgeInsets.only(top: 16),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
```

---

### Step 5: Show Evidence in Incident History

Create a screen to view stored evidence:

```dart
// lib/child/bottom_screens/evidence_viewer_page.dart
import 'package:flutter/material.dart';
import 'package:title_proj/services/free_evidence_storage_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EvidenceViewerPage extends StatelessWidget {
  final String incidentId;
  
  const EvidenceViewerPage({required this.incidentId});
  
  @override
  Widget build(BuildContext context) {
    final evidenceService = FreeEvidenceStorageService();
    
    return Scaffold(
      appBar: AppBar(title: Text('Evidence')),
      body: FutureBuilder<List<EvidenceRecord>>(
        future: evidenceService.getIncidentEvidence(incidentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No evidence captured'));
          }
          
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final evidence = snapshot.data![index];
              return Card(
                child: Column(
                  children: [
                    if (evidence.fileType == 'image')
                      CachedNetworkImage(
                        imageUrl: evidence.ipfsUrls.first,
                        placeholder: (context, url) => CircularProgressIndicator(),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                      ),
                    ListTile(
                      title: Text(evidence.fileName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hash: ${evidence.fileHash.substring(0, 16)}...'),
                          Text('Size: ${(evidence.fileSize / 1024).toStringAsFixed(2)} KB'),
                          Text('Type: ${evidence.fileType}'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.verified, color: Colors.green),
                        onPressed: () async {
                          final verified = await evidenceService.verifyEvidence(
                            evidence.fileHash,
                            evidence.ipfsHash,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(verified 
                                  ? '✅ Evidence verified' 
                                  : '❌ Verification failed'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

---

## 💰 Cost Breakdown

### Firebase Storage (Recommended)
- **Storage:** 5GB free
- **Downloads:** 1GB/day free
- **Cost:** $0.00/month
- **After free tier:** $0.026/GB storage, $0.12/GB downloads

### Web3.Storage
- **Storage:** 5GB free
- **Cost:** $0.00/month
- **After free tier:** Contact for pricing

### NFT.Storage
- **Storage:** Unlimited free
- **Cost:** $0.00/month
- **Permanent storage**

---

## 🔐 Security Features

1. **Hash Verification**
   - Each file has SHA-256 hash
   - Can verify file integrity anytime
   - Proves file hasn't been tampered with

2. **Firebase Security Rules**
   - Only user can access their evidence
   - Encrypted in transit
   - Secure storage

3. **IPFS (if used)**
   - Decentralized (no single point of failure)
   - Content-addressed (hash = address)
   - Cannot be deleted

---

## 📊 Storage Limits

### Free Tier Limits:
- **Firebase:** 5GB storage, 1GB/day downloads
- **Web3.Storage:** 5GB storage
- **NFT.Storage:** Unlimited

### For Your App:
- Average photo: ~2MB
- 5GB = ~2,500 photos
- More than enough for evidence storage!

---

## 🚀 Quick Start

1. ✅ Service already created: `free_evidence_storage_service.dart`
2. Add to your emergency flow
3. Test with a photo
4. Done!

---

## 📝 Example Usage

```dart
// Capture evidence after emergency
final evidenceService = FreeEvidenceStorageService();

final evidence = await evidenceService.storeEvidence(
  incidentId: 'incident_123',
  description: 'Emergency photo',
  source: ImageSource.camera,
);

print('Evidence stored: ${evidence.ipfsHash}');
print('Hash: ${evidence.fileHash}');

// Verify later
final verified = await evidenceService.verifyEvidence(
  evidence.fileHash,
  evidence.ipfsHash,
);
print('Verified: $verified');
```

---

## ✅ Summary

**What You Get:**
- ✅ Completely free evidence storage
- ✅ Hash verification (tamper-proof)
- ✅ Easy integration
- ✅ Works with your existing Firebase
- ✅ No blockchain transactions needed
- ✅ No credit card required

**Next Steps:**
1. Review `free_evidence_storage_service.dart`
2. Integrate with emergency service
3. Add UI for evidence capture
4. Test and deploy!

All completely FREE! 🎉

