// GENERATED CODE - DO NOT MODIFY BY HAND
// Manual implementation for hackathon MVP (no build_runner)

part of 'hive_post_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HivePostModelAdapter extends TypeAdapter<HivePostModel> {
  @override
  final int typeId = 0;

  @override
  HivePostModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HivePostModel(
      id: fields[0] as int,
      caption: fields[1] as String,
      imagePath: fields[2] as String?,
      contentStatus: fields[3] as HiveContentStatus,
      upvotes: fields[4] as int,
      downvotes: fields[5] as int,
      createdAt: fields[6] as DateTime,
      postType: fields[7] as HivePostType,
    );
  }

  @override
  void write(BinaryWriter writer, HivePostModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.caption)
      ..writeByte(2)
      ..write(obj.imagePath)
      ..writeByte(3)
      ..write(obj.contentStatus)
      ..writeByte(4)
      ..write(obj.upvotes)
      ..writeByte(5)
      ..write(obj.downvotes)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.postType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HivePostModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveContentStatusAdapter extends TypeAdapter<HiveContentStatus> {
  @override
  final int typeId = 1;

  @override
  HiveContentStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return HiveContentStatus.normal;
      case 1:
        return HiveContentStatus.warning;
      case 2:
        return HiveContentStatus.blocked;
      default:
        return HiveContentStatus.normal;
    }
  }

  @override
  void write(BinaryWriter writer, HiveContentStatus obj) {
    switch (obj) {
      case HiveContentStatus.normal:
        writer.writeByte(0);
        break;
      case HiveContentStatus.warning:
        writer.writeByte(1);
        break;
      case HiveContentStatus.blocked:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveContentStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HivePostTypeAdapter extends TypeAdapter<HivePostType> {
  @override
  final int typeId = 2;

  @override
  HivePostType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return HivePostType.issue;
      case 1:
        return HivePostType.idea;
      default:
        return HivePostType.issue;
    }
  }

  @override
  void write(BinaryWriter writer, HivePostType obj) {
    switch (obj) {
      case HivePostType.issue:
        writer.writeByte(0);
        break;
      case HivePostType.idea:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HivePostTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
