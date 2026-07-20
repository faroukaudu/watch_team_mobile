import 'package:flutter/material.dart';
import 'package:watch_team/global.dart' as g;
import 'package:watch_team/services/api_client.dart';
import 'package:watch_team/session_data.dart';

class ParkingManagerScreen extends StatefulWidget {
  const ParkingManagerScreen({super.key});

  @override
  State<ParkingManagerScreen> createState() => _ParkingManagerScreenState();
}

class _ParkingManagerScreenState extends State<ParkingManagerScreen> {
  final ApiClient api = ApiClient(baseUrl: g.baseUrl);

  List<Map<String, dynamic>> zones = [];
  bool loading = true;
  bool saving = false;

  String get companyId =>
      (SessionData.userProfile?['assignedCompanyID'] ?? '').toString();

  String get guardId =>
      (SessionData.userProfile?['_id'] ?? '').toString();

  String get guardName =>
      (SessionData.userProfile?['fullname'] ??
          SessionData.userProfile?['username'] ??
          'Guard')
          .toString();

  String get postSiteId => (SessionData.postSiteID ?? '').toString();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() => loading = true);
    }

    try {
      final result = await api.listParkingZones(
        companyId: companyId,
        postSiteId: postSiteId,
      );

      if (!mounted) return;

      setState(() {
        zones = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);
      _message(_error(e), error: true);
    }
  }

  String _error(Object error) {
    final value = error.toString().replaceFirst('Exception: ', '');

    if (value.contains('409')) {
      return 'This vehicle is already checked in.';
    }

    return value;
  }

  void _message(String text, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: error
            ? const Color(0xFFB3261E)
            : const Color(0xFF0D5F73),
        content: Text(text),
      ),
    );
  }

  Future<void> _showActionSheet(Map<String, dynamic> zone) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          decoration: const BoxDecoration(
            color: Color(0xFF0B1A29),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  zone['zoneName']?.toString() ?? 'Parking Zone',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  zone['instructions']?.toString().trim().isNotEmpty == true
                      ? zone['instructions'].toString()
                      : 'Select the parking operation you want to perform.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white60,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                _actionTile(
                  Icons.login_rounded,
                  'Vehicle Check-In',
                  'Register a newly arriving vehicle',
                  const Color(0xFF22D3EE),
                      () async {
                    Navigator.of(sheetContext).pop();

                    await Future<void>.delayed(
                      const Duration(milliseconds: 250),
                    );

                    if (!mounted) return;
                    await _showCheckIn(zone);
                  },
                ),

                _actionTile(
                  Icons.logout_rounded,
                  'Vehicle Check-Out',
                  'Find a parked vehicle and record its exit',
                  const Color(0xFF60A5FA),
                      () async {
                    Navigator.of(sheetContext).pop();

                    await Future<void>.delayed(
                      const Duration(milliseconds: 250),
                    );

                    if (!mounted) return;
                    await _showCheckOut(zone);
                  },
                ),

                _actionTile(
                  Icons.report_problem_rounded,
                  'Log Parking Violation',
                  'Record unauthorized or unsafe parking',
                  const Color(0xFFF59E0B),
                      () async {
                    Navigator.of(sheetContext).pop();

                    await Future<void>.delayed(
                      const Duration(milliseconds: 250),
                    );

                    if (!mounted) return;
                    await _showViolation(zone);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _actionTile(
      IconData icon,
      String title,
      String subtitle,
      Color color,
      VoidCallback onTap,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: const Color(0xFF102538),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white38,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCheckIn(Map<String, dynamic> zone) async {
    final plate = TextEditingController();
    final make = TextEditingController();
    final model = TextEditingController();
    final color = TextEditingController();
    final driver = TextEditingController();
    final phone = TextEditingController();
    final permit = TextEditingController();
    final space = TextEditingController();
    final purpose = TextEditingController();
    final notes = TextEditingController();

    try {
      final submit = await _formDialog(
        title: 'Vehicle Check-In',
        subtitle: 'Register the vehicle before granting parking access.',
        actionLabel: 'Check Vehicle In',
        fields: [
          _field(
            plate,
            'Plate Number *',
            icon: Icons.pin_outlined,
            caps: TextCapitalization.characters,
          ),
          _field(
            driver,
            'Driver / Visitor Name',
            icon: Icons.person_outline_rounded,
          ),
          _field(
            phone,
            'Phone Number',
            icon: Icons.phone_outlined,
            keyboard: TextInputType.phone,
          ),
          _field(
            make,
            'Vehicle Make',
            icon: Icons.directions_car_outlined,
          ),
          _field(
            model,
            'Vehicle Model',
            icon: Icons.car_rental_outlined,
          ),
          _field(
            color,
            'Vehicle Color',
            icon: Icons.palette_outlined,
          ),
          _field(
            permit,
            'Permit Number',
            icon: Icons.badge_outlined,
          ),
          _field(
            space,
            'Parking Space',
            icon: Icons.local_parking_rounded,
          ),
          _field(
            purpose,
            'Purpose of Visit',
            icon: Icons.work_outline_rounded,
          ),
          _field(
            notes,
            'Notes',
            icon: Icons.notes_rounded,
            lines: 3,
          ),
        ],
      );

      if (submit != true) return;

      if (plate.text.trim().isEmpty) {
        _message('Plate number is required.', error: true);
        return;
      }

      if (mounted) {
        setState(() => saving = true);
      }

      await api.checkInParkingVehicle(
        zoneId: zone['_id'].toString(),
        companyId: companyId,
        guardId: guardId,
        guardName: guardName,
        plateNumber: plate.text,
        vehicleMake: make.text,
        vehicleModel: model.text,
        vehicleColor: color.text,
        driverName: driver.text,
        driverPhone: phone.text,
        permitNumber: permit.text,
        parkingSpace: space.text,
        purpose: purpose.text,
        notes: notes.text,
      );

      _message(
        'Vehicle ${plate.text.trim().toUpperCase()} checked in successfully.',
      );

      await _load();
    } catch (e) {
      _message(_error(e), error: true);
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Future<void> _showCheckOut(Map<String, dynamic> zone) async {
    final rawRecords = zone['records'];

    final records = rawRecords is List
        ? rawRecords
        .where(
          (record) =>
      record is Map &&
          record['type'] == 'CheckIn' &&
          record['status'] == 'Parked',
    )
        .map((record) => Map<String, dynamic>.from(record as Map))
        .toList()
        : <Map<String, dynamic>>[];

    if (records.isEmpty) {
      _message(
        'There are no currently parked vehicles in this zone.',
        error: true,
      );
      return;
    }

    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: const Color(0xFF0B1A29),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Vehicle to Check Out',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: records.length,
                    separatorBuilder: (_, __) =>
                    const Divider(color: Colors.white12),
                    itemBuilder: (_, index) {
                      final record = records[index];
                      final subtitle = [
                        record['driverName'],
                        record['parkingSpace'],
                      ]
                          .where(
                            (value) =>
                        value != null &&
                            value.toString().trim().isNotEmpty,
                      )
                          .join(' · ');

                      return ListTile(
                        onTap: () => Navigator.pop(context, record),
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF123458),
                          child: Icon(
                            Icons.directions_car,
                            color: Color(0xFF79ECFF),
                          ),
                        ),
                        title: Text(
                          record['plateNumber']?.toString() ?? 'Vehicle',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: subtitle.isEmpty
                            ? null
                            : Text(
                          subtitle,
                          style: const TextStyle(
                            color: Colors.white54,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.white38,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null) return;

    if (mounted) {
      setState(() => saving = true);
    }

    try {
      await api.checkOutParkingVehicle(
        zoneId: zone['_id'].toString(),
        recordId: selected['_id'].toString(),
        companyId: companyId,
      );

      _message('${selected['plateNumber']} checked out successfully.');
      await _load();
    } catch (e) {
      _message(_error(e), error: true);
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Future<void> _showViolation(Map<String, dynamic> zone) async {
    final plate = TextEditingController();
    final make = TextEditingController();
    final model = TextEditingController();
    final color = TextEditingController();
    final space = TextEditingController();
    final notes = TextEditingController();

    String violation = 'Unauthorized Parking';

    try {
      final submit = await _formDialog(
        title: 'Parking Violation',
        subtitle: 'Document the vehicle and the observed parking issue.',
        actionLabel: 'Submit Violation',
        fields: [
          _field(
            plate,
            'Plate Number *',
            icon: Icons.pin_outlined,
            caps: TextCapitalization.characters,
          ),
          StatefulBuilder(
            builder: (context, setLocal) {
              return DropdownButtonFormField<String>(
                value: violation,
                dropdownColor: const Color(0xFF102538),
                style: const TextStyle(color: Colors.white),
                decoration: _decoration(
                  'Violation Type',
                  Icons.report_problem_outlined,
                ),
                items: const [
                  'Unauthorized Parking',
                  'Reserved Space',
                  'Fire Lane',
                  'Expired Permit',
                  'Blocking Access',
                  'Overstayed',
                  'Unsafe Parking',
                  'Other',
                ]
                    .map(
                      (item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  ),
                )
                    .toList(),
                onChanged: (value) {
                  setLocal(() {
                    violation = value ?? violation;
                  });
                },
              );
            },
          ),
          _field(
            space,
            'Parking Space / Area',
            icon: Icons.local_parking_rounded,
          ),
          _field(
            make,
            'Vehicle Make',
            icon: Icons.directions_car_outlined,
          ),
          _field(
            model,
            'Vehicle Model',
            icon: Icons.car_rental_outlined,
          ),
          _field(
            color,
            'Vehicle Color',
            icon: Icons.palette_outlined,
          ),
          _field(
            notes,
            'Violation Details *',
            icon: Icons.notes_rounded,
            lines: 4,
          ),
        ],
      );

      if (submit != true) return;

      if (plate.text.trim().isEmpty) {
        _message('Plate number is required.', error: true);
        return;
      }

      if (notes.text.trim().isEmpty) {
        _message('Violation details are required.', error: true);
        return;
      }

      if (mounted) {
        setState(() => saving = true);
      }

      await api.logParkingViolation(
        zoneId: zone['_id'].toString(),
        companyId: companyId,
        guardId: guardId,
        guardName: guardName,
        plateNumber: plate.text,
        vehicleMake: make.text,
        vehicleModel: model.text,
        vehicleColor: color.text,
        parkingSpace: space.text,
        violationType: violation,
        notes: notes.text,
      );

      _message('Parking violation submitted to management.');
      await _load();
    } catch (e) {
      _message(_error(e), error: true);
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Future<bool?> _formDialog({
    required String title,
    required String subtitle,
    required String actionLabel,
    required List<Widget> fields,
  }) {
    if (!mounted) {
      return Future<bool?>.value(false);
    }

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: const Color(0xFF0B1A29),
          insetPadding: const EdgeInsets.all(14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 520,
              maxHeight: 650,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      IconButton(
                        onPressed: () {
                          FocusScope.of(dialogContext).unfocus();
                          Navigator.of(dialogContext).pop(false);
                        },
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  Flexible(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        children: fields
                            .map(
                              (field) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: field,
                          ),
                        )
                            .toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0EA5E9),
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                        ),
                      ),
                      onPressed: () {
                        FocusScope.of(dialogContext).unfocus();
                        Navigator.of(dialogContext).pop(true);
                      },
                      child: Text(actionLabel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _field(
      TextEditingController controller,
      String label, {
        required IconData icon,
        int lines = 1,
        TextInputType? keyboard,
        TextCapitalization caps = TextCapitalization.words,
      }) {
    return TextField(
      controller: controller,
      maxLines: lines,
      keyboardType: keyboard,
      textCapitalization: caps,
      style: const TextStyle(color: Colors.white),
      decoration: _decoration(label, icon),
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(
        icon,
        color: const Color(0xFF67E8F9),
      ),
      filled: true,
      fillColor: const Color(0xFF102538),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFF203B50),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFF22D3EE),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF123458),
            Color(0xFF0A7185),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3300C8FF),
            blurRadius: 26,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_parking_rounded,
                color: Color(0xFF79ECFF),
              ),
              SizedBox(width: 8),
              Text(
                'PARKING OPERATIONS',
                style: TextStyle(
                  color: Color(0xFF79ECFF),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          Text(
            'Control every space.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Check vehicles in and out, monitor zone occupancy, and report parking violations. No GPS is collected.',
            style: TextStyle(
              color: Colors.white70,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 40,
        horizontal: 22,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1C2A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF20394D),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.local_parking_rounded,
            size: 46,
            color: Colors.white30,
          ),
          SizedBox(height: 12),
          Text(
            'No parking zone available',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'An administrator must publish a Parking Manager zone for your post site.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneCard(Map<String, dynamic> zone) {
    final occupied = int.tryParse('${zone['occupiedCount'] ?? 0}') ?? 0;
    final capacity = int.tryParse('${zone['capacity'] ?? 1}') ?? 1;
    final safeCapacity = capacity <= 0 ? 1 : capacity;
    final percent = (occupied / safeCapacity).clamp(0.0, 1.0).toDouble();

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Material(
        color: const Color(0xFF0D1C2A),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _showActionSheet(zone),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0EA5E9).withOpacity(0.14),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.local_parking_rounded,
                        color: Color(0xFF67E8F9),
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            zone['zoneName']?.toString() ?? 'Parking Zone',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            zone['postSiteName']?.toString() ?? '',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white38,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Current occupancy',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '$occupied / $capacity',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 8,
                    backgroundColor: const Color(0xFF172D40),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF22D3EE),
                    ),
                  ),
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 17,
                      color: Color(0xFFFBBF24),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${zone['openViolationCount'] ?? 0} open violations',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${zone['maxStayMinutes'] ?? 0} min max stay',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06111D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF06111D),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Parking Manager'),
        actions: [
          IconButton(
            onPressed: loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (loading)
            const Center(
              child: CircularProgressIndicator(),
            )
          else
            RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 17),
                  if (zones.isEmpty)
                    _buildEmptyState()
                  else
                    ...zones.map(_buildZoneCard),
                ],
              ),
            ),
          if (saving)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
