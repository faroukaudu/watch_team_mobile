import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:watch_team/global.dart';
import 'package:watch_team/services/api_client.dart';

class DispatchDetailScreen extends StatefulWidget {
  final Map<String, dynamic> dispatch;

  const DispatchDetailScreen({
    super.key,
    required this.dispatch,
  });

  @override
  State<DispatchDetailScreen> createState() => _DispatchDetailScreenState();
}

class _DispatchDetailScreenState extends State<DispatchDetailScreen> {
  final ApiClient api = ApiClient(baseUrl: baseUrl);
  bool approving = false;

  String value(String key) {
    final v = widget.dispatch[key];
    if (v == null || v.toString().trim().isEmpty) return "N/A";
    return v.toString();
  }

  String formatDate(dynamic raw) {
    if (raw == null) return "N/A";

    try {
      final date = DateTime.parse(raw.toString());
      return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    } catch (_) {
      return raw.toString();
    }
  }

  Future<void> approveDispatch() async {
    setState(() => approving = true);

    try {
      await api.acceptDispatch(dispatchId: widget.dispatch['_id'].toString());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Dispatch approved successfully")),
      );

      Navigator.pop(context, true);
    } catch (e) {
      setState(() => approving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Approval failed: $e")),
      );
    }
  }

  Widget infoTile({
    required IconData icon,
    required String title,
    required String text,
  }) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;
    final muted = theme.textTheme.bodyMedium?.color?.withOpacity(.6);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withOpacity(.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: theme.primaryColor.withOpacity(.15),
            child: Icon(icon, color: theme.primaryColor, size: 20),
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
                  text,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaffoldColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final primary = theme.primaryColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;

    final accepted = value("status") == "Accepted";

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        backgroundColor: scaffoldColor,
        elevation: 0,
        title: Text(
          "Dispatch Details",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        iconTheme: IconThemeData(color: textColor),
        centerTitle: true,
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          border: Border(top: BorderSide(color: textColor.withOpacity(.08))),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: accepted || approving ? null : approveDispatch,
              icon: approving
                  ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Icon(accepted ? Icons.check_circle : Icons.verified),
              label: Text(
                accepted
                    ? "Already Approved"
                    : approving
                    ? "Approving..."
                    : "Approve Dispatch",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accepted ? Colors.green : primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          /// HEADER CARD (THEMED, NOT BLUE)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: textColor.withOpacity(.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.18),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value("ticketId"),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value("postSiteName"),
                  style: TextStyle(
                    color: textColor.withOpacity(.7),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Chip(
                      label: Text(value("priority")),
                      backgroundColor: primary.withOpacity(.15),
                      labelStyle: TextStyle(color: primary),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(accepted ? "Approved" : "Pending"),
                      backgroundColor: accepted
                          ? Colors.green.withOpacity(.15)
                          : Colors.orange.withOpacity(.15),
                      labelStyle: TextStyle(
                        color: accepted ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),

          const SizedBox(height: 18),

          infoTile(icon: Icons.business, title: "Client", text: value("clientName")),
          infoTile(icon: Icons.location_on, title: "Incident Location", text: value("incidentLocation")),
          infoTile(icon: Icons.warning_amber, title: "Incident Type", text: value("incidentType")),
          infoTile(icon: Icons.calendar_month, title: "Incident Date & Time", text: formatDate(widget.dispatch["incidentDateTime"])),
          infoTile(icon: Icons.person, title: "Caller", text: "${value("callerType")} - ${value("callerName")}"),
          infoTile(icon: Icons.description, title: "Incident Details", text: value("incidentDetails")),
          infoTile(icon: Icons.task_alt, title: "Action Taken", text: value("actionTaken")),
          infoTile(icon: Icons.notes, title: "Internal Notes", text: value("internalNotes")),
        ],
      ),
    );
  }
}