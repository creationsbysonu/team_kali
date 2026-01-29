import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/features/auth/domain/entities/ministry.dart';

/// Ministry List Page - Shows all ministries fetched from backend
/// Route: /ministries
class MinistryListPage extends StatelessWidget {
  final List<Ministry> ministries;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final Function(String ministrySlug, String ministryName, String? logoUrl)
  onMinistrySelected;
  final VoidCallback onBack;

  const MinistryListPage({
    super.key,
    required this.ministries,
    required this.onMinistrySelected,
    required this.onBack,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryCobaltDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: onBack,
        ),
        title: const Text(
          'Select Your Ministry',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.white.withAlpha(180),
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (onRetry != null)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
          ],
        ),
      );
    }

    if (ministries.isEmpty) {
      return const Center(
        child: Text(
          'No ministries found',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: ministries.length,
          itemBuilder: (context, index) {
            final ministry = ministries[index];
            return _MinistryCard(
              ministry: ministry,
              onTap: () => onMinistrySelected(
                ministry.slug,
                ministry.name,
                ministry.logoUrl,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MinistryCard extends StatelessWidget {
  final Ministry ministry;
  final VoidCallback onTap;

  const _MinistryCard({required this.ministry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Ministry logo with CachedNetworkImage for better loading
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ministry.hasLogo
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: ministry.logoUrl!,
                          fit: BoxFit.cover,
                          width: 56,
                          height: 56,
                          placeholder: (context, url) => const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.accentBlue,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.account_balance,
                            color: AppTheme.accentBlue,
                            size: 28,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.account_balance,
                        color: AppTheme.accentBlue,
                        size: 28,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ministry.name,
                      style: AppTheme.bodyLarge().copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ministry.status,
                      style: AppTheme.bodySmall().copyWith(
                        color: ministry.isActive
                            ? AppTheme.success
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
