part of 'staff_panel_bloc.dart';

/// Staff Panel Events
abstract class StaffPanelEvent extends Equatable {
  const StaffPanelEvent();

  @override
  List<Object?> get props => [];
}

/// Initialize the staff panel with service ID
class InitializeStaffPanel extends StaffPanelEvent {
  final String staffServiceId;
  final String serviceName;

  const InitializeStaffPanel({
    required this.staffServiceId,
    required this.serviceName,
  });

  @override
  List<Object?> get props => [staffServiceId, serviceName];
}

/// Load active tokens (WAITING, IN_SERVICE)
class LoadActiveTokens extends StaffPanelEvent {}

/// Load all tokens (complete history)
class LoadAllTokens extends StaffPanelEvent {}

/// Load pending tokens
class LoadPendingTokens extends StaffPanelEvent {}

/// Refresh all data (all three tabs)
class RefreshAllData extends StaffPanelEvent {}

/// Start service for a token
class StartTokenService extends StaffPanelEvent {
  final String tokenId;

  const StartTokenService({required this.tokenId});

  @override
  List<Object?> get props => [tokenId];
}

/// Mark token as no-show
class MarkTokenNoShow extends StaffPanelEvent {
  final String tokenId;

  const MarkTokenNoShow({required this.tokenId});

  @override
  List<Object?> get props => [tokenId];
}

/// Mark token as pending (government fault)
class MarkTokenPending extends StaffPanelEvent {
  final String tokenId;
  final String reason;

  const MarkTokenPending({required this.tokenId, required this.reason});

  @override
  List<Object?> get props => [tokenId, reason];
}

/// Send pending email notification
class SendTokenPendingEmail extends StaffPanelEvent {
  final String tokenId;

  const SendTokenPendingEmail({required this.tokenId});

  @override
  List<Object?> get props => [tokenId];
}

/// Mark pending token as served
class MarkPendingTokenServed extends StaffPanelEvent {
  final String tokenId;

  const MarkPendingTokenServed({required this.tokenId});

  @override
  List<Object?> get props => [tokenId];
}

/// Change current tab
class ChangeTab extends StaffPanelEvent {
  final int tab;

  const ChangeTab({required this.tab});

  @override
  List<Object?> get props => [tab];
}

/// Start auto-refresh timer
class StartAutoRefresh extends StaffPanelEvent {
  const StartAutoRefresh();
}

/// Stop auto-refresh timer
class StopAutoRefresh extends StaffPanelEvent {
  const StopAutoRefresh();
}

/// Update service countdown for a token
class UpdateServiceCountdown extends StaffPanelEvent {
  final String tokenId;
  final int remainingSeconds;

  const UpdateServiceCountdown({
    required this.tokenId,
    required this.remainingSeconds,
  });

  @override
  List<Object?> get props => [tokenId, remainingSeconds];
}
