import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/features/staff_queue/domain/entities/staff_token.dart';
import 'package:sewa_web/features/staff_queue/domain/usecases/new_queue_usecases.dart';

part 'staff_panel_event.dart';
part 'staff_panel_state.dart';

/// Convert raw error messages to user-friendly text
String _getUserFriendlyError(String rawError) {
  if (rawError.contains('404')) {
    return 'Queue service not available yet';
  } else if (rawError.contains('401') || rawError.contains('403')) {
    return 'Session expired. Please login again';
  } else if (rawError.contains('500')) {
    return 'Server error. Please try again later';
  } else if (rawError.contains('SocketException') ||
      rawError.contains('connection')) {
    return 'No internet connection';
  }
  return 'Unable to load data';
}

/// Staff Panel BLoC - Manages the staff queue panel with 3 tabs
class StaffPanelBloc extends Bloc<StaffPanelEvent, StaffPanelState> {
  final GetActiveTokensUseCase getActiveTokens;
  final GetAllTokensUseCase getAllTokens;
  final GetPendingTokensUseCase getPendingTokens;
  final StartServiceUseCase startService;
  final MarkNoShowUseCase markNoShow;
  final MarkPendingUseCase markPending;
  final SendPendingEmailUseCase sendPendingEmail;
  final MarkPendingServedUseCase markPendingServed;

  Timer? _autoRefreshTimer;
  String? _currentStaffServiceId;

  StaffPanelBloc({
    required this.getActiveTokens,
    required this.getAllTokens,
    required this.getPendingTokens,
    required this.startService,
    required this.markNoShow,
    required this.markPending,
    required this.sendPendingEmail,
    required this.markPendingServed,
  }) : super(const StaffPanelState()) {
    on<InitializeStaffPanel>(_onInitialize);
    on<LoadActiveTokens>(_onLoadActiveTokens);
    on<LoadAllTokens>(_onLoadAllTokens);
    on<LoadPendingTokens>(_onLoadPendingTokens);
    on<RefreshAllData>(_onRefreshAllData);
    on<StartTokenService>(_onStartTokenService);
    on<MarkTokenNoShow>(_onMarkTokenNoShow);
    on<MarkTokenPending>(_onMarkTokenPending);
    on<SendTokenPendingEmail>(_onSendTokenPendingEmail);
    on<MarkPendingTokenServed>(_onMarkPendingTokenServed);
    on<ChangeTab>(_onChangeTab);
    on<StartAutoRefresh>(_onStartAutoRefresh);
    on<StopAutoRefresh>(_onStopAutoRefresh);
    on<UpdateServiceCountdown>(_onUpdateServiceCountdown);
  }

  Future<void> _onInitialize(
    InitializeStaffPanel event,
    Emitter<StaffPanelState> emit,
  ) async {
    _currentStaffServiceId = event.staffServiceId;
    emit(
      state.copyWith(
        staffServiceId: event.staffServiceId,
        serviceName: event.serviceName,
        isLoading: true,
      ),
    );

    // Load all data initially (auto-refresh will start after successful load)
    add(RefreshAllData());
  }

  Future<void> _onLoadActiveTokens(
    LoadActiveTokens event,
    Emitter<StaffPanelState> emit,
  ) async {
    if (_currentStaffServiceId == null) return;

    emit(state.copyWith(isLoadingActive: true, activeTokensError: null));

    final result = await getActiveTokens(_currentStaffServiceId!);

    result.fold(
      (failure) {
        // Use empty data on error for smooth UI
        const emptyData = ActiveTokensData(
          tokens: [],
          currentServing: 0,
          totalWaiting: 0,
          totalInService: 0,
        );
        emit(
          state.copyWith(
            isLoadingActive: false,
            activeTokensData: state.activeTokensData ?? emptyData,
            activeTokensError: _getUserFriendlyError(failure.message),
          ),
        );
      },
      (data) => emit(
        state.copyWith(
          isLoadingActive: false,
          activeTokensData: data,
          activeTokensError: null,
        ),
      ),
    );
  }

  Future<void> _onLoadAllTokens(
    LoadAllTokens event,
    Emitter<StaffPanelState> emit,
  ) async {
    if (_currentStaffServiceId == null) return;

    emit(state.copyWith(isLoadingAll: true, allTokensError: null));

    final result = await getAllTokens(_currentStaffServiceId!);

    result.fold(
      (failure) {
        // Use empty data on error for smooth UI
        final emptyData = AllTokensData(
          tokens: const [],
          summary: TokensSummary.empty(),
        );
        emit(
          state.copyWith(
            isLoadingAll: false,
            allTokensData: state.allTokensData ?? emptyData,
            allTokensError: _getUserFriendlyError(failure.message),
          ),
        );
      },
      (data) => emit(
        state.copyWith(
          isLoadingAll: false,
          allTokensData: data,
          allTokensError: null,
        ),
      ),
    );
  }

  Future<void> _onLoadPendingTokens(
    LoadPendingTokens event,
    Emitter<StaffPanelState> emit,
  ) async {
    if (_currentStaffServiceId == null) return;

    emit(state.copyWith(isLoadingPending: true, pendingTokensError: null));

    final result = await getPendingTokens(_currentStaffServiceId!);

    result.fold(
      (failure) {
        // Use empty data on error for smooth UI
        const emptyData = PendingTokensData(tokens: []);
        emit(
          state.copyWith(
            isLoadingPending: false,
            pendingTokensData: state.pendingTokensData ?? emptyData,
            pendingTokensError: _getUserFriendlyError(failure.message),
          ),
        );
      },
      (data) => emit(
        state.copyWith(
          isLoadingPending: false,
          pendingTokensData: data,
          pendingTokensError: null,
        ),
      ),
    );
  }

  Future<void> _onRefreshAllData(
    RefreshAllData event,
    Emitter<StaffPanelState> emit,
  ) async {
    if (_currentStaffServiceId == null) return;

    emit(state.copyWith(isLoading: true));

    // Load all three tabs in parallel
    final results = await Future.wait([
      getActiveTokens(_currentStaffServiceId!),
      getAllTokens(_currentStaffServiceId!),
      getPendingTokens(_currentStaffServiceId!),
    ]);

    final activeResult = results[0];
    final allResult = results[1];
    final pendingResult = results[2];

    // Check if any API calls succeeded
    final activeSuccess = activeResult.isRight();
    final allSuccess = allResult.isRight();
    final pendingSuccess = pendingResult.isRight();
    final anySuccess = activeSuccess || allSuccess || pendingSuccess;
    final allFailed = !activeSuccess && !allSuccess && !pendingSuccess;

    // Use empty data when API fails (404) - for development/demo
    const emptyActiveData = ActiveTokensData(
      tokens: [],
      currentServing: 0,
      totalWaiting: 0,
      totalInService: 0,
    );
    final emptyAllData = AllTokensData(
      tokens: const [],
      summary: TokensSummary.empty(),
    );
    const emptyPendingData = PendingTokensData(tokens: []);

    emit(
      state.copyWith(
        isLoading: false,
        isInitialized: true,
        isLoadingActive: false,
        isLoadingAll: false,
        isLoadingPending: false,
        activeTokensData: activeResult.fold(
          (_) => emptyActiveData,
          (data) => data as ActiveTokensData,
        ),
        allTokensData: allResult.fold(
          (_) => emptyAllData,
          (data) => data as AllTokensData,
        ),
        pendingTokensData: pendingResult.fold(
          (_) => emptyPendingData,
          (data) => data as PendingTokensData,
        ),
        activeTokensError: activeSuccess ? null : 'Service unavailable',
        allTokensError: allSuccess ? null : 'Service unavailable',
        pendingTokensError: pendingSuccess ? null : 'Service unavailable',
      ),
    );

    // Only start auto-refresh if at least one API succeeded
    // Stop auto-refresh if all APIs failed (endpoints don't exist yet)
    if (allFailed) {
      add(const StopAutoRefresh());
    } else if (anySuccess && _autoRefreshTimer == null) {
      add(const StartAutoRefresh());
    }
  }

  Future<void> _onStartTokenService(
    StartTokenService event,
    Emitter<StaffPanelState> emit,
  ) async {
    emit(
      state.copyWith(isPerformingAction: true, actionTokenId: event.tokenId),
    );

    final result = await startService(event.tokenId);

    result.fold(
      (failure) => emit(
        state.copyWith(
          isPerformingAction: false,
          actionTokenId: null,
          actionError: failure.message,
        ),
      ),
      (data) {
        emit(
          state.copyWith(
            isPerformingAction: false,
            actionTokenId: null,
            actionError: null,
            actionSuccess: 'Service started for Token #${data.tokenNumber}',
          ),
        );
        // Refresh active tokens
        add(LoadActiveTokens());
      },
    );
  }

  Future<void> _onMarkTokenNoShow(
    MarkTokenNoShow event,
    Emitter<StaffPanelState> emit,
  ) async {
    emit(
      state.copyWith(isPerformingAction: true, actionTokenId: event.tokenId),
    );

    final result = await markNoShow(event.tokenId);

    result.fold(
      (failure) => emit(
        state.copyWith(
          isPerformingAction: false,
          actionTokenId: null,
          actionError: failure.message,
        ),
      ),
      (data) {
        String message;
        if (data.isCancelled) {
          message = 'Token #${data.oldTokenNumber} cancelled due to 2 no-shows';
        } else {
          message =
              'Token #${data.oldTokenNumber} pushed back to #${data.newTokenNumber}. Warning ${data.noShowCount}/2';
        }
        emit(
          state.copyWith(
            isPerformingAction: false,
            actionTokenId: null,
            actionError: null,
            actionSuccess: message,
          ),
        );
        // Refresh active tokens
        add(LoadActiveTokens());
      },
    );
  }

  Future<void> _onMarkTokenPending(
    MarkTokenPending event,
    Emitter<StaffPanelState> emit,
  ) async {
    emit(
      state.copyWith(isPerformingAction: true, actionTokenId: event.tokenId),
    );

    final result = await markPending(
      MarkPendingParams(tokenId: event.tokenId, reason: event.reason),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          isPerformingAction: false,
          actionTokenId: null,
          actionError: failure.message,
        ),
      ),
      (data) {
        emit(
          state.copyWith(
            isPerformingAction: false,
            actionTokenId: null,
            actionError: null,
            actionSuccess: 'Token #${data.tokenNumber} moved to pending queue',
          ),
        );
        // Refresh all data
        add(RefreshAllData());
      },
    );
  }

  Future<void> _onSendTokenPendingEmail(
    SendTokenPendingEmail event,
    Emitter<StaffPanelState> emit,
  ) async {
    emit(
      state.copyWith(isPerformingAction: true, actionTokenId: event.tokenId),
    );

    final result = await sendPendingEmail(event.tokenId);

    result.fold(
      (failure) => emit(
        state.copyWith(
          isPerformingAction: false,
          actionTokenId: null,
          actionError: failure.message,
        ),
      ),
      (_) {
        emit(
          state.copyWith(
            isPerformingAction: false,
            actionTokenId: null,
            actionError: null,
            actionSuccess: 'Pending notification email sent successfully',
          ),
        );
        // Refresh pending tokens
        add(LoadPendingTokens());
      },
    );
  }

  Future<void> _onMarkPendingTokenServed(
    MarkPendingTokenServed event,
    Emitter<StaffPanelState> emit,
  ) async {
    emit(
      state.copyWith(isPerformingAction: true, actionTokenId: event.tokenId),
    );

    final result = await markPendingServed(event.tokenId);

    result.fold(
      (failure) => emit(
        state.copyWith(
          isPerformingAction: false,
          actionTokenId: null,
          actionError: failure.message,
        ),
      ),
      (data) {
        emit(
          state.copyWith(
            isPerformingAction: false,
            actionTokenId: null,
            actionError: null,
            actionSuccess: 'Token #${data.tokenNumber} marked as served',
          ),
        );
        // Refresh all data
        add(RefreshAllData());
      },
    );
  }

  void _onChangeTab(ChangeTab event, Emitter<StaffPanelState> emit) {
    emit(state.copyWith(currentTab: event.tab));
  }

  void _onStartAutoRefresh(
    StartAutoRefresh event,
    Emitter<StaffPanelState> emit,
  ) {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => add(RefreshAllData()),
    );
  }

  void _onStopAutoRefresh(
    StopAutoRefresh event,
    Emitter<StaffPanelState> emit,
  ) {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  void _onUpdateServiceCountdown(
    UpdateServiceCountdown event,
    Emitter<StaffPanelState> emit,
  ) {
    // Update the countdown for a specific token
    if (state.activeTokensData == null) return;

    final updatedTokens = state.activeTokensData!.tokens.map((token) {
      if (token.id == event.tokenId) {
        return token.copyWith(
          serviceTimeRemainingSeconds: event.remainingSeconds,
        );
      }
      return token;
    }).toList();

    emit(
      state.copyWith(
        activeTokensData: ActiveTokensData(
          tokens: updatedTokens,
          currentServing: state.activeTokensData!.currentServing,
          totalWaiting: state.activeTokensData!.totalWaiting,
          totalInService: state.activeTokensData!.totalInService,
        ),
      ),
    );
  }

  @override
  Future<void> close() {
    _autoRefreshTimer?.cancel();
    return super.close();
  }
}
