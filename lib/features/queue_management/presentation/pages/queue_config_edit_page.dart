import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/core/di/injection_container.dart';
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/core/utils/responsive_helper.dart';
import 'package:sewa_web/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sewa_web/features/officials/presentation/bloc/officials_bloc.dart';
import 'package:sewa_web/features/queue_management/domain/entities/queue_configuration.dart';
import 'package:sewa_web/features/queue_management/presentation/bloc/queue_config_bloc.dart';
import 'package:sewa_web/features/queue_management/presentation/widgets/queue_config/queue_config.dart';

/// Queue Configuration Edit Page - Full form for creating/editing queue config
///
/// This page uses the extracted widget components for each configuration section.
/// The [QueueConfigFormData] class manages all form state and is shared via
/// [ListenableBuilder] for reactive updates.
class QueueConfigEditPage extends StatelessWidget {
  final Map<String, dynamic>? service;
  final bool isConfigured;

  const QueueConfigEditPage({
    super.key,
    required this.service,
    this.isConfigured = false,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) {
            final bloc = sl<QueueConfigBloc>();
            // If already configured, fetch the config on page load
            if (isConfigured && service != null) {
              final staffServiceId = service!['id']?.toString() ?? '';
              bloc.add(
                LoadConfigByServiceEvent(staffServiceId: staffServiceId),
              );
            }
            return bloc;
          },
        ),
        BlocProvider(
          create: (context) {
            final authState = context.read<AuthBloc>().state;
            String? ministryId;
            if (authState is Authenticated) {
              ministryId = authState.user.ministry?.id;
            }
            return sl<OfficialsBloc>()
              ..add(LoadOfficialsEvent(ministryId: ministryId ?? ''));
          },
        ),
      ],
      child: _QueueConfigEditContent(
        service: service,
        isConfigured: isConfigured,
      ),
    );
  }
}

class _QueueConfigEditContent extends StatefulWidget {
  final Map<String, dynamic>? service;
  final bool isConfigured;

  const _QueueConfigEditContent({
    required this.service,
    required this.isConfigured,
  });

  @override
  State<_QueueConfigEditContent> createState() =>
      _QueueConfigEditContentState();
}

class _QueueConfigEditContentState extends State<_QueueConfigEditContent> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  QueueConfigFormData? _formData;
  bool _isLoading = false;
  QueueConfiguration? _loadedConfig;

  bool get isEditing => widget.isConfigured;

  String get serviceName =>
      widget.service?['service_name']?.toString() ??
      widget.service?['name']?.toString() ??
      'Service';

  @override
  void initState() {
    super.initState();
    // If not configured, initialize empty form data immediately
    if (!widget.isConfigured) {
      _formData = QueueConfigFormData();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _formData?.dispose();
    super.dispose();
  }

  void _initFormDataFromConfig(QueueConfiguration config) {
    _loadedConfig = config;
    _formData?.dispose();
    _formData = QueueConfigFormData.fromConfig(config);
    setState(() {});
  }

  void _handleSave() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isLoading) return;
    if (_formData == null) return;

    setState(() => _isLoading = true);

    final staffServiceId = widget.service?['id']?.toString() ?? '';
    final configData = _formData!.toApiMap(staffServiceId);

    if (isEditing && _loadedConfig != null) {
      context.read<QueueConfigBloc>().add(
        UpdateConfigEvent(configId: _loadedConfig!.id, configData: configData),
      );
    } else {
      context.read<QueueConfigBloc>().add(
        CreateConfigEvent(configData: configData),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return BlocListener<QueueConfigBloc, QueueConfigState>(
      listener: (context, state) {
        // Handle config loaded - initialize form data
        if (state is QueueConfigLoaded) {
          _initFormDataFromConfig(state.config);
        } else if (state is QueueConfigNotFound) {
          // Config doesn't exist, initialize empty form
          _formData = QueueConfigFormData();
          setState(() {});
        } else if (state is QueueConfigOperationSuccess) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(state.message),
                ],
              ),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
          // Navigate back with success result
          Navigator.of(context).pop(true);
        } else if (state is QueueConfigOperationError) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: _handleSave,
              ),
            ),
          );
        } else if (state is QueueConfigOperationInProgress) {
          // Update loading state with operation message
          setState(() => _isLoading = true);
        } else if (state is QueueConfigError) {
          // Error loading config
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: AppTheme.background,
            body: Column(
              children: [
                _buildHeader(context, isMobile),
                Expanded(
                  child: _formData == null
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.secondary,
                          ),
                        )
                      : SingleChildScrollView(
                          controller: _scrollController,
                          padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                          child: Form(
                            key: _formKey,
                            child: ListenableBuilder(
                              listenable: _formData!,
                              builder: (context, _) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Office Hours Section
                                    OfficeHoursSection(
                                      formData: _formData!,
                                      isMobile: isMobile,
                                    ),
                                    const SizedBox(height: 24),

                                    // Documents Section
                                    DocumentsSection(
                                      formData: _formData!,
                                      isMobile: isMobile,
                                    ),
                                    const SizedBox(height: 24),

                                    // Prebooking Section
                                    PrebookingSection(
                                      formData: _formData!,
                                      isMobile: isMobile,
                                    ),
                                    const SizedBox(height: 24),

                                    // Emergency Section
                                    EmergencySection(
                                      formData: _formData!,
                                      isMobile: isMobile,
                                    ),
                                    const SizedBox(height: 24),

                                    // Higher Officials Section
                                    HigherOfficialsSection(
                                      formData: _formData!,
                                      isMobile: isMobile,
                                    ),
                                    const SizedBox(height: 24),

                                    // Progress Steps Section
                                    ProgressStepsSection(
                                      formData: _formData!,
                                      isMobile: isMobile,
                                    ),
                                    const SizedBox(height: 32),

                                    // Action Buttons
                                    _buildActionButtons(context, isMobile),
                                    const SizedBox(height: 24),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),

          // Loading Overlay - Uses BlocBuilder for dynamic messages
          if (_isLoading)
            Positioned.fill(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                    child: Center(
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: BlocBuilder<QueueConfigBloc, QueueConfigState>(
                            builder: (context, state) {
                              String message = 'Processing...';
                              if (state is QueueConfigOperationInProgress) {
                                message = state.message;
                              } else if (isEditing) {
                                message = 'Saving changes...';
                              } else {
                                message = 'Creating configuration...';
                              }
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: CircularProgressIndicator(
                                      color: AppTheme.primaryCobalt,
                                      strokeWidth: 3,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    message,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing
                      ? 'Edit Queue Configuration'
                      : 'New Queue Configuration',
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  serviceName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.textSecondary,
            side: BorderSide(color: Colors.grey[300]!),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryCobalt,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          ),
          child: Text(isEditing ? 'Save Changes' : 'Create Configuration'),
        ),
      ],
    );
  }
}
