import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:watch_team/services/guard_password_reset_service.dart';

import 'reset_password_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final GuardPasswordResetService resetService;
  final String email;
  final String userId;
  final String maskedEmail;

  const OtpVerificationScreen({
    super.key,
    required this.resetService,
    required this.email,
    required this.userId,
    required this.maskedEmail,
  });

  @override
  State<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends State<OtpVerificationScreen> {
  final controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final focusNodes = List.generate(
    6,
    (_) => FocusNode(),
  );

  bool verifying = false;
  bool resending = false;

  int resendSeconds = 60;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    timer?.cancel();

    for (final controller in controllers) {
      controller.dispose();
    }

    for (final node in focusNodes) {
      node.dispose();
    }

    super.dispose();
  }

  void _startTimer() {
    timer?.cancel();

    setState(() => resendSeconds = 60);

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (currentTimer) {
        if (!mounted) {
          currentTimer.cancel();
          return;
        }

        if (resendSeconds <= 1) {
          currentTimer.cancel();
          setState(() => resendSeconds = 0);
        } else {
          setState(() => resendSeconds--);
        }
      },
    );
  }

  String get otp =>
      controllers.map((item) => item.text).join();

  Future<void> _verify() async {
    if (otp.length != 6) {
      _showMessage(
        'Enter the complete 6-digit OTP.',
        isError: true,
      );
      return;
    }

    setState(() => verifying = true);

    try {
      final response =
          await widget.resetService.verifyOtp(
        userId: widget.userId,
        otp: otp,
      );

      if (!mounted) return;

      final resetToken =
          response['resetToken']?.toString() ?? '';

      if (resetToken.isEmpty) {
        throw Exception(
          'OTP verified, but no reset token was returned.',
        );
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(
            resetService: widget.resetService,
            userId: widget.userId,
            resetToken: resetToken,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => verifying = false);
      }
    }
  }

  Future<void> _resend() async {
    if (resending || resendSeconds > 0) {
      return;
    }

    setState(() => resending = true);

    try {
      await widget.resetService.requestOtp(
        email: widget.email,
        userId: widget.userId,
      );

      if (!mounted) return;

      for (final controller in controllers) {
        controller.clear();
      }

      focusNodes.first.requestFocus();
      _startTimer();

      _showMessage(
        'A new OTP has been sent.',
        isError: false,
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => resending = false);
      }
    }
  }

  void _handleChanged(
    int index,
    String value,
  ) {
    if (value.isNotEmpty && index < 5) {
      focusNodes[index + 1].requestFocus();
    }

    if (value.isEmpty && index > 0) {
      focusNodes[index - 1].requestFocus();
    }

    if (otp.length == 6) {
      _verify();
    }
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
                  Icons.mark_email_read_outlined,
                  color: Color(0xFF6D8BFF),
                  size: 30,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Verify your email',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Enter the 6-digit OTP sent to ${widget.maskedEmail}.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.58),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: List.generate(
                  6,
                  (index) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index == 5 ? 0 : 8,
                      ),
                      child: TextField(
                        controller: controllers[index],
                        focusNode: focusNodes[index],
                        keyboardType:
                            TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        inputFormatters: [
                          FilteringTextInputFormatter
                              .digitsOnly,
                        ],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor:
                              const Color(0xFF151922),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(13),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(13),
                            borderSide:
                                const BorderSide(
                              color: Colors.white12,
                            ),
                          ),
                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(13),
                            borderSide:
                                const BorderSide(
                              color: Color(0xFF0F3DFF),
                              width: 1.7,
                            ),
                          ),
                        ),
                        onChanged: (value) =>
                            _handleChanged(
                          index,
                          value,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed:
                      verifying ? null : _verify,
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
                  child: verifying
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
                          'Verify OTP',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed:
                      resendSeconds == 0 && !resending
                          ? _resend
                          : null,
                  child: Text(
                    resending
                        ? 'Sending...'
                        : resendSeconds > 0
                            ? 'Resend OTP in ${resendSeconds}s'
                            : 'Resend OTP',
                    style: TextStyle(
                      color: resendSeconds == 0
                          ? const Color(0xFF6D8BFF)
                          : Colors.white38,
                      fontWeight: FontWeight.w700,
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
