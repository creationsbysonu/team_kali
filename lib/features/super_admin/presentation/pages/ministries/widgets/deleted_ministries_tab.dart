import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/features/super_admin/presentation/bloc/ministry_bloc.dart';
import 'package:sewa_web/features/super_admin/presentation/pages/ministries/widgets/ministries_table.dart';
import 'package:sewa_web/features/super_admin/presentation/pages/ministries/widgets/ministry_shared_widgets.dart';

/// Deleted Ministries Tab
class DeletedMinistriesTab extends StatelessWidget {
  final VoidCallback onRefresh;

  const DeletedMinistriesTab({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MinistryBloc, MinistryState>(
      builder: (context, state) {
        // Get deleted ministries from bloc's cache
        final deletedMinistries = context
            .read<MinistryBloc>()
            .cachedDeletedMinistries;

        if (state is MinistryLoading || state is MinistryRefreshing) {
          if (deletedMinistries.isEmpty) {
            return const LoadingView();
          }
        }

        if (deletedMinistries.isEmpty) {
          return const EmptyView(
            icon: Icons.delete_outline,
            title: 'No deleted ministries',
            subtitle: 'Deleted ministries will appear here for recovery',
          );
        }

        return MinistriesTable(ministries: deletedMinistries, isDeleted: true);
      },
    );
  }
}
