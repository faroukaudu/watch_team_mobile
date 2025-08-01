import 'package:flutter/material.dart';
import 'post_site.dart';
import 'home-dash.dart';

class PostsiteDetails extends StatefulWidget {
  const PostsiteDetails({super.key});

  @override
  State<PostsiteDetails> createState() => _PostsiteDetailsState();
}

class _PostsiteDetailsState extends State<PostsiteDetails> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.greenAccent,
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 20, horizontal: 20),

              decoration: BoxDecoration(
                color: Colors.green[600],
                border: Border.all(color: Colors.white24, width: 3,),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login),
                  SizedBox(width: 10,),
                  Text("CHECK IN", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold))
                ],
              ),

            ),
          ),
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
                            IconsText(iconType: Icons.qr_code_scanner, itemName: "Scan Tag",),
                          ]
                      ),
                      TableRow(
                          children: [
                            IconsText(iconType: Icons.add_chart, itemName: "Post Orders"),
                            IconsText(iconType: Icons.description_outlined, itemName: "Reports",),
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
                            // Text(""),
                            // IconsText(iconType: Icons.attractions_outlined, itemName: "Availability",),
                          ]
                      ),
                      TableRow(
                          children: [
                            IconsText(iconType: Icons.content_paste_search, itemName: "DAR",),
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
