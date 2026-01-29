import 'package:sewa_sathi/features/notice/data/models/ministry_model.dart';
import 'package:sewa_sathi/features/notice/data/models/service_model.dart';
import 'package:sewa_sathi/features/notice/domain/entities/filter_options_entity.dart';

/// Model for FilterOptions with JSON serialization.
class FilterOptionsModel extends FilterOptionsEntity {
  const FilterOptionsModel({
    required super.ministries,
    required super.services,
    required super.fileTypes,
  });

  factory FilterOptionsModel.fromJson(Map<String, dynamic> json) {
    // Parse file_types - API returns objects with 'value' and 'label' keys
    final fileTypesList = (json['file_types'] as List).map((ft) {
      if (ft is String) return ft;
      if (ft is Map<String, dynamic>) return ft['value'] as String;
      return ft.toString();
    }).toList();

    return FilterOptionsModel(
      ministries: (json['ministries'] as List)
          .map((m) => MinistryModel.fromJson(m))
          .toList(),
      services: (json['services'] as List)
          .map((s) => ServiceModel.fromJson(s))
          .toList(),
      fileTypes: fileTypesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ministries': ministries
          .map((m) => MinistryModel.fromEntity(m).toJson())
          .toList(),
      'services': services
          .map((s) => ServiceModel.fromEntity(s).toJson())
          .toList(),
      'file_types': fileTypes,
    };
  }
}
