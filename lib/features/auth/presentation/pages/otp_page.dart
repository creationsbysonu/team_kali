import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinput/pinput.dart';
import 'package:sewa_sathi/core/theme/theme.dart';
import 'package:sewa_sathi/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sewa_sathi/features/auth/presentation/widgets/auth_loading_overlay.dart';

/// OTP verification page.
class OtpPage extends StatefulWidget {
  final String email;

  const OtpPage({super.key, required this.email});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _otpController = TextEditingController();
  final _focusNode = FocusNode();

  Timer? _resendTimer;
  int _resendCountdown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _resendCountdown = 60;
    });

    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
        setState(() => _canResend = true);
      }
    });
  }

  void _handleVerifyOtp() {
    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter complete 6-digit OTP'),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppTheme.spacingMedium),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
      );
      return;
    }

    context.read<AuthBloc>().add(
      VerifyOtpEvent(email: widget.email, otp: _otpController.text),
    );
  }

  void _handleResendOtp() {
    if (!_canResend) return;

    context.read<AuthBloc>().add(ResendOtpEvent(email: widget.email));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      // Only listen to relevant state changes for OTP page
      listenWhen: (previous, current) {
        // Navigate on authentication
        if (current is Authenticated) return true;
        // Handle resent OTP
        if (current is OtpResent) return true;
        // Show errors
        if (current is AuthError) return true;
        return false;
      },
      listener: (context, state) {
        if (state is Authenticated) {
          // Pop back to root and let _AuthWrapper handle navigation
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else if (state is OtpResent) {
          _startResendTimer();
          _otpController.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('OTP sent successfully'),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(AppTheme.spacingMedium),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
          );
        } else if (state is AuthError) {
          _otpController.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(AppTheme.spacingMedium),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        // Only rebuild when loading state changes
        buildWhen: (previous, current) {
          return (previous is AuthLoading) != (current is AuthLoading);
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return AuthLoadingOverlay(
            isLoading: isLoading,
            child: Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: AppTheme.textPrimary,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spacingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),

                      // Icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryCobaltPale,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusXLarge,
                          ),
                        ),
                        child: const Icon(
                          Icons.mark_email_read_outlined,
                          size: 40,
                          color: AppTheme.primaryCobalt,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingLarge),

                      // Title
                      const Text(
                        'Verify OTP',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeTitle,
                          fontWeight: AppTheme.fontWeightBold,
                          color: AppTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.spacingSmall),

                      // Subtitle
                      const Text(
                        'Enter the 6-digit code sent to',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.spacingXSmall),
                      Text(
                        widget.email,
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          fontWeight: AppTheme.fontWeightSemiBold,
                          color: AppTheme.primaryCobalt,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      // OTP Input
                      Center(
                        child: Pinput(
                          controller: _otpController,
                          focusNode: _focusNode,
                          length: 6,
                          defaultPinTheme: PinTheme(
                            width: 50,
                            height: 56,
                            textStyle: const TextStyle(
                              fontSize: AppTheme.fontSizeTitle,
                              fontWeight: AppTheme.fontWeightSemiBold,
                              color: AppTheme.textPrimary,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryCobaltPale.withOpacity(
                                0.3,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMedium,
                              ),
                              border: Border.all(color: AppTheme.borderColor),
                            ),
                          ),
                          focusedPinTheme: PinTheme(
                            width: 50,
                            height: 56,
                            textStyle: const TextStyle(
                              fontSize: AppTheme.fontSizeTitle,
                              fontWeight: AppTheme.fontWeightSemiBold,
                              color: AppTheme.primaryCobalt,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMedium,
                              ),
                              border: Border.all(
                                color: AppTheme.primaryCobalt,
                                width: 2,
                              ),
                            ),
                          ),
                          errorPinTheme: PinTheme(
                            width: 50,
                            height: 56,
                            textStyle: const TextStyle(
                              fontSize: AppTheme.fontSizeTitle,
                              fontWeight: AppTheme.fontWeightSemiBold,
                              color: AppTheme.error,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentRedPale.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMedium,
                              ),
                              border: Border.all(color: AppTheme.error),
                            ),
                          ),
                          onCompleted: (_) => _handleVerifyOtp(),
                          keyboardType: TextInputType.number,
                          autofocus: true,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXLarge),

                      // Verify Button
                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleVerifyOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryCobalt,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppTheme.primaryCobalt
                                .withOpacity(0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMedium,
                              ),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Verify OTP',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeLarge,
                              fontWeight: AppTheme.fontWeightSemiBold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingLarge),

                      // Resend OTP
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Didn't receive code? ",
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeMedium,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          TextButton(
                            onPressed: _canResend && !isLoading
                                ? _handleResendOtp
                                : null,
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primaryCobalt,
                              disabledForegroundColor: AppTheme.textMuted,
                            ),
                            child: Text(
                              _canResend
                                  ? 'Resend OTP'
                                  : 'Resend in ${_resendCountdown}s',
                              style: const TextStyle(
                                fontWeight: AppTheme.fontWeightSemiBold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingLarge),

                      // Change email
                      Center(
                        child: TextButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.edit,
                            size: 18,
                            color: AppTheme.textSecondary,
                          ),
                          label: const Text(
                            'Change email address',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeMedium,
                              color: AppTheme.textSecondary,
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
        },
      ),
    );
  }
}
