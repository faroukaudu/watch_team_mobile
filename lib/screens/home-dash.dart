import 'package:flutter/material.dart';
import 'package:torch_light/torch_light.dart';
import '../routes.dart';
import '../main.dart';


class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {

  bool isTorchOn = false;
  Future<void> _enableTorch(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);



    try {

      if(isTorchOn == false){
        isTorchOn =true;
        await TorchLight.enableTorch();

      }else{
        isTorchOn =false;
        await TorchLight.disableTorch();

      }

    } on Exception catch (_) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Could not enable torch'),
        ),
      );
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    TorchLight.disableTorch();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              // crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // WORKED HOURS
                Expanded(
                  child: Container(
                    margin: EdgeInsets.all(8),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[800], // Background color
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hours Worked', style: TextStyle( color: Colors.white ,fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              children: [
                                Text("Daily", style: TextStyle(color: Colors.white),),
                                Text("00:00",style: TextStyle(color: Colors.deepOrange,
                                    fontWeight: FontWeight.bold, fontSize: 20), )
                              ],
                            ),
                            Column(
                              children: [
                                Text("Weekly", style: TextStyle(color: Colors.white),),
                                Text("00:00",style: TextStyle(color: Colors.deepOrange,
                                    fontWeight: FontWeight.bold, fontSize: 20), )
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.all(8),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[800], // Background color
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Shift Status', style: TextStyle( color: Colors.white ,fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              children: [
                                Text("Pending", style: TextStyle(color: Colors.white),),
                                Text("0",style: TextStyle(color: Colors.deepOrange,
                                    fontWeight: FontWeight.bold, fontSize: 20), )
                              ],
                            ),
                            Column(
                              children: [
                                Text("Confirmed", style: TextStyle(color: Colors.white),),
                                Text("0",style: TextStyle(color: Colors.deepOrange,
                                    fontWeight: FontWeight.bold, fontSize: 20), )
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),


              ],
            ),
            // Charts

            Container(
              height: 260,

              width: double.maxFinite,
              margin: EdgeInsets.all(8),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[800], // Background color
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Card 1 Title', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  CircularProgressIndicator(
                  // value: 0.5,
                    color: Colors.deepOrange,
                    strokeWidth: 4,
                    backgroundColor: Colors.green,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  // ElevatedButton(onPressed:(){
                  //   _enableTorch(context);
                  //
                  //   setState(() {
                  //     //TODO: FIX THE TOUCH TO THE BUTTON
                  //   });
                  // }
                  //     , child: Text("Turn Torch"))
                ],
              ),
            ),

            // Bottom
            Expanded(
              child: Container(
                width: double.maxFinite,
                margin: EdgeInsets.fromLTRB(8, 8, 8, 0),
                padding: EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: Color(0xFF222324), // Background color
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12), bottom: Radius.circular(0)),
                ),
                child: SingleChildScrollView(
                  child: Table(
                      border: TableBorder(
                        horizontalInside: BorderSide(color: Colors.grey.shade800),
                        verticalInside: BorderSide(color: Colors.grey.shade800),
                      ),
                      children: [
                        TableRow(
                            children: [
                              IconsText(iconType: Icons.event, itemName: "Events",),
                              IconsText(iconType: Icons.send_time_extension, itemName: "Dispatch",),
                              IconsText(iconType: Icons.local_taxi, itemName: "Vehicle Patrol",),
                            ]
                        ),
                        TableRow(
                            children: [
                              IconsText(iconType: Icons.policy, itemName: "Docs & Policies"),
                              IconsText(iconType: Icons.event_note, itemName: "Schedule",),
                              IconsText(iconType: Icons.av_timer, itemName: "Open Shifts",),
                            ]
                        ),
                        TableRow(
                            children: [
                              InkWell(

                                onTap: (){
                                  print(isTorchOn);
                                  setState(() {
                                    _enableTorch(context);

                                  });
                                },
                                child: Container(
                                  margin: EdgeInsets.symmetric(vertical: 15, horizontal: 5),
                                  child: Column(
                                    children: [
                                      Container(
                                          margin: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                                          height:35,
                                          width: 35,
                                          decoration: BoxDecoration(color: Color(0xFF123458), borderRadius: BorderRadius.circular(10)),
                                          child: Icon(isTorchOn?Icons.flashlight_on:Icons.flashlight_off, color: isTorchOn?Colors.deepOrange:Colors.white, size: 20,)),
                                      Text("Flash Light", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white, )),
                                    ],
                                  ),
                                ),
                              ),
                              IconsText(iconType: Icons.nest_cam_wired_stand, itemName: "Watch Mode",),
                              IconsText(iconType: Icons.event_available, itemName: "Availability",),
                            ]
                        ),
                        TableRow(
                            children: [
                              IconsText(iconType: Icons.alarm, itemName: "Remainders",),
                              IconsText(iconType: Icons.edit_document, itemName: "Notes",),
                              Text(""),
                              // IconsText(iconType: Icons.attractions_outlined, itemName: "Availability",),
                            ]
                        ),

                      ]
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

    );
  }
}


class IconsText extends StatelessWidget {


  final IconData iconType;
  final String itemName;
  // final Route link;


  // final String formKey;
  const IconsText({Key? key,  required this.iconType, required this.itemName, }): super(key: key);



  @override
  Widget build(BuildContext context) {
    return  TableCell(
      child: InkWell(
        onTap: (){
          print(itemName);
        },
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 15, horizontal: 5),
          child: Column(
            children: [
              Container(
                  margin: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                  height:35,
                  width: 35,
                  decoration: BoxDecoration(color: Color(0xFF123458), borderRadius: BorderRadius.circular(10)),
                  child: Icon(iconType, color: Colors.white, size: 20,)),
              Text(itemName, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white, )),
            ],
          ),
        ),
      ),
    );
  }
}


Future<bool> _isTorchAvailable(BuildContext context) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);

  try {
    return await TorchLight.isTorchAvailable();
  } on Exception catch (_) {
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('Could not check if the device has an available torch'),
      ),
    );
    rethrow;
  }
}



Future<void> _disableTorch(BuildContext context) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);

  try {
    await TorchLight.disableTorch();
  } on Exception catch (_) {
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('Could not disable torch'),
      ),
    );
  }
}





