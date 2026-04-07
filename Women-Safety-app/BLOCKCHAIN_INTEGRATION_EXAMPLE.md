# Blockchain Integration Example

## Quick Integration Guide

### Step 1: Add Dependencies

Add to `pubspec.yaml`:
```yaml
dependencies:
  web3dart: ^2.7.3      # For blockchain interaction
  crypto: ^3.0.6         # For hashing (already in project)
  http: ^1.3.0           # For API calls (already in project)
```

Run:
```bash
flutter pub get
```

---

### Step 2: Modify Emergency Service

**File:** `lib/widgets/home_widgets/SOSButton/emergency_service.dart`

Add blockchain logging after sending SMS:

```dart
import 'package:title_proj/services/blockchain_service_example.dart';

class EmergencyService {
  // ... existing code ...
  
  final BlockchainService _blockchain = BlockchainService();
  
  Future<void> handleEmergency(Position position, {String? customMessage}) async {
    try {
      // ... existing SMS sending code ...
      
      // NEW: Store on blockchain
      final user = _auth.currentUser;
      if (user != null) {
        try {
          final txHash = await _blockchain.logIncident(
            userId: user.uid,
            latitude: position.latitude,
            longitude: position.longitude,
            timestamp: DateTime.now(),
            incidentType: 'SOS',
            additionalData: customMessage,
          );
          
          print('✅ Incident stored on blockchain: $txHash');
          
          // Optional: Show user confirmation
          Fluttertoast.showToast(
            msg: 'Incident logged securely',
            backgroundColor: Colors.blue,
          );
        } catch (e) {
          // Don't fail the whole emergency if blockchain fails
          print('⚠️ Blockchain logging failed: $e');
        }
      }
      
    } catch (e) {
      // ... existing error handling ...
    }
  }
}
```

---

### Step 3: Add Blockchain View (Optional)

Create a screen to view blockchain incidents:

**File:** `lib/child/bottom_screens/blockchain_incidents_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:title_proj/services/blockchain_service_example.dart';

class BlockchainIncidentsPage extends StatefulWidget {
  @override
  _BlockchainIncidentsPageState createState() => _BlockchainIncidentsPageState();
}

class _BlockchainIncidentsPageState extends State<BlockchainIncidentsPage> {
  final BlockchainService _blockchain = BlockchainService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _incidents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    setState(() => _loading = true);
    final user = _auth.currentUser;
    if (user != null) {
      final incidents = await _blockchain.getUserIncidents(user.uid);
      setState(() {
        _incidents = incidents;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Blockchain Incidents'),
        subtitle: Text('Tamper-proof records'),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _incidents.isEmpty
              ? Center(child: Text('No incidents recorded'))
              : ListView.builder(
                  itemCount: _incidents.length,
                  itemBuilder: (context, index) {
                    final incident = _incidents[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.security, color: Colors.green),
                        title: Text(incident['type'] ?? 'Unknown'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hash: ${incident['blockchainHash']?.substring(0, 20)}...'),
                            Text('TX: ${incident['transactionHash']?.substring(0, 20)}...'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.verified),
                          onPressed: () async {
                            final verified = await _blockchain.verifyIncident(
                              incident['transactionHash'],
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(verified
                                    ? '✅ Verified on blockchain'
                                    : '❌ Verification failed'),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
```

---

### Step 4: Test Implementation

1. **Test with mock blockchain first:**
   - The example service uses mock implementation
   - Test that incidents are stored in Firestore
   - Verify the flow works

2. **Connect to real blockchain:**
   - Set up Polygon testnet account
   - Deploy simple smart contract
   - Update `_storeOnBlockchain` method
   - Test on testnet before mainnet

---

### Step 5: Production Setup

1. **Deploy Smart Contract:**
```solidity
// Simple contract to store incident hashes
pragma solidity ^0.8.0;

contract IncidentRegistry {
    struct Incident {
        string hash;
        uint256 timestamp;
        address user;
    }
    
    mapping(string => Incident) public incidents;
    
    function storeIncident(string memory hash) public {
        incidents[hash] = Incident({
            hash: hash,
            timestamp: block.timestamp,
            user: msg.sender
        });
    }
    
    function verifyIncident(string memory hash) public view returns (bool) {
        return incidents[hash].timestamp > 0;
    }
}
```

2. **Update BlockchainService:**
   - Replace mock methods with actual web3dart calls
   - Connect to Polygon RPC
   - Call smart contract methods

---

## Cost Breakdown

**Per Incident:**
- Blockchain transaction: ~$0.001 (Polygon)
- Firestore storage: ~$0.00001
- **Total: ~$0.001 per incident**

**Monthly (1000 incidents):**
- Blockchain: ~$1.00
- Firestore: ~$0.01
- **Total: ~$1.01/month**

Very affordable! 💰

---

## Next Steps

1. ✅ Review the implementation ideas
2. ✅ Choose which features to implement
3. ✅ Set up Polygon testnet
4. ✅ Test with mock implementation
5. ✅ Deploy smart contract
6. ✅ Connect to real blockchain
7. ✅ Deploy to production

---

## Support

If you need help implementing any of these features, I can:
- Create the actual smart contract code
- Set up the blockchain connection
- Integrate with your existing code
- Help with testing and deployment

Just let me know which feature you'd like to implement first! 🚀

