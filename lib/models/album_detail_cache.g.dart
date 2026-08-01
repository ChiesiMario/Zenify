// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'album_detail_cache.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAlbumDetailCacheCollection on Isar {
  IsarCollection<AlbumDetailCache> get albumDetailCaches => this.collection();
}

const AlbumDetailCacheSchema = CollectionSchema(
  name: r'AlbumDetailCache',
  id: -1343804786165852474,
  properties: {
    r'albumId': PropertySchema(
      id: 0,
      name: r'albumId',
      type: IsarType.string,
    ),
    r'rawData': PropertySchema(
      id: 1,
      name: r'rawData',
      type: IsarType.string,
    ),
    r'serverId': PropertySchema(
      id: 2,
      name: r'serverId',
      type: IsarType.long,
    )
  },
  estimateSize: _albumDetailCacheEstimateSize,
  serialize: _albumDetailCacheSerialize,
  deserialize: _albumDetailCacheDeserialize,
  deserializeProp: _albumDetailCacheDeserializeProp,
  idName: r'id',
  indexes: {
    r'albumId_serverId': IndexSchema(
      id: -4140454583501747996,
      name: r'albumId_serverId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'albumId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'serverId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _albumDetailCacheGetId,
  getLinks: _albumDetailCacheGetLinks,
  attach: _albumDetailCacheAttach,
  version: '3.1.0+1',
);

int _albumDetailCacheEstimateSize(
  AlbumDetailCache object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.albumId.length * 3;
  bytesCount += 3 + object.rawData.length * 3;
  return bytesCount;
}

void _albumDetailCacheSerialize(
  AlbumDetailCache object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.albumId);
  writer.writeString(offsets[1], object.rawData);
  writer.writeLong(offsets[2], object.serverId);
}

AlbumDetailCache _albumDetailCacheDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AlbumDetailCache();
  object.albumId = reader.readString(offsets[0]);
  object.id = id;
  object.rawData = reader.readString(offsets[1]);
  object.serverId = reader.readLong(offsets[2]);
  return object;
}

P _albumDetailCacheDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _albumDetailCacheGetId(AlbumDetailCache object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _albumDetailCacheGetLinks(AlbumDetailCache object) {
  return [];
}

void _albumDetailCacheAttach(
    IsarCollection<dynamic> col, Id id, AlbumDetailCache object) {
  object.id = id;
}

extension AlbumDetailCacheByIndex on IsarCollection<AlbumDetailCache> {
  Future<AlbumDetailCache?> getByAlbumIdServerId(String albumId, int serverId) {
    return getByIndex(r'albumId_serverId', [albumId, serverId]);
  }

  AlbumDetailCache? getByAlbumIdServerIdSync(String albumId, int serverId) {
    return getByIndexSync(r'albumId_serverId', [albumId, serverId]);
  }

  Future<bool> deleteByAlbumIdServerId(String albumId, int serverId) {
    return deleteByIndex(r'albumId_serverId', [albumId, serverId]);
  }

  bool deleteByAlbumIdServerIdSync(String albumId, int serverId) {
    return deleteByIndexSync(r'albumId_serverId', [albumId, serverId]);
  }

  Future<List<AlbumDetailCache?>> getAllByAlbumIdServerId(
      List<String> albumIdValues, List<int> serverIdValues) {
    final len = albumIdValues.length;
    assert(serverIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([albumIdValues[i], serverIdValues[i]]);
    }

    return getAllByIndex(r'albumId_serverId', values);
  }

  List<AlbumDetailCache?> getAllByAlbumIdServerIdSync(
      List<String> albumIdValues, List<int> serverIdValues) {
    final len = albumIdValues.length;
    assert(serverIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([albumIdValues[i], serverIdValues[i]]);
    }

    return getAllByIndexSync(r'albumId_serverId', values);
  }

  Future<int> deleteAllByAlbumIdServerId(
      List<String> albumIdValues, List<int> serverIdValues) {
    final len = albumIdValues.length;
    assert(serverIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([albumIdValues[i], serverIdValues[i]]);
    }

    return deleteAllByIndex(r'albumId_serverId', values);
  }

  int deleteAllByAlbumIdServerIdSync(
      List<String> albumIdValues, List<int> serverIdValues) {
    final len = albumIdValues.length;
    assert(serverIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([albumIdValues[i], serverIdValues[i]]);
    }

    return deleteAllByIndexSync(r'albumId_serverId', values);
  }

  Future<Id> putByAlbumIdServerId(AlbumDetailCache object) {
    return putByIndex(r'albumId_serverId', object);
  }

  Id putByAlbumIdServerIdSync(AlbumDetailCache object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'albumId_serverId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByAlbumIdServerId(List<AlbumDetailCache> objects) {
    return putAllByIndex(r'albumId_serverId', objects);
  }

  List<Id> putAllByAlbumIdServerIdSync(List<AlbumDetailCache> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'albumId_serverId', objects,
        saveLinks: saveLinks);
  }
}

extension AlbumDetailCacheQueryWhereSort
    on QueryBuilder<AlbumDetailCache, AlbumDetailCache, QWhere> {
  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension AlbumDetailCacheQueryWhere
    on QueryBuilder<AlbumDetailCache, AlbumDetailCache, QWhereClause> {
  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterWhereClause>
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

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterWhereClause> idBetween(
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

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterWhereClause>
      albumIdEqualToAnyServerId(String albumId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'albumId_serverId',
        value: [albumId],
      ));
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterWhereClause>
      albumIdNotEqualToAnyServerId(String albumId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'albumId_serverId',
              lower: [],
              upper: [albumId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'albumId_serverId',
              lower: [albumId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'albumId_serverId',
              lower: [albumId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'albumId_serverId',
              lower: [],
              upper: [albumId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterWhereClause>
      albumIdServerIdEqualTo(String albumId, int serverId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'albumId_serverId',
        value: [albumId, serverId],
      ));
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterWhereClause>
      albumIdEqualToServerIdNotEqualTo(String albumId, int serverId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'albumId_serverId',
              lower: [albumId],
              upper: [albumId, serverId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'albumId_serverId',
              lower: [albumId, serverId],
              includeLower: false,
              upper: [albumId],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'albumId_serverId',
              lower: [albumId, serverId],
              includeLower: false,
              upper: [albumId],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'albumId_serverId',
              lower: [albumId],
              upper: [albumId, serverId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterWhereClause>
      albumIdEqualToServerIdGreaterThan(
    String albumId,
    int serverId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'albumId_serverId',
        lower: [albumId, serverId],
        includeLower: include,
        upper: [albumId],
      ));
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterWhereClause>
      albumIdEqualToServerIdLessThan(
    String albumId,
    int serverId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'albumId_serverId',
        lower: [albumId],
        upper: [albumId, serverId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterWhereClause>
      albumIdEqualToServerIdBetween(
    String albumId,
    int lowerServerId,
    int upperServerId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'albumId_serverId',
        lower: [albumId, lowerServerId],
        includeLower: includeLower,
        upper: [albumId, upperServerId],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension AlbumDetailCacheQueryFilter
    on QueryBuilder<AlbumDetailCache, AlbumDetailCache, QFilterCondition> {
  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterFilterCondition>
      albumIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'albumId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterFilterCondition>
      albumIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'albumId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterFilterCondition>
      albumIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'albumId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterFilterCondition>
      albumIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'albumId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterFilterCondition>
      albumIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'albumId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterFilterCondition>
      albumIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'albumId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterFilterCondition>
      albumIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'albumId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterFilterCondition>
      albumIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'albumId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterFilterCondition>
      albumIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'albumId',
        value: '',
      ));
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterFilterCondition>
      albumIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'albumId',
        value: '',
      ));
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterFilterCondition>
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

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterFilterCondition>
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

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterFilterCondition>
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

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterFilterCondition>
      rawDataEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rawData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterFilterCondition>
      rawDataGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rawData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterFilterCondition>
      rawDataLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rawData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterFilterCondition>
      rawDataBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rawData',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterFilterCondition>
      rawDataStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'rawData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterFilterCondition>
      rawDataEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'rawData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterFilterCondition>
      rawDataContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'rawData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterFilterCondition>
      rawDataMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'rawData',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterFilterCondition>
      rawDataIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rawData',
        value: '',
      ));
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterFilterCondition>
      rawDataIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'rawData',
        value: '',
      ));
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterFilterCondition>
      serverIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serverId',
        value: value,
      ));
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterFilterCondition>
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

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterFilterCondition>
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

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterFilterCondition>
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
}

extension AlbumDetailCacheQueryObject
    on QueryBuilder<AlbumDetailCache, AlbumDetailCache, QFilterCondition> {}

extension AlbumDetailCacheQueryLinks
    on QueryBuilder<AlbumDetailCache, AlbumDetailCache, QFilterCondition> {}

extension AlbumDetailCacheQuerySortBy
    on QueryBuilder<AlbumDetailCache, AlbumDetailCache, QSortBy> {
  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterSortBy>
      sortByAlbumId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'albumId', Sort.asc);
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterSortBy>
      sortByAlbumIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'albumId', Sort.desc);
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterSortBy>
      sortByRawData() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawData', Sort.asc);
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterSortBy>
      sortByRawDataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawData', Sort.desc);
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterSortBy>
      sortByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterSortBy>
      sortByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }
}

extension AlbumDetailCacheQuerySortThenBy
    on QueryBuilder<AlbumDetailCache, AlbumDetailCache, QSortThenBy> {
  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterSortBy>
      thenByAlbumId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'albumId', Sort.asc);
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterSortBy>
      thenByAlbumIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'albumId', Sort.desc);
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterSortBy>
      thenByRawData() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawData', Sort.asc);
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterSortBy>
      thenByRawDataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawData', Sort.desc);
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterSortBy>
      thenByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QAfterSortBy>
      thenByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }
}

extension AlbumDetailCacheQueryWhereDistinct
    on QueryBuilder<AlbumDetailCache, AlbumDetailCache, QDistinct> {
  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QDistinct> distinctByAlbumId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'albumId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QDistinct> distinctByRawData(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rawData', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AlbumDetailCache, AlbumDetailCache, QDistinct>
      distinctByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serverId');
    });
  }
}

extension AlbumDetailCacheQueryProperty
    on QueryBuilder<AlbumDetailCache, AlbumDetailCache, QQueryProperty> {
  QueryBuilder<AlbumDetailCache, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<AlbumDetailCache, String, QQueryOperations> albumIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'albumId');
    });
  }

  QueryBuilder<AlbumDetailCache, String, QQueryOperations> rawDataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rawData');
    });
  }

  QueryBuilder<AlbumDetailCache, int, QQueryOperations> serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serverId');
    });
  }
}
