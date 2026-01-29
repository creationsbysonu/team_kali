/// Staff Feature - Barrel Export
library staff;

// Domain
export 'domain/entities/staff_member.dart';
export 'domain/repositories/staff_repository.dart';
export 'domain/usecases/staff_usecases.dart';

// Data
export 'data/models/staff_model.dart';
export 'data/data_sources/staff_remote_data_source.dart';
export 'data/repositories/staff_repository_impl.dart';

// Presentation
export 'presentation/bloc/staff_bloc.dart';
export 'presentation/pages/staff_dashboard.dart';
export 'presentation/pages/staff_management_page.dart';