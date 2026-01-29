import 'package:equatable/equatable.dart';

/// Document required for a service
class DocumentRequired extends Equatable {
  final String name;
  final String sampleImageUrl;

  const DocumentRequired({required this.name, required this.sampleImageUrl});

  @override
  List<Object?> get props => [name, sampleImageUrl];

  DocumentRequired copyWith({String? name, String? sampleImageUrl}) {
    return DocumentRequired(
      name: name ?? this.name,
      sampleImageUrl: sampleImageUrl ?? this.sampleImageUrl,
    );
  }
}
