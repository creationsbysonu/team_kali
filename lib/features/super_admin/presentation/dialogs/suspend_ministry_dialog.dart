import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/features/auth/domain/entities/ministry.dart';
import 'package:sewa_web/features/super_admin/presentation/bloc/ministry_bloc.dart';

/// Dialog to suspend a ministry with inline loading
class SuspendMinistryDialog extends StatefulWidget {
  final Ministry ministry;

  const SuspendMinistryDialog({super.key, required this.ministry});

  @override
  State<SuspendMinistryDialog> createState() => _SuspendMinistryDialogState();
}

class _SuspendMinistryDialogState extends State<SuspendMinistryDialog> {
  final _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _handleSuspend() {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    context.read<MinistryBloc>().add(
      SuspendMinistryEvent(
        ministryId: widget.ministry.id,
        reason: _reasonController.text.isEmpty ? null : _reasonController.text,
      ),
    );
  }

  void _showSuccess(String name) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.pause_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text('Ministry "$name" has been suspended.'),
          ],
        ),
        backgroundColor: AppTheme.warning,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showError(String message) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MinistryBloc, MinistryState>(
      listener: (context, state) {
        if (state is MinistrySuspended) {
          _showSuccess(state.ministry.name);
        } else if (state is MinistryOperationError) {
          _showError(state.message);
        }
      },
      child: PopScope(
        canPop: !_isLoading,
        child: AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.pause_circle, color: Colors.orange),
              const SizedBox(width: 12),
              Expanded(child: Text('Suspend ${widget.ministry.name}?')),
              if (_isLoading) ...[
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
          content: AbsorbPointer(
            absorbing: _isLoading,
            child: Opacity(
              opacity: _isLoading ? 0.6 : 1.0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This ministry will not be able to login while suspended.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Reason (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSuspend,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warning,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Suspend'),
            ),
          ],
        ),
      ),
    );
  }
}
