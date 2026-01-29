import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/features/auth/domain/entities/ministry.dart';
import 'package:sewa_web/features/super_admin/presentation/bloc/ministry_bloc.dart';
import 'package:sewa_web/features/super_admin/presentation/pages/ministries/widgets/ministries_table.dart';
import 'package:sewa_web/features/super_admin/presentation/pages/ministries/widgets/ministry_shared_widgets.dart';

/// Active Ministries Tab
class ActiveMinistriesTab extends StatelessWidget {
  final VoidCallback onRefresh;

  const ActiveMinistriesTab({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MinistryBloc, MinistryState>(
      builder: (context, state) {
        if (state is MinistryLoading) {
          return const LoadingView();
        }

        if (state is MinistryOperationError && state is! MinistryLoaded) {
          return ErrorView(message: state.message, onRetry: onRefresh);
        }

        // Get ministries from various states
        List<Ministry> ministries = [];
        bool isRefreshing = false;

        if (state is MinistryLoaded) {
          ministries = state.ministries;
        } else if (state is MinistryRefreshing) {
          ministries = state.ministries;
          isRefreshing = true;
        } else if (state is MinistryUpdating) {
          ministries = state.ministries;
        } else if (state is MinistryCreating) {
          ministries = state.ministries;
        }

        if (ministries.isEmpty && !isRefreshing) {
          return EmptyView(
            icon: Icons.account_balance_outlined,
            title: 'No ministries yet',
            subtitle: 'Get started by adding your first ministry',
            actionLabel: 'Add Ministry',
            onAction: () => showCreateMinistryDialog(context),
          );
        }

        return Stack(
          children: [
            MinistriesTable(ministries: ministries, isDeleted: false),
            if (isRefreshing)
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(15),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryCobalt,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Refreshing...',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
