// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_image_upload.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPendingImageUploadCollection on Isar {
  IsarCollection<PendingImageUpload> get pendingImageUploads =>
      this.collection();
}

const PendingImageUploadSchema = CollectionSchema(
  name: r'PendingImageUpload',
  id: -3586430645432319653,
  properties: {
    r'contentType': PropertySchema(
      id: 0,
      name: r'contentType',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'fileSize': PropertySchema(
      id: 2,
      name: r'fileSize',
      type: IsarType.long,
    ),
    r'hasFailed': PropertySchema(
      id: 3,
      name: r'hasFailed',
      type: IsarType.bool,
    ),
    r'isCompleted': PropertySchema(
      id: 4,
      name: r'isCompleted',
      type: IsarType.bool,
    ),
    r'isPending': PropertySchema(
      id: 5,
      name: r'isPending',
      type: IsarType.bool,
    ),
    r'isUploading': PropertySchema(
      id: 6,
      name: r'isUploading',
      type: IsarType.bool,
    ),
    r'lastError': PropertySchema(
      id: 7,
      name: r'lastError',
      type: IsarType.string,
    ),
    r'lastRetryAt': PropertySchema(
      id: 8,
      name: r'lastRetryAt',
      type: IsarType.dateTime,
    ),
    r'localImagePath': PropertySchema(
      id: 9,
      name: r'localImagePath',
      type: IsarType.string,
    ),
    r'noteId': PropertySchema(
      id: 10,
      name: r'noteId',
      type: IsarType.long,
    ),
    r'originalFilename': PropertySchema(
      id: 11,
      name: r'originalFilename',
      type: IsarType.string,
    ),
    r'r2ImageUrl': PropertySchema(
      id: 12,
      name: r'r2ImageUrl',
      type: IsarType.string,
    ),
    r'retryCount': PropertySchema(
      id: 13,
      name: r'retryCount',
      type: IsarType.long,
    ),
    r'serverId': PropertySchema(
      id: 14,
      name: r'serverId',
      type: IsarType.string,
    ),
    r'shouldRetry': PropertySchema(
      id: 15,
      name: r'shouldRetry',
      type: IsarType.bool,
    ),
    r'status': PropertySchema(
      id: 16,
      name: r'status',
      type: IsarType.string,
      enumMap: _PendingImageUploadstatusEnumValueMap,
    ),
    r'uploadedAt': PropertySchema(
      id: 17,
      name: r'uploadedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _pendingImageUploadEstimateSize,
  serialize: _pendingImageUploadSerialize,
  deserialize: _pendingImageUploadDeserialize,
  deserializeProp: _pendingImageUploadDeserializeProp,
  idName: r'id',
  indexes: {
    r'noteId': IndexSchema(
      id: -9014133502494436840,
      name: r'noteId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'noteId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'serverId': IndexSchema(
      id: -7950187970872907662,
      name: r'serverId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'serverId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _pendingImageUploadGetId,
  getLinks: _pendingImageUploadGetLinks,
  attach: _pendingImageUploadAttach,
  version: '3.1.0+1',
);

int _pendingImageUploadEstimateSize(
  PendingImageUpload object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.contentType;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.lastError;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.localImagePath.length * 3;
  {
    final value = object.originalFilename;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.r2ImageUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.serverId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.status.name.length * 3;
  return bytesCount;
}

void _pendingImageUploadSerialize(
  PendingImageUpload object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.contentType);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeLong(offsets[2], object.fileSize);
  writer.writeBool(offsets[3], object.hasFailed);
  writer.writeBool(offsets[4], object.isCompleted);
  writer.writeBool(offsets[5], object.isPending);
  writer.writeBool(offsets[6], object.isUploading);
  writer.writeString(offsets[7], object.lastError);
  writer.writeDateTime(offsets[8], object.lastRetryAt);
  writer.writeString(offsets[9], object.localImagePath);
  writer.writeLong(offsets[10], object.noteId);
  writer.writeString(offsets[11], object.originalFilename);
  writer.writeString(offsets[12], object.r2ImageUrl);
  writer.writeLong(offsets[13], object.retryCount);
  writer.writeString(offsets[14], object.serverId);
  writer.writeBool(offsets[15], object.shouldRetry);
  writer.writeString(offsets[16], object.status.name);
  writer.writeDateTime(offsets[17], object.uploadedAt);
}

PendingImageUpload _pendingImageUploadDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PendingImageUpload();
  object.contentType = reader.readStringOrNull(offsets[0]);
  object.createdAt = reader.readDateTime(offsets[1]);
  object.fileSize = reader.readLongOrNull(offsets[2]);
  object.id = id;
  object.lastError = reader.readStringOrNull(offsets[7]);
  object.lastRetryAt = reader.readDateTimeOrNull(offsets[8]);
  object.localImagePath = reader.readString(offsets[9]);
  object.noteId = reader.readLong(offsets[10]);
  object.originalFilename = reader.readStringOrNull(offsets[11]);
  object.r2ImageUrl = reader.readStringOrNull(offsets[12]);
  object.retryCount = reader.readLong(offsets[13]);
  object.serverId = reader.readStringOrNull(offsets[14]);
  object.status = _PendingImageUploadstatusValueEnumMap[
          reader.readStringOrNull(offsets[16])] ??
      UploadStatus.pending;
  object.uploadedAt = reader.readDateTimeOrNull(offsets[17]);
  return object;
}

P _pendingImageUploadDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readLong(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readLong(offset)) as P;
    case 14:
      return (reader.readStringOrNull(offset)) as P;
    case 15:
      return (reader.readBool(offset)) as P;
    case 16:
      return (_PendingImageUploadstatusValueEnumMap[
              reader.readStringOrNull(offset)] ??
          UploadStatus.pending) as P;
    case 17:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _PendingImageUploadstatusEnumValueMap = {
  r'pending': r'pending',
  r'uploading': r'uploading',
  r'completed': r'completed',
  r'failed': r'failed',
};
const _PendingImageUploadstatusValueEnumMap = {
  r'pending': UploadStatus.pending,
  r'uploading': UploadStatus.uploading,
  r'completed': UploadStatus.completed,
  r'failed': UploadStatus.failed,
};

Id _pendingImageUploadGetId(PendingImageUpload object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _pendingImageUploadGetLinks(
    PendingImageUpload object) {
  return [];
}

void _pendingImageUploadAttach(
    IsarCollection<dynamic> col, Id id, PendingImageUpload object) {
  object.id = id;
}

extension PendingImageUploadQueryWhereSort
    on QueryBuilder<PendingImageUpload, PendingImageUpload, QWhere> {
  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterWhere>
      anyNoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'noteId'),
      );
    });
  }
}

extension PendingImageUploadQueryWhere
    on QueryBuilder<PendingImageUpload, PendingImageUpload, QWhereClause> {
  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterWhereClause>
      noteIdEqualTo(int noteId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'noteId',
        value: [noteId],
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterWhereClause>
      noteIdNotEqualTo(int noteId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'noteId',
              lower: [],
              upper: [noteId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'noteId',
              lower: [noteId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'noteId',
              lower: [noteId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'noteId',
              lower: [],
              upper: [noteId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterWhereClause>
      noteIdGreaterThan(
    int noteId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'noteId',
        lower: [noteId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterWhereClause>
      noteIdLessThan(
    int noteId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'noteId',
        lower: [],
        upper: [noteId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterWhereClause>
      noteIdBetween(
    int lowerNoteId,
    int upperNoteId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'noteId',
        lower: [lowerNoteId],
        includeLower: includeLower,
        upper: [upperNoteId],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterWhereClause>
      serverIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'serverId',
        value: [null],
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterWhereClause>
      serverIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'serverId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterWhereClause>
      serverIdEqualTo(String? serverId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'serverId',
        value: [serverId],
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterWhereClause>
      serverIdNotEqualTo(String? serverId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId',
              lower: [],
              upper: [serverId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId',
              lower: [serverId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId',
              lower: [serverId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId',
              lower: [],
              upper: [serverId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension PendingImageUploadQueryFilter
    on QueryBuilder<PendingImageUpload, PendingImageUpload, QFilterCondition> {
  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      contentTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'contentType',
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      contentTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'contentType',
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      contentTypeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'contentType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      contentTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'contentType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      contentTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'contentType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      contentTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'contentType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      contentTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'contentType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      contentTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'contentType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      contentTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'contentType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      contentTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'contentType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      contentTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'contentType',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      contentTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'contentType',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      fileSizeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'fileSize',
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      fileSizeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'fileSize',
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      fileSizeEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fileSize',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      fileSizeGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fileSize',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      fileSizeLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fileSize',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      fileSizeBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fileSize',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      hasFailedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hasFailed',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      isCompletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isCompleted',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      isPendingEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isPending',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      isUploadingEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isUploading',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      lastErrorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastError',
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      lastErrorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastError',
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      lastErrorEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      lastErrorGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      lastErrorLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      lastErrorBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastError',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      lastErrorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lastError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      lastErrorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lastError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      lastErrorContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lastError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      lastErrorMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lastError',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      lastErrorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastError',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      lastErrorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lastError',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      lastRetryAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastRetryAt',
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      lastRetryAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastRetryAt',
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      lastRetryAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastRetryAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      lastRetryAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastRetryAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      lastRetryAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastRetryAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      lastRetryAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastRetryAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      localImagePathEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localImagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      localImagePathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'localImagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      localImagePathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'localImagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      localImagePathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'localImagePath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      localImagePathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'localImagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      localImagePathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'localImagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      localImagePathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'localImagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      localImagePathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'localImagePath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      localImagePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localImagePath',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      localImagePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'localImagePath',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      noteIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'noteId',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      noteIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'noteId',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      noteIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'noteId',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      noteIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'noteId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      originalFilenameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'originalFilename',
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      originalFilenameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'originalFilename',
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      originalFilenameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'originalFilename',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      originalFilenameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'originalFilename',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      originalFilenameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'originalFilename',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      originalFilenameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'originalFilename',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      originalFilenameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'originalFilename',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      originalFilenameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'originalFilename',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      originalFilenameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'originalFilename',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      originalFilenameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'originalFilename',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      originalFilenameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'originalFilename',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      originalFilenameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'originalFilename',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      r2ImageUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'r2ImageUrl',
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      r2ImageUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'r2ImageUrl',
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      r2ImageUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'r2ImageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      r2ImageUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'r2ImageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      r2ImageUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'r2ImageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      r2ImageUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'r2ImageUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      r2ImageUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'r2ImageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      r2ImageUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'r2ImageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      r2ImageUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'r2ImageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      r2ImageUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'r2ImageUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      r2ImageUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'r2ImageUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      r2ImageUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'r2ImageUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      retryCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'retryCount',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      retryCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'retryCount',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      retryCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'retryCount',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      retryCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'retryCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      serverIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'serverId',
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      serverIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'serverId',
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      serverIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      serverIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      serverIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      serverIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'serverId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      serverIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      serverIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      serverIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      serverIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'serverId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      serverIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      serverIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      shouldRetryEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'shouldRetry',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      statusEqualTo(
    UploadStatus value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      statusGreaterThan(
    UploadStatus value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      statusLessThan(
    UploadStatus value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      statusBetween(
    UploadStatus lower,
    UploadStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      statusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      statusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      uploadedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'uploadedAt',
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      uploadedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'uploadedAt',
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      uploadedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uploadedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      uploadedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uploadedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      uploadedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uploadedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterFilterCondition>
      uploadedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uploadedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension PendingImageUploadQueryObject
    on QueryBuilder<PendingImageUpload, PendingImageUpload, QFilterCondition> {}

extension PendingImageUploadQueryLinks
    on QueryBuilder<PendingImageUpload, PendingImageUpload, QFilterCondition> {}

extension PendingImageUploadQuerySortBy
    on QueryBuilder<PendingImageUpload, PendingImageUpload, QSortBy> {
  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      sortByContentType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentType', Sort.asc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      sortByContentTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentType', Sort.desc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      sortByFileSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSize', Sort.asc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      sortByFileSizeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSize', Sort.desc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      sortByHasFailed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasFailed', Sort.asc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      sortByHasFailedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasFailed', Sort.desc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      sortByIsCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.asc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      sortByIsCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.desc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      sortByIsPending() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPending', Sort.asc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      sortByIsPendingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPending', Sort.desc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      sortByIsUploading() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUploading', Sort.asc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      sortByIsUploadingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUploading', Sort.desc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      sortByLastError() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.asc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      sortByLastErrorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.desc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      sortByLastRetryAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastRetryAt', Sort.asc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      sortByLastRetryAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastRetryAt', Sort.desc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      sortByLocalImagePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localImagePath', Sort.asc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      sortByLocalImagePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localImagePath', Sort.desc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      sortByNoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noteId', Sort.asc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      sortByNoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noteId', Sort.desc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      sortByOriginalFilename() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalFilename', Sort.asc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      sortByOriginalFilenameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalFilename', Sort.desc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      sortByR2ImageUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'r2ImageUrl', Sort.asc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      sortByR2ImageUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'r2ImageUrl', Sort.desc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      sortByRetryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryCount', Sort.asc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      sortByRetryCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryCount', Sort.desc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      sortByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      sortByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      sortByShouldRetry() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shouldRetry', Sort.asc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      sortByShouldRetryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shouldRetry', Sort.desc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      sortByUploadedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadedAt', Sort.asc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      sortByUploadedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadedAt', Sort.desc);
    });
  }
}

extension PendingImageUploadQuerySortThenBy
    on QueryBuilder<PendingImageUpload, PendingImageUpload, QSortThenBy> {
  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      thenByContentType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentType', Sort.asc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      thenByContentTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentType', Sort.desc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      thenByFileSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSize', Sort.asc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      thenByFileSizeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSize', Sort.desc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      thenByHasFailed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasFailed', Sort.asc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      thenByHasFailedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasFailed', Sort.desc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      thenByIsCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.asc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      thenByIsCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.desc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      thenByIsPending() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPending', Sort.asc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      thenByIsPendingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPending', Sort.desc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      thenByIsUploading() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUploading', Sort.asc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      thenByIsUploadingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUploading', Sort.desc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      thenByLastError() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.asc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      thenByLastErrorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.desc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      thenByLastRetryAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastRetryAt', Sort.asc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      thenByLastRetryAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastRetryAt', Sort.desc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      thenByLocalImagePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localImagePath', Sort.asc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      thenByLocalImagePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localImagePath', Sort.desc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      thenByNoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noteId', Sort.asc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      thenByNoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noteId', Sort.desc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      thenByOriginalFilename() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalFilename', Sort.asc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      thenByOriginalFilenameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalFilename', Sort.desc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      thenByR2ImageUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'r2ImageUrl', Sort.asc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      thenByR2ImageUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'r2ImageUrl', Sort.desc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      thenByRetryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryCount', Sort.asc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      thenByRetryCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryCount', Sort.desc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      thenByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      thenByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      thenByShouldRetry() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shouldRetry', Sort.asc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      thenByShouldRetryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shouldRetry', Sort.desc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      thenByUploadedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadedAt', Sort.asc);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QAfterSortBy>
      thenByUploadedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadedAt', Sort.desc);
    });
  }
}

extension PendingImageUploadQueryWhereDistinct
    on QueryBuilder<PendingImageUpload, PendingImageUpload, QDistinct> {
  QueryBuilder<PendingImageUpload, PendingImageUpload, QDistinct>
      distinctByContentType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'contentType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QDistinct>
      distinctByFileSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fileSize');
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QDistinct>
      distinctByHasFailed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hasFailed');
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QDistinct>
      distinctByIsCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isCompleted');
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QDistinct>
      distinctByIsPending() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isPending');
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QDistinct>
      distinctByIsUploading() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isUploading');
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QDistinct>
      distinctByLastError({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastError', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QDistinct>
      distinctByLastRetryAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastRetryAt');
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QDistinct>
      distinctByLocalImagePath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localImagePath',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QDistinct>
      distinctByNoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'noteId');
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QDistinct>
      distinctByOriginalFilename({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'originalFilename',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QDistinct>
      distinctByR2ImageUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'r2ImageUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QDistinct>
      distinctByRetryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'retryCount');
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QDistinct>
      distinctByServerId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serverId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QDistinct>
      distinctByShouldRetry() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'shouldRetry');
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QDistinct>
      distinctByStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PendingImageUpload, PendingImageUpload, QDistinct>
      distinctByUploadedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uploadedAt');
    });
  }
}

extension PendingImageUploadQueryProperty
    on QueryBuilder<PendingImageUpload, PendingImageUpload, QQueryProperty> {
  QueryBuilder<PendingImageUpload, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PendingImageUpload, String?, QQueryOperations>
      contentTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'contentType');
    });
  }

  QueryBuilder<PendingImageUpload, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<PendingImageUpload, int?, QQueryOperations> fileSizeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fileSize');
    });
  }

  QueryBuilder<PendingImageUpload, bool, QQueryOperations> hasFailedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hasFailed');
    });
  }

  QueryBuilder<PendingImageUpload, bool, QQueryOperations>
      isCompletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isCompleted');
    });
  }

  QueryBuilder<PendingImageUpload, bool, QQueryOperations> isPendingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isPending');
    });
  }

  QueryBuilder<PendingImageUpload, bool, QQueryOperations>
      isUploadingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isUploading');
    });
  }

  QueryBuilder<PendingImageUpload, String?, QQueryOperations>
      lastErrorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastError');
    });
  }

  QueryBuilder<PendingImageUpload, DateTime?, QQueryOperations>
      lastRetryAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastRetryAt');
    });
  }

  QueryBuilder<PendingImageUpload, String, QQueryOperations>
      localImagePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localImagePath');
    });
  }

  QueryBuilder<PendingImageUpload, int, QQueryOperations> noteIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'noteId');
    });
  }

  QueryBuilder<PendingImageUpload, String?, QQueryOperations>
      originalFilenameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'originalFilename');
    });
  }

  QueryBuilder<PendingImageUpload, String?, QQueryOperations>
      r2ImageUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'r2ImageUrl');
    });
  }

  QueryBuilder<PendingImageUpload, int, QQueryOperations> retryCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'retryCount');
    });
  }

  QueryBuilder<PendingImageUpload, String?, QQueryOperations>
      serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serverId');
    });
  }

  QueryBuilder<PendingImageUpload, bool, QQueryOperations>
      shouldRetryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'shouldRetry');
    });
  }

  QueryBuilder<PendingImageUpload, UploadStatus, QQueryOperations>
      statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<PendingImageUpload, DateTime?, QQueryOperations>
      uploadedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uploadedAt');
    });
  }
}
