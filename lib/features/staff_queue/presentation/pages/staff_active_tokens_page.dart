import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entities/staff_token.dart';
import '../bloc/staff_panel_bloc.dart';
import '../widgets/mark_pending_dialog.dart';

/// Staff Active Tokens Page - Clean standalone page for managing active tokens
/// Shows tokens currently being served (IN_SERVICE) and waiting queue (WAITING)
class StaffActiveTokensPage extends StatelessWidget {
  const StaffActiveTokensPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StaffPanelBloc, StaffPanelState>(
      listener: (context, state) {
        // Show success message
        if (state.actionSuccess != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.actionSuccess!),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        // Show error message
        if (state.actionError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.actionError!),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.play_circle_outline,
                          color: AppTheme.success,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Tokens',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Colors.grey.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state.serviceName ?? 'Queue Management',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              // Refresh button
              OutlinedButton.icon(
                onPressed: state.isLoading
                    ? null
                    : () => context.read<StaffPanelBloc>().add(
                        LoadActiveTokens(),
                      ),
                icon: state.isLoadingActive
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
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
    if (state.isLoadingActive && state.activeTokensData == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryCobalt),
      );
    }

    final data = state.activeTokensData;

    // Show empty state with error message if available
    if (data == null) {
      return _buildErrorOrEmptyState(
        context,
        state.activeTokensError,
        'No active tokens data available',
      );
    }

    // Split tokens by status
    final servingTokens = data.tokens
        .where((t) => t.status == StaffTokenStatus.inService)
        .toList();
    final waitingTokens = data.tokens
        .where((t) => t.status == StaffTokenStatus.waiting)
        .toList();

    return RefreshIndicator(
      onRefresh: () async {
        context.read<StaffPanelBloc>().add(LoadActiveTokens());
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show error banner if there's an error but we still have data
            if (state.activeTokensError != null)
              _buildErrorBanner(context, state.activeTokensError!),

            // Summary cards row
            _SummaryCardsRow(
              currentServing: data.currentServing,
              totalWaiting: data.totalWaiting,
              totalInService: data.totalInService,
            ),
            const SizedBox(height: 32),

            // Currently Serving Section
            _SectionHeader(
              title: 'Currently Serving',
              subtitle:
                  '${servingTokens.length} token${servingTokens.length != 1 ? 's' : ''}',
              icon: Icons.play_circle_outline,
              iconColor: AppTheme.success,
            ),
            const SizedBox(height: 16),
            if (servingTokens.isEmpty)
              _buildEmptyCard('No tokens currently being served')
            else
              ...servingTokens.map(
                (token) => _CurrentlyServingCard(token: token),
              ),

            const SizedBox(height: 32),

            // Waiting Queue Section
            _SectionHeader(
              title: 'Waiting Queue',
              subtitle:
                  '${waitingTokens.length} token${waitingTokens.length != 1 ? 's' : ''}',
              icon: Icons.hourglass_empty,
              iconColor: AppTheme.warning,
            ),
            const SizedBox(height: 16),
            if (waitingTokens.isEmpty)
              _buildEmptyCard('No tokens waiting')
            else
              ...waitingTokens.map((token) => _WaitingTokenCard(token: token)),
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
                context.read<StaffPanelBloc>().add(LoadActiveTokens()),
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
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _SummaryCardsRow extends StatelessWidget {
  final int currentServing;
  final int totalWaiting;
  final int totalInService;

  const _SummaryCardsRow({
    required this.currentServing,
    required this.totalWaiting,
    required this.totalInService,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Current Token',
            value: currentServing > 0 ? '#$currentServing' : '-',
            icon: Icons.confirmation_number_outlined,
            color: AppTheme.info,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryCard(
            title: 'Waiting',
            value: totalWaiting.toString(),
            icon: Icons.hourglass_empty,
            color: AppTheme.warning,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryCard(
            title: 'In Service',
            value: totalInService.toString(),
            icon: Icons.play_circle_outline,
            color: AppTheme.success,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ],
    );
  }
}

class _CurrentlyServingCard extends StatelessWidget {
  final StaffToken token;

  const _CurrentlyServingCard({required this.token});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.success.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.success.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with token info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.success,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#${token.tokenNumber}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        token.citizenName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        token.serviceName,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (token.serviceStartedAt != null)
                  _ServiceCountdownTimer(
                    startTime: token.serviceStartedAt!,
                    remainingSeconds: token.serviceTimeRemainingSeconds,
                  ),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (token.canMarkPending) ...[
                  Expanded(
                    child: _ActionButton(
                      label: 'Mark Pending',
                      icon: Icons.pause_circle_outline,
                      color: AppTheme.warning,
                      outlined: true,
                      onPressed: () => _showMarkPendingDialog(context, token),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (token.canMarkNoShow)
                  Expanded(
                    child: _ActionButton(
                      label: 'No Show',
                      icon: Icons.person_off_outlined,
                      color: AppTheme.error,
                      outlined: true,
                      onPressed: () {
                        context.read<StaffPanelBloc>().add(
                          MarkTokenNoShow(tokenId: token.id),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMarkPendingDialog(BuildContext context, StaffToken token) {
    showDialog(
      context: context,
      builder: (dialogContext) => MarkPendingDialog(
        tokenNumber: '#${token.tokenNumber}',
        onConfirm: (reason) {
          context.read<StaffPanelBloc>().add(
            MarkTokenPending(tokenId: token.id, reason: reason),
          );
        },
      ),
    );
  }
}

class _WaitingTokenCard extends StatelessWidget {
  final StaffToken token;

  const _WaitingTokenCard({required this.token});

  @override
  Widget build(BuildContext context) {
    final isMyTurn = token.isMyTurn;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMyTurn
              ? AppTheme.success.withOpacity(0.5)
              : Colors.grey.shade200,
          width: isMyTurn ? 2 : 1,
        ),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isMyTurn
                  ? AppTheme.success.withOpacity(0.1)
                  : AppTheme.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isMyTurn
                    ? AppTheme.success.withOpacity(0.3)
                    : AppTheme.warning.withOpacity(0.3),
              ),
            ),
            child: Text(
              '#${token.tokenNumber}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isMyTurn ? AppTheme.success : Colors.orange.shade700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      token.citizenName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    if (token.hasNoShowWarning) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${token.noShowCount} no-show',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.error,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.work_outline,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      token.serviceName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    if (token.expectedServiceTimeNepal != null) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        token.expectedServiceTimeNepal!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isMyTurn)
            ElevatedButton.icon(
              onPressed: () {
                context.read<StaffPanelBloc>().add(
                  StartTokenService(tokenId: token.id),
                );
              },
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('Start'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )
          else if (token.countdownSeconds != null &&
              token.countdownSeconds! > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatCountdown(token.countdownSeconds!),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatCountdown(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${secs}s';
    }
    return '${secs}s';
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool outlined;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _ServiceCountdownTimer extends StatefulWidget {
  final DateTime startTime;
  final int? remainingSeconds;

  const _ServiceCountdownTimer({
    required this.startTime,
    this.remainingSeconds,
  });

  @override
  State<_ServiceCountdownTimer> createState() => _ServiceCountdownTimerState();
}

class _ServiceCountdownTimerState extends State<_ServiceCountdownTimer> {
  late Timer _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateElapsed();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateElapsed(),
    );
  }

  void _updateElapsed() {
    setState(() {
      _elapsed = DateTime.now().difference(widget.startTime);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOvertime =
        widget.remainingSeconds != null && widget.remainingSeconds! <= 0;
    final color = isOvertime ? AppTheme.error : AppTheme.success;

    final minutes = _elapsed.inMinutes;
    final seconds = _elapsed.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOvertime ? Icons.warning_amber_rounded : Icons.timer_outlined,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
