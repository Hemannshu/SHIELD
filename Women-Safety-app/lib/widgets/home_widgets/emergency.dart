import 'package:flutter/material.dart';
import 'package:title_proj/widgets/home_widgets/SOSButton/SOSButton.dart';
import 'package:title_proj/widgets/home_widgets/emergencies/FireBrigadeEmergency.dart';
import 'package:title_proj/widgets/home_widgets/emergencies/AmbulanceEmergency.dart';
import 'package:title_proj/widgets/home_widgets/emergencies/ArmyEmergency.dart';
import 'package:title_proj/widgets/home_widgets/emergencies/PoliceEmergency.dart';

class Emergency extends StatelessWidget {
  final Future<void> Function() onSosPressed;

  const Emergency({super.key, required this.onSosPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 200,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              children: [
                const PoliceEmergency(),
                const AmbulanceEmergency(),
                const FireBrigadeEmergency(),
                const ArmyEmergency(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: SOSButton(onPressed: onSosPressed),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}