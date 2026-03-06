import 'package:flutter/material.dart';
import 'package:watch_team/screens/report/all_report.dart';
import 'post_site.dart';
import 'home-dash.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:watch_team/session_data.dart';
import '../check_in.dart';
import '../server_push.dart';
import 'package:watch_team/services/live_location_manager.dart';
import '../routes.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

// MAP SCREEN
class PostsiteDetails extends StatefulWidget {
  const PostsiteDetails({super.key});

  @override
  State<PostsiteDetails> createState() => _PostsiteDetailsState();

}
late GoogleMapController mapController;


// final LatLng _center = const LatLng(37.76670350847729, -122.4103439222306); // Example: San Francisco

// void _onMapCreated(GoogleMapController controller) {
//   mapController = controller;
// }

class _PostsiteDetailsState extends State<PostsiteDetails> {
  late GoogleMapController _mapController;
  late Map<String, dynamic> postSitemap;
  bool _initialized = false;

  Map<String, dynamic>? comProfile;
  Map<String, dynamic>? user;
  String ? mypostId;

  // String post
   // bool check;

  Future<void> _simulateTask({String? notify_text,String? load_text} ) async {
    // 1️⃣ Show the dialog and store its context
    BuildContext? dialogContext;

    // 1️⃣ Show the loading popup
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        dialogContext = context; // capture the dialog's context
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children:  [
                CircularProgressIndicator(),
                SizedBox(width: 24),
                Text(load_text ?? "Please Wait..."),
              ],
            ),
          ),
        );
      },
    );





 void checkingIn () async{
   DateTime now = DateTime.now();
   final serverResponse = await CheckInOut.checkIntoServer(checkInTime: now.toString(),

       userData: SessionData.userProfile,
       // userData: postSitemap['clientName'],
       companyData: SessionData.companyInfo);
   // ✅ start live tracking now
   await LiveLocationManager.startLive();
   // 2️⃣ Simulate your long-running task (e.g., network call)
   await Future.delayed(const Duration(seconds: 3));
   // print("This is the Response Below");

   final data =(serverResponse);
   print(data["reportId"]);
   SessionData.checkID = data['reportId'];
   print(serverResponse.toString());


   // 3️⃣ Close only the dialog, not the page
   if (dialogContext != null && mounted) {
     Navigator.of(dialogContext!).pop(); // safe to pop the dialog
   }

   // 4️⃣ Show result (optional)
   ScaffoldMessenger.of(context).showSnackBar(
     SnackBar(content: Text(notify_text ?? "Successful")),
   );
 }
    void checkingout () async{
      DateTime now = DateTime.now();
      final serverResponse = await CheckOut.checkIntoServer(checkId: SessionData.checkID!,
          userData: SessionData.userProfile,
          // userData: postSitemap['clientName'],
          checkoutTime: now.toString());
      // ✅ stop live tracking now
      await LiveLocationManager.stopLive();
      // 2️⃣ Simulate your long-running task (e.g., network call)
      await Future.delayed(const Duration(seconds: 2));
      // print("This is the Response Below");

      final data =(serverResponse);
      // print(data["reportId"]);
      SessionData.checkID = data['reportId'];
      print(serverResponse.toString());
      SessionData.checkID = null;


      // 3️⃣ Close only the dialog, not the page
      if (dialogContext != null && mounted) {
        Navigator.of(dialogContext!).pop(); // safe to pop the dialog
      }

      // 4️⃣ Show result (optional)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(notify_text ?? "Successful")),
      );
    }

    if(checkedIn == false){
      setState(() {
        checkedIn = true;
        SessionData.clockedIn = true;
      });
      checkingIn();

    }else{
      setState(() {
        checkedIn = false;
        SessionData.clockedIn = false;
      });
      checkingout();

    }

    }



  @override
  void initState() {
    // TODO: implement initState
    comProfile = SessionData.companyInfo;
    user = SessionData.userProfile;
    mypostId = SessionData.postSiteID;

  }
  // RUNNING TO GET MAP BEFORE BUILD

  late LatLng targetLocation ;
  late String title ;
  late String snip;
  // LatLng? targetLocation; // starts as null
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return; // prevents running multiple times

    // ✅ Safely get arguments BEFORE build runs the first time
    postSitemap = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    // you can now extract or initialize anything before build:
    final lat = double.parse( postSitemap['lat']);
    final long = double.parse( postSitemap['long']);
    // initialize something, for example:
    // targetLocation = LatLng(lat, lng);
    targetLocation = LatLng(lat, long); // now assigned
    title = postSitemap['clientName'];
    snip = postSitemap['siteName'];

    _initialized = true;
  }
  bool checkedIn = false;
  void _checkIN(){
    // if(checkedIn == false){
    //   setState(() {
    //     checkedIn = !checkedIn;
    //     SessionData.clockedIn = true;
    //   });
    //
    // }else{
    //   setState(() {
    //     checkedIn = !checkedIn;
    //     SessionData.clockedIn = false;
    //   });
    //
    // }



  }

  // 11.993775748647009, 8.551624924497037
  // The specific Lat/Lng where you want to drop the marker

  // final LatLng targetLocation = LatLng(37.76678419626347, -122.41042047508151); // San Franscis co

  final Set<Marker> _markers = {};
  bool _clicked = false;

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId("targetLocation"),
          position: targetLocation,
          infoWindow: InfoWindow(
            title: title,
            snippet: snip,
          ),
        ),
      );
    });
  }
  @override
  Widget build(BuildContext context) {
    // Get the argument passed from previous screen
    // final String siteId = ModalRoute.of(context)!.settings.arguments as String;

    final args = ModalRoute.of(context)!.settings.arguments as Map;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child:GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: targetLocation,
                tilt: 15.0,
                zoom: 17.0,
              ),
              myLocationEnabled: true,
              zoomControlsEnabled: true,
              mapType: MapType.satellite,
              markers: _markers,
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 20, horizontal: 20),

              decoration: BoxDecoration(
                color: checkedIn ? Colors.red[600] : Colors.green[600],
                border: Border.all(color: Colors.white24, width: 3,),
                borderRadius: BorderRadius.circular(10),
              ),
              child: GestureDetector(

                behavior: HitTestBehavior.opaque, // makes the whole area tappable
                onTap: () async  {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );


                  print("tapping!");
                  final double onlylat = targetLocation.latitude;
                  final double onlylong = targetLocation.longitude;
                  // print("MY Lat & Long is, ${onlylong}");
                  try {
                   if(checkedIn == false){
                     final pos = await determinePosition();
                     final posFind = await isWithinSite(siteLat: onlylat, siteLng: onlylong);
                     if(posFind == true){
                       // _checkIN();
                       DateTime now = DateTime.now();
                       print(now);
                       // final serverResponse = await CheckInOut.checkIntoServer(checkInTime: now.toString(),
                       //     userData: SessionData.userProfile,companyData: SessionData.companyInfo);
                       Navigator.of(context, rootNavigator: true).pop();
                       await _simulateTask(notify_text:
                       checkedIn ? "Guard Successfully Checked Out!." : "Guard Successfully Checked In." ,
                           load_text: checkedIn ? "Checking Out Guard..." : "Finding Co-ordinates..." );
                     }

                     ScaffoldMessenger.of(context).showSnackBar(
                       // SnackBar(content: Text('this is the Lat: ${pos.latitude}, Lng: ${pos.longitude}')),
                       SnackBar(content: Text('${posFind}')),

                     );
                     print(pos);
                   }else{
                     Navigator.of(context, rootNavigator: true).pop();
                     await _simulateTask(notify_text:
                     checkedIn ? "Guard Successfully Checked Out!." : "Guard Successfully Checked In." ,
                         load_text: checkedIn ? "Checking Out Guard..." : "Finding Co-ordinates..." );

                   }


                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Location error: $e')),
                    );
                    Navigator.of(context, rootNavigator: true).pop();
                  }
                  // // _determinePosition();
                  // determinePosition();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    checkedIn ? Icon(Icons.logout) : Icon(Icons.login),
                    SizedBox(width: 10,),
                    Text(checkedIn ? "Check Out": "Check In" , style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    // Text("${args}")
                  ],

                ),
              )

            ),
          ),
          // Expanded(
          //   flex: 1,
          //   child: Container(
          //     margin: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          //
          //     decoration: BoxDecoration(
          //       color: Colors.green[600],
          //       border: Border.all(color: Colors.white24, width: 3,),
          //       borderRadius: BorderRadius.circular(10),
          //     ),
          //     child: Row(
          //       mainAxisAlignment: MainAxisAlignment.center,
          //       children: [
          //         Icon(Icons.login),
          //         SizedBox(width: 10,),
          //         Text("${args['lat']}", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          //         // Text("${args}")
          //       //   GETTING DATA
          //       ],
          //
          //     ),
          //
          //   ),
          // ),

          Expanded(
            flex: 3,
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
                            IconsText(iconType: Icons.crisis_alert, itemName: "Panic Mode",),
                            IconsText(iconType: Icons.person_pin_circle_outlined, itemName: "Site Tours",),
                            IconsText(iconType: Icons.qr_code_scanner, itemName: "Scan Tag",
                            onTap: (){
                              Navigator.of(context, rootNavigator: true).pushNamed('/scantag_screen');
                            },
                            ),
                          ]
                      ),
                      TableRow(
                          // Navigator.pushNamed(context, AppRoutes.all_reports);
                          children: [
                            IconsText(iconType: Icons.add_chart, itemName: "Post Orders",
                                onTap: (){
                                Navigator.of(context, rootNavigator: true).pushNamed('/post_order_screen');
                                }
                            ),
                            IconsText(iconType: Icons.description_outlined, itemName: "Reports",
                              onTap: (){ print('working');
                              Navigator.of(context, rootNavigator: true).pushNamed('/all_report');

                              },),
                            IconsText(iconType: Icons.av_timer, itemName: "Task",),
                          ]
                      ),
                      TableRow(
                          children: [
                            InkWell(

                              // onTap: (){
                              //   print(isTorchOn);
                              //   setState(() {
                              //     _enableTorch(context);
                              //
                              //   });
                              // },
                              child: Container(
                                margin: EdgeInsets.symmetric(vertical: 15, horizontal: 5),
                                child: Column(
                                  children: [
                                    Container(
                                        margin: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                                        height:35,
                                        width: 35,
                                        decoration: BoxDecoration(color: Color(0xFF123458), borderRadius: BorderRadius.circular(10)),
                                        child: Icon(Icons.move_down, size: 20,)),
                                    Text("PassDown", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white, )),
                                  ],
                                ),
                              ),
                            ),
                            IconsText(iconType: Icons.groups_2_outlined, itemName: "Visitors",),
                            IconsText(iconType: Icons.checklist_outlined, itemName: "Checklist",),
                          ]
                      ),
                      TableRow(
                          children: [
                            IconsText(iconType: Icons.local_parking, itemName: "Parking Manager",),
                            IconsText(iconType: Icons.supervisor_account, itemName: "Security Team",),
                            IconsText(iconType: Icons.contact_phone, itemName: "Contact",),
                            // Textgtgt(""),
                            // IconsText(iconType: Icons.attractions_outlined, itemName: "Availability",),
                          ]
                      ),
                      TableRow(
                          children: [
                            IconsText(iconType: Icons.content_paste_search, itemName: "DAR",),
                            // Text(
                            //   mypostId ?? "No post site selected",
                            //   style: const TextStyle(color: Colors.white),
                            // ),
                            Text(""),
                            Text(""),
                            // IconsText(iconType: Icons.edit_document, itemName: "Security Team",),
                            // IconsText(iconType: Icons.edit_document, itemName: "Contact",),
                            // Text(""),
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
    );
  }
}


