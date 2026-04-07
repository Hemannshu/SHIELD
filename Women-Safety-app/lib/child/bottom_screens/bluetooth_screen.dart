import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class BluetoothScreen extends StatefulWidget {
  @override
  _BluetoothScreenState createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  List<ScanResult> scanResults = [];
  BluetoothDevice? connectedDevice;
  List<BluetoothService> bluetoothServices = [];

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  Future<void> requestPermissions() async {
    await Permission.bluetooth.request();
    await Permission.location.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
  }

  void scanForDevices() {
    scanResults.clear();
    FlutterBluePlus.startScan(timeout: Duration(seconds: 4));
    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        scanResults = results;
      });
    });
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    await device.connect();
    setState(() {
      connectedDevice = device;
    });
    bluetoothServices = await device.discoverServices();
    setState(() {});
  }

  Future<Position> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are denied.');
      }
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Widget buildDeviceTile(ScanResult result) {
    return ListTile(
      title: Text(result.device.name.isNotEmpty
          ? result.device.name
          : 'Unknown Device'),
      subtitle: Text(result.device.id.toString()),
      trailing: ElevatedButton(
        onPressed: () => connectToDevice(result.device),
        child: Text('Connect'),
      ),
    );
  }

  Widget buildServiceTile(BluetoothService service) {
    return ExpansionTile(
      title: Text('Service: ${service.uuid}'),
      children: service.characteristics.map((characteristic) {
        return ListTile(
          title: Text('Characteristic: ${characteristic.uuid}'),
          subtitle: Text('Write: ${characteristic.properties.write}'),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Devices'),
        actions: [
          IconButton(
            icon: Icon(Icons.bluetooth_searching),
            onPressed: scanForDevices,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: connectedDevice == null
            ? ListView.builder(
                itemCount: scanResults.length,
                itemBuilder: (context, index) =>
                    buildDeviceTile(scanResults[index]),
              )
            : Column(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final pos = await _getLocation();
                      final locationString =
                          "${pos.latitude},${pos.longitude}";

                      bool sent = false;

                      for (var service in bluetoothServices) {
                        for (var char in service.characteristics) {
                          if (char.properties.write) {
                            await char.write(utf8.encode(locationString));
                            sent = true;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("📍 Location sent via BLE"),
                              ),
                            );
                            break;
                          }
                        }
                        if (sent) break;
                      }

                      if (!sent) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text("⚠️ No writable characteristic found."),
                          ),
                        );
                      }
                    },
                    child: Text("📤 Send Location"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: StadiumBorder(),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children: bluetoothServices
                          .map((s) => buildServiceTile(s))
                          .toList(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
