import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/features/auth/presentation/bloc/auth_bloc.dart';

/// Login types based on role selection
enum LoginType { superAdmin, ministry, staff }

class LoginPage extends StatefulWidget {
  final LoginType loginType;
  final String? placeSlug;
  final String? placeName;
  final String? ministrySlug;
  final String? ministryName;
  final String? ministryLogoUrl;
  final String? serviceSlug;
  final String? serviceName;
  final String? staffName;
  final String? staffImageUrl;
  final VoidCallback? onBackToSelection;

  const LoginPage({
    super.key,
    this.loginType = LoginType.superAdmin,
    this.placeSlug,
    this.placeName,
    this.ministrySlug,
    this.ministryName,
    this.ministryLogoUrl,
    this.serviceSlug,
    this.serviceName,
    this.staffName,
    this.staffImageUrl,
    this.onBackToSelection,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isSuperAdmin => widget.loginType == LoginType.superAdmin;
  bool get _isMinistry => widget.loginType == LoginType.ministry;
  bool get _isStaff => widget.loginType == LoginType.staff;

  Color get _accentColor {
    if (_isSuperAdmin) return AppTheme.accentRed;
    if (_isStaff) return AppTheme.accentGreen;
    return AppTheme.accentBlue;
  }

  String get _title {
    if (_isSuperAdmin) return 'Super Admin Login';
    if (_isStaff) {
      // Show staff name if available
      return widget.staffName ?? widget.serviceName ?? 'Staff Login';
    }
    return widget.ministryName ?? 'Ministry Login';
  }

  String? get _subtitle {
    if (_isSuperAdmin) return null;
    if (_isStaff) {
      // No subtitle for staff - just show staff name as title
      return null;
    }
    if (_isMinistry && widget.placeName != null) {
      return widget.placeName;
    }
    return null;
  }

  /// Build the logo widget - shows ministry logo or fallback icon
  Widget _buildLogo() {
    // Super Admin - show admin icon
    if (_isSuperAdmin) {
      return const Icon(
        Icons.admin_panel_settings,
        size: 64,
        color: AppTheme.accentRed,
      );
    }

    // Staff - show staff avatar or person icon
    if (_isStaff) {
      if (widget.staffImageUrl != null && widget.staffImageUrl!.isNotEmpty) {
        return SizedBox(
          width: 64,
          height: 64,
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl: widget.staffImageUrl!,
              fit: BoxFit.contain,
              width: 64,
              height: 64,
              placeholder: (context, url) => Container(
                color: AppTheme.accentGreen.withAlpha(10),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.accentGreen,
                    ),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: AppTheme.accentGreen.withAlpha(10),
                child: const Icon(
                  Icons.person,
                  size: 32,
                  color: AppTheme.accentGreen,
                ),
              ),
            ),
          ),
        );
      }
      return const Icon(Icons.person, size: 64, color: AppTheme.accentGreen);
    }

    // Ministry with logo - show the logo in circular shape
    if (widget.ministryLogoUrl != null && widget.ministryLogoUrl!.isNotEmpty) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppTheme.accentBlue.withAlpha(25),
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: widget.ministryLogoUrl!,
            fit: BoxFit.contain,
            width: 56,
            height: 56,
            placeholder: (context, url) => const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.accentBlue,
                ),
              ),
            ),
            errorWidget: (context, url, error) => const Icon(
              Icons.account_balance,
              size: 28,
              color: AppTheme.accentBlue,
            ),
          ),
        ),
      );
    }

    // Ministry without logo - show fallback icon
    return const Icon(
      Icons.account_balance,
      size: 64,
      color: AppTheme.accentBlue,
    );
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        LoginEvent(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          placeSlug: _isSuperAdmin ? null : widget.placeSlug,
          ministrySlug: _isSuperAdmin ? null : widget.ministrySlug,
          serviceSlug: _isStaff ? widget.serviceSlug : null,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryCobaltDark,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.negative,
              ),
            );
          }
        },
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: 400,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Back button
                        if (widget.onBackToSelection != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              onPressed: widget.onBackToSelection,
                              icon: const Icon(Icons.arrow_back),
                              tooltip: 'Back',
                            ),
                          ),

                        // Logo/Icon
                        _buildLogo(),
                        const SizedBox(height: 16),
                        Text(
                          _title,
                          style: AppTheme.headingMedium().copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _subtitle!,
                            style: AppTheme.bodyMedium().copyWith(
                              color: AppTheme.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 32),

                        // Email field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _handleLogin(),
                        ),
                        const SizedBox(height: 24),

                        // Login button
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            final isLoading = state is AuthLoading;
                            return ElevatedButton(
                              onPressed: isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accentColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Login',
                                      style: TextStyle(fontSize: 16),
                                    ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
