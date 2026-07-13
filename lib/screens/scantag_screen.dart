import 'package:flutter/material.dart';
import 'package:watch_team/screens/site_tour_qr_scan_screen.dart';
import 'package:watch_team/screens/site_tours_screen.dart';


class ScanTagScreen extends StatelessWidget {
  final String? postSiteId;
  final String? postSiteName;

  const ScanTagScreen({
    super.key,
     this.postSiteId,
     this.postSiteName,
  });


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      body: SafeArea(
        child: Stack(
          children: [
            // Blue header background
            Container(
              height: 220,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF123458),
                    Color(0xFF123458),
                    Color(0xFF123458),
                  ],
                ),
              ),
            ),

            // Page content
            Column(
              children: [
                // Header row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      _CircleIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      const Text(
                        "Scan Tag",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      // right spacer to balance the back button size
                      const SizedBox(width: 44),
                    ],
                  ),
                ),

                const SizedBox(height: 26),

                // Card container with options
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2F3A),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ScanOptionTile(
                          icon: Icons.nfc_rounded,
                          title: "Scan NFC Tag",
                          onTap: () {
                            // TODO: start NFC scan
                            // Navigator.pushNamed(context, AppRoutes.nfc);
                          },
                        ),
                        const SizedBox(height: 12),
                         ScanOptionTile(
                            icon: Icons.qr_code_rounded,
                            title: "Scan QR Tag",
                            onTap: () {
                              if (postSiteId == null || postSiteId!.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please open Scan Tag from a Post Site.'),
                                  ),
                                );
                                return;
                              }

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SiteToursScreen(
                                    postSiteId: postSiteId!,
                                    postSiteName: postSiteName ?? 'Post Site',
                                  ),
                                ),
                              );
                            },
                          ),

                        const SizedBox(height: 12),
                        ScanOptionTile(
                          icon: Icons.sync_alt_rounded,
                          title: "Scan Virtual Tag",
                          onTap: () {
                            // TODO: virtual tag flow
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ScanOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const ScanOptionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF3A3F4B),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: 92,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              // Left icon in a small rounded square
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white70,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.15),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          height: 44,
          width: 44,
          child: Center(
            child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}
