import 'package:flutter/material.dart';
import 'package:torch_light/torch_light.dart';
import '../postsite_navigator.dart';
import '../routes.dart';
import '../main.dart';
import 'home-dash.dart';
import 'post_site.dart';
import 'time_clock.dart';

class DashBoardScreen extends StatefulWidget {
  const DashBoardScreen({super.key});


  @override

  State<DashBoardScreen> createState() => _DashBoardScreenState();
}


class _DashBoardScreenState extends State<DashBoardScreen> {

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


  // Bottom NAV Bar Selection
  int _selectedindex = 0;

  // ✅ List of page widgets
  final List<Widget> _pages = [
    HomeDashboard(),
    PostSiteNavigator(),
    TimeClock(),
    // PostsiteDetails()
    // MessengerPage(),
  ];

  // ✅ List of app bar titles
  final List<String> _titles = [
    'Watch Team',
    'Post Site',
    'Time Clock',
    'Messenger',
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Color(0xFF123458),
        title: Text(_titles[_selectedindex], style: TextStyle(fontWeight: FontWeight.w700),),
        centerTitle: true,
        actions: [
          IconButton(
              icon:Icon(Icons.search),
              onPressed: (){
                print("Ap Bar");
    },)
        ],
      ),
      drawer: SafeArea(
        child: Drawer(
          backgroundColor: Colors.black,
          child: ListView(

            padding: EdgeInsets.zero,

            children: [
              DrawerHeader(
                // padding: EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: Colors.blueGrey,
                image: DecorationImage(image: AssetImage('images/drawer-head.jpg'),
                fit: BoxFit.cover)
                ),
                child: Row(
                  // mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.account_circle, size: 60, color: Colors.white),
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Farouk Audu ", style:
                            TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),),
                            Text("fagzy99@gmail.com", style: TextStyle(fontSize: 12),),
                            Text("+2348160278321", style: TextStyle(fontSize: 12),),
                          ],
                        ),
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
                title: Text("Chat Support", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),),
                visualDensity: VisualDensity(vertical: -4),
              ),
              ListTile(
                leading: Icon(Icons.settings, size: 25, color: Colors.blueGrey,),
                title: Text("Email Support", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),),
                visualDensity: VisualDensity(vertical: -4),
              ),
              ListTile(
                leading: Icon(Icons.settings, size: 25, color: Colors.blueGrey,),
                title: Text("Support Center", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),),
                visualDensity: VisualDensity(vertical: -4),
              ),
              ListTile(
                leading: Icon(Icons.settings, size: 25, color: Colors.blueGrey,),
                title: Text("Feedback", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),),
                visualDensity: VisualDensity(vertical: -4),
              ),
              ListTile(
                leading: Icon(Icons.settings, size: 25, color: Colors.blueGrey,),
                title: Text("Share App", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),),
                visualDensity: VisualDensity(vertical: -4),
              ),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  child: Divider(thickness: 0.5, height: 10, color: Colors.white24,)),
              ListTile(
                leading: Icon(Icons.house, size: 25, color: Colors.blueGrey,),
                title: Text("About Watch Team", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),),
                visualDensity: VisualDensity(vertical: -4),
              ),
              ListTile(
                leading: Icon(Icons.settings, size: 25, color: Colors.blueGrey,),
                title: Text("App Version", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),),
                visualDensity: VisualDensity(vertical: -4),
              ),

            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _selectedindex,
        children: _pages,
      ),


      bottomNavigationBar: BottomNavigationBar(
          currentIndex:_selectedindex,
        backgroundColor: Color(0xFF123458),
          selectedItemColor: Colors.orange[600],
          unselectedItemColor:Colors.white ,
        iconSize: 22,
        unselectedFontSize: 10,
        elevation: 150,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
        selectedFontSize: 13,
        type: BottomNavigationBarType.fixed,
        onTap: (index){
            setState(() {
              _selectedindex = index;
            });
        },// REQUIRED for 4+ items

          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label:"Home"),
            BottomNavigationBarItem(icon: Icon(Icons.apartment), label:"POST SITE"),
            BottomNavigationBarItem(icon: Icon(Icons.browse_gallery), label:"TIME CLOCK"),
            BottomNavigationBarItem(icon: Icon(Icons.mark_unread_chat_alt), label:"MESSENGER"),


          ],

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




