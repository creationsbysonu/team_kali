import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_sathi/core/theme/theme.dart';
import 'package:sewa_sathi/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sewa_sathi/features/auth/presentation/pages/otp_page.dart';
import 'package:sewa_sathi/features/auth/presentation/widgets/auth_loading_overlay.dart';

/// Email input page for OTP authentication.
class EmailPage extends StatefulWidget {
  const EmailPage({super.key});

  @override
  State<EmailPage> createState() => _EmailPageState();
}

class _EmailPageState extends State<EmailPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  void _handleRequestOtp() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(
      RequestOtpEvent(email: _emailController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      // Only listen when transitioning TO these states (not when already in them)
      listenWhen: (previous, current) {
        // Navigate to OTP only when transitioning from non-OtpSent to OtpSent
        if (current is OtpSent && previous is! OtpSent) return true;
        // Show error only when transitioning to AuthError
        if (current is AuthError) return true;
        return false;
      },
      listener: (context, state) {
        if (state is OtpSent) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpPage(email: state.email),
            ),
          );
        } else if (state is AuthError) {
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
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spacingLarge),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 60),

                        // Logo/Icon
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusXLarge,
                            ),
                            boxShadow: AppTheme.shadowMedium,
                          ),
                          child: const Icon(
                            Icons.handshake_outlined,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXLarge),

                        // Title
                        const Text(
                          'Welcome to',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeLarge,
                            color: AppTheme.textSecondary,
                            fontWeight: AppTheme.fontWeightMedium,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTheme.spacingXSmall),
                        const Text(
                          'Sewa Sathi',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeDisplay,
                            fontWeight: AppTheme.fontWeightBold,
                            color: AppTheme.primaryCobalt,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTheme.spacingSmall),

                        // Subtitle
                        const Text(
                          'Your Government Services Companion',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeMedium,
                            color: AppTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 60),

                        // Email Input
                        const Text(
                          'Enter your email to continue',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeMedium,
                            fontWeight: AppTheme.fontWeightSemiBold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingMedium),

                        TextFormField(
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleRequestOtp(),
                          decoration: InputDecoration(
                            hintText: 'you@example.com',
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: AppTheme.primaryCobalt,
                            ),
                            filled: true,
                            fillColor: AppTheme.primaryCobaltPale.withOpacity(
                              0.3,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMedium,
                              ),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMedium,
                              ),
                              borderSide: const BorderSide(
                                color: AppTheme.borderColor,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMedium,
                              ),
                              borderSide: const BorderSide(
                                color: AppTheme.primaryCobalt,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMedium,
                              ),
                              borderSide: const BorderSide(
                                color: AppTheme.error,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMedium,
                              ),
                              borderSide: const BorderSide(
                                color: AppTheme.error,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingMedium,
                              vertical: AppTheme.spacingMedium,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!EmailValidator.validate(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppTheme.spacingLarge),

                        // Continue Button
                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _handleRequestOtp,
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
                              'Continue',
                              style: TextStyle(
                                fontSize: AppTheme.fontSizeLarge,
                                fontWeight: AppTheme.fontWeightSemiBold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXLarge),

                        // Info text
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacingMedium),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryCobaltPale.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMedium,
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppTheme.primaryCobalt,
                                size: 20,
                              ),
                              SizedBox(width: AppTheme.spacingSmall),
                              Expanded(
                                child: Text(
                                  'We\'ll send a 6-digit OTP to verify your email',
                                  style: TextStyle(
                                    fontSize: AppTheme.fontSizeSmall,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
