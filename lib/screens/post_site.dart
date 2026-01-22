import 'package:flutter/material.dart';
import 'package:watch_team/session_data.dart';
// import '';

class PostSite extends StatefulWidget {
  const PostSite({super.key});


  @override
  State<PostSite> createState() => _PostSiteState();
}

class _PostSiteState extends State<PostSite> {

  Map<String, dynamic>? comProfile;
  Map<String, dynamic>? user;
  String ? postSiteid;

  @override
  void initState() {
    // TODO: implement initState
    comProfile = SessionData.companyInfo;
    user = SessionData.userProfile;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // optional background
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(15),
          child: Column(
            children: [
              // Text("${user!['guardPostSite'][0]["postSiteID"]}"),
              Text("Select your Post Site!"),
              // Barnawa Default Post Site.....<><><>
              // Container(
              //   padding: EdgeInsets.all(10),
              //   decoration: BoxDecoration(
              //     color: Color(0xFF222324),
              //     border: Border.all(color: Colors.white38),
              //     borderRadius: BorderRadius.circular(10),
              //   ),
              //   child: Row(
              //     crossAxisAlignment: CrossAxisAlignment.center,
              //     children: [
              //       // Left Side: Address
              //       Expanded(
              //         flex: 2,
              //         child: Column(
              //           crossAxisAlignment: CrossAxisAlignment.start,
              //           // mainAxisAlignment: MainAxisAlignment.center,
              //           children: [
              //             Text(
              //               "Barnawa, KD",
              //               style: TextStyle(
              //                 fontWeight: FontWeight.bold,
              //                 color: Colors.white,
              //               ),
              //             ),
              //             SizedBox(height: 4),
              //             Text(
              //               "B7 Kurkuja Road, Barnawa Kaduna State.",
              //               style: TextStyle(
              //                 fontWeight: FontWeight.w300,
              //                 color: Colors.white,
              //               ),
              //             ),
              //           ],
              //         ),
              //       ),
              //       Container(
              //         height: 40,
              //         width: 1,
              //         color: Colors.grey[700],
              //         // margin: EdgeInsets.symmetric(horizontal: 8),
              //       ),
              //       // Middle: Location Icon
              //       Expanded(
              //         flex: 1,
              //         child: Column(
              //           children: [
              //             Icon(Icons.my_location, color: Colors.grey),
              //             Text("Navigate", style: TextStyle(color: Colors.white)),
              //           ],
              //         ),
              //       ),
              //       Container(
              //         height: 40,
              //         width: 1,
              //         color: Colors.grey[700],
              //         // margin: EdgeInsets.symmetric(horizontal: 8),
              //       ),
              //
              //       // Right: Arrow Icon
              //       Expanded(
              //         flex: 1,
              //         child: InkWell(
              //           onTap: (){
              //             Navigator.of(context).pushNamed('/postsite_details');
              //             // navigatorKey.
              //           },
              //           child: Column(
              //             children: [
              //               Icon(Icons.arrow_circle_right, color: Colors.green),
              //               Text("Continue", style: TextStyle(color: Colors.green)),
              //             ],
              //           ),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              // Text("show me"),

        // Text("${comProfile!['postSite']}"),
              // Text("${user!['guardPostSite'][0]["id"]}"),
              // I WILL FIND THE POST SITE AND THE GUARD POST SITE
              // Text("${user!['guardPostSite']['id']}"),
              Column(
                children: (comProfile!['postSite'] as List)
                    .where((item) => (user!['guardPostSite'] as List)
                    .any((g) => g['postSiteID'] == item['_id']
                ))
                    .map<Widget>((item)


                {

                  final postSitemap = item as Map<String, dynamic>;
                  final postSITEid = item['_id'].toString();

                  return Container(
                  margin: EdgeInsets.symmetric(vertical: 10),
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Color(0xFF222324),
                    border: Border.all(color: Colors.white38),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left Side: Address
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          // mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item['clientName'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              item['address'],
                              style: TextStyle(
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.grey[700],
                        // margin: EdgeInsets.symmetric(horizontal: 8),
                      ),
                      // Middle: Location Icon
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            Icon(Icons.my_location, color: Colors.grey),
                            Text("Navigate", style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.grey[700],
                        // margin: EdgeInsets.symmetric(horizontal: 8),
                      ),

                      // Right: Arrow Icon
                      Expanded(
                        flex: 1,
                        child: InkWell(
                          onTap: (){
                            SessionData.postSiteID = postSITEid;
                            Navigator.of(context).pushNamed('/postsite_details', arguments:  postSitemap);// arguments:  item,);
                            // navigatorKey.
                          },
                          child: Column(
                            children: [
                              Icon(Icons.arrow_circle_right, color: Colors.green),
                              Text("Continue", style: TextStyle(color: Colors.green)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );}
                )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void filter (){


}
