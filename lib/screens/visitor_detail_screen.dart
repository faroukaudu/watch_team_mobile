import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VisitorDetailScreen extends StatelessWidget {
  final Map<String, dynamic> visitor;

  const VisitorDetailScreen({
    super.key,
    required this.visitor,
  });

  String value(String key) {
    final v = visitor[key];
    if (v == null || v.toString().trim().isEmpty) return "N/A";
    return v.toString();
  }

  String formatDate(dynamic raw) {
    if (raw == null) return "N/A";
    try {
      return DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.parse(raw.toString()));
    } catch (_) {
      return raw.toString();
    }
  }

  String? imageUrl(String key) {
    final v = visitor[key];
    if (v is Map && v['secureUrl'] != null) return v['secureUrl'].toString();
    return null;
  }

  Widget infoTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String textValue,
      }) {
    final theme = Theme.of(context);
    final text = theme.textTheme.bodyLarge?.color ?? Colors.white;
    final muted = theme.textTheme.bodyMedium?.color?.withOpacity(.65) ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: text.withOpacity(.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                Text(title, style: TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(textValue, style: TextStyle(color: text, fontSize: 14, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget imageBlock(BuildContext context, String title, String? url) {
    final theme = Theme.of(context);
    final text = theme.textTheme.bodyLarge?.color ?? Colors.white;
    final muted = theme.textTheme.bodyMedium?.color?.withOpacity(.65) ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: text.withOpacity(.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: text, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          if (url != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                url,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 130,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text("No image attached", style: TextStyle(color: muted)),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.scaffoldBackgroundColor;
    final card = theme.cardColor;
    final text = theme.textTheme.bodyLarge?.color ?? Colors.white;
    final muted = theme.textTheme.bodyMedium?.color?.withOpacity(.65) ?? Colors.grey;

    final face = imageUrl("visitorFace");

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: text),
        centerTitle: true,
        title: Text(
          "Visitor Details",
          style: TextStyle(color: text, fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: text.withOpacity(.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.16),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: theme.primaryColor.withOpacity(.15),
                  backgroundImage: face != null ? NetworkImage(face) : null,
                  child: face == null ? Icon(Icons.person, color: theme.primaryColor, size: 34) : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(value("visitorName"), style: TextStyle(color: text, fontSize: 20, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 5),
                      Text(value("postSiteName"), style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 5),
                      Text(formatDate(visitor["visitDateTime"]), style: TextStyle(color: muted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          infoTile(context, icon: Icons.person, title: "Sex", textValue: value("sex")),
          infoTile(context, icon: Icons.phone, title: "Phone Number", textValue: value("phoneNumber")),
          infoTile(context, icon: Icons.email, title: "Email", textValue: value("email")),
          infoTile(context, icon: Icons.work, title: "Purpose of Visit", textValue: value("purposeOfVisit")),
          infoTile(
            context,
            icon: Icons.verified_user,
            title: "First Time Visiting",
            textValue: visitor["firstTimeVisiting"] == true ? "Yes" : "No",
          ),
          infoTile(context, icon: Icons.security, title: "Guard", textValue: value("guardName")),

          const SizedBox(height: 6),

          imageBlock(context, "Visitor Face", imageUrl("visitorFace")),
          imageBlock(context, "Visitor ID", imageUrl("visitorIdCard")),
          imageBlock(context, "Signature", imageUrl("signature")),
        ],
      ),
    );
  }
}