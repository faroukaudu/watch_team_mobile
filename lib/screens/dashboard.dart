import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:watch_team/global.dart';
import 'package:watch_team/services/api_client.dart';
import 'package:watch_team/services/notification_helper.dart';
import 'package:torch_light/torch_light.dart';
import '../postsite_navigator.dart';
import 'package:watch_team/session_data.dart';
import 'chat_caller.dart';
import '../routes.dart';
import '../main.dart';
import 'home-dash.dart';
import 'post_site.dart';
import 'time_clock.dart';
import 'package:watch_team/widgets/security_drawer.dart';
import 'chat.dart';


var externalProfile = SessionData.userProfile;
var company = SessionData.companyInfo;

class DashBoardScreen extends StatefulWidget {
  static int initialIndex = 0;


  const DashBoardScreen({super.key});

  @override
  State<DashBoardScreen> createState() => _DashBoardScreenState();
}

class _DashBoardScreenState extends State<DashBoardScreen> {
  final ApiClient notificationApi = ApiClient(baseUrl: baseUrl);
  int notificationCount = 0;
  List<Map<String, dynamic>> notificationList = [];
  bool isTorchOn = false;
  Timer? _notificationTimer;


  Future<void> _enableTorch(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      if (isTorchOn == false) {
        isTorchOn = true;
        await TorchLight.enableTorch();
      } else {
        isTorchOn = false;
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

  Map<String, dynamic>? profile;

  // ✅ Use only one selected index variable
  late int _selectedindex;

  @override
  void initState() {
    TorchLight.disableTorch();
    profile = SessionData.userProfile;
    super.initState();
    loadNotifications();
    _notificationTimer = Timer.periodic(const Duration(seconds: 15), (_) => loadNotifications());

    // ✅ This now controls the bottom navigation selected tab
    _selectedindex = DashBoardScreen.initialIndex;
  }

  final List<Widget> _pages = [
    HomeDashboard(),
    PostSiteNavigator(),
    TimeClock(),
    ChatUserListScreen()
  ];

  final List<String> _titles = [
    "${company!['companyName']}",
    'Post Site',
    'Time Clock',
    'Messenger',
  ];



  Future<void> loadNotifications() async {
    try {
      final companyId = (SessionData.userProfile?['assignedCompanyID'] ?? '').toString();
      final viewerId = (SessionData.userProfile?['_id'] ?? '').toString();
      final data = await notificationApi.listNotifications(companyId: companyId, viewerId: viewerId);
      final items = data['notifications'] is List ? data['notifications'] as List : [];
      final oldCount = notificationCount;
      setState(() {
        notificationList = items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        notificationCount = int.tryParse((data['unread'] ?? 0).toString()) ?? 0;
      });
      if (notificationCount > oldCount) {
        NotificationHelper.show(
          title: 'New Activity',
          body: 'You have a new Watch Team notification',
        );
      }
    } catch (_) {}
  }

  Future<void> openNotifications() async {
    final companyId = (SessionData.userProfile?['assignedCompanyID'] ?? '').toString();
    final viewerId = (SessionData.userProfile?['_id'] ?? '').toString();
    await loadNotifications();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF123458),
      builder: (_) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          shrinkWrap: true,
          children: [
            const Text('Notifications', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (notificationList.isEmpty)
              const Text('No notifications found', style: TextStyle(color: Colors.white70)),
            ...notificationList.map((item) => ListTile(
              leading: const Icon(Icons.notifications, color: Colors.white),
              title: Text((item['message'] ?? item['type'] ?? 'Activity').toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              subtitle: Text((item['name'] ?? item['email'] ?? '').toString(), style: const TextStyle(color: Colors.white70)),
            )),
          ],
        ),
      ),
    );
    await notificationApi.clearNotifications(companyId: companyId, viewerId: viewerId);
    setState(() => notificationCount = 0);
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (profile == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text('No Data Found'),
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Color(0xFF123458),
          title: Text(
            _titles[_selectedindex],
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          centerTitle: true,
          actions: [
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_on),
                  onPressed: openNotifications,
                ),
                if (notificationCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: Text('$notificationCount', style: const TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ),
              ],
            )
          ],
        ),
        drawer: SecurityDrawer(
          onHome: () {
            Navigator.pop(context);

            setState(() {
              _selectedindex = 0;
              DashBoardScreen.initialIndex = 0;
            });
          },

          onSelectCompany: () {
            Navigator.pop(context);

            DashBoardScreen.initialIndex = 1;

            setState(() {
              _selectedindex = 1;
            });
          },

          onLogout: () async {
            SessionData.userProfile = null;
            SessionData.companyInfo = null;

            if (!context.mounted) return;

            Navigator.of(context).pushNamedAndRemoveUntil(
              '/',
                  (route) => false,
            );
          },
        ),
        body: IndexedStack(
          index: _selectedindex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedindex,
          backgroundColor: Color(0xFF123458),
          selectedItemColor: Colors.orange[600],
          unselectedItemColor: Colors.white,
          iconSize: 22,
          unselectedFontSize: 10,
          elevation: 150,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
          selectedFontSize: 13,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() {
              _selectedindex = index;
              DashBoardScreen.initialIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.apartment), label: "POST SITE"),
            BottomNavigationBarItem(icon: Icon(Icons.browse_gallery), label: "TIME CLOCK"),
            BottomNavigationBarItem(icon: Icon(Icons.mark_unread_chat_alt), label: "MESSENGER"),
          ],
        ),
      );
    }
  }
}

class IconsText extends StatelessWidget {
  final IconData iconType;
  final String itemName;

  const IconsText({
    Key? key,
    required this.iconType,
    required this.itemName,
  }) : super(key: key);

  @override

  @override
  Widget build(BuildContext context) {
    return TableCell(
      child: InkWell(
        onTap: () {
          print(itemName);
        },
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 15, horizontal: 5),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                height: 35,
                width: 35,
                decoration: BoxDecoration(
                  color: Color(0xFF123458),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(iconType, color: Colors.white, size: 20),
              ),
              Text(
                itemName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
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