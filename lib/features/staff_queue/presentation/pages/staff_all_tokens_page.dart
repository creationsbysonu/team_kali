import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entities/staff_token.dart';
import '../bloc/staff_panel_bloc.dart';

/// Staff All Tokens Page - Clean standalone page for viewing all tokens
/// Shows a read-only table of all today's tokens with their status history
class StaffAllTokensPage extends StatelessWidget {
  const StaffAllTokensPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StaffPanelBloc, StaffPanelState>(
      builder: (context, state) {
        return Container(
          color: Colors.grey.shade50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context, state),
              // Content
              Expanded(child: _buildContent(context, state)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, StaffPanelState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.list_alt_rounded,
                  color: AppTheme.info,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All Tokens',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.serviceName ?? 'Today\'s Complete Token History',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Refresh button
          OutlinedButton.icon(
            onPressed: state.isLoading
                ? null
                : () => context.read<StaffPanelBloc>().add(LoadAllTokens()),
            icon: state.isLoadingAll
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, size: 18),
            label: const Text('Refresh'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryCobalt,
              side: BorderSide(color: Colors.grey.shade300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, StaffPanelState state) {
    // Show loading during initial load
    if (!state.isInitialized && state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryCobalt),
      );
    }

    // Show loading spinner if actively loading and no data yet
    if (state.isLoadingAll && state.allTokensData == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryCobalt),
      );
    }

    final data = state.allTokensData;

    // Show error state if data is null
    if (data == null) {
      return _buildErrorOrEmptyState(
        context,
        state.allTokensError,
        'No tokens data available',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<StaffPanelBloc>().add(LoadAllTokens());
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show error banner if there's an error but we still have data
            if (state.allTokensError != null)
              _buildErrorBanner(context, state.allTokensError!),

            // Summary Row
            _SummaryRow(summary: data.summary),
            const SizedBox(height: 24),

            // Show empty state or tokens table
            if (data.tokens.isEmpty)
              _buildEmptyCard('No tokens found for today')
            else
              _TokensTable(tokens: data.tokens),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, String error) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppTheme.warning,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Unable to refresh: $error',
              style: TextStyle(color: Colors.orange.shade800, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () =>
                context.read<StaffPanelBloc>().add(LoadAllTokens()),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorOrEmptyState(
    BuildContext context,
    String? error,
    String emptyMessage,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            error != null ? Icons.cloud_off : Icons.inbox_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            error ?? emptyMessage,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          if (error != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  context.read<StaffPanelBloc>().add(RefreshAllData()),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryCobalt,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final TokensSummary summary;

  const _SummaryRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _SummaryItem(
            label: 'Total',
            value: summary.total,
            color: AppTheme.info,
          ),
          _divider(),
          _SummaryItem(
            label: 'Waiting',
            value: summary.waiting,
            color: AppTheme.warning,
          ),
          _divider(),
          _SummaryItem(
            label: 'In Service',
            value: summary.inService,
            color: AppTheme.success,
          ),
          _divider(),
          _SummaryItem(
            label: 'Completed',
            value: summary.completed,
            color: Colors.teal,
          ),
          _divider(),
          _SummaryItem(
            label: 'Pending',
            value: summary.pending,
            color: AppTheme.info,
          ),
          _divider(),
          _SummaryItem(
            label: 'Cancelled',
            value: summary.cancelled,
            color: AppTheme.error,
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.grey.shade200,
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _TokensTable extends StatelessWidget {
  final List<StaffToken> tokens;

  const _TokensTable({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: const Row(
              children: [
                _TableHeader('Token', flex: 1),
                _TableHeader('Citizen', flex: 2),
                _TableHeader('Service', flex: 2),
                _TableHeader('Status', flex: 1),
                _TableHeader('Booking', flex: 1),
                _TableHeader('Time', flex: 1),
              ],
            ),
          ),

          // Table body
          ...tokens.map((token) => _TokenRow(token: token)),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String title;
  final int flex;

  const _TableHeader(this.title, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }
}

class _TokenRow extends StatelessWidget {
  final StaffToken token;

  const _TokenRow({required this.token});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          // Token number
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(token.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '#${token.tokenNumber}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _getStatusColor(token.status),
                ),
              ),
            ),
          ),

          // Citizen name
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  token.citizenName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  token.citizenEmail,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),

          // Service name
          Expanded(
            flex: 2,
            child: Text(
              token.serviceName,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ),

          // Status
          Expanded(flex: 1, child: _StatusBadge(status: token.status)),

          // Booking type
          Expanded(flex: 1, child: _BookingTypeBadge(type: token.bookingType)),

          // Created time
          Expanded(
            flex: 1,
            child: Text(
              _formatTime(token.createdAt),
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(StaffTokenStatus status) {
    switch (status) {
      case StaffTokenStatus.waiting:
        return AppTheme.warning;
      case StaffTokenStatus.inService:
        return AppTheme.success;
      case StaffTokenStatus.completed:
        return Colors.teal;
      case StaffTokenStatus.pending:
        return AppTheme.info;
      case StaffTokenStatus.cancelled:
        return AppTheme.error;
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$hour12:$minute $period';
  }
}

class _StatusBadge extends StatelessWidget {
  final StaffTokenStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.displayName.split(' ').first,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getStatusColor(StaffTokenStatus status) {
    switch (status) {
      case StaffTokenStatus.waiting:
        return AppTheme.warning;
      case StaffTokenStatus.inService:
        return AppTheme.success;
      case StaffTokenStatus.completed:
        return Colors.teal;
      case StaffTokenStatus.pending:
        return AppTheme.info;
      case StaffTokenStatus.cancelled:
        return AppTheme.error;
    }
  }
}

class _BookingTypeBadge extends StatelessWidget {
  final StaffBookingType type;

  const _BookingTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _getTypeStyle(type);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          type.displayName.split(' ').first,
          style: TextStyle(fontSize: 12, color: color),
        ),
      ],
    );
  }

  (Color, IconData) _getTypeStyle(StaffBookingType type) {
    switch (type) {
      case StaffBookingType.regular:
        return (Colors.grey.shade600, Icons.person_outline);
      case StaffBookingType.prebooked:
        return (AppTheme.info, Icons.event_available);
      case StaffBookingType.emergency:
        return (AppTheme.error, Icons.priority_high);
    }
  }
}
