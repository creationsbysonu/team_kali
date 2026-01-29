// Staff Queue Feature - Barrel Export
// Staff manages daily queue operations - 3 separate pages

// Domain - Entities (New Queue System)
export 'domain/entities/staff_token.dart';

// Domain - Repository
export 'domain/repositories/staff_queue_repository.dart';

// Domain - Use Cases (New Queue System)
export 'domain/usecases/staff_queue_usecases.dart';

// Data - Models (New Queue System)
export 'data/models/staff_token_model.dart';

// Data - Data Sources (New Queue System)
export 'data/data_sources/staff_queue_data_source.dart';

// Data - Repository Implementation
export 'data/repositories/staff_queue_repository_impl.dart';

// Presentation - BLoC (New Queue System)
export 'presentation/bloc/staff_panel_bloc.dart';

// Presentation - Pages (3 separate pages)
export 'presentation/pages/staff_active_tokens_page.dart';
export 'presentation/pages/staff_all_tokens_page.dart';
export 'presentation/pages/staff_pending_tokens_page.dart';

// Presentation - Legacy unified panel (deprecated)
export 'presentation/pages/staff_panel_page.dart';
