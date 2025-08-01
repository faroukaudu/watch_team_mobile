

import 'package:flutter/material.dart';

class TimeClock extends StatefulWidget {
  const TimeClock({super.key});

  @override
  State<TimeClock> createState() => _TimeClockState();
}

class _TimeClockState extends State<TimeClock> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Container(

                  height: 100,
                  width: double.infinity,

                  decoration: BoxDecoration(
                      color: Color(0xFF222324), borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Work Hours", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),),
                        Text("00:00:00", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.deepOrange),),
                      ],
                    ),
                  ),

                ),
              ),
              SizedBox(
                width: 10,
              ),
              Expanded(
                child: Container(

                  height: 100,
                  width: double.infinity,

                  decoration: BoxDecoration(
                    color: Color(0xFF222324), borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Break Hours", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),),
                        Text("00:00:00", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.white),),
                      ],
                    ),
                  ),

                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Color(0xFF20a0e9), borderRadius: BorderRadius.circular(10),
            ),

            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(


                        children: [
                          Text("Current Time",style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),),
                          Text("00:00:00",style: TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold),)
                        ],
                      ),
                      Column(


                        children: [
                          Text("Current Time",style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),),
                          Text("00:00:00",style: TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold),)
                        ],
                      ),

                    ],
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  Container(
                    height: 10,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white38,
                        borderRadius: BorderRadius.circular(15)
                    ),
                  )

                ],

              ),
            ),
          ),
          SizedBox(height: 15),
          GestureDetector(
            onLongPress: (){
              print("Long Pressing Clock in");
            },

            // onTap: (){
            //   print("clocking in");
            // },
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green[600],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer_outlined),
                  Text("Clock In", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),)
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
