import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:title_proj/widgets/home_widgets/live_safe/BusStationCard.dart';
import 'package:title_proj/widgets/home_widgets/live_safe/HospitalCard.dart';
import 'package:title_proj/widgets/home_widgets/live_safe/PharmacyCard.dart';
import 'package:title_proj/widgets/home_widgets/live_safe/PoliceStationCard.dart';
import 'package:url_launcher/url_launcher.dart';

class LiveSafe extends StatelessWidget {
  const LiveSafe({Key? key}) : super(key: key);

  static Future<void> openMap(String location) async {
    String googleUrl = 'https://www.google.com/maps/search/$location';
    final Uri _url = Uri.parse(googleUrl);
    try {
      await launchUrl(_url);
    } catch (e) {
      Fluttertoast.showToast(
          msg: 'Something went wrong! Call emergency number',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      height: 120, // Increased height for better spacing
      width: MediaQuery.of(context).size.width,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        children: [
          PoliceStationCard(
            onMapFunction: openMap,
            isDarkMode: isDarkMode,
          ),
          const SizedBox(width: 12),
          HospitalCard(
            onMapFunction: openMap,
            isDarkMode: isDarkMode,
          ),
          const SizedBox(width: 12),
          PharmacyCard(
            onMapFunction: openMap,
            isDarkMode: isDarkMode,
          ),
          const SizedBox(width: 12),
          BusStationCard(
            onMapFunction: openMap,
            isDarkMode: isDarkMode,
          ),
        ],
      ),
    );
  }
}