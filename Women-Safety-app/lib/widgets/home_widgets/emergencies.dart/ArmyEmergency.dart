import 'package:flutter/material.dart';

class ArmyEmergency extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left:10.0, bottom:5),
      child: Card(
        elevation :5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
             ),
        child: Container(
          height: 180,
          width: MediaQuery.of(context).size.width*0.7,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomLeft,
              colors: [
                Color.fromRGBO(216, 68, 173, 100),
                Color.fromRGBO(248, 7, 89, 100),
              ],
              )),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.white.withOpacity(0.5),
                    child: Image.asset('assets/police-image.png'),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Police Emergency',
                          style: TextStyle(
                            color:Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: MediaQuery.of(context).size.width*0.06,
                            ),
                        ),
                        Text(
                          'Call the Police',
                          style: TextStyle(
                            color:Colors.white,
                            fontSize: MediaQuery.of(context).size.width*0.045,
                            ),
                        ),
                        Container(
                          height: 30,
                          width: 80,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text('100',
                            style: TextStyle(
                              color:Colors.red[300],
                              fontWeight: FontWeight.bold,
                              fontSize: MediaQuery.of(context).size.width*0.055,
                              ),
                            
                            ),
                          ),
                          
                        )
                      ],
                    ),
                  )
                ],
                ),
              ),
        ),
      ),
    );
  }
}