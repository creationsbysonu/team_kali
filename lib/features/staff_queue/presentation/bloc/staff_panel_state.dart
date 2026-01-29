part of 'staff_panel_bloc.dart';

/// Staff Panel State
class StaffPanelState extends Equatable {
  // Service information
  final String? staffServiceId;
  final String? serviceName;

  // Current tab (0: Active, 1: All, 2: Pending)
  final int currentTab;

  // Initialization flag
  final bool isInitialized;

  // Loading states
  final bool isLoading;
  final bool isLoadingActive;
  final bool isLoadingAll;
  final bool isLoadingPending;

  // Data
  final ActiveTokensData? activeTokensData;
  final AllTokensData? allTokensData;
  final PendingTokensData? pendingTokensData;

  // Error states
  final String? activeTokensError;
  final String? allTokensError;
  final String? pendingTokensError;

  // Action states
  final bool isPerformingAction;
  final String? actionTokenId;
  final String? actionError;
  final String? actionSuccess;

  const StaffPanelState({
    this.staffServiceId,
    this.serviceName,
    this.currentTab = 0,
    this.isInitialized = false,
    this.isLoading = false,
    this.isLoadingActive = false,
    this.isLoadingAll = false,
    this.isLoadingPending = false,
    this.activeTokensData,
    this.allTokensData,
    this.pendingTokensData,
    this.activeTokensError,
    this.allTokensError,
    this.pendingTokensError,
    this.isPerformingAction = false,
    this.actionTokenId,
    this.actionError,
    this.actionSuccess,
  });

  /// Get active tokens count
  int get activeTokensCount => activeTokensData?.tokens.length ?? 0;

  /// Get all tokens count
  int get allTokensCount => allTokensData?.tokens.length ?? 0;

  /// Get pending tokens count
  int get pendingTokensCount => pendingTokensData?.tokens.length ?? 0;

  /// Get current serving token number
  int get currentServing => activeTokensData?.currentServing ?? 0;

  /// Get total waiting count
  int get totalWaiting => activeTokensData?.totalWaiting ?? 0;

  /// Get total in service count
  int get totalInService => activeTokensData?.totalInService ?? 0;

  /// Get the token currently being served
  StaffToken? get currentlyServingToken {
    return activeTokensData?.tokens
        .where((t) => t.status == StaffTokenStatus.inService)
        .firstOrNull;
  }

  /// Get waiting tokens
  List<StaffToken> get waitingTokens {
    return activeTokensData?.tokens
            .where((t) => t.status == StaffTokenStatus.waiting)
            .toList() ??
        [];
  }

  /// Check if a specific token is being acted upon
  bool isTokenBeingActedUpon(String tokenId) {
    return isPerformingAction && actionTokenId == tokenId;
  }

  /// Check if there are any errors
  bool get hasActiveError => activeTokensError != null;
  bool get hasAllError => allTokensError != null;
  bool get hasPendingError => pendingTokensError != null;
  bool get hasAnyError => hasActiveError || hasAllError || hasPendingError;

  StaffPanelState copyWith({
    String? staffServiceId,
    String? serviceName,
    int? currentTab,
    bool? isInitialized,
    bool? isLoading,
    bool? isLoadingActive,
    bool? isLoadingAll,
    bool? isLoadingPending,
    ActiveTokensData? activeTokensData,
    AllTokensData? allTokensData,
    PendingTokensData? pendingTokensData,
    String? activeTokensError,
    String? allTokensError,
    String? pendingTokensError,
    bool? isPerformingAction,
    String? actionTokenId,
    String? actionError,
    String? actionSuccess,
  }) {
    return StaffPanelState(
      staffServiceId: staffServiceId ?? this.staffServiceId,
      serviceName: serviceName ?? this.serviceName,
      currentTab: currentTab ?? this.currentTab,
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      isLoadingActive: isLoadingActive ?? this.isLoadingActive,
      isLoadingAll: isLoadingAll ?? this.isLoadingAll,
      isLoadingPending: isLoadingPending ?? this.isLoadingPending,
      activeTokensData: activeTokensData ?? this.activeTokensData,
      allTokensData: allTokensData ?? this.allTokensData,
      pendingTokensData: pendingTokensData ?? this.pendingTokensData,
      activeTokensError: activeTokensError,
      allTokensError: allTokensError,
      pendingTokensError: pendingTokensError,
      isPerformingAction: isPerformingAction ?? this.isPerformingAction,
      actionTokenId: actionTokenId,
      actionError: actionError,
      actionSuccess: actionSuccess,
    );
  }

  @override
  List<Object?> get props => [
    staffServiceId,
    serviceName,
    currentTab,
    isInitialized,
    isLoading,
    isLoadingActive,
    isLoadingAll,
    isLoadingPending,
    activeTokensData,
    allTokensData,
    pendingTokensData,
    activeTokensError,
    allTokensError,
    pendingTokensError,
    isPerformingAction,
    actionTokenId,
    actionError,
    actionSuccess,
  ];
}
