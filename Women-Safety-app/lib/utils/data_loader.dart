import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

Future<List<dynamic>> loadCrimeData() async {
  String jsonString = await rootBundle.loadString('assets/crime_data.json');
  return jsonDecode(jsonString);
}