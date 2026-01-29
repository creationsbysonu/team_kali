import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/core/di/injection_container.dart';
import 'package:sewa_web/core/service/navigation_service.dart';
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/features/auth/presentation/bloc/auth_bloc.dart';

/// Controller for managing current route state across sidebar
class NavigationController extends ValueNotifier<String> {
  static final NavigationController _instance =
      NavigationController._internal();
  factory NavigationController() => _instance;
  NavigationController._internal() : super('/super-admin/places');

  void setCurrentRoute(String route) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (value != route) {
        value = route;
      }
    });
  }
}

/// Professional sidebar with smooth expand/collapse animation
class DashboardSideBar extends StatefulWidget {
  final bool isExpanded;
  final VoidCallback? onToggle;

  const DashboardSideBar({super.key, this.isExpanded = true, this.onToggle});

  @override
  State<DashboardSideBar> createState() => _DashboardSideBarState();
}

class _DashboardSideBarState extends State<DashboardSideBar>
    with SingleTickerProviderStateMixin {
  final NavigationController _controller = sl<NavigationController>();
  final NavigationService _navigationService = sl<NavigationService>();

  late AnimationController _animationController;
  late Animation<double> _widthAnimation;
  late Animation<double> _opacityAnimation;

  static const double _collapsedWidth = 72.0;
  static const double _expandedWidth = 260.0;
  static const double _textFadeThreshold = 0.5;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _widthAnimation = Tween<double>(begin: _collapsedWidth, end: _expandedWidth)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.value = widget.isExpanded ? 1.0 : 0.0;
  }

  @override
  void didUpdateWidget(covariant DashboardSideBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      widget.isExpanded
          ? _animationController.forward()
          : _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool get _isExpanded => _animationController.value > _textFadeThreshold;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: _controller,
      builder: (context, currentRoute, _) {
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, _) {
            return Container(
              width: _widthAnimation.value,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 8,
                    offset: const Offset(2, 0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, authState) {
                        final isSuperAdmin =
                            authState is Authenticated &&
                            authState.user.isSuperAdmin;
                        final isMinistryAdmin =
                            authState is Authenticated &&
                            authState.user.isAdmin;
                        final isStaff =
                            authState is Authenticated &&
                            authState.user.isStaff;

                        return SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_isExpanded) _buildSectionLabel('MANAGEMENT'),
                              const SizedBox(height: 4),

                              // Super Admin only items
                              if (isSuperAdmin) ...[
                                _buildNavItem(
                                  icon: Icons.location_city_outlined,
                                  selectedIcon: Icons.location_city,
                                  label: 'Places',
                                  route: '/super-admin/places',
                                  isSelected:
                                      currentRoute == '/super-admin/places' ||
                                      currentRoute == '/dashboard',
                                ),
                                _buildNavItem(
                                  icon: Icons.account_balance_outlined,
                                  selectedIcon: Icons.account_balance,
                                  label: 'Ministries',
                                  route: '/super-admin/ministries',
                                  isSelected:
                                      currentRoute == '/super-admin/ministries',
                                ),
                              ],

                              // Ministry Admin items
                              if (isMinistryAdmin) ...[
                                _buildNavItem(
                                  icon: Icons.medical_services_outlined,
                                  selectedIcon: Icons.medical_services,
                                  label: 'Services',
                                  route: '/ministry/services',
                                  isSelected:
                                      currentRoute == '/ministry/services',
                                ),
                                _buildNavItem(
                                  icon: Icons.people_outline,
                                  selectedIcon: Icons.people,
                                  label: 'Officials',
                                  route: '/ministry/officials',
                                  isSelected:
                                      currentRoute == '/ministry/officials',
                                ),
                                _buildNavItem(
                                  icon: Icons.calendar_today_outlined,
                                  selectedIcon: Icons.calendar_today,
                                  label: 'Holidays',
                                  route: '/ministry/holidays',
                                  isSelected:
                                      currentRoute == '/ministry/holidays',
                                ),
                                _buildNavItem(
                                  icon: Icons.checklist_outlined,
                                  selectedIcon: Icons.checklist,
                                  label: 'Attendance',
                                  route: '/ministry/attendance',
                                  isSelected:
                                      currentRoute == '/ministry/attendance',
                                ),
                                _buildNavItem(
                                  icon: Icons.queue_outlined,
                                  selectedIcon: Icons.queue,
                                  label: 'Queue Config',
                                  route: '/ministry/queue-config',
                                  isSelected:
                                      currentRoute == '/ministry/queue-config',
                                ),
                                _buildNavItem(
                                  icon: Icons.article_outlined,
                                  selectedIcon: Icons.article,
                                  label: 'Notices',
                                  route: '/ministry/notices',
                                  isSelected:
                                      currentRoute == '/ministry/notices',
                                ),
                              ],

                              // Staff Admin items - 3 separate queue management pages
                              if (isStaff) ...[
                                _buildNavItem(
                                  icon: Icons.play_circle_outline,
                                  selectedIcon: Icons.play_circle,
                                  label: 'Active Tokens',
                                  route: '/staff/active-tokens',
                                  isSelected:
                                      currentRoute == '/staff/active-tokens' ||
                                      currentRoute == '/staff/dashboard' ||
                                      currentRoute == '/dashboard',
                                ),
                                _buildNavItem(
                                  icon: Icons.list_alt_outlined,
                                  selectedIcon: Icons.list_alt,
                                  label: 'All Tokens',
                                  route: '/staff/all-tokens',
                                  isSelected:
                                      currentRoute == '/staff/all-tokens',
                                ),
                                _buildNavItem(
                                  icon: Icons.pending_actions_outlined,
                                  selectedIcon: Icons.pending_actions,
                                  label: 'Pending Tokens',
                                  route: '/staff/pending-tokens',
                                  isSelected:
                                      currentRoute == '/staff/pending-tokens',
                                ),
                                _buildNavItem(
                                  icon: Icons.article_outlined,
                                  selectedIcon: Icons.article,
                                  label: 'Notices',
                                  route: '/staff/notices',
                                  isSelected: currentRoute == '/staff/notices',
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  _buildFooter(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: _isExpanded ? 16 : 0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor.withAlpha(80)),
        ),
      ),
      child: _isExpanded ? _buildExpandedHeader() : _buildCollapsedHeader(),
    );
  }

  Widget _buildExpandedHeader() {
    return Row(
      children: [
        // Logo
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.analytics, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: const Text(
              'Sewa Sathi',
              style: TextStyle(
                color: AppTheme.primaryCobalt,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ),
        // Toggle button - only show when expanded
        if (widget.onToggle != null)
          _ToggleButton(isExpanded: true, onTap: widget.onToggle!),
      ],
    );
  }

  Widget _buildCollapsedHeader() {
    return Center(
      child: GestureDetector(
        onTap: widget.onToggle,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.analytics, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Opacity(
      opacity: _opacityAnimation.value,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
        child: Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required String route,
    required bool isSelected,
  }) {
    return _NavItem(
      icon: icon,
      selectedIcon: selectedIcon,
      label: label,
      isSelected: isSelected,
      isExpanded: _isExpanded,
      opacity: _opacityAnimation.value,
      // Prevent navigation if already on the same route
      onTap: isSelected ? null : () => _navigationService.pushNamed(route),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(_isExpanded ? 16 : 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.borderColor.withAlpha(80)),
        ),
      ),
      child: _isExpanded ? _buildExpandedFooter() : _buildCollapsedFooter(),
    );
  }

  Widget _buildExpandedFooter() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        String displayName = 'Admin';
        String displayRole = 'Administrator';

        if (authState is Authenticated) {
          if (authState.user.isSuperAdmin) {
            displayName = 'Super Admin';
            displayRole = 'Administrator';
          } else if (authState.user.isAdmin) {
            displayName = 'Ministry Admin';
            displayRole = authState.user.ministry?.name ?? 'Ministry';
          } else if (authState.user.isStaff) {
            displayName = 'Staff Admin';
            displayRole = 'Administrator';
          }
        }

        return Opacity(
          opacity: _opacityAnimation.value,
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primaryCobalt.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: AppTheme.primaryCobalt,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      displayRole,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCollapsedFooter() {
    return Center(
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.primaryCobalt.withAlpha(15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.person_outline,
          color: AppTheme.primaryCobalt,
          size: 20,
        ),
      ),
    );
  }
}

/// Professional toggle button with hover effect
class _ToggleButton extends StatefulWidget {
  final bool isExpanded;
  final VoidCallback onTap;

  const _ToggleButton({required this.isExpanded, required this.onTap});

  @override
  State<_ToggleButton> createState() => _ToggleButtonState();
}

class _ToggleButtonState extends State<_ToggleButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _isHovered
                ? AppTheme.primaryCobalt.withAlpha(15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _isHovered
                  ? AppTheme.primaryCobalt.withAlpha(40)
                  : AppTheme.borderColor.withAlpha(80),
            ),
          ),
          child: Icon(
            widget.isExpanded
                ? Icons.chevron_left_rounded
                : Icons.chevron_right_rounded,
            size: 18,
            color: _isHovered ? AppTheme.primaryCobalt : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Navigation item with hover and selected states
class _NavItem extends StatefulWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final bool isExpanded;
  final double opacity;
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.isExpanded,
    required this.opacity,
    this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Don't show hover effect if already selected (no action available)
    final showHover = _isHovered && !widget.isSelected;

    final item = MouseRegion(
      cursor: widget.isSelected
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isExpanded ? 12 : 0,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppTheme.primaryCobalt.withAlpha(12)
                : showHover
                ? AppTheme.primaryCobalt.withAlpha(8)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: widget.isSelected
                ? Border.all(color: AppTheme.primaryCobalt.withAlpha(25))
                : null,
          ),
          child: Row(
            mainAxisAlignment: widget.isExpanded
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Icon(
                widget.isSelected ? widget.selectedIcon : widget.icon,
                size: 20,
                color: widget.isSelected
                    ? AppTheme.primaryCobalt
                    : showHover
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary,
              ),
              if (widget.isExpanded) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Opacity(
                    opacity: widget.opacity,
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        color: widget.isSelected
                            ? AppTheme.primaryCobalt
                            : showHover
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                        fontSize: 14,
                        fontWeight: widget.isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (!widget.isExpanded) {
      return Tooltip(message: widget.label, preferBelow: false, child: item);
    }
    return item;
  }
}
