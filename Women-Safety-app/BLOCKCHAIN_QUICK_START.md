# Blockchain Quick Start - Shield App

## ⚡ 5-Minute Setup

### 1. Install MetaMask
- Download: https://metamask.io/
- Create test wallet

### 2. Add Polygon Mumbai
- Network: Polygon Mumbai
- RPC: `https://rpc-mumbai.maticvigil.com`
- Chain ID: `80001`

### 3. Get Free MATIC
- Faucet: https://faucet.polygon.technology/
- Select Mumbai → Enter address → Get tokens

### 4. Deploy Contract
- Go to: https://remix.ethereum.org/
- Copy `contracts/IncidentRegistry.sol`
- Compile → Deploy → Copy address

### 5. Update Code
```dart
// In lib/services/blockchain_service.dart
static const String _contractAddress = '0xYourContractAddress';
```

### 6. Add Private Key (Testnet Only!)
```dart
// In .env file
POLYGON_PRIVATE_KEY=0xYourPrivateKey
```

### 7. Test!
- Trigger SOS
- Check console for transaction hash
- Verify on: https://mumbai.polygonscan.com/

---

## ✅ Done!

Your app now has tamper-proof incident reporting on blockchain!

**Full guide:** See `BLOCKCHAIN_SETUP_GUIDE.md`

