import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/core/di/injection_container.dart';
import 'package:sewa_web/core/routes/route_names.dart';
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/core/utils/responsive_helper.dart';
import 'package:sewa_web/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sewa_web/features/queue_management/presentation/bloc/queue_config_bloc.dart';

/// Queue Configuration Page - Ministry Admin configures queue settings
class QueueConfigurationPage extends StatelessWidget {
  const QueueConfigurationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final authState = context.read<AuthBloc>().state;
        String? ministryId;
        if (authState is Authenticated) {
          ministryId = authState.user.ministry?.id;
        }
        return sl<QueueConfigBloc>()
          ..add(LoadQueueConfigsEvent(ministryId: ministryId ?? ''));
      },
      child: const _QueueConfigPageContent(),
    );
  }
}

class _QueueConfigPageContent extends StatelessWidget {
  const _QueueConfigPageContent();

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return BlocSelector<QueueConfigBloc, QueueConfigState, bool>(
      selector: (state) => state is QueueConfigOperationInProgress,
      builder: (context, isOperationInProgress) {
        return Stack(
          children: [
            Scaffold(
              backgroundColor: AppTheme.background,
              body: Padding(
                padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, isMobile),
                    const SizedBox(height: 24),
                    Expanded(child: _buildConfigList(context, isMobile)),
                  ],
                ),
              ),
            ),
            // Blur loading overlay for operations
            if (isOperationInProgress)
              Positioned.fill(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                    child: Container(
                      color: Colors.white.withOpacity(0.3),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primaryCobalt,
                                  ),
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Saving configuration...',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF374151),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Queue Configuration',
                style: TextStyle(
                  fontSize: isMobile ? 24 : 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Configure office hours, documents, and booking options for each service',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfigList(BuildContext context, bool isMobile) {
    return BlocConsumer<QueueConfigBloc, QueueConfigState>(
      listener: (context, state) {
        if (state is QueueConfigOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Text(state.message),
                ],
              ),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          // Reload configs after successful operation
          final authState = context.read<AuthBloc>().state;
          if (authState is Authenticated) {
            context.read<QueueConfigBloc>().add(
              LoadQueueConfigsEvent(
                ministryId: authState.user.ministry?.id ?? '',
              ),
            );
          }
        } else if (state is QueueConfigError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              action: state.canRetry
                  ? SnackBarAction(
                      label: 'Retry',
                      textColor: Colors.white,
                      onPressed: () {
                        context.read<QueueConfigBloc>().add(
                          const RetryLastEventEvent(),
                        );
                      },
                    )
                  : null,
            ),
          );
        }
      },
      builder: (context, state) {
        // Show loading indicator only on initial load
        if (state is QueueConfigLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.secondary),
          );
        }

        // Loading with previous data - show shimmer overlay on existing data
        if (state is QueueConfigsLoading) {
          if (state.previousServices != null &&
              state.previousServices!.isNotEmpty) {
            return Stack(
              children: [
                _buildServicesGrid(
                  context,
                  state.previousServices!,
                  state.previousConfigExists ?? {},
                  isMobile,
                ),
                // Subtle loading indicator
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryCobalt.withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            );
          }
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.secondary),
          );
        }

        if (state is QueueConfigsLoaded) {
          if (state.services.isEmpty) {
            return _buildEmptyState();
          }
          return _buildServicesGrid(
            context,
            state.services,
            state.configExists,
            isMobile,
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildServicesGrid(
    BuildContext context,
    List<dynamic> services,
    Map<String, bool> configExists,
    bool isMobile,
  ) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile
            ? 1
            : (ResponsiveHelper.isTablet(context) ? 2 : 3),
        childAspectRatio: isMobile ? 3.5 : 1.4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        final serviceId = service['id'].toString();
        final isConfigured = configExists[serviceId] ?? false;
        return _buildServiceCard(context, service, isConfigured, isMobile);
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings_outlined, size: 64, color: AppTheme.textMuted),
          SizedBox(height: 16),
          Text(
            'No services found',
            style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
          ),
          SizedBox(height: 8),
          Text(
            'Create services first before configuring queues',
            style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context,
    dynamic service,
    bool isConfigured,
    bool isMobile,
  ) {
    final serviceLogo =
        service['service_logo_url']?.toString() ??
        service['service_logo']?.toString();

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Service Name with Logo
            Row(
              children: [
                // Service Logo
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryCobalt.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: serviceLogo != null && serviceLogo.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSmall,
                          ),
                          child: Image.network(
                            serviceLogo,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.medical_services_outlined,
                                  color: AppTheme.primaryCobalt,
                                  size: 24,
                                ),
                          ),
                        )
                      : const Icon(
                          Icons.medical_services_outlined,
                          color: AppTheme.primaryCobalt,
                          size: 24,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    service['service_name']?.toString() ??
                        service['name']?.toString() ??
                        'Unnamed Service',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isConfigured
                    ? AppTheme.success.withOpacity(0.1)
                    : AppTheme.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(
                  color: isConfigured ? AppTheme.success : AppTheme.warning,
                ),
              ),
              child: Text(
                isConfigured ? 'CONFIGURED' : 'NOT CONFIGURED',
                style: TextStyle(
                  color: isConfigured ? AppTheme.success : AppTheme.warning,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const Spacer(),
            const SizedBox(height: 16),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.pushNamed(
                    context,
                    RouteNames.ministryQueueConfigEdit,
                    arguments: {
                      'service': service,
                      'isConfigured': isConfigured,
                    },
                  );

                  // Reload configs if operation was successful
                  if (result == true && context.mounted) {
                    final authState = context.read<AuthBloc>().state;
                    if (authState is Authenticated) {
                      context.read<QueueConfigBloc>().add(
                        LoadQueueConfigsEvent(
                          ministryId: authState.user.ministry?.id ?? '',
                        ),
                      );
                    }
                  }
                },
                icon: Icon(isConfigured ? Icons.edit : Icons.add, size: 18),
                label: Text(
                  isConfigured ? 'Edit Config' : 'Configure',
                  style: const TextStyle(fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryCobalt,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
