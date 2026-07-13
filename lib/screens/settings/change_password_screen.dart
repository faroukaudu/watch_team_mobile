
import 'package:flutter/material.dart';
import 'package:watch_team/global.dart' as g;
import 'package:watch_team/session_data.dart';
import 'package:watch_team/services/support_service.dart';
import 'package:watch_team/widgets/security_ui.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final oldController = TextEditingController();
  final newController = TextEditingController();
  final confirmController = TextEditingController();
  bool saving = false;
  bool hideOld = true;
  bool hideNew = true;
  bool hideConfirm = true;

  late final SupportService service;

  @override
  void initState() {
    super.initState();
    service = SupportService(
      baseUrl: g.baseUrl,
      userId: (SessionData.userProfile?['_id'] ?? '').toString(),
    );
  }

  @override
  void dispose() {
    oldController.dispose();
    newController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => saving = true);
    try {
      await service.changePassword(
        oldPassword: oldController.text,
        newPassword: newController.text,
        confirmPassword: confirmController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully'),
          backgroundColor: SecurityColors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: SecurityColors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  InputDecoration decoration(
    String label,
    bool hidden,
    VoidCallback toggle,
  ) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.white54),
      suffixIcon: IconButton(
        onPressed: toggle,
        icon: Icon(
          hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: Colors.white54,
        ),
      ),
      filled: true,
      fillColor: SecurityColors.surface2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: SecurityColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: SecurityColors.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SecurityPage(
      title: 'Change Password',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: SecuritySectionCard(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(Icons.admin_panel_settings_outlined,
                    color: SecurityColors.primary, size: 54),
                const SizedBox(height: 12),
                const Text(
                  'Secure your account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: oldController,
                  obscureText: hideOld,
                  style: const TextStyle(color: Colors.white),
                  decoration: decoration(
                    'Old password',
                    hideOld,
                    () => setState(() => hideOld = !hideOld),
                  ),
                  validator: (v) =>
                      (v ?? '').isEmpty ? 'Enter your current password' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: newController,
                  obscureText: hideNew,
                  style: const TextStyle(color: Colors.white),
                  decoration: decoration(
                    'New password',
                    hideNew,
                    () => setState(() => hideNew = !hideNew),
                  ),
                  validator: (v) {
                    final value = v ?? '';
                    if (value.length < 8) return 'Use at least 8 characters';
                    if (!RegExp(r'[A-Z]').hasMatch(value)) {
                      return 'Add an uppercase letter';
                    }
                    if (!RegExp(r'[a-z]').hasMatch(value)) {
                      return 'Add a lowercase letter';
                    }
                    if (!RegExp(r'\d').hasMatch(value)) return 'Add a number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmController,
                  obscureText: hideConfirm,
                  style: const TextStyle(color: Colors.white),
                  decoration: decoration(
                    'Confirm new password',
                    hideConfirm,
                    () => setState(() => hideConfirm = !hideConfirm),
                  ),
                  validator: (v) =>
                      v != newController.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: saving ? null : save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SecurityColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.security_rounded),
                    label: Text(saving ? 'Updating...' : 'Update Password'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
