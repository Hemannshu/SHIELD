# Blockchain Setup Guide - Shield App

## 🎯 Overview

This guide helps you set up **FREE blockchain integration** for tamper-proof incident reporting using **Polygon Mumbai Testnet**.

**What goes on blockchain:**
- ✅ Incident hash (SHA-256) - tamper-proof record
- ✅ Automatic verification when incident is created

**What stays off-chain:**
- ✅ Full incident details → Firebase
- ✅ Evidence files → Supabase
- ✅ Real-time alerts → Firebase

---

## 📋 Prerequisites

1. **MetaMask** (or any Web3 wallet)
2. **Polygon Mumbai Testnet** configured
3. **Testnet MATIC** (free from faucet)

---

## 🚀 Step-by-Step Setup

### Step 1: Install MetaMask

1. Download MetaMask: https://metamask.io/
2. Create a wallet (or import existing)
3. **⚠️ IMPORTANT:** This is for TESTNET only - use a test wallet!

### Step 2: Add Polygon Mumbai Testnet

1. Open MetaMask
2. Click network dropdown → "Add Network"
3. Enter these details:

```
Network Name: Polygon Mumbai
RPC URL: https://rpc-mumbai.maticvigil.com
Chain ID: 80001
Currency Symbol: MATIC
Block Explorer: https://mumbai.polygonscan.com
```

4. Click "Save"

### Step 3: Get Free Testnet MATIC

1. Visit Polygon Mumbai Faucet: https://faucet.polygon.technology/
2. Select "Mumbai" network
3. Enter your wallet address
4. Request testnet MATIC (free!)
5. Wait 1-2 minutes for tokens

**Alternative Faucets:**
- https://mumbaifaucet.com/
- https://faucets.chain.link/mumbai

### Step 4: Deploy Smart Contract

#### Option A: Using Remix (Easiest - Recommended)

1. Go to: https://remix.ethereum.org/
2. Create new file: `IncidentRegistry.sol`
3. Copy contract code from `contracts/IncidentRegistry.sol`
4. Compile contract:
   - Select compiler version: `0.8.0` or higher
   - Click "Compile IncidentRegistry.sol"
5. Deploy:
   - Go to "Deploy & Run Transactions"
   - Environment: "Injected Provider - MetaMask"
   - Select "IncidentRegistry" contract
   - Click "Deploy"
   - Confirm in MetaMask (uses testnet MATIC)
6. Copy contract address (shown after deployment)

#### Option B: Using Hardhat (Advanced)

```bash
# Install Hardhat
npm install --save-dev hardhat

# Initialize project
npx hardhat init

# Deploy to Mumbai
npx hardhat run scripts/deploy.js --network mumbai
```

### Step 5: Update Contract Address in App

1. Open `lib/services/blockchain_service.dart`
2. Find this line:
   ```dart
   static const String _contractAddress = '0x0000000000000000000000000000000000000000';
   ```
3. Replace with your deployed contract address:
   ```dart
   static const String _contractAddress = '0xYourContractAddressHere';
   ```

### Step 6: Get Wallet Private Key (Testnet Only!)

**⚠️ SECURITY WARNING:**
- **NEVER** use mainnet private keys
- **ONLY** use testnet wallet for this project
- **NEVER** share your private key

**To get testnet private key:**
1. Open MetaMask
2. Click account icon → "Account Details"
3. Click "Export Private Key"
4. Enter password
5. Copy private key (starts with `0x`)

**Store securely:**
- Add to `.env` file (don't commit to git!)
- Or use Flutter's `shared_preferences` (encrypted)

### Step 7: Configure Private Key in App

**Option A: Environment Variable (.env)**

1. Create `.env` file in `Women-Safety-app/`:
   ```
   POLYGON_PRIVATE_KEY=0xYourPrivateKeyHere
   ```

2. Load in app:
   ```dart
   import 'package:flutter_dotenv/flutter_dotenv.dart';
   
   // In main.dart
   await dotenv.load(fileName: ".env");
   
   // In blockchain_service.dart
   final privateKey = dotenv.env['POLYGON_PRIVATE_KEY'];
   ```

**Option B: User Settings (Recommended)**

Store in app settings (encrypted):
```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart';

// Store encrypted private key
final prefs = await SharedPreferences.getInstance();
await prefs.setString('blockchain_private_key', encryptedKey);
```

### Step 8: Test the Integration

1. Run the app: `flutter run`
2. Trigger an SOS emergency
3. Check console logs for:
   - "✅ Incident hash recorded on blockchain!"
   - Transaction hash
4. Verify on PolygonScan:
   - Visit: https://mumbai.polygonscan.com/
   - Paste transaction hash
   - See your incident hash on-chain!

---

## 🔍 Verification

### Verify Incident Hash

```dart
final blockchainService = BlockchainService();
final verified = await blockchainService.verifyIncidentHash(incidentHash);
print('Hash verified: $verified');
```

### View on PolygonScan

1. Go to: https://mumbai.polygonscan.com/
2. Enter transaction hash
3. See:
   - Transaction details
   - Event logs (IncidentRecorded)
   - Block number
   - Timestamp

---

## 📊 How It Works

### Flow:

1. **User triggers SOS** → Emergency alert sent
2. **Incident created** → Stored in Firebase
3. **Hash generated** → SHA-256 of incident data
4. **Hash stored on-chain** → Polygon Mumbai (tamper-proof)
5. **Transaction confirmed** → Stored in Firebase

### Data Structure:

**On Blockchain (Hash Only):**
```solidity
bytes32 incidentHash = sha256(incidentData)
```

**In Firebase (Full Data):**
```json
{
  "incidentId": "1234567890",
  "userId": "user123",
  "location": { "lat": 12.34, "lng": 56.78 },
  "timestamp": "2024-01-01T12:00:00Z",
  "blockchainHash": "abc123...",
  "blockchainTxHash": "0xdef456...",
  "blockchainRecorded": true
}
```

---

## 🛠️ Troubleshooting

### "Contract not deployed"
- ✅ Deploy contract first (Step 4)
- ✅ Update contract address in code

### "Insufficient funds"
- ✅ Get testnet MATIC from faucet (Step 3)
- ✅ Check wallet has MATIC balance

### "Private key not found"
- ✅ Add private key to `.env` or settings
- ✅ Use testnet wallet only!

### "Transaction failed"
- ✅ Check network is Polygon Mumbai
- ✅ Verify contract address is correct
- ✅ Check gas limit (should be auto)

### "Hash not verified"
- ✅ Wait for transaction confirmation (1-2 minutes)
- ✅ Check transaction on PolygonScan

---

## 📝 Smart Contract Details

**Contract:** `IncidentRegistry.sol`

**Functions:**
- `recordIncident(bytes32 hash)` - Store hash on-chain
- `verifyIncident(bytes32 hash)` - Verify hash exists
- `getTotalIncidents()` - Get total count

**Events:**
- `IncidentRecorded` - Emitted when hash is stored

**Security:**
- Prevents duplicate hashes
- Immutable once stored
- Public verification

---

## 💡 Tips

1. **Test First:** Always test on testnet before mainnet
2. **Backup Keys:** Save private key securely (testnet only!)
3. **Monitor Gas:** Testnet is free, but monitor usage
4. **Verify Transactions:** Always check PolygonScan
5. **Documentation:** Keep contract address and ABI handy

---

## 🎓 For College Project

**What to Include:**

1. **Smart Contract Code** (`IncidentRegistry.sol`)
2. **Deployment Address** (on PolygonScan)
3. **Transaction Examples** (screenshots from PolygonScan)
4. **Architecture Diagram** (on-chain vs off-chain)
5. **Code Explanation** (how hash is generated)

**Presentation Points:**

- ✅ Tamper-proof incident records
- ✅ Immutable blockchain storage
- ✅ Free testnet (no cost)
- ✅ Automatic verification
- ✅ Simple implementation

---

## ✅ Checklist

- [ ] MetaMask installed
- [ ] Polygon Mumbai added to MetaMask
- [ ] Testnet MATIC obtained
- [ ] Smart contract deployed
- [ ] Contract address updated in code
- [ ] Private key configured (testnet only!)
- [ ] Tested SOS trigger
- [ ] Verified transaction on PolygonScan
- [ ] Hash verification working

---

## 🆘 Need Help?

**Common Issues:**
- Check console logs for errors
- Verify network is Mumbai testnet
- Ensure contract is deployed
- Check private key format (starts with `0x`)

**Resources:**
- Polygon Docs: https://docs.polygon.technology/
- Remix IDE: https://remix.ethereum.org/
- PolygonScan: https://mumbai.polygonscan.com/

---

## 🎉 Success!

Once setup is complete:
- ✅ Incidents are automatically recorded on blockchain
- ✅ Hashes are tamper-proof
- ✅ Verification is automatic
- ✅ All FREE on testnet!

**Your Shield app now has blockchain-powered tamper-proof incident reporting!** 🚀

