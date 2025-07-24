import 'package:flutter/material.dart';
import '../routes.dart';
import '../main.dart';

class DashBoardScreen extends StatefulWidget {
  const DashBoardScreen({super.key});

  @override
  State<DashBoardScreen> createState() => _DashBoardScreenState();
}

class _DashBoardScreenState extends State<DashBoardScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.blueGrey,
          title: Text("WatchTeam", style: TextStyle(fontWeight: FontWeight.w700),),
          centerTitle: true,
          actions: [
            IconButton(
                icon:Icon(Icons.search),
                onPressed: (){
                  print("Ap Bar");
      },)
          ],
        ),
        drawer: Drawer(
          backgroundColor: Colors.black54,
          child: ListView(

            padding: EdgeInsets.zero,

            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: Colors.blueGrey),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(Icons.account_circle, size: 100, color: Colors.white),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Farouk Audu ", style:
                          TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 25),),
                          Text("fagzy99@gmail.com", style: TextStyle(fontSize: 12),),
                          Text("+2348160278321", style: TextStyle(fontSize: 12),),
                        ],
                      ),
                    ),
                  ],
                )
              ),
              Container(
                margin: EdgeInsets.fromLTRB(20, 15, 0, 10),
                  child: Text("MANAGE")),
              ListTile(
                leading: Icon(Icons.home, size: 25, color: Colors.blueGrey,),
                title: Text("Home", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),),
                visualDensity: VisualDensity(vertical: -3), // tighten vertical space
                onTap: (){
                  print("Home");
                },
              ),
              ListTile(
                leading: Icon(Icons.house, size: 25, color: Colors.blueGrey,),
                title: Text("Select Company", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),),
                visualDensity: VisualDensity(vertical: -3),
              ),
              ListTile(
                leading: Icon(Icons.settings, size: 25, color: Colors.blueGrey,),
                title: Text("Settings", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),),
                visualDensity: VisualDensity(vertical: -3),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                  child: Divider(thickness: 0.5, height: 10, color: Colors.white24,)),
              ListTile(
                leading: Icon(Icons.house, size: 25, color: Colors.blueGrey,),
                title: Text("Select Company", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),),
                visualDensity: VisualDensity(vertical: -4),
              ),
              ListTile(
                leading: Icon(Icons.settings, size: 25, color: Colors.blueGrey,),
                title: Text("Settings", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),),
                visualDensity: VisualDensity(vertical: -4),
              ),

            ],
          ),
        ),
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
                      Text('Some description here.'),
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
                               IconsText(iconType: Icons.flashlight_on, itemName: "Flash Light",),
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
        bottomNavigationBar: BottomNavigationBar(
            // currentIndex: _selectIndex,
          backgroundColor: Colors.grey[800],
            selectedItemColor: Colors.blue,
            unselectedItemColor:Colors.white ,
          type: BottomNavigationBarType.fixed, // REQUIRED for 4+ items

            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label:"Home"),
              BottomNavigationBarItem(icon: Icon(Icons.apartment), label:"POST SITE"),
              BottomNavigationBarItem(icon: Icon(Icons.browse_gallery), label:"TIME CLOCK"),
              BottomNavigationBarItem(icon: Icon(Icons.mark_unread_chat_alt), label:"MESSENGER"),


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



