import 'package:flutter/material.dart';
// import '';

class PostSite extends StatefulWidget {
  const PostSite({super.key});

  @override
  State<PostSite> createState() => _PostSiteState();
}

class _PostSiteState extends State<PostSite> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // optional background
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(15),
          child: Column(
            children: [
              Container(
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
                            "Barnawa, KD",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "B7 Kurkuja Road, Barnawa Kaduna State.",
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
                          Navigator.of(context).pushNamed('/postsite_details');
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
