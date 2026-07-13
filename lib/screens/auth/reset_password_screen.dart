import 'package:flutter/material.dart';
import 'package:watch_team/services/guard_password_reset_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final GuardPasswordResetService resetService;
  final String userId;
  final String resetToken;

  const ResetPasswordScreen({
    super.key,
    required this.resetService,
    required this.userId,
    required this.resetToken,
  });

  @override
  State<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState
    extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final passwordController =
      TextEditingController();
  final confirmPasswordController =
      TextEditingController();

  bool hidePassword = true;
  bool hideConfirmPassword = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    passwordController.addListener(_refreshStrength);
  }

  @override
  void dispose() {
    passwordController
        .removeListener(_refreshStrength);
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _refreshStrength() {
    if (mounted) {
      setState(() {});
    }
  }

  _PasswordStrength get strength =>
      _calculateStrength(passwordController.text);

  _PasswordStrength _calculateStrength(
    String password,
  ) {
    if (password.isEmpty) {
      return const _PasswordStrength(
        label: 'Enter a password',
        progress: 0,
        color: Colors.white24,
      );
    }

    int score = 0;

    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[A-Z]').hasMatch(password)) {
      score++;
    }
    if (RegExp(r'\d').hasMatch(password)) {
      score++;
    }
    if (RegExp(r'[^A-Za-z0-9]')
        .hasMatch(password)) {
      score++;
    }

    if (score <= 2) {
      return const _PasswordStrength(
        label: 'Weak',
        progress: 0.33,
        color: Color(0xFFE53935),
      );
    }

    if (score <= 4) {
      return const _PasswordStrength(
        label: 'Normal',
        progress: 0.66,
        color: Color(0xFFFFA000),
      );
    }

    return const _PasswordStrength(
      label: 'Strong',
      progress: 1,
      color: Color(0xFF2EAD62),
    );
  }

  Future<void> _savePassword() async {
    if (!(_formKey.currentState?.validate() ??
        false)) {
      return;
    }

    setState(() => saving = true);

    try {
      await widget.resetService.resetPassword(
        userId: widget.userId,
        resetToken: widget.resetToken,
        password: passwordController.text,
        confirmPassword:
            confirmPasswordController.text,
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor:
                const Color(0xFF171A20),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(20),
            ),
            icon: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF2EAD62),
              size: 54,
            ),
            title: const Text(
              'Password changed',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            content: Text(
              'Your password has been reset successfully. You can now sign in using your new password.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.62),
                height: 1.5,
              ),
            ),
            actionsAlignment:
                MainAxisAlignment.center,
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF0F3DFF),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Return to login'),
                ),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      Navigator.of(context).popUntil(
        (route) => route.isFirst,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error
                .toString()
                .replaceFirst('Exception: ', ''),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              const Color(0xFFB3261E),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStrength = strength;

    return Scaffold(
      backgroundColor: const Color(0xFF090B0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF090B0F),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            18,
            20,
            30,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF0F3DFF,
                    ).withOpacity(0.14),
                    borderRadius:
                        BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.password_rounded,
                    color: Color(0xFF6D8BFF),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Create new password',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Use at least 8 characters with uppercase, lowercase, and a number.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.58),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: passwordController,
                  obscureText: hidePassword,
                  textInputAction:
                      TextInputAction.next,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                  decoration: _passwordDecoration(
                    label: 'New password',
                    hidden: hidePassword,
                    onToggle: () => setState(
                      () =>
                          hidePassword = !hidePassword,
                    ),
                  ),
                  validator: (value) {
                    final password = value ?? '';

                    if (password.length < 8) {
                      return 'Use at least 8 characters';
                    }

                    if (!RegExp(r'[a-z]')
                        .hasMatch(password)) {
                      return 'Add a lowercase letter';
                    }

                    if (!RegExp(r'[A-Z]')
                        .hasMatch(password)) {
                      return 'Add an uppercase letter';
                    }

                    if (!RegExp(r'\d')
                        .hasMatch(password)) {
                      return 'Add at least one number';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(999),
                        child:
                            LinearProgressIndicator(
                          value:
                              currentStrength.progress,
                          minHeight: 7,
                          backgroundColor:
                              Colors.white12,
                          valueColor:
                              AlwaysStoppedAnimation(
                            currentStrength.color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 58,
                      child: Text(
                        currentStrength.label,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color:
                              currentStrength.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                TextFormField(
                  controller:
                      confirmPasswordController,
                  obscureText: hideConfirmPassword,
                  textInputAction:
                      TextInputAction.done,
                  onFieldSubmitted: (_) =>
                      _savePassword(),
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                  decoration: _passwordDecoration(
                    label: 'Confirm new password',
                    hidden: hideConfirmPassword,
                    onToggle: () => setState(
                      () => hideConfirmPassword =
                          !hideConfirmPassword,
                    ),
                  ),
                  validator: (value) {
                    if ((value ?? '').isEmpty) {
                      return 'Confirm your new password';
                    }

                    if (value !=
                        passwordController.text) {
                      return 'Passwords do not match';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed:
                        saving ? null : _savePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF0F3DFF),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          const Color(0xFF263366),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Change Password',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _passwordDecoration({
    required String label,
    required bool hidden,
    required VoidCallback onToggle,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: const Icon(
        Icons.lock_outline_rounded,
        color: Colors.white54,
      ),
      suffixIcon: IconButton(
        onPressed: onToggle,
        icon: Icon(
          hidden
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: Colors.white54,
        ),
      ),
      labelStyle: const TextStyle(
        color: Colors.white54,
      ),
      filled: true,
      fillColor: const Color(0xFF151922),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Colors.white12,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color(0xFF0F3DFF),
          width: 1.6,
        ),
      ),
    );
  }
}

class _PasswordStrength {
  final String label;
  final double progress;
  final Color color;

  const _PasswordStrength({
    required this.label,
    required this.progress,
    required this.color,
  });
}
