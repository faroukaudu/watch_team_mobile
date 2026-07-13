import 'package:flutter/material.dart';
import 'package:watch_team/global.dart';
import 'package:watch_team/session_data.dart';
import 'package:watch_team/services/api_client.dart';

class ShiftDetailScreen extends StatefulWidget {
  final Map<String, dynamic> shift;

  const ShiftDetailScreen({
    super.key,
    required this.shift,
  });

  @override
  State<ShiftDetailScreen> createState() => _ShiftDetailScreenState();
}

class _ShiftDetailScreenState extends State<ShiftDetailScreen> {
  final ApiClient api = ApiClient(baseUrl: baseUrl);

  bool loadingExchange = false;
  Map<String, dynamic>? pendingExchangeForMe;

  bool selecting = false;

  String value(String key) {
    final v = widget.shift[key];
    if (v == null || v.toString().trim().isEmpty) return "N/A";
    return v.toString();
  }

  bool selectedByMe() {
    final guardId = (SessionData.userProfile?['_id'] ?? '').toString();
    final selected = widget.shift['selectedGuards'];

    if (selected is List) {
      return selected.any((g) => g is Map && g['guardId']?.toString() == guardId);
    }

    return false;
  }

  bool selectedByAnotherGuard() {
    final myGuardId = (SessionData.userProfile?['_id'] ?? '').toString();
    final selected = widget.shift['selectedGuards'];

    if (selected is List && selected.isNotEmpty) {
      return selected.any((g) {
        if (g is Map) {
          return g['guardId']?.toString() != myGuardId;
        }
        return false;
      });
    }

    return false;
  }

  Future<void> selectShift() async {
    if (selecting || selectedByMe()) return;

    setState(() => selecting = true);

    try {
      final guardId = (SessionData.userProfile?['_id'] ?? '').toString();
      final guardName =
      (SessionData.userProfile?['fullname'] ?? 'Guard').toString();

      final selectedResponse = await api.selectOpenShift(
        shiftTemplateId: widget.shift['_id'].toString(),
        guardId: guardId,
        guardName: guardName,
      );

      if (selectedResponse['shift'] is Map) {
        SessionData.selectedShift =
        Map<String, dynamic>.from(selectedResponse['shift'] as Map);
      } else {
        SessionData.selectedShift = widget.shift;
      }

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Shift Selected"),
          content: const Text(
            "You are signed into this shift. Kindly check in to this post site to start your time clock.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Okay"),
            )
          ],
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      setState(() => selecting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to select shift: $e")),
      );
    }
  }

  Widget infoTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String textValue,
      }) {
    final theme = Theme.of(context);
    final text = theme.textTheme.bodyLarge?.color ?? Colors.white;
    final muted =
        theme.textTheme.bodyMedium?.color?.withOpacity(.65) ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: text.withOpacity(.08)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.primaryColor.withOpacity(.15),
            child: Icon(icon, color: theme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  textValue,
                  style: TextStyle(
                    color: text,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> loadPendingExchangeForMe() async {
    try {
      final companyId =
      (SessionData.userProfile?['assignedCompanyID'] ?? '').toString();
      final guardId = (SessionData.userProfile?['_id'] ?? '').toString();

      final exchanges = await api.getReceivedShiftExchangeRequests(
        companyId: companyId,
        guardId: guardId,
        shiftTemplateId: widget.shift['_id'].toString(),
      );

      if (exchanges.isNotEmpty) {
        setState(() {
          pendingExchangeForMe = Map<String, dynamic>.from(exchanges.first);
        });
      } else {
        setState(() {
          pendingExchangeForMe = null;
        });
      }
    } catch (_) {}
  }

  Future<void> openExchangeGuardModal() async {
    setState(() => loadingExchange = true);

    try {
      final companyId =
      (SessionData.userProfile?['assignedCompanyID'] ?? '').toString();
      final guardId = (SessionData.userProfile?['_id'] ?? '').toString();

      final guards = await api.getShiftExchangeGuards(
        companyId: companyId,
        postSiteId: widget.shift['postSiteId'].toString(),
        guardId: guardId,
      );

      setState(() => loadingExchange = false);

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: Theme.of(context).cardColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        builder: (_) {
          final text =
              Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
          final muted = Theme.of(context)
              .textTheme
              .bodyMedium
              ?.color
              ?.withOpacity(.65) ??
              Colors.grey;

          if (guards.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                "No other guard found on this post site.",
                style: TextStyle(color: muted, fontWeight: FontWeight.w700),
              ),
            );
          }

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              shrinkWrap: true,
              children: [
                Text(
                  "Exchange Shift With",
                  style: TextStyle(
                    color: text,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                ...guards.map((guard) {
                  return ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.local_police),
                    ),
                    title: Text(
                      guard['fullname']?.toString() ?? "Guard",
                      style: TextStyle(color: text, fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      guard['email']?.toString() ?? "",
                      style: TextStyle(color: muted),
                    ),
                    trailing: const Icon(Icons.send),
                    onTap: () async {
                      Navigator.pop(context);
                      await sendExchangeRequestToGuard(guard);
                    },
                  );
                }).toList(),
              ],
            ),
          );
        },
      );
    } catch (e) {
      setState(() => loadingExchange = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load guards: $e")),
      );
    }
  }

  Future<void> sendExchangeRequestToGuard(Map<String, dynamic> guard) async {
    try {
      final companyId =
      (SessionData.userProfile?['assignedCompanyID'] ?? '').toString();
      final myGuardId = (SessionData.userProfile?['_id'] ?? '').toString();
      final myGuardName =
      (SessionData.userProfile?['fullname'] ?? 'Guard').toString();

      await api.sendShiftExchangeRequest(
        payload: {
          'companyId': companyId,
          'shiftTemplateId': widget.shift['_id'].toString(),
          'shiftTitle': widget.shift['shiftTitle']?.toString() ?? '',
          'postSiteId': widget.shift['postSiteId']?.toString() ?? '',
          'postSiteName': widget.shift['postSiteName']?.toString() ?? '',
          'sentByGuardId': myGuardId,
          'sentByGuardName': myGuardName,
          'receivedByGuardId': guard['_id'].toString(),
          'receivedByGuardName': guard['fullname']?.toString() ?? 'Guard',
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Shift exchange request sent")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send exchange request: $e")),
      );
    }
  }

  Future<void> acceptExchange() async {
    if (pendingExchangeForMe == null) return;

    final exchangeStatus =
    (pendingExchangeForMe?['status'] ?? '').toString().toLowerCase();

    if (exchangeStatus != "pending") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Already Assigned")),
      );
      return;
    }

    try {
      await api.respondShiftExchange(
        exchangeId: pendingExchangeForMe!['_id'].toString(),
        status: "Accepted",
      );

      if (!mounted) return;

      setState(() {
        pendingExchangeForMe = {
          ...pendingExchangeForMe!,
          'status': 'Accepted',
        };
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Shift exchange accepted")),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains("409")
                ? "Already Assigned"
                : "Failed to accept exchange: $e",
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    loadPendingExchangeForMe();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.scaffoldBackgroundColor;
    final card = theme.cardColor;
    final primary = theme.primaryColor;
    final text = theme.textTheme.bodyLarge?.color ?? Colors.white;
    final muted =
        theme.textTheme.bodyMedium?.color?.withOpacity(.65) ?? Colors.grey;

    final selected = selectedByMe();
    final selectedByOther = selectedByAnotherGuard();
    final hasExchangeRequest = pendingExchangeForMe != null;
    final exchangeStatus =
    (pendingExchangeForMe?['status'] ?? '').toString().toLowerCase();
    final canAcceptExchange = hasExchangeRequest && exchangeStatus == "pending";
    final exchangeAlreadyAccepted =
        hasExchangeRequest && exchangeStatus == "accepted";

    final repeatDays = widget.shift['repeatDays'] is List
        ? (widget.shift['repeatDays'] as List).join(", ")
        : "N/A";

    final breaks = widget.shift['breaks'] is List
        ? (widget.shift['breaks'] as List).join(", ")
        : "None";

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: text),
        title: Text(
          "Shift Details",
          style: TextStyle(color: text, fontWeight: FontWeight.w800),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
        decoration: BoxDecoration(
          color: card,
          border: Border(top: BorderSide(color: text.withOpacity(.08))),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 54,
            child: Row(
              children: [
                if (selected) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: loadingExchange ? null : openExchangeGuardModal,
                      icon: loadingExchange
                          ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Icon(Icons.swap_horiz),
                      label: const Text("Exchange Shift"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orangeAccent,
                        side: const BorderSide(color: Colors.orangeAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],

                if (canAcceptExchange) ...[
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: acceptExchange,
                        icon: const Icon(Icons.check_circle, size: 20),
                        label: const Text(
                          "Accept Exchange",
                          textAlign: TextAlign.center,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.center,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            height: 1.1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ] else if (exchangeAlreadyAccepted) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.lock),
                      label: const Text("Already Assigned"),
                      style: ElevatedButton.styleFrom(
                        disabledBackgroundColor: Colors.grey.shade700,
                        disabledForegroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                      selected || selectedByOther || selecting ? null : selectShift,
                      icon: selecting
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : Icon(
                        selectedByOther
                            ? Icons.lock
                            : selected
                            ? Icons.check_circle
                            : Icons.login,
                      ),
                      label: Text(
                        selectedByOther
                            ? "Already Assigned"
                            : selected
                            ? "Shift Selected"
                            : selecting
                            ? "Selecting..."
                            : "Select Shift",
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selected ? Colors.green : primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                        selectedByOther ? Colors.grey.shade700 : Colors.green,
                        disabledForegroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primary,
                  primary.withOpacity(.75),
                  Colors.deepOrange.withOpacity(.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: primary.withOpacity(.35),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -8,
                  bottom: -12,
                  child: Icon(
                    Icons.work_history_rounded,
                    size: 110,
                    color: Colors.white.withOpacity(.12),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.schedule_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      value("shiftTitle"),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      value("postSiteName"),
                      style: TextStyle(
                        color: Colors.white.withOpacity(.82),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.18),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: Colors.white.withOpacity(.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                selected
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                selected ? "Selected" : "Available",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(.16),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "${value("startTime")} - ${value("endTime")}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          infoTile(
            context,
            icon: Icons.schedule,
            title: "Shift Time",
            textValue: "${value("startTime")} - ${value("endTime")}",
          ),
          infoTile(
            context,
            icon: Icons.calendar_month,
            title: "Repeat Days",
            textValue: repeatDays,
          ),
          infoTile(
            context,
            icon: Icons.timelapse,
            title: "Repeat For",
            textValue: value("repeatFor"),
          ),
          infoTile(
            context,
            icon: Icons.coffee,
            title: "Breaks",
            textValue: breaks,
          ),
          infoTile(
            context,
            icon: Icons.notes,
            title: "Note",
            textValue: value("note"),
          ),
        ],
      ),
    );
  }
}