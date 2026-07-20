import 'package:flutter/material.dart';
import 'package:watch_team/global.dart' as g;
import 'package:watch_team/services/guard_password_reset_service.dart';

import 'otp_verification_screen.dart';

class ForgotPasswordEmailScreen extends StatefulWidget {
  const ForgotPasswordEmailScreen({super.key});

  @override
  State<ForgotPasswordEmailScreen> createState() =>
      _ForgotPasswordEmailScreenState();
}

class _ForgotPasswordEmailScreenState
    extends State<ForgotPasswordEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  late final GuardPasswordResetService resetService;

  bool loading = false;

  @override
  void initState() {
    super.initState();
    resetService = GuardPasswordResetService(baseUrl: '${g.baseUrl}');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => loading = true);

    try {
      final email = _emailController.text.trim();

      final response = await resetService.requestOtp(
        email: email,
      );

      if (!mounted) return;

      if (response['requiresAccountSelection'] == true) {
        final rawAccounts = response['accounts'] as List? ?? [];

        final accounts = rawAccounts
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

        final selectedUserId =
            await _showAccountSelection(accounts);

        if (!mounted || selectedUserId == null) {
          return;
        }

        final selectedResponse =
            await resetService.requestOtp(
          email: email,
          userId: selectedUserId,
        );

        if (!mounted) return;

        await _openOtpScreen(
          email: email,
          response: selectedResponse,
        );

        return;
      }

      await _openOtpScreen(
        email: email,
        response: response,
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _openOtpScreen({
    required String email,
    required Map<String, dynamic> response,
  }) async {
    final userId = response['userId']?.toString() ?? '';

    if (userId.isEmpty) {
      throw Exception(
        'OTP was sent, but no guard account ID was returned.',
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(
          resetService: resetService,
          email: email,
          userId: userId,
          maskedEmail:
              response['maskedEmail']?.toString() ?? email,
        ),
      ),
    );
  }

  Future<String?> _showAccountSelection(
    List<Map<String, dynamic>> accounts,
  ) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF171A20),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              18,
              18,
              18,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(
                    bottom: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius:
                        BorderRadius.circular(999),
                  ),
                ),
                const Text(
                  'Select your guard account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'More than one guard account uses this email address.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: accounts.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final account = accounts[index];

                      final userId =
                          account['userId']?.toString() ??
                              '';

                      final fullname =
                          account['fullname']?.toString() ??
                              'Guard Account';

                      final companyName =
                          account['companyName']
                                  ?.toString() ??
                              '';

                      final postSites =
                          account['postSites'] as List? ??
                              [];

                      String postSiteName = '';

                      if (postSites.isNotEmpty &&
                          postSites.first is Map) {
                        final site =
                            Map<String, dynamic>.from(
                          postSites.first as Map,
                        );

                        postSiteName =
                            site['siteName']?.toString() ??
                                '';
                      }

                      return InkWell(
                        onTap: userId.isEmpty
                            ? null
                            : () => Navigator.pop(
                                  sheetContext,
                                  userId,
                                ),
                        borderRadius:
                            BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D0F13),
                            borderRadius:
                                BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white12,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF0F3DFF,
                                  ).withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.shield_outlined,
                                  color: Color(0xFF6D8BFF),
                                ),
                              ),
                              const SizedBox(width: 13),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(
                                      fullname,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight:
                                            FontWeight.w800,
                                      ),
                                    ),
                                    if (companyName
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        companyName,
                                        style: TextStyle(
                                          color: Colors.white
                                              .withOpacity(0.55),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                    if (postSiteName
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        postSiteName,
                                        style: const TextStyle(
                                          color: Color(
                                            0xFF6D8BFF,
                                          ),
                                          fontSize: 12,
                                          fontWeight:
                                              FontWeight.w700,
                                        ),
                                      ),
                                    ],
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
  }

  void _showMessage(
    String message, {
    required bool isError,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError
            ? const Color(0xFFB3261E)
            : const Color(0xFF198754),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Hero(
                        tag: "navi-logo",
                        child: Image.asset("images/logonew.png", width: 90, height: 90,)),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFF0F3DFF,
                        ).withOpacity(0.14),
                        borderRadius:
                        BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.lock_reset_rounded,
                        color: Color(0xFF6D8BFF),
                        size: 31,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 50),
                const Text(
                  'Forgot your password?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Enter the email registered to your guard account. We will send you a secure one-time password.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.58),
                    fontSize: 14,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _emailController,
                  keyboardType:
                      TextInputType.emailAddress,
                  textInputAction:
                      TextInputAction.done,
                  onFieldSubmitted: (_) => _continue(),
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Email address',
                    hintText: 'guard@example.com',
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: Colors.white54,
                    ),
                    labelStyle: const TextStyle(
                      color: Colors.white54,
                    ),
                    hintStyle: const TextStyle(
                      color: Colors.white24,
                    ),
                    filled: true,
                    fillColor:
                        const Color(0xFF151922),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        color: Colors.white12,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        color: Color(0xFF0F3DFF),
                        width: 1.6,
                      ),
                    ),
                  ),
                  validator: (value) {
                    final email =
                        value?.trim() ?? '';

                    if (email.isEmpty) {
                      return 'Enter your registered email';
                    }

                    final validEmail =
                        RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                            .hasMatch(email);

                    if (!validEmail) {
                      return 'Enter a valid email address';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed:
                        loading ? null : _continue,
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
                    child: loading
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
                            'Send OTP',
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
}
