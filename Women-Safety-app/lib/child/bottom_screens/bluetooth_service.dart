import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class MyBluetoothService {
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? _characteristic;

  Future<List<BluetoothDevice>> scanForDevices() async {
    List<BluetoothDevice> foundDevices = [];

    FlutterBluePlus.startScan(timeout: Duration(seconds: 4));
    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (!foundDevices.contains(r.device)) {
          foundDevices.add(r.device);
        }
      }
    });

    await Future.delayed(Duration(seconds: 5));
    await FlutterBluePlus.stopScan();
    return foundDevices;
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    await device.connect();
    connectedDevice = device;

    List<BluetoothService> services = await device.discoverServices();
    for (BluetoothService service in services) {
      for (BluetoothCharacteristic c in service.characteristics) {
        if (c.properties.write) {
          _characteristic = c;
          break;
        }
      }
      if (_characteristic != null) break;
    }
  }

  Future<void> sendMessage(String message) async {
    if (_characteristic != null) {
      await _characteristic!.write(message.codeUnits);
    } else {
      throw Exception("No writable characteristic found.");
    }
  }
}
