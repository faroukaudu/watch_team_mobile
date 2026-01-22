import 'package:flutter/material.dart';
import 'package:torch_light/torch_light.dart';
import 'package:watch_team/session_data.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
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

  DateTime getMonday(DateTime date) {
    // date.weekday: Mon=1, Tue=2, ... Sun=7
    return date.subtract(Duration(days: date.weekday - 1));
  }

  Map<String, dynamic>? profile;
  // Pop

  // Future<void> _handleBackPressed(BuildContext context) async {
  //   final shouldLogout = await _confirmLogoutDialog(context);
  //
  //   if (shouldLogout == true) {
  //     // logout cleanup
  //     SessionData.userProfile = null; // or SessionData.clear() if you have it
  //
  //     try { await TorchLight.disableTorch(); } catch (_) {}
  //
  //     // go to home.dart and clear navigation stack
  //     if (!context.mounted) return;
  //     Navigator.pop(context);
  //
  //   }
  //   // if No => do nothing, remain on page
  // }
  // POP UP FOR LOGOUT
  Future<bool?> showLogoutDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            decoration: BoxDecoration(
              color: const Color(0xFF2A3558), // dark bluish
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon (doc + ?)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 64,
                      width: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.logout_rounded, // logout icon
                        color: Colors.white70,
                        size: 30,
                      ),
                    ),
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        height: 26,
                        width: 26,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Center(
                          child: Text(
                            "!",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                const Text(
                  "Confirm!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Do you want to logout?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE7EDF6), // light button
                            foregroundColor: const Color(0xFF1B1F2A),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            "No",
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935), // red button
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            "Yes, Logout",
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }



  @override
  void initState() {
    // TODO: implement initState
    TorchLight.disableTorch();

    profile = SessionData.userProfile;

  }



  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final ok = await showLogoutDialog(context);
        if (ok == true) {
          SessionData.userProfile = null;
          try { await TorchLight.disableTorch(); } catch (_) {}

          if (!context.mounted) return;
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.login,
                (route) => false,
          );
        }
      },
      child: Scaffold(
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
      
               Padding(
                 padding: const EdgeInsets.all(5.0),
                 child: AspectRatio(
                    aspectRatio: 1.1,
                    child: Card(
                      color: Colors.grey[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(30.0),
                        child: BarChart(
                          BarChartData(
                            groupsSpace: 5,
                            barTouchData: BarTouchData(enabled: true),
                            gridData: FlGridData(show: true),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 32,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                                    );
                                  },
                                ),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index < 0 || index > 6) {
                                      return const SizedBox.shrink();
                                    }
      
                                    // Today + index days
                                    final DateTime now = DateTime.now();
                                    final monday = getMonday(now);
                                    final DateTime date = monday.add(Duration(days: index));
      
                                    final label = DateFormat('MMM d').format(date); // Example: "Nov 18"
                                    // e.g. "Nov 17"
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 4.0, ),
                                      child: RotatedBox(
                                        quarterTurns: 0,
                                        child: Text(
                                          label,
                                          style: const TextStyle(color: Colors.white70, fontSize: 10),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            barGroups: _buildBarGroups(),
                          ),
                        ),
                      ),
                    ),
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
      
      ),
    );
  }
}

List<BarChartGroupData> _buildBarGroups() {
  // Example weekly data
  final values = [3.0, 4.5, 2.0, 5.0, 6.5, 4.0, 3.5];

  return List.generate(values.length, (index) {
    return BarChartGroupData(

      x: index,
      barsSpace: 10,
      barRods: [
        BarChartRodData(
          toY: values[index],
          width: 18,
          borderRadius: BorderRadius.circular(2),
          color: Colors.deepOrangeAccent,
        ),
      ],
    );
  });
}



class IconsText extends StatelessWidget {


  final IconData iconType;
  final String itemName;
  final VoidCallback? onTap;
  // final Route link;


  // final String formKey;
  const IconsText({Key? key,  required this.iconType, required this.itemName, this.onTap}): super(key: key);



  @override
  Widget build(BuildContext context) {
    return  TableCell(
      child: InkWell(
        onTap: onTap,
        // onTap: (){
        //   print(itemName);
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





