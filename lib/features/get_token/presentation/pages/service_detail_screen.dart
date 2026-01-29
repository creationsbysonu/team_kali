import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sewa_sathi/core/di/injection_container.dart';
import 'package:sewa_sathi/core/theme/theme.dart';
import 'package:sewa_sathi/features/get_token/domain/entities/staff_service_entity.dart';
import 'package:sewa_sathi/features/get_token/domain/entities/queue_config_entity.dart';
import 'package:sewa_sathi/features/get_token/presentation/bloc/get_token_bloc.dart';
import 'package:sewa_sathi/features/get_token/presentation/widgets/availability_badge.dart';

/// Screen for displaying service details and booking token.
class ServiceDetailScreen extends StatelessWidget {
  final StaffServiceEntity service;

  const ServiceDetailScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<GetTokenBloc>()
            ..add(LoadServiceDetailsEvent(serviceId: service.id)),
      child: _ServiceDetailView(service: service),
    );
  }
}

class _ServiceDetailView extends StatefulWidget {
  final StaffServiceEntity service;

  const _ServiceDetailView({required this.service});

  @override
  State<_ServiceDetailView> createState() => _ServiceDetailViewState();
}

class _ServiceDetailViewState extends State<_ServiceDetailView> {
  String _selectedBookingType = 'regular';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: BlocConsumer<GetTokenBloc, GetTokenState>(
        listener: (context, state) {
          if (state is TokenBooked) {
            _showBookingSuccessDialog(
              context,
              state.token.tokenNumber.toString(),
            );
          } else if (state is GetTokenError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is GetTokenLoading) {
            return const _LoadingView();
          }

          if (state is GetTokenError && state is! ServiceDetailsLoaded) {
            return _ErrorView(
              message: state.message,
              onRetry: () {
                context.read<GetTokenBloc>().add(
                  LoadServiceDetailsEvent(serviceId: widget.service.id),
                );
              },
            );
          }

          if (state is ServiceDetailsLoaded) {
            return Stack(
              children: [
                _ServiceDetailContent(
                  service: widget.service,
                  config: state.config,
                  selectedBookingType: _selectedBookingType,
                  onBookingTypeChanged: (type) {
                    setState(() => _selectedBookingType = type);
                  },
                  onBookToken: () => _bookToken(context, state.config),
                  isBooking: false,
                ),
                if (state.config.availabilityStatus.isAcceptingTokens)
                  _BookTokenButton(
                    onPressed: () => _bookToken(context, state.config),
                    isLoading: false,
                  ),
              ],
            );
          }

          if (state is BookingInProgress) {
            return Stack(
              children: [
                _ServiceDetailContent(
                  service: widget.service,
                  config: state.config,
                  selectedBookingType: _selectedBookingType,
                  onBookingTypeChanged: null,
                  onBookToken: null,
                  isBooking: true,
                ),
                const _BookTokenButton(onPressed: null, isLoading: true),
              ],
            );
          }

          return const _LoadingView();
        },
      ),
    );
  }

  void _bookToken(BuildContext context, QueueConfigEntity config) {
    context.read<GetTokenBloc>().add(
      BookTokenEvent(
        serviceId: widget.service.id,
        bookingType: _selectedBookingType,
      ),
    );
  }

  void _showBookingSuccessDialog(BuildContext context, String tokenNumber) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 64,
                color: Colors.green.shade600,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Token Booked!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your token number is',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '#$tokenNumber',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Done'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              // Navigate to my tokens
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('View My Tokens'),
          ),
        ],
      ),
    );
  }
}

class _ServiceDetailContent extends StatelessWidget {
  final StaffServiceEntity service;
  final QueueConfigEntity config;
  final String selectedBookingType;
  final ValueChanged<String>? onBookingTypeChanged;
  final VoidCallback? onBookToken;
  final bool isBooking;

  const _ServiceDetailContent({
    required this.service,
    required this.config,
    required this.selectedBookingType,
    required this.onBookingTypeChanged,
    required this.onBookToken,
    required this.isBooking,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // App bar
        SliverAppBar(
          expandedHeight: 180,
          pinned: true,
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            background: _ServiceHeader(service: service, config: config),
          ),
          title: Text(
            service.serviceName,
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Availability status
                AvailabilityBadge(
                  status: config.availabilityStatus,
                  showDetails: true,
                ),

                const SizedBox(height: 24),

                // Office hours section
                _SectionCard(
                  title: 'Office Hours',
                  icon: Icons.access_time,
                  child: Column(
                    children: [
                      _InfoRow(
                        label: 'Opening Time',
                        value: config.openingTime.isNotEmpty
                            ? config.openingTime
                            : 'Not specified',
                      ),
                      _InfoRow(
                        label: 'Closing Time',
                        value: config.closingTime.isNotEmpty
                            ? config.closingTime
                            : 'Not specified',
                      ),
                      if (config.hasLunchBreak)
                        _InfoRow(
                          label: 'Lunch Break',
                          value: config.lunchBreak!,
                        ),
                      _InfoRow(
                        label: 'Daily Limit',
                        value: '${config.dailyTokenLimit} tokens',
                      ),
                      _InfoRow(
                        label: 'Avg. Service Time',
                        value: config.averageServiceTimeDisplay.isNotEmpty
                            ? config.averageServiceTimeDisplay
                            : '${config.averageServiceTimeMinutes} minutes',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Required documents section
                if (config.documentsRequired.isNotEmpty)
                  _SectionCard(
                    title: 'Required Documents',
                    icon: Icons.description_outlined,
                    child: Column(
                      children: config.documentsRequired
                          .map((doc) => _DocumentItem(document: doc))
                          .toList(),
                    ),
                  ),

                const SizedBox(height: 16),

                // Process steps section
                if (config.progressSteps.isNotEmpty)
                  _SectionCard(
                    title: 'Service Process',
                    icon: Icons.timeline,
                    child: Column(
                      children: config.progressSteps.asMap().entries.map((e) {
                        return _ProcessStep(
                          step: e.value,
                          index: e.key + 1,
                          isLast: e.key == config.progressSteps.length - 1,
                        );
                      }).toList(),
                    ),
                  ),

                const SizedBox(height: 16),

                // Officials section
                if (config.officials.isNotEmpty)
                  _SectionCard(
                    title: 'Service Officials',
                    icon: Icons.people_outline,
                    child: Column(
                      children: config.officials
                          .map((official) => _OfficialItem(official: official))
                          .toList(),
                    ),
                  ),

                const SizedBox(height: 16),

                // Booking type selection
                if (config.availabilityStatus.isAcceptingTokens)
                  _SectionCard(
                    title: 'Select Booking Type',
                    icon: Icons.confirmation_number_outlined,
                    child: Column(
                      children: [
                        _BookingTypeOption(
                          title: 'Regular',
                          subtitle: 'Standard queue booking',
                          icon: Icons.people_alt_outlined,
                          isSelected: selectedBookingType == 'regular',
                          onTap: onBookingTypeChanged != null
                              ? () => onBookingTypeChanged!('regular')
                              : null,
                        ),
                        if (config.isPrebookingEnabled)
                          _BookingTypeOption(
                            title: 'Pre-book',
                            subtitle: 'Schedule for later',
                            icon: Icons.calendar_today,
                            isSelected: selectedBookingType == 'prebooked',
                            onTap: onBookingTypeChanged != null
                                ? () => onBookingTypeChanged!('prebooked')
                                : null,
                          ),
                        if (config.isEmergencyEnabled)
                          _BookingTypeOption(
                            title: 'Emergency',
                            subtitle: 'Priority service',
                            icon: Icons.bolt,
                            isSelected: selectedBookingType == 'emergency',
                            onTap: onBookingTypeChanged != null
                                ? () => onBookingTypeChanged!('emergency')
                                : null,
                          ),
                      ],
                    ),
                  ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ServiceHeader extends StatelessWidget {
  final StaffServiceEntity service;
  final QueueConfigEntity config;

  const _ServiceHeader({required this.service, required this.config});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.8)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: service.hasLogo
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: CachedNetworkImage(
                          imageUrl: service.serviceLogoUrl!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(
                        Icons.description,
                        color: Colors.white,
                        size: 32,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Served by',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.staffName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentItem extends StatelessWidget {
  final DocumentRequired document;

  const _DocumentItem({required this.document});

  /// Check if the image URL is a base64 data URI
  bool get _isBase64Image {
    final url = document.sampleImageUrl;
    return url != null && url.startsWith('data:image');
  }

  /// Get base64 data from data URI
  String? get _base64Data {
    final url = document.sampleImageUrl;
    if (url == null || !url.contains(',')) return null;
    return url.split(',').last;
  }

  void _viewSampleDocument(BuildContext context) {
    if (!document.hasSample) return;

    if (_isBase64Image) {
      // Show base64 image in a dialog
      _showImageDialog(context);
    } else {
      // Open URL in browser
      _openUrlInBrowser(context);
    }
  }

  void _showImageDialog(BuildContext context) {
    final base64Data = _base64Data;
    if (base64Data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not load the document image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with title and close button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      document.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // Image content
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.memory(
                    base64Decode(base64Data),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.broken_image_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Could not load image',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrlInBrowser(BuildContext context) async {
    final url = document.sampleImageUrl;
    if (url == null) return;

    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open the document'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            document.isRequired
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            size: 18,
            color: document.isRequired ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (document.description != null)
                  Text(
                    document.description!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // View sample button
          if (document.hasSample)
            GestureDetector(
              onTap: () => _viewSampleDocument(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.visibility_outlined,
                      size: 14,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'View',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 8),
          if (document.isRequired)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Required',
                style: TextStyle(fontSize: 10, color: Colors.red.shade700),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProcessStep extends StatelessWidget {
  final ConfigProgressStep step;
  final int index;
  final bool isLast;

  const _ProcessStep({
    required this.step,
    required this.index,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$index',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(width: 2, height: 40, color: Colors.grey.shade300),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (step.description != null)
                  Text(
                    step.description!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OfficialItem extends StatelessWidget {
  final Official official;

  const _OfficialItem({required this.official});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: official.hasImage
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: official.imageUrl!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(Icons.person, size: 24, color: Colors.grey.shade500),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  official.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  official.designation,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (official.isAvailable)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Available',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BookingTypeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  const _BookingTypeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary.withOpacity(0.2)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? AppTheme.primary : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? AppTheme.primary : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primary),
            SizedBox(height: 16),
            Text(
              'Loading service details...',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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

class _BookTokenButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const _BookTokenButton({required this.onPressed, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.primary.withOpacity(0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.confirmation_number_outlined),
                        SizedBox(width: 8),
                        Text(
                          'Book Token',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
