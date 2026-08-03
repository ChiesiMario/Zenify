// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_preference.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetOfflinePreferenceCollection on Isar {
  IsarCollection<OfflinePreference> get offlinePreferences => this.collection();
}

const OfflinePreferenceSchema = CollectionSchema(
  name: r'OfflinePreference',
  id: -1187357973746869656,
  properties: {
    r'isOffline': PropertySchema(
      id: 0,
      name: r'isOffline',
      type: IsarType.bool,
    ),
    r'serverId': PropertySchema(
      id: 1,
      name: r'serverId',
      type: IsarType.long,
    ),
    r'targetId': PropertySchema(
      id: 2,
      name: r'targetId',
      type: IsarType.string,
    ),
    r'type': PropertySchema(
      id: 3,
      name: r'type',
      type: IsarType.string,
    )
  },
  estimateSize: _offlinePreferenceEstimateSize,
  serialize: _offlinePreferenceSerialize,
  deserialize: _offlinePreferenceDeserialize,
  deserializeProp: _offlinePreferenceDeserializeProp,
  idName: r'id',
  indexes: {
    r'serverId_type_targetId': IndexSchema(
      id: -1357212261388746303,
      name: r'serverId_type_targetId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'serverId',
          type: IndexType.value,
          caseSensitive: false,
        ),
        IndexPropertySchema(
          name: r'type',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'targetId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _offlinePreferenceGetId,
  getLinks: _offlinePreferenceGetLinks,
  attach: _offlinePreferenceAttach,
  version: '3.1.0+1',
);

int _offlinePreferenceEstimateSize(
  OfflinePreference object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.targetId.length * 3;
  bytesCount += 3 + object.type.length * 3;
  return bytesCount;
}

void _offlinePreferenceSerialize(
  OfflinePreference object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.isOffline);
  writer.writeLong(offsets[1], object.serverId);
  writer.writeString(offsets[2], object.targetId);
  writer.writeString(offsets[3], object.type);
}

OfflinePreference _offlinePreferenceDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = OfflinePreference();
  object.id = id;
  object.isOffline = reader.readBool(offsets[0]);
  object.serverId = reader.readLong(offsets[1]);
  object.targetId = reader.readString(offsets[2]);
  object.type = reader.readString(offsets[3]);
  return object;
}

P _offlinePreferenceDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _offlinePreferenceGetId(OfflinePreference object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _offlinePreferenceGetLinks(
    OfflinePreference object) {
  return [];
}

void _offlinePreferenceAttach(
    IsarCollection<dynamic> col, Id id, OfflinePreference object) {
  object.id = id;
}

extension OfflinePreferenceByIndex on IsarCollection<OfflinePreference> {
  Future<OfflinePreference?> getByServerIdTypeTargetId(
      int serverId, String type, String targetId) {
    return getByIndex(r'serverId_type_targetId', [serverId, type, targetId]);
  }

  OfflinePreference? getByServerIdTypeTargetIdSync(
      int serverId, String type, String targetId) {
    return getByIndexSync(
        r'serverId_type_targetId', [serverId, type, targetId]);
  }

  Future<bool> deleteByServerIdTypeTargetId(
      int serverId, String type, String targetId) {
    return deleteByIndex(r'serverId_type_targetId', [serverId, type, targetId]);
  }

  bool deleteByServerIdTypeTargetIdSync(
      int serverId, String type, String targetId) {
    return deleteByIndexSync(
        r'serverId_type_targetId', [serverId, type, targetId]);
  }

  Future<List<OfflinePreference?>> getAllByServerIdTypeTargetId(
      List<int> serverIdValues,
      List<String> typeValues,
      List<String> targetIdValues) {
    final len = serverIdValues.length;
    assert(typeValues.length == len && targetIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([serverIdValues[i], typeValues[i], targetIdValues[i]]);
    }

    return getAllByIndex(r'serverId_type_targetId', values);
  }

  List<OfflinePreference?> getAllByServerIdTypeTargetIdSync(
      List<int> serverIdValues,
      List<String> typeValues,
      List<String> targetIdValues) {
    final len = serverIdValues.length;
    assert(typeValues.length == len && targetIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([serverIdValues[i], typeValues[i], targetIdValues[i]]);
    }

    return getAllByIndexSync(r'serverId_type_targetId', values);
  }

  Future<int> deleteAllByServerIdTypeTargetId(List<int> serverIdValues,
      List<String> typeValues, List<String> targetIdValues) {
    final len = serverIdValues.length;
    assert(typeValues.length == len && targetIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([serverIdValues[i], typeValues[i], targetIdValues[i]]);
    }

    return deleteAllByIndex(r'serverId_type_targetId', values);
  }

  int deleteAllByServerIdTypeTargetIdSync(List<int> serverIdValues,
      List<String> typeValues, List<String> targetIdValues) {
    final len = serverIdValues.length;
    assert(typeValues.length == len && targetIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([serverIdValues[i], typeValues[i], targetIdValues[i]]);
    }

    return deleteAllByIndexSync(r'serverId_type_targetId', values);
  }

  Future<Id> putByServerIdTypeTargetId(OfflinePreference object) {
    return putByIndex(r'serverId_type_targetId', object);
  }

  Id putByServerIdTypeTargetIdSync(OfflinePreference object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'serverId_type_targetId', object,
        saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByServerIdTypeTargetId(
      List<OfflinePreference> objects) {
    return putAllByIndex(r'serverId_type_targetId', objects);
  }

  List<Id> putAllByServerIdTypeTargetIdSync(List<OfflinePreference> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'serverId_type_targetId', objects,
        saveLinks: saveLinks);
  }
}

extension OfflinePreferenceQueryWhereSort
    on QueryBuilder<OfflinePreference, OfflinePreference, QWhere> {
  QueryBuilder<OfflinePreference, OfflinePreference, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension OfflinePreferenceQueryWhere
    on QueryBuilder<OfflinePreference, OfflinePreference, QWhereClause> {
  QueryBuilder<OfflinePreference, OfflinePreference, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterWhereClause>
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

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterWhereClause>
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

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterWhereClause>
      serverIdEqualToAnyTypeTargetId(int serverId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'serverId_type_targetId',
        value: [serverId],
      ));
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterWhereClause>
      serverIdNotEqualToAnyTypeTargetId(int serverId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId_type_targetId',
              lower: [],
              upper: [serverId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId_type_targetId',
              lower: [serverId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId_type_targetId',
              lower: [serverId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId_type_targetId',
              lower: [],
              upper: [serverId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterWhereClause>
      serverIdGreaterThanAnyTypeTargetId(
    int serverId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'serverId_type_targetId',
        lower: [serverId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterWhereClause>
      serverIdLessThanAnyTypeTargetId(
    int serverId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'serverId_type_targetId',
        lower: [],
        upper: [serverId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterWhereClause>
      serverIdBetweenAnyTypeTargetId(
    int lowerServerId,
    int upperServerId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'serverId_type_targetId',
        lower: [lowerServerId],
        includeLower: includeLower,
        upper: [upperServerId],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterWhereClause>
      serverIdTypeEqualToAnyTargetId(int serverId, String type) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'serverId_type_targetId',
        value: [serverId, type],
      ));
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterWhereClause>
      serverIdEqualToTypeNotEqualToAnyTargetId(int serverId, String type) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId_type_targetId',
              lower: [serverId],
              upper: [serverId, type],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId_type_targetId',
              lower: [serverId, type],
              includeLower: false,
              upper: [serverId],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId_type_targetId',
              lower: [serverId, type],
              includeLower: false,
              upper: [serverId],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId_type_targetId',
              lower: [serverId],
              upper: [serverId, type],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterWhereClause>
      serverIdTypeTargetIdEqualTo(int serverId, String type, String targetId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'serverId_type_targetId',
        value: [serverId, type, targetId],
      ));
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterWhereClause>
      serverIdTypeEqualToTargetIdNotEqualTo(
          int serverId, String type, String targetId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId_type_targetId',
              lower: [serverId, type],
              upper: [serverId, type, targetId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId_type_targetId',
              lower: [serverId, type, targetId],
              includeLower: false,
              upper: [serverId, type],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId_type_targetId',
              lower: [serverId, type, targetId],
              includeLower: false,
              upper: [serverId, type],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId_type_targetId',
              lower: [serverId, type],
              upper: [serverId, type, targetId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension OfflinePreferenceQueryFilter
    on QueryBuilder<OfflinePreference, OfflinePreference, QFilterCondition> {
  QueryBuilder<OfflinePreference, OfflinePreference, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterFilterCondition>
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

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterFilterCondition>
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

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterFilterCondition>
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

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterFilterCondition>
      isOfflineEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isOffline',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterFilterCondition>
      serverIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serverId',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterFilterCondition>
      serverIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'serverId',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterFilterCondition>
      serverIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'serverId',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterFilterCondition>
      serverIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'serverId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterFilterCondition>
      targetIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'targetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterFilterCondition>
      targetIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'targetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterFilterCondition>
      targetIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'targetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterFilterCondition>
      targetIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'targetId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterFilterCondition>
      targetIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'targetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterFilterCondition>
      targetIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'targetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterFilterCondition>
      targetIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'targetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterFilterCondition>
      targetIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'targetId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterFilterCondition>
      targetIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'targetId',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterFilterCondition>
      targetIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'targetId',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterFilterCondition>
      typeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterFilterCondition>
      typeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterFilterCondition>
      typeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterFilterCondition>
      typeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterFilterCondition>
      typeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterFilterCondition>
      typeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterFilterCondition>
      typeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterFilterCondition>
      typeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'type',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterFilterCondition>
      typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterFilterCondition>
      typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'type',
        value: '',
      ));
    });
  }
}

extension OfflinePreferenceQueryObject
    on QueryBuilder<OfflinePreference, OfflinePreference, QFilterCondition> {}

extension OfflinePreferenceQueryLinks
    on QueryBuilder<OfflinePreference, OfflinePreference, QFilterCondition> {}

extension OfflinePreferenceQuerySortBy
    on QueryBuilder<OfflinePreference, OfflinePreference, QSortBy> {
  QueryBuilder<OfflinePreference, OfflinePreference, QAfterSortBy>
      sortByIsOffline() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOffline', Sort.asc);
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterSortBy>
      sortByIsOfflineDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOffline', Sort.desc);
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterSortBy>
      sortByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterSortBy>
      sortByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterSortBy>
      sortByTargetId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetId', Sort.asc);
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterSortBy>
      sortByTargetIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetId', Sort.desc);
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterSortBy>
      sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterSortBy>
      sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension OfflinePreferenceQuerySortThenBy
    on QueryBuilder<OfflinePreference, OfflinePreference, QSortThenBy> {
  QueryBuilder<OfflinePreference, OfflinePreference, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterSortBy>
      thenByIsOffline() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOffline', Sort.asc);
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterSortBy>
      thenByIsOfflineDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOffline', Sort.desc);
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterSortBy>
      thenByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterSortBy>
      thenByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterSortBy>
      thenByTargetId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetId', Sort.asc);
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterSortBy>
      thenByTargetIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetId', Sort.desc);
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterSortBy>
      thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QAfterSortBy>
      thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension OfflinePreferenceQueryWhereDistinct
    on QueryBuilder<OfflinePreference, OfflinePreference, QDistinct> {
  QueryBuilder<OfflinePreference, OfflinePreference, QDistinct>
      distinctByIsOffline() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isOffline');
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QDistinct>
      distinctByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serverId');
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QDistinct>
      distinctByTargetId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'targetId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflinePreference, OfflinePreference, QDistinct> distinctByType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }
}

extension OfflinePreferenceQueryProperty
    on QueryBuilder<OfflinePreference, OfflinePreference, QQueryProperty> {
  QueryBuilder<OfflinePreference, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<OfflinePreference, bool, QQueryOperations> isOfflineProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isOffline');
    });
  }

  QueryBuilder<OfflinePreference, int, QQueryOperations> serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serverId');
    });
  }

  QueryBuilder<OfflinePreference, String, QQueryOperations> targetIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'targetId');
    });
  }

  QueryBuilder<OfflinePreference, String, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }
}
