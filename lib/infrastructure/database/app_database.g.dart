// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TimelineImportsTable extends TimelineImports
    with TableInfo<$TimelineImportsTable, TimelineImportRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimelineImportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _fileHashMeta = const VerificationMeta(
    'fileHash',
  );
  @override
  late final GeneratedColumn<String> fileHash = GeneratedColumn<String>(
    'file_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _schemaTypeMeta = const VerificationMeta(
    'schemaType',
  );
  @override
  late final GeneratedColumn<String> schemaType = GeneratedColumn<String>(
    'schema_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMinAtMeta = const VerificationMeta(
    'sourceMinAt',
  );
  @override
  late final GeneratedColumn<DateTime> sourceMinAt = GeneratedColumn<DateTime>(
    'source_min_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMaxAtMeta = const VerificationMeta(
    'sourceMaxAt',
  );
  @override
  late final GeneratedColumn<DateTime> sourceMaxAt = GeneratedColumn<DateTime>(
    'source_max_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _warningCountMeta = const VerificationMeta(
    'warningCount',
  );
  @override
  late final GeneratedColumn<int> warningCount = GeneratedColumn<int>(
    'warning_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _addedVisitsMeta = const VerificationMeta(
    'addedVisits',
  );
  @override
  late final GeneratedColumn<int> addedVisits = GeneratedColumn<int>(
    'added_visits',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _addedMovementsMeta = const VerificationMeta(
    'addedMovements',
  );
  @override
  late final GeneratedColumn<int> addedMovements = GeneratedColumn<int>(
    'added_movements',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedVisitsMeta = const VerificationMeta(
    'updatedVisits',
  );
  @override
  late final GeneratedColumn<int> updatedVisits = GeneratedColumn<int>(
    'updated_visits',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedMovementsMeta = const VerificationMeta(
    'updatedMovements',
  );
  @override
  late final GeneratedColumn<int> updatedMovements = GeneratedColumn<int>(
    'updated_movements',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _reconciliationKindMeta =
      const VerificationMeta('reconciliationKind');
  @override
  late final GeneratedColumn<String> reconciliationKind =
      GeneratedColumn<String>(
        'reconciliation_kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('noChanges'),
      );
  static const VerificationMeta _requiresFullReconciliationMeta =
      const VerificationMeta('requiresFullReconciliation');
  @override
  late final GeneratedColumn<bool> requiresFullReconciliation =
      GeneratedColumn<bool>(
        'requires_full_reconciliation',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("requires_full_reconciliation" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fileHash,
    schemaType,
    startedAt,
    completedAt,
    sourceMinAt,
    sourceMaxAt,
    status,
    warningCount,
    addedVisits,
    addedMovements,
    updatedVisits,
    updatedMovements,
    reconciliationKind,
    requiresFullReconciliation,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'timeline_imports';
  @override
  VerificationContext validateIntegrity(
    Insertable<TimelineImportRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('file_hash')) {
      context.handle(
        _fileHashMeta,
        fileHash.isAcceptableOrUnknown(data['file_hash']!, _fileHashMeta),
      );
    } else if (isInserting) {
      context.missing(_fileHashMeta);
    }
    if (data.containsKey('schema_type')) {
      context.handle(
        _schemaTypeMeta,
        schemaType.isAcceptableOrUnknown(data['schema_type']!, _schemaTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_schemaTypeMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('source_min_at')) {
      context.handle(
        _sourceMinAtMeta,
        sourceMinAt.isAcceptableOrUnknown(
          data['source_min_at']!,
          _sourceMinAtMeta,
        ),
      );
    }
    if (data.containsKey('source_max_at')) {
      context.handle(
        _sourceMaxAtMeta,
        sourceMaxAt.isAcceptableOrUnknown(
          data['source_max_at']!,
          _sourceMaxAtMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('warning_count')) {
      context.handle(
        _warningCountMeta,
        warningCount.isAcceptableOrUnknown(
          data['warning_count']!,
          _warningCountMeta,
        ),
      );
    }
    if (data.containsKey('added_visits')) {
      context.handle(
        _addedVisitsMeta,
        addedVisits.isAcceptableOrUnknown(
          data['added_visits']!,
          _addedVisitsMeta,
        ),
      );
    }
    if (data.containsKey('added_movements')) {
      context.handle(
        _addedMovementsMeta,
        addedMovements.isAcceptableOrUnknown(
          data['added_movements']!,
          _addedMovementsMeta,
        ),
      );
    }
    if (data.containsKey('updated_visits')) {
      context.handle(
        _updatedVisitsMeta,
        updatedVisits.isAcceptableOrUnknown(
          data['updated_visits']!,
          _updatedVisitsMeta,
        ),
      );
    }
    if (data.containsKey('updated_movements')) {
      context.handle(
        _updatedMovementsMeta,
        updatedMovements.isAcceptableOrUnknown(
          data['updated_movements']!,
          _updatedMovementsMeta,
        ),
      );
    }
    if (data.containsKey('reconciliation_kind')) {
      context.handle(
        _reconciliationKindMeta,
        reconciliationKind.isAcceptableOrUnknown(
          data['reconciliation_kind']!,
          _reconciliationKindMeta,
        ),
      );
    }
    if (data.containsKey('requires_full_reconciliation')) {
      context.handle(
        _requiresFullReconciliationMeta,
        requiresFullReconciliation.isAcceptableOrUnknown(
          data['requires_full_reconciliation']!,
          _requiresFullReconciliationMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TimelineImportRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimelineImportRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      fileHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_hash'],
      )!,
      schemaType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}schema_type'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      sourceMinAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}source_min_at'],
      ),
      sourceMaxAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}source_max_at'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      warningCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}warning_count'],
      )!,
      addedVisits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}added_visits'],
      )!,
      addedMovements: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}added_movements'],
      )!,
      updatedVisits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_visits'],
      )!,
      updatedMovements: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_movements'],
      )!,
      reconciliationKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reconciliation_kind'],
      )!,
      requiresFullReconciliation: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}requires_full_reconciliation'],
      )!,
    );
  }

  @override
  $TimelineImportsTable createAlias(String alias) {
    return $TimelineImportsTable(attachedDatabase, alias);
  }
}

class TimelineImportRow extends DataClass
    implements Insertable<TimelineImportRow> {
  final int id;
  final String fileHash;
  final String schemaType;
  final DateTime startedAt;
  final DateTime? completedAt;
  final DateTime? sourceMinAt;
  final DateTime? sourceMaxAt;
  final String status;
  final int warningCount;
  final int addedVisits;
  final int addedMovements;
  final int updatedVisits;
  final int updatedMovements;
  final String reconciliationKind;
  final bool requiresFullReconciliation;
  const TimelineImportRow({
    required this.id,
    required this.fileHash,
    required this.schemaType,
    required this.startedAt,
    this.completedAt,
    this.sourceMinAt,
    this.sourceMaxAt,
    required this.status,
    required this.warningCount,
    required this.addedVisits,
    required this.addedMovements,
    required this.updatedVisits,
    required this.updatedMovements,
    required this.reconciliationKind,
    required this.requiresFullReconciliation,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['file_hash'] = Variable<String>(fileHash);
    map['schema_type'] = Variable<String>(schemaType);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || sourceMinAt != null) {
      map['source_min_at'] = Variable<DateTime>(sourceMinAt);
    }
    if (!nullToAbsent || sourceMaxAt != null) {
      map['source_max_at'] = Variable<DateTime>(sourceMaxAt);
    }
    map['status'] = Variable<String>(status);
    map['warning_count'] = Variable<int>(warningCount);
    map['added_visits'] = Variable<int>(addedVisits);
    map['added_movements'] = Variable<int>(addedMovements);
    map['updated_visits'] = Variable<int>(updatedVisits);
    map['updated_movements'] = Variable<int>(updatedMovements);
    map['reconciliation_kind'] = Variable<String>(reconciliationKind);
    map['requires_full_reconciliation'] = Variable<bool>(
      requiresFullReconciliation,
    );
    return map;
  }

  TimelineImportsCompanion toCompanion(bool nullToAbsent) {
    return TimelineImportsCompanion(
      id: Value(id),
      fileHash: Value(fileHash),
      schemaType: Value(schemaType),
      startedAt: Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      sourceMinAt: sourceMinAt == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceMinAt),
      sourceMaxAt: sourceMaxAt == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceMaxAt),
      status: Value(status),
      warningCount: Value(warningCount),
      addedVisits: Value(addedVisits),
      addedMovements: Value(addedMovements),
      updatedVisits: Value(updatedVisits),
      updatedMovements: Value(updatedMovements),
      reconciliationKind: Value(reconciliationKind),
      requiresFullReconciliation: Value(requiresFullReconciliation),
    );
  }

  factory TimelineImportRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimelineImportRow(
      id: serializer.fromJson<int>(json['id']),
      fileHash: serializer.fromJson<String>(json['fileHash']),
      schemaType: serializer.fromJson<String>(json['schemaType']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      sourceMinAt: serializer.fromJson<DateTime?>(json['sourceMinAt']),
      sourceMaxAt: serializer.fromJson<DateTime?>(json['sourceMaxAt']),
      status: serializer.fromJson<String>(json['status']),
      warningCount: serializer.fromJson<int>(json['warningCount']),
      addedVisits: serializer.fromJson<int>(json['addedVisits']),
      addedMovements: serializer.fromJson<int>(json['addedMovements']),
      updatedVisits: serializer.fromJson<int>(json['updatedVisits']),
      updatedMovements: serializer.fromJson<int>(json['updatedMovements']),
      reconciliationKind: serializer.fromJson<String>(
        json['reconciliationKind'],
      ),
      requiresFullReconciliation: serializer.fromJson<bool>(
        json['requiresFullReconciliation'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fileHash': serializer.toJson<String>(fileHash),
      'schemaType': serializer.toJson<String>(schemaType),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'sourceMinAt': serializer.toJson<DateTime?>(sourceMinAt),
      'sourceMaxAt': serializer.toJson<DateTime?>(sourceMaxAt),
      'status': serializer.toJson<String>(status),
      'warningCount': serializer.toJson<int>(warningCount),
      'addedVisits': serializer.toJson<int>(addedVisits),
      'addedMovements': serializer.toJson<int>(addedMovements),
      'updatedVisits': serializer.toJson<int>(updatedVisits),
      'updatedMovements': serializer.toJson<int>(updatedMovements),
      'reconciliationKind': serializer.toJson<String>(reconciliationKind),
      'requiresFullReconciliation': serializer.toJson<bool>(
        requiresFullReconciliation,
      ),
    };
  }

  TimelineImportRow copyWith({
    int? id,
    String? fileHash,
    String? schemaType,
    DateTime? startedAt,
    Value<DateTime?> completedAt = const Value.absent(),
    Value<DateTime?> sourceMinAt = const Value.absent(),
    Value<DateTime?> sourceMaxAt = const Value.absent(),
    String? status,
    int? warningCount,
    int? addedVisits,
    int? addedMovements,
    int? updatedVisits,
    int? updatedMovements,
    String? reconciliationKind,
    bool? requiresFullReconciliation,
  }) => TimelineImportRow(
    id: id ?? this.id,
    fileHash: fileHash ?? this.fileHash,
    schemaType: schemaType ?? this.schemaType,
    startedAt: startedAt ?? this.startedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    sourceMinAt: sourceMinAt.present ? sourceMinAt.value : this.sourceMinAt,
    sourceMaxAt: sourceMaxAt.present ? sourceMaxAt.value : this.sourceMaxAt,
    status: status ?? this.status,
    warningCount: warningCount ?? this.warningCount,
    addedVisits: addedVisits ?? this.addedVisits,
    addedMovements: addedMovements ?? this.addedMovements,
    updatedVisits: updatedVisits ?? this.updatedVisits,
    updatedMovements: updatedMovements ?? this.updatedMovements,
    reconciliationKind: reconciliationKind ?? this.reconciliationKind,
    requiresFullReconciliation:
        requiresFullReconciliation ?? this.requiresFullReconciliation,
  );
  TimelineImportRow copyWithCompanion(TimelineImportsCompanion data) {
    return TimelineImportRow(
      id: data.id.present ? data.id.value : this.id,
      fileHash: data.fileHash.present ? data.fileHash.value : this.fileHash,
      schemaType: data.schemaType.present
          ? data.schemaType.value
          : this.schemaType,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      sourceMinAt: data.sourceMinAt.present
          ? data.sourceMinAt.value
          : this.sourceMinAt,
      sourceMaxAt: data.sourceMaxAt.present
          ? data.sourceMaxAt.value
          : this.sourceMaxAt,
      status: data.status.present ? data.status.value : this.status,
      warningCount: data.warningCount.present
          ? data.warningCount.value
          : this.warningCount,
      addedVisits: data.addedVisits.present
          ? data.addedVisits.value
          : this.addedVisits,
      addedMovements: data.addedMovements.present
          ? data.addedMovements.value
          : this.addedMovements,
      updatedVisits: data.updatedVisits.present
          ? data.updatedVisits.value
          : this.updatedVisits,
      updatedMovements: data.updatedMovements.present
          ? data.updatedMovements.value
          : this.updatedMovements,
      reconciliationKind: data.reconciliationKind.present
          ? data.reconciliationKind.value
          : this.reconciliationKind,
      requiresFullReconciliation: data.requiresFullReconciliation.present
          ? data.requiresFullReconciliation.value
          : this.requiresFullReconciliation,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimelineImportRow(')
          ..write('id: $id, ')
          ..write('fileHash: $fileHash, ')
          ..write('schemaType: $schemaType, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('sourceMinAt: $sourceMinAt, ')
          ..write('sourceMaxAt: $sourceMaxAt, ')
          ..write('status: $status, ')
          ..write('warningCount: $warningCount, ')
          ..write('addedVisits: $addedVisits, ')
          ..write('addedMovements: $addedMovements, ')
          ..write('updatedVisits: $updatedVisits, ')
          ..write('updatedMovements: $updatedMovements, ')
          ..write('reconciliationKind: $reconciliationKind, ')
          ..write('requiresFullReconciliation: $requiresFullReconciliation')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    fileHash,
    schemaType,
    startedAt,
    completedAt,
    sourceMinAt,
    sourceMaxAt,
    status,
    warningCount,
    addedVisits,
    addedMovements,
    updatedVisits,
    updatedMovements,
    reconciliationKind,
    requiresFullReconciliation,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimelineImportRow &&
          other.id == this.id &&
          other.fileHash == this.fileHash &&
          other.schemaType == this.schemaType &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt &&
          other.sourceMinAt == this.sourceMinAt &&
          other.sourceMaxAt == this.sourceMaxAt &&
          other.status == this.status &&
          other.warningCount == this.warningCount &&
          other.addedVisits == this.addedVisits &&
          other.addedMovements == this.addedMovements &&
          other.updatedVisits == this.updatedVisits &&
          other.updatedMovements == this.updatedMovements &&
          other.reconciliationKind == this.reconciliationKind &&
          other.requiresFullReconciliation == this.requiresFullReconciliation);
}

class TimelineImportsCompanion extends UpdateCompanion<TimelineImportRow> {
  final Value<int> id;
  final Value<String> fileHash;
  final Value<String> schemaType;
  final Value<DateTime> startedAt;
  final Value<DateTime?> completedAt;
  final Value<DateTime?> sourceMinAt;
  final Value<DateTime?> sourceMaxAt;
  final Value<String> status;
  final Value<int> warningCount;
  final Value<int> addedVisits;
  final Value<int> addedMovements;
  final Value<int> updatedVisits;
  final Value<int> updatedMovements;
  final Value<String> reconciliationKind;
  final Value<bool> requiresFullReconciliation;
  const TimelineImportsCompanion({
    this.id = const Value.absent(),
    this.fileHash = const Value.absent(),
    this.schemaType = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.sourceMinAt = const Value.absent(),
    this.sourceMaxAt = const Value.absent(),
    this.status = const Value.absent(),
    this.warningCount = const Value.absent(),
    this.addedVisits = const Value.absent(),
    this.addedMovements = const Value.absent(),
    this.updatedVisits = const Value.absent(),
    this.updatedMovements = const Value.absent(),
    this.reconciliationKind = const Value.absent(),
    this.requiresFullReconciliation = const Value.absent(),
  });
  TimelineImportsCompanion.insert({
    this.id = const Value.absent(),
    required String fileHash,
    required String schemaType,
    required DateTime startedAt,
    this.completedAt = const Value.absent(),
    this.sourceMinAt = const Value.absent(),
    this.sourceMaxAt = const Value.absent(),
    required String status,
    this.warningCount = const Value.absent(),
    this.addedVisits = const Value.absent(),
    this.addedMovements = const Value.absent(),
    this.updatedVisits = const Value.absent(),
    this.updatedMovements = const Value.absent(),
    this.reconciliationKind = const Value.absent(),
    this.requiresFullReconciliation = const Value.absent(),
  }) : fileHash = Value(fileHash),
       schemaType = Value(schemaType),
       startedAt = Value(startedAt),
       status = Value(status);
  static Insertable<TimelineImportRow> custom({
    Expression<int>? id,
    Expression<String>? fileHash,
    Expression<String>? schemaType,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? sourceMinAt,
    Expression<DateTime>? sourceMaxAt,
    Expression<String>? status,
    Expression<int>? warningCount,
    Expression<int>? addedVisits,
    Expression<int>? addedMovements,
    Expression<int>? updatedVisits,
    Expression<int>? updatedMovements,
    Expression<String>? reconciliationKind,
    Expression<bool>? requiresFullReconciliation,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fileHash != null) 'file_hash': fileHash,
      if (schemaType != null) 'schema_type': schemaType,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (sourceMinAt != null) 'source_min_at': sourceMinAt,
      if (sourceMaxAt != null) 'source_max_at': sourceMaxAt,
      if (status != null) 'status': status,
      if (warningCount != null) 'warning_count': warningCount,
      if (addedVisits != null) 'added_visits': addedVisits,
      if (addedMovements != null) 'added_movements': addedMovements,
      if (updatedVisits != null) 'updated_visits': updatedVisits,
      if (updatedMovements != null) 'updated_movements': updatedMovements,
      if (reconciliationKind != null) 'reconciliation_kind': reconciliationKind,
      if (requiresFullReconciliation != null)
        'requires_full_reconciliation': requiresFullReconciliation,
    });
  }

  TimelineImportsCompanion copyWith({
    Value<int>? id,
    Value<String>? fileHash,
    Value<String>? schemaType,
    Value<DateTime>? startedAt,
    Value<DateTime?>? completedAt,
    Value<DateTime?>? sourceMinAt,
    Value<DateTime?>? sourceMaxAt,
    Value<String>? status,
    Value<int>? warningCount,
    Value<int>? addedVisits,
    Value<int>? addedMovements,
    Value<int>? updatedVisits,
    Value<int>? updatedMovements,
    Value<String>? reconciliationKind,
    Value<bool>? requiresFullReconciliation,
  }) {
    return TimelineImportsCompanion(
      id: id ?? this.id,
      fileHash: fileHash ?? this.fileHash,
      schemaType: schemaType ?? this.schemaType,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      sourceMinAt: sourceMinAt ?? this.sourceMinAt,
      sourceMaxAt: sourceMaxAt ?? this.sourceMaxAt,
      status: status ?? this.status,
      warningCount: warningCount ?? this.warningCount,
      addedVisits: addedVisits ?? this.addedVisits,
      addedMovements: addedMovements ?? this.addedMovements,
      updatedVisits: updatedVisits ?? this.updatedVisits,
      updatedMovements: updatedMovements ?? this.updatedMovements,
      reconciliationKind: reconciliationKind ?? this.reconciliationKind,
      requiresFullReconciliation:
          requiresFullReconciliation ?? this.requiresFullReconciliation,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fileHash.present) {
      map['file_hash'] = Variable<String>(fileHash.value);
    }
    if (schemaType.present) {
      map['schema_type'] = Variable<String>(schemaType.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (sourceMinAt.present) {
      map['source_min_at'] = Variable<DateTime>(sourceMinAt.value);
    }
    if (sourceMaxAt.present) {
      map['source_max_at'] = Variable<DateTime>(sourceMaxAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (warningCount.present) {
      map['warning_count'] = Variable<int>(warningCount.value);
    }
    if (addedVisits.present) {
      map['added_visits'] = Variable<int>(addedVisits.value);
    }
    if (addedMovements.present) {
      map['added_movements'] = Variable<int>(addedMovements.value);
    }
    if (updatedVisits.present) {
      map['updated_visits'] = Variable<int>(updatedVisits.value);
    }
    if (updatedMovements.present) {
      map['updated_movements'] = Variable<int>(updatedMovements.value);
    }
    if (reconciliationKind.present) {
      map['reconciliation_kind'] = Variable<String>(reconciliationKind.value);
    }
    if (requiresFullReconciliation.present) {
      map['requires_full_reconciliation'] = Variable<bool>(
        requiresFullReconciliation.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimelineImportsCompanion(')
          ..write('id: $id, ')
          ..write('fileHash: $fileHash, ')
          ..write('schemaType: $schemaType, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('sourceMinAt: $sourceMinAt, ')
          ..write('sourceMaxAt: $sourceMaxAt, ')
          ..write('status: $status, ')
          ..write('warningCount: $warningCount, ')
          ..write('addedVisits: $addedVisits, ')
          ..write('addedMovements: $addedMovements, ')
          ..write('updatedVisits: $updatedVisits, ')
          ..write('updatedMovements: $updatedMovements, ')
          ..write('reconciliationKind: $reconciliationKind, ')
          ..write('requiresFullReconciliation: $requiresFullReconciliation')
          ..write(')'))
        .toString();
  }
}

class $VisitsTable extends Visits with TableInfo<$VisitsTable, VisitRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VisitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sourceKeyMeta = const VerificationMeta(
    'sourceKey',
  );
  @override
  late final GeneratedColumn<String> sourceKey = GeneratedColumn<String>(
    'source_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _startAtUtcMeta = const VerificationMeta(
    'startAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> startAtUtc = GeneratedColumn<DateTime>(
    'start_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endAtUtcMeta = const VerificationMeta(
    'endAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> endAtUtc = GeneratedColumn<DateTime>(
    'end_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latE7Meta = const VerificationMeta('latE7');
  @override
  late final GeneratedColumn<int> latE7 = GeneratedColumn<int>(
    'lat_e7',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lngE7Meta = const VerificationMeta('lngE7');
  @override
  late final GeneratedColumn<int> lngE7 = GeneratedColumn<int>(
    'lng_e7',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accuracyMMeta = const VerificationMeta(
    'accuracyM',
  );
  @override
  late final GeneratedColumn<int> accuracyM = GeneratedColumn<int>(
    'accuracy_m',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceLabelMeta = const VerificationMeta(
    'sourceLabel',
  );
  @override
  late final GeneratedColumn<String> sourceLabel = GeneratedColumn<String>(
    'source_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clusterIdMeta = const VerificationMeta(
    'clusterId',
  );
  @override
  late final GeneratedColumn<int> clusterId = GeneratedColumn<int>(
    'cluster_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceKey,
    startAtUtc,
    endAtUtc,
    latE7,
    lngE7,
    accuracyM,
    sourceLabel,
    clusterId,
    confidence,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'visits';
  @override
  VerificationContext validateIntegrity(
    Insertable<VisitRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source_key')) {
      context.handle(
        _sourceKeyMeta,
        sourceKey.isAcceptableOrUnknown(data['source_key']!, _sourceKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceKeyMeta);
    }
    if (data.containsKey('start_at_utc')) {
      context.handle(
        _startAtUtcMeta,
        startAtUtc.isAcceptableOrUnknown(
          data['start_at_utc']!,
          _startAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startAtUtcMeta);
    }
    if (data.containsKey('end_at_utc')) {
      context.handle(
        _endAtUtcMeta,
        endAtUtc.isAcceptableOrUnknown(data['end_at_utc']!, _endAtUtcMeta),
      );
    } else if (isInserting) {
      context.missing(_endAtUtcMeta);
    }
    if (data.containsKey('lat_e7')) {
      context.handle(
        _latE7Meta,
        latE7.isAcceptableOrUnknown(data['lat_e7']!, _latE7Meta),
      );
    } else if (isInserting) {
      context.missing(_latE7Meta);
    }
    if (data.containsKey('lng_e7')) {
      context.handle(
        _lngE7Meta,
        lngE7.isAcceptableOrUnknown(data['lng_e7']!, _lngE7Meta),
      );
    } else if (isInserting) {
      context.missing(_lngE7Meta);
    }
    if (data.containsKey('accuracy_m')) {
      context.handle(
        _accuracyMMeta,
        accuracyM.isAcceptableOrUnknown(data['accuracy_m']!, _accuracyMMeta),
      );
    }
    if (data.containsKey('source_label')) {
      context.handle(
        _sourceLabelMeta,
        sourceLabel.isAcceptableOrUnknown(
          data['source_label']!,
          _sourceLabelMeta,
        ),
      );
    }
    if (data.containsKey('cluster_id')) {
      context.handle(
        _clusterIdMeta,
        clusterId.isAcceptableOrUnknown(data['cluster_id']!, _clusterIdMeta),
      );
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VisitRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VisitRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sourceKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_key'],
      )!,
      startAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_at_utc'],
      )!,
      endAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_at_utc'],
      )!,
      latE7: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lat_e7'],
      )!,
      lngE7: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lng_e7'],
      )!,
      accuracyM: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}accuracy_m'],
      ),
      sourceLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_label'],
      ),
      clusterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cluster_id'],
      ),
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      ),
    );
  }

  @override
  $VisitsTable createAlias(String alias) {
    return $VisitsTable(attachedDatabase, alias);
  }
}

class VisitRow extends DataClass implements Insertable<VisitRow> {
  final int id;
  final String sourceKey;
  final DateTime startAtUtc;
  final DateTime endAtUtc;
  final int latE7;
  final int lngE7;
  final int? accuracyM;
  final String? sourceLabel;
  final int? clusterId;
  final double? confidence;
  const VisitRow({
    required this.id,
    required this.sourceKey,
    required this.startAtUtc,
    required this.endAtUtc,
    required this.latE7,
    required this.lngE7,
    this.accuracyM,
    this.sourceLabel,
    this.clusterId,
    this.confidence,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['source_key'] = Variable<String>(sourceKey);
    map['start_at_utc'] = Variable<DateTime>(startAtUtc);
    map['end_at_utc'] = Variable<DateTime>(endAtUtc);
    map['lat_e7'] = Variable<int>(latE7);
    map['lng_e7'] = Variable<int>(lngE7);
    if (!nullToAbsent || accuracyM != null) {
      map['accuracy_m'] = Variable<int>(accuracyM);
    }
    if (!nullToAbsent || sourceLabel != null) {
      map['source_label'] = Variable<String>(sourceLabel);
    }
    if (!nullToAbsent || clusterId != null) {
      map['cluster_id'] = Variable<int>(clusterId);
    }
    if (!nullToAbsent || confidence != null) {
      map['confidence'] = Variable<double>(confidence);
    }
    return map;
  }

  VisitsCompanion toCompanion(bool nullToAbsent) {
    return VisitsCompanion(
      id: Value(id),
      sourceKey: Value(sourceKey),
      startAtUtc: Value(startAtUtc),
      endAtUtc: Value(endAtUtc),
      latE7: Value(latE7),
      lngE7: Value(lngE7),
      accuracyM: accuracyM == null && nullToAbsent
          ? const Value.absent()
          : Value(accuracyM),
      sourceLabel: sourceLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceLabel),
      clusterId: clusterId == null && nullToAbsent
          ? const Value.absent()
          : Value(clusterId),
      confidence: confidence == null && nullToAbsent
          ? const Value.absent()
          : Value(confidence),
    );
  }

  factory VisitRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VisitRow(
      id: serializer.fromJson<int>(json['id']),
      sourceKey: serializer.fromJson<String>(json['sourceKey']),
      startAtUtc: serializer.fromJson<DateTime>(json['startAtUtc']),
      endAtUtc: serializer.fromJson<DateTime>(json['endAtUtc']),
      latE7: serializer.fromJson<int>(json['latE7']),
      lngE7: serializer.fromJson<int>(json['lngE7']),
      accuracyM: serializer.fromJson<int?>(json['accuracyM']),
      sourceLabel: serializer.fromJson<String?>(json['sourceLabel']),
      clusterId: serializer.fromJson<int?>(json['clusterId']),
      confidence: serializer.fromJson<double?>(json['confidence']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sourceKey': serializer.toJson<String>(sourceKey),
      'startAtUtc': serializer.toJson<DateTime>(startAtUtc),
      'endAtUtc': serializer.toJson<DateTime>(endAtUtc),
      'latE7': serializer.toJson<int>(latE7),
      'lngE7': serializer.toJson<int>(lngE7),
      'accuracyM': serializer.toJson<int?>(accuracyM),
      'sourceLabel': serializer.toJson<String?>(sourceLabel),
      'clusterId': serializer.toJson<int?>(clusterId),
      'confidence': serializer.toJson<double?>(confidence),
    };
  }

  VisitRow copyWith({
    int? id,
    String? sourceKey,
    DateTime? startAtUtc,
    DateTime? endAtUtc,
    int? latE7,
    int? lngE7,
    Value<int?> accuracyM = const Value.absent(),
    Value<String?> sourceLabel = const Value.absent(),
    Value<int?> clusterId = const Value.absent(),
    Value<double?> confidence = const Value.absent(),
  }) => VisitRow(
    id: id ?? this.id,
    sourceKey: sourceKey ?? this.sourceKey,
    startAtUtc: startAtUtc ?? this.startAtUtc,
    endAtUtc: endAtUtc ?? this.endAtUtc,
    latE7: latE7 ?? this.latE7,
    lngE7: lngE7 ?? this.lngE7,
    accuracyM: accuracyM.present ? accuracyM.value : this.accuracyM,
    sourceLabel: sourceLabel.present ? sourceLabel.value : this.sourceLabel,
    clusterId: clusterId.present ? clusterId.value : this.clusterId,
    confidence: confidence.present ? confidence.value : this.confidence,
  );
  VisitRow copyWithCompanion(VisitsCompanion data) {
    return VisitRow(
      id: data.id.present ? data.id.value : this.id,
      sourceKey: data.sourceKey.present ? data.sourceKey.value : this.sourceKey,
      startAtUtc: data.startAtUtc.present
          ? data.startAtUtc.value
          : this.startAtUtc,
      endAtUtc: data.endAtUtc.present ? data.endAtUtc.value : this.endAtUtc,
      latE7: data.latE7.present ? data.latE7.value : this.latE7,
      lngE7: data.lngE7.present ? data.lngE7.value : this.lngE7,
      accuracyM: data.accuracyM.present ? data.accuracyM.value : this.accuracyM,
      sourceLabel: data.sourceLabel.present
          ? data.sourceLabel.value
          : this.sourceLabel,
      clusterId: data.clusterId.present ? data.clusterId.value : this.clusterId,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VisitRow(')
          ..write('id: $id, ')
          ..write('sourceKey: $sourceKey, ')
          ..write('startAtUtc: $startAtUtc, ')
          ..write('endAtUtc: $endAtUtc, ')
          ..write('latE7: $latE7, ')
          ..write('lngE7: $lngE7, ')
          ..write('accuracyM: $accuracyM, ')
          ..write('sourceLabel: $sourceLabel, ')
          ..write('clusterId: $clusterId, ')
          ..write('confidence: $confidence')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceKey,
    startAtUtc,
    endAtUtc,
    latE7,
    lngE7,
    accuracyM,
    sourceLabel,
    clusterId,
    confidence,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VisitRow &&
          other.id == this.id &&
          other.sourceKey == this.sourceKey &&
          other.startAtUtc == this.startAtUtc &&
          other.endAtUtc == this.endAtUtc &&
          other.latE7 == this.latE7 &&
          other.lngE7 == this.lngE7 &&
          other.accuracyM == this.accuracyM &&
          other.sourceLabel == this.sourceLabel &&
          other.clusterId == this.clusterId &&
          other.confidence == this.confidence);
}

class VisitsCompanion extends UpdateCompanion<VisitRow> {
  final Value<int> id;
  final Value<String> sourceKey;
  final Value<DateTime> startAtUtc;
  final Value<DateTime> endAtUtc;
  final Value<int> latE7;
  final Value<int> lngE7;
  final Value<int?> accuracyM;
  final Value<String?> sourceLabel;
  final Value<int?> clusterId;
  final Value<double?> confidence;
  const VisitsCompanion({
    this.id = const Value.absent(),
    this.sourceKey = const Value.absent(),
    this.startAtUtc = const Value.absent(),
    this.endAtUtc = const Value.absent(),
    this.latE7 = const Value.absent(),
    this.lngE7 = const Value.absent(),
    this.accuracyM = const Value.absent(),
    this.sourceLabel = const Value.absent(),
    this.clusterId = const Value.absent(),
    this.confidence = const Value.absent(),
  });
  VisitsCompanion.insert({
    this.id = const Value.absent(),
    required String sourceKey,
    required DateTime startAtUtc,
    required DateTime endAtUtc,
    required int latE7,
    required int lngE7,
    this.accuracyM = const Value.absent(),
    this.sourceLabel = const Value.absent(),
    this.clusterId = const Value.absent(),
    this.confidence = const Value.absent(),
  }) : sourceKey = Value(sourceKey),
       startAtUtc = Value(startAtUtc),
       endAtUtc = Value(endAtUtc),
       latE7 = Value(latE7),
       lngE7 = Value(lngE7);
  static Insertable<VisitRow> custom({
    Expression<int>? id,
    Expression<String>? sourceKey,
    Expression<DateTime>? startAtUtc,
    Expression<DateTime>? endAtUtc,
    Expression<int>? latE7,
    Expression<int>? lngE7,
    Expression<int>? accuracyM,
    Expression<String>? sourceLabel,
    Expression<int>? clusterId,
    Expression<double>? confidence,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceKey != null) 'source_key': sourceKey,
      if (startAtUtc != null) 'start_at_utc': startAtUtc,
      if (endAtUtc != null) 'end_at_utc': endAtUtc,
      if (latE7 != null) 'lat_e7': latE7,
      if (lngE7 != null) 'lng_e7': lngE7,
      if (accuracyM != null) 'accuracy_m': accuracyM,
      if (sourceLabel != null) 'source_label': sourceLabel,
      if (clusterId != null) 'cluster_id': clusterId,
      if (confidence != null) 'confidence': confidence,
    });
  }

  VisitsCompanion copyWith({
    Value<int>? id,
    Value<String>? sourceKey,
    Value<DateTime>? startAtUtc,
    Value<DateTime>? endAtUtc,
    Value<int>? latE7,
    Value<int>? lngE7,
    Value<int?>? accuracyM,
    Value<String?>? sourceLabel,
    Value<int?>? clusterId,
    Value<double?>? confidence,
  }) {
    return VisitsCompanion(
      id: id ?? this.id,
      sourceKey: sourceKey ?? this.sourceKey,
      startAtUtc: startAtUtc ?? this.startAtUtc,
      endAtUtc: endAtUtc ?? this.endAtUtc,
      latE7: latE7 ?? this.latE7,
      lngE7: lngE7 ?? this.lngE7,
      accuracyM: accuracyM ?? this.accuracyM,
      sourceLabel: sourceLabel ?? this.sourceLabel,
      clusterId: clusterId ?? this.clusterId,
      confidence: confidence ?? this.confidence,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sourceKey.present) {
      map['source_key'] = Variable<String>(sourceKey.value);
    }
    if (startAtUtc.present) {
      map['start_at_utc'] = Variable<DateTime>(startAtUtc.value);
    }
    if (endAtUtc.present) {
      map['end_at_utc'] = Variable<DateTime>(endAtUtc.value);
    }
    if (latE7.present) {
      map['lat_e7'] = Variable<int>(latE7.value);
    }
    if (lngE7.present) {
      map['lng_e7'] = Variable<int>(lngE7.value);
    }
    if (accuracyM.present) {
      map['accuracy_m'] = Variable<int>(accuracyM.value);
    }
    if (sourceLabel.present) {
      map['source_label'] = Variable<String>(sourceLabel.value);
    }
    if (clusterId.present) {
      map['cluster_id'] = Variable<int>(clusterId.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VisitsCompanion(')
          ..write('id: $id, ')
          ..write('sourceKey: $sourceKey, ')
          ..write('startAtUtc: $startAtUtc, ')
          ..write('endAtUtc: $endAtUtc, ')
          ..write('latE7: $latE7, ')
          ..write('lngE7: $lngE7, ')
          ..write('accuracyM: $accuracyM, ')
          ..write('sourceLabel: $sourceLabel, ')
          ..write('clusterId: $clusterId, ')
          ..write('confidence: $confidence')
          ..write(')'))
        .toString();
  }
}

class $MovementsTable extends Movements
    with TableInfo<$MovementsTable, MovementRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MovementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sourceKeyMeta = const VerificationMeta(
    'sourceKey',
  );
  @override
  late final GeneratedColumn<String> sourceKey = GeneratedColumn<String>(
    'source_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _startAtUtcMeta = const VerificationMeta(
    'startAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> startAtUtc = GeneratedColumn<DateTime>(
    'start_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endAtUtcMeta = const VerificationMeta(
    'endAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> endAtUtc = GeneratedColumn<DateTime>(
    'end_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startLatE7Meta = const VerificationMeta(
    'startLatE7',
  );
  @override
  late final GeneratedColumn<int> startLatE7 = GeneratedColumn<int>(
    'start_lat_e7',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startLngE7Meta = const VerificationMeta(
    'startLngE7',
  );
  @override
  late final GeneratedColumn<int> startLngE7 = GeneratedColumn<int>(
    'start_lng_e7',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endLatE7Meta = const VerificationMeta(
    'endLatE7',
  );
  @override
  late final GeneratedColumn<int> endLatE7 = GeneratedColumn<int>(
    'end_lat_e7',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endLngE7Meta = const VerificationMeta(
    'endLngE7',
  );
  @override
  late final GeneratedColumn<int> endLngE7 = GeneratedColumn<int>(
    'end_lng_e7',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _distanceMMeta = const VerificationMeta(
    'distanceM',
  );
  @override
  late final GeneratedColumn<int> distanceM = GeneratedColumn<int>(
    'distance_m',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _distanceMethodMeta = const VerificationMeta(
    'distanceMethod',
  );
  @override
  late final GeneratedColumn<String> distanceMethod = GeneratedColumn<String>(
    'distance_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activityTypeMeta = const VerificationMeta(
    'activityType',
  );
  @override
  late final GeneratedColumn<String> activityType = GeneratedColumn<String>(
    'activity_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pathJsonMeta = const VerificationMeta(
    'pathJson',
  );
  @override
  late final GeneratedColumn<String> pathJson = GeneratedColumn<String>(
    'path_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _validDistanceMeta = const VerificationMeta(
    'validDistance',
  );
  @override
  late final GeneratedColumn<bool> validDistance = GeneratedColumn<bool>(
    'valid_distance',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("valid_distance" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceKey,
    startAtUtc,
    endAtUtc,
    startLatE7,
    startLngE7,
    endLatE7,
    endLngE7,
    distanceM,
    distanceMethod,
    activityType,
    confidence,
    pathJson,
    validDistance,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'movements';
  @override
  VerificationContext validateIntegrity(
    Insertable<MovementRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source_key')) {
      context.handle(
        _sourceKeyMeta,
        sourceKey.isAcceptableOrUnknown(data['source_key']!, _sourceKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceKeyMeta);
    }
    if (data.containsKey('start_at_utc')) {
      context.handle(
        _startAtUtcMeta,
        startAtUtc.isAcceptableOrUnknown(
          data['start_at_utc']!,
          _startAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startAtUtcMeta);
    }
    if (data.containsKey('end_at_utc')) {
      context.handle(
        _endAtUtcMeta,
        endAtUtc.isAcceptableOrUnknown(data['end_at_utc']!, _endAtUtcMeta),
      );
    } else if (isInserting) {
      context.missing(_endAtUtcMeta);
    }
    if (data.containsKey('start_lat_e7')) {
      context.handle(
        _startLatE7Meta,
        startLatE7.isAcceptableOrUnknown(
          data['start_lat_e7']!,
          _startLatE7Meta,
        ),
      );
    }
    if (data.containsKey('start_lng_e7')) {
      context.handle(
        _startLngE7Meta,
        startLngE7.isAcceptableOrUnknown(
          data['start_lng_e7']!,
          _startLngE7Meta,
        ),
      );
    }
    if (data.containsKey('end_lat_e7')) {
      context.handle(
        _endLatE7Meta,
        endLatE7.isAcceptableOrUnknown(data['end_lat_e7']!, _endLatE7Meta),
      );
    }
    if (data.containsKey('end_lng_e7')) {
      context.handle(
        _endLngE7Meta,
        endLngE7.isAcceptableOrUnknown(data['end_lng_e7']!, _endLngE7Meta),
      );
    }
    if (data.containsKey('distance_m')) {
      context.handle(
        _distanceMMeta,
        distanceM.isAcceptableOrUnknown(data['distance_m']!, _distanceMMeta),
      );
    }
    if (data.containsKey('distance_method')) {
      context.handle(
        _distanceMethodMeta,
        distanceMethod.isAcceptableOrUnknown(
          data['distance_method']!,
          _distanceMethodMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_distanceMethodMeta);
    }
    if (data.containsKey('activity_type')) {
      context.handle(
        _activityTypeMeta,
        activityType.isAcceptableOrUnknown(
          data['activity_type']!,
          _activityTypeMeta,
        ),
      );
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    }
    if (data.containsKey('path_json')) {
      context.handle(
        _pathJsonMeta,
        pathJson.isAcceptableOrUnknown(data['path_json']!, _pathJsonMeta),
      );
    }
    if (data.containsKey('valid_distance')) {
      context.handle(
        _validDistanceMeta,
        validDistance.isAcceptableOrUnknown(
          data['valid_distance']!,
          _validDistanceMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MovementRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MovementRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sourceKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_key'],
      )!,
      startAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_at_utc'],
      )!,
      endAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_at_utc'],
      )!,
      startLatE7: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_lat_e7'],
      ),
      startLngE7: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_lng_e7'],
      ),
      endLatE7: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_lat_e7'],
      ),
      endLngE7: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_lng_e7'],
      ),
      distanceM: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}distance_m'],
      ),
      distanceMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}distance_method'],
      )!,
      activityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_type'],
      ),
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      ),
      pathJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path_json'],
      ),
      validDistance: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}valid_distance'],
      )!,
    );
  }

  @override
  $MovementsTable createAlias(String alias) {
    return $MovementsTable(attachedDatabase, alias);
  }
}

class MovementRow extends DataClass implements Insertable<MovementRow> {
  final int id;
  final String sourceKey;
  final DateTime startAtUtc;
  final DateTime endAtUtc;
  final int? startLatE7;
  final int? startLngE7;
  final int? endLatE7;
  final int? endLngE7;
  final int? distanceM;
  final String distanceMethod;
  final String? activityType;
  final double? confidence;
  final String? pathJson;
  final bool validDistance;
  const MovementRow({
    required this.id,
    required this.sourceKey,
    required this.startAtUtc,
    required this.endAtUtc,
    this.startLatE7,
    this.startLngE7,
    this.endLatE7,
    this.endLngE7,
    this.distanceM,
    required this.distanceMethod,
    this.activityType,
    this.confidence,
    this.pathJson,
    required this.validDistance,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['source_key'] = Variable<String>(sourceKey);
    map['start_at_utc'] = Variable<DateTime>(startAtUtc);
    map['end_at_utc'] = Variable<DateTime>(endAtUtc);
    if (!nullToAbsent || startLatE7 != null) {
      map['start_lat_e7'] = Variable<int>(startLatE7);
    }
    if (!nullToAbsent || startLngE7 != null) {
      map['start_lng_e7'] = Variable<int>(startLngE7);
    }
    if (!nullToAbsent || endLatE7 != null) {
      map['end_lat_e7'] = Variable<int>(endLatE7);
    }
    if (!nullToAbsent || endLngE7 != null) {
      map['end_lng_e7'] = Variable<int>(endLngE7);
    }
    if (!nullToAbsent || distanceM != null) {
      map['distance_m'] = Variable<int>(distanceM);
    }
    map['distance_method'] = Variable<String>(distanceMethod);
    if (!nullToAbsent || activityType != null) {
      map['activity_type'] = Variable<String>(activityType);
    }
    if (!nullToAbsent || confidence != null) {
      map['confidence'] = Variable<double>(confidence);
    }
    if (!nullToAbsent || pathJson != null) {
      map['path_json'] = Variable<String>(pathJson);
    }
    map['valid_distance'] = Variable<bool>(validDistance);
    return map;
  }

  MovementsCompanion toCompanion(bool nullToAbsent) {
    return MovementsCompanion(
      id: Value(id),
      sourceKey: Value(sourceKey),
      startAtUtc: Value(startAtUtc),
      endAtUtc: Value(endAtUtc),
      startLatE7: startLatE7 == null && nullToAbsent
          ? const Value.absent()
          : Value(startLatE7),
      startLngE7: startLngE7 == null && nullToAbsent
          ? const Value.absent()
          : Value(startLngE7),
      endLatE7: endLatE7 == null && nullToAbsent
          ? const Value.absent()
          : Value(endLatE7),
      endLngE7: endLngE7 == null && nullToAbsent
          ? const Value.absent()
          : Value(endLngE7),
      distanceM: distanceM == null && nullToAbsent
          ? const Value.absent()
          : Value(distanceM),
      distanceMethod: Value(distanceMethod),
      activityType: activityType == null && nullToAbsent
          ? const Value.absent()
          : Value(activityType),
      confidence: confidence == null && nullToAbsent
          ? const Value.absent()
          : Value(confidence),
      pathJson: pathJson == null && nullToAbsent
          ? const Value.absent()
          : Value(pathJson),
      validDistance: Value(validDistance),
    );
  }

  factory MovementRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MovementRow(
      id: serializer.fromJson<int>(json['id']),
      sourceKey: serializer.fromJson<String>(json['sourceKey']),
      startAtUtc: serializer.fromJson<DateTime>(json['startAtUtc']),
      endAtUtc: serializer.fromJson<DateTime>(json['endAtUtc']),
      startLatE7: serializer.fromJson<int?>(json['startLatE7']),
      startLngE7: serializer.fromJson<int?>(json['startLngE7']),
      endLatE7: serializer.fromJson<int?>(json['endLatE7']),
      endLngE7: serializer.fromJson<int?>(json['endLngE7']),
      distanceM: serializer.fromJson<int?>(json['distanceM']),
      distanceMethod: serializer.fromJson<String>(json['distanceMethod']),
      activityType: serializer.fromJson<String?>(json['activityType']),
      confidence: serializer.fromJson<double?>(json['confidence']),
      pathJson: serializer.fromJson<String?>(json['pathJson']),
      validDistance: serializer.fromJson<bool>(json['validDistance']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sourceKey': serializer.toJson<String>(sourceKey),
      'startAtUtc': serializer.toJson<DateTime>(startAtUtc),
      'endAtUtc': serializer.toJson<DateTime>(endAtUtc),
      'startLatE7': serializer.toJson<int?>(startLatE7),
      'startLngE7': serializer.toJson<int?>(startLngE7),
      'endLatE7': serializer.toJson<int?>(endLatE7),
      'endLngE7': serializer.toJson<int?>(endLngE7),
      'distanceM': serializer.toJson<int?>(distanceM),
      'distanceMethod': serializer.toJson<String>(distanceMethod),
      'activityType': serializer.toJson<String?>(activityType),
      'confidence': serializer.toJson<double?>(confidence),
      'pathJson': serializer.toJson<String?>(pathJson),
      'validDistance': serializer.toJson<bool>(validDistance),
    };
  }

  MovementRow copyWith({
    int? id,
    String? sourceKey,
    DateTime? startAtUtc,
    DateTime? endAtUtc,
    Value<int?> startLatE7 = const Value.absent(),
    Value<int?> startLngE7 = const Value.absent(),
    Value<int?> endLatE7 = const Value.absent(),
    Value<int?> endLngE7 = const Value.absent(),
    Value<int?> distanceM = const Value.absent(),
    String? distanceMethod,
    Value<String?> activityType = const Value.absent(),
    Value<double?> confidence = const Value.absent(),
    Value<String?> pathJson = const Value.absent(),
    bool? validDistance,
  }) => MovementRow(
    id: id ?? this.id,
    sourceKey: sourceKey ?? this.sourceKey,
    startAtUtc: startAtUtc ?? this.startAtUtc,
    endAtUtc: endAtUtc ?? this.endAtUtc,
    startLatE7: startLatE7.present ? startLatE7.value : this.startLatE7,
    startLngE7: startLngE7.present ? startLngE7.value : this.startLngE7,
    endLatE7: endLatE7.present ? endLatE7.value : this.endLatE7,
    endLngE7: endLngE7.present ? endLngE7.value : this.endLngE7,
    distanceM: distanceM.present ? distanceM.value : this.distanceM,
    distanceMethod: distanceMethod ?? this.distanceMethod,
    activityType: activityType.present ? activityType.value : this.activityType,
    confidence: confidence.present ? confidence.value : this.confidence,
    pathJson: pathJson.present ? pathJson.value : this.pathJson,
    validDistance: validDistance ?? this.validDistance,
  );
  MovementRow copyWithCompanion(MovementsCompanion data) {
    return MovementRow(
      id: data.id.present ? data.id.value : this.id,
      sourceKey: data.sourceKey.present ? data.sourceKey.value : this.sourceKey,
      startAtUtc: data.startAtUtc.present
          ? data.startAtUtc.value
          : this.startAtUtc,
      endAtUtc: data.endAtUtc.present ? data.endAtUtc.value : this.endAtUtc,
      startLatE7: data.startLatE7.present
          ? data.startLatE7.value
          : this.startLatE7,
      startLngE7: data.startLngE7.present
          ? data.startLngE7.value
          : this.startLngE7,
      endLatE7: data.endLatE7.present ? data.endLatE7.value : this.endLatE7,
      endLngE7: data.endLngE7.present ? data.endLngE7.value : this.endLngE7,
      distanceM: data.distanceM.present ? data.distanceM.value : this.distanceM,
      distanceMethod: data.distanceMethod.present
          ? data.distanceMethod.value
          : this.distanceMethod,
      activityType: data.activityType.present
          ? data.activityType.value
          : this.activityType,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      pathJson: data.pathJson.present ? data.pathJson.value : this.pathJson,
      validDistance: data.validDistance.present
          ? data.validDistance.value
          : this.validDistance,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MovementRow(')
          ..write('id: $id, ')
          ..write('sourceKey: $sourceKey, ')
          ..write('startAtUtc: $startAtUtc, ')
          ..write('endAtUtc: $endAtUtc, ')
          ..write('startLatE7: $startLatE7, ')
          ..write('startLngE7: $startLngE7, ')
          ..write('endLatE7: $endLatE7, ')
          ..write('endLngE7: $endLngE7, ')
          ..write('distanceM: $distanceM, ')
          ..write('distanceMethod: $distanceMethod, ')
          ..write('activityType: $activityType, ')
          ..write('confidence: $confidence, ')
          ..write('pathJson: $pathJson, ')
          ..write('validDistance: $validDistance')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceKey,
    startAtUtc,
    endAtUtc,
    startLatE7,
    startLngE7,
    endLatE7,
    endLngE7,
    distanceM,
    distanceMethod,
    activityType,
    confidence,
    pathJson,
    validDistance,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MovementRow &&
          other.id == this.id &&
          other.sourceKey == this.sourceKey &&
          other.startAtUtc == this.startAtUtc &&
          other.endAtUtc == this.endAtUtc &&
          other.startLatE7 == this.startLatE7 &&
          other.startLngE7 == this.startLngE7 &&
          other.endLatE7 == this.endLatE7 &&
          other.endLngE7 == this.endLngE7 &&
          other.distanceM == this.distanceM &&
          other.distanceMethod == this.distanceMethod &&
          other.activityType == this.activityType &&
          other.confidence == this.confidence &&
          other.pathJson == this.pathJson &&
          other.validDistance == this.validDistance);
}

class MovementsCompanion extends UpdateCompanion<MovementRow> {
  final Value<int> id;
  final Value<String> sourceKey;
  final Value<DateTime> startAtUtc;
  final Value<DateTime> endAtUtc;
  final Value<int?> startLatE7;
  final Value<int?> startLngE7;
  final Value<int?> endLatE7;
  final Value<int?> endLngE7;
  final Value<int?> distanceM;
  final Value<String> distanceMethod;
  final Value<String?> activityType;
  final Value<double?> confidence;
  final Value<String?> pathJson;
  final Value<bool> validDistance;
  const MovementsCompanion({
    this.id = const Value.absent(),
    this.sourceKey = const Value.absent(),
    this.startAtUtc = const Value.absent(),
    this.endAtUtc = const Value.absent(),
    this.startLatE7 = const Value.absent(),
    this.startLngE7 = const Value.absent(),
    this.endLatE7 = const Value.absent(),
    this.endLngE7 = const Value.absent(),
    this.distanceM = const Value.absent(),
    this.distanceMethod = const Value.absent(),
    this.activityType = const Value.absent(),
    this.confidence = const Value.absent(),
    this.pathJson = const Value.absent(),
    this.validDistance = const Value.absent(),
  });
  MovementsCompanion.insert({
    this.id = const Value.absent(),
    required String sourceKey,
    required DateTime startAtUtc,
    required DateTime endAtUtc,
    this.startLatE7 = const Value.absent(),
    this.startLngE7 = const Value.absent(),
    this.endLatE7 = const Value.absent(),
    this.endLngE7 = const Value.absent(),
    this.distanceM = const Value.absent(),
    required String distanceMethod,
    this.activityType = const Value.absent(),
    this.confidence = const Value.absent(),
    this.pathJson = const Value.absent(),
    this.validDistance = const Value.absent(),
  }) : sourceKey = Value(sourceKey),
       startAtUtc = Value(startAtUtc),
       endAtUtc = Value(endAtUtc),
       distanceMethod = Value(distanceMethod);
  static Insertable<MovementRow> custom({
    Expression<int>? id,
    Expression<String>? sourceKey,
    Expression<DateTime>? startAtUtc,
    Expression<DateTime>? endAtUtc,
    Expression<int>? startLatE7,
    Expression<int>? startLngE7,
    Expression<int>? endLatE7,
    Expression<int>? endLngE7,
    Expression<int>? distanceM,
    Expression<String>? distanceMethod,
    Expression<String>? activityType,
    Expression<double>? confidence,
    Expression<String>? pathJson,
    Expression<bool>? validDistance,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceKey != null) 'source_key': sourceKey,
      if (startAtUtc != null) 'start_at_utc': startAtUtc,
      if (endAtUtc != null) 'end_at_utc': endAtUtc,
      if (startLatE7 != null) 'start_lat_e7': startLatE7,
      if (startLngE7 != null) 'start_lng_e7': startLngE7,
      if (endLatE7 != null) 'end_lat_e7': endLatE7,
      if (endLngE7 != null) 'end_lng_e7': endLngE7,
      if (distanceM != null) 'distance_m': distanceM,
      if (distanceMethod != null) 'distance_method': distanceMethod,
      if (activityType != null) 'activity_type': activityType,
      if (confidence != null) 'confidence': confidence,
      if (pathJson != null) 'path_json': pathJson,
      if (validDistance != null) 'valid_distance': validDistance,
    });
  }

  MovementsCompanion copyWith({
    Value<int>? id,
    Value<String>? sourceKey,
    Value<DateTime>? startAtUtc,
    Value<DateTime>? endAtUtc,
    Value<int?>? startLatE7,
    Value<int?>? startLngE7,
    Value<int?>? endLatE7,
    Value<int?>? endLngE7,
    Value<int?>? distanceM,
    Value<String>? distanceMethod,
    Value<String?>? activityType,
    Value<double?>? confidence,
    Value<String?>? pathJson,
    Value<bool>? validDistance,
  }) {
    return MovementsCompanion(
      id: id ?? this.id,
      sourceKey: sourceKey ?? this.sourceKey,
      startAtUtc: startAtUtc ?? this.startAtUtc,
      endAtUtc: endAtUtc ?? this.endAtUtc,
      startLatE7: startLatE7 ?? this.startLatE7,
      startLngE7: startLngE7 ?? this.startLngE7,
      endLatE7: endLatE7 ?? this.endLatE7,
      endLngE7: endLngE7 ?? this.endLngE7,
      distanceM: distanceM ?? this.distanceM,
      distanceMethod: distanceMethod ?? this.distanceMethod,
      activityType: activityType ?? this.activityType,
      confidence: confidence ?? this.confidence,
      pathJson: pathJson ?? this.pathJson,
      validDistance: validDistance ?? this.validDistance,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sourceKey.present) {
      map['source_key'] = Variable<String>(sourceKey.value);
    }
    if (startAtUtc.present) {
      map['start_at_utc'] = Variable<DateTime>(startAtUtc.value);
    }
    if (endAtUtc.present) {
      map['end_at_utc'] = Variable<DateTime>(endAtUtc.value);
    }
    if (startLatE7.present) {
      map['start_lat_e7'] = Variable<int>(startLatE7.value);
    }
    if (startLngE7.present) {
      map['start_lng_e7'] = Variable<int>(startLngE7.value);
    }
    if (endLatE7.present) {
      map['end_lat_e7'] = Variable<int>(endLatE7.value);
    }
    if (endLngE7.present) {
      map['end_lng_e7'] = Variable<int>(endLngE7.value);
    }
    if (distanceM.present) {
      map['distance_m'] = Variable<int>(distanceM.value);
    }
    if (distanceMethod.present) {
      map['distance_method'] = Variable<String>(distanceMethod.value);
    }
    if (activityType.present) {
      map['activity_type'] = Variable<String>(activityType.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (pathJson.present) {
      map['path_json'] = Variable<String>(pathJson.value);
    }
    if (validDistance.present) {
      map['valid_distance'] = Variable<bool>(validDistance.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MovementsCompanion(')
          ..write('id: $id, ')
          ..write('sourceKey: $sourceKey, ')
          ..write('startAtUtc: $startAtUtc, ')
          ..write('endAtUtc: $endAtUtc, ')
          ..write('startLatE7: $startLatE7, ')
          ..write('startLngE7: $startLngE7, ')
          ..write('endLatE7: $endLatE7, ')
          ..write('endLngE7: $endLngE7, ')
          ..write('distanceM: $distanceM, ')
          ..write('distanceMethod: $distanceMethod, ')
          ..write('activityType: $activityType, ')
          ..write('confidence: $confidence, ')
          ..write('pathJson: $pathJson, ')
          ..write('validDistance: $validDistance')
          ..write(')'))
        .toString();
  }
}

class $PlaceClustersTable extends PlaceClusters
    with TableInfo<$PlaceClustersTable, PlaceClusterRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaceClustersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _stableKeyMeta = const VerificationMeta(
    'stableKey',
  );
  @override
  late final GeneratedColumn<String> stableKey = GeneratedColumn<String>(
    'stable_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _centroidLatE7Meta = const VerificationMeta(
    'centroidLatE7',
  );
  @override
  late final GeneratedColumn<int> centroidLatE7 = GeneratedColumn<int>(
    'centroid_lat_e7',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _centroidLngE7Meta = const VerificationMeta(
    'centroidLngE7',
  );
  @override
  late final GeneratedColumn<int> centroidLngE7 = GeneratedColumn<int>(
    'centroid_lng_e7',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _radiusMMeta = const VerificationMeta(
    'radiusM',
  );
  @override
  late final GeneratedColumn<double> radiusM = GeneratedColumn<double>(
    'radius_m',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _visitCountMeta = const VerificationMeta(
    'visitCount',
  );
  @override
  late final GeneratedColumn<int> visitCount = GeneratedColumn<int>(
    'visit_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dwellSecondsMeta = const VerificationMeta(
    'dwellSeconds',
  );
  @override
  late final GeneratedColumn<int> dwellSeconds = GeneratedColumn<int>(
    'dwell_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firstAtMeta = const VerificationMeta(
    'firstAt',
  );
  @override
  late final GeneratedColumn<DateTime> firstAt = GeneratedColumn<DateTime>(
    'first_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastAtMeta = const VerificationMeta('lastAt');
  @override
  late final GeneratedColumn<DateTime> lastAt = GeneratedColumn<DateTime>(
    'last_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelIdMeta = const VerificationMeta(
    'labelId',
  );
  @override
  late final GeneratedColumn<int> labelId = GeneratedColumn<int>(
    'label_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _excludedMeta = const VerificationMeta(
    'excluded',
  );
  @override
  late final GeneratedColumn<bool> excluded = GeneratedColumn<bool>(
    'excluded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("excluded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _privacyModeMeta = const VerificationMeta(
    'privacyMode',
  );
  @override
  late final GeneratedColumn<String> privacyMode = GeneratedColumn<String>(
    'privacy_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('visible'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    stableKey,
    centroidLatE7,
    centroidLngE7,
    radiusM,
    visitCount,
    dwellSeconds,
    firstAt,
    lastAt,
    labelId,
    excluded,
    privacyMode,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'place_clusters';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaceClusterRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('stable_key')) {
      context.handle(
        _stableKeyMeta,
        stableKey.isAcceptableOrUnknown(data['stable_key']!, _stableKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_stableKeyMeta);
    }
    if (data.containsKey('centroid_lat_e7')) {
      context.handle(
        _centroidLatE7Meta,
        centroidLatE7.isAcceptableOrUnknown(
          data['centroid_lat_e7']!,
          _centroidLatE7Meta,
        ),
      );
    } else if (isInserting) {
      context.missing(_centroidLatE7Meta);
    }
    if (data.containsKey('centroid_lng_e7')) {
      context.handle(
        _centroidLngE7Meta,
        centroidLngE7.isAcceptableOrUnknown(
          data['centroid_lng_e7']!,
          _centroidLngE7Meta,
        ),
      );
    } else if (isInserting) {
      context.missing(_centroidLngE7Meta);
    }
    if (data.containsKey('radius_m')) {
      context.handle(
        _radiusMMeta,
        radiusM.isAcceptableOrUnknown(data['radius_m']!, _radiusMMeta),
      );
    } else if (isInserting) {
      context.missing(_radiusMMeta);
    }
    if (data.containsKey('visit_count')) {
      context.handle(
        _visitCountMeta,
        visitCount.isAcceptableOrUnknown(data['visit_count']!, _visitCountMeta),
      );
    } else if (isInserting) {
      context.missing(_visitCountMeta);
    }
    if (data.containsKey('dwell_seconds')) {
      context.handle(
        _dwellSecondsMeta,
        dwellSeconds.isAcceptableOrUnknown(
          data['dwell_seconds']!,
          _dwellSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dwellSecondsMeta);
    }
    if (data.containsKey('first_at')) {
      context.handle(
        _firstAtMeta,
        firstAt.isAcceptableOrUnknown(data['first_at']!, _firstAtMeta),
      );
    } else if (isInserting) {
      context.missing(_firstAtMeta);
    }
    if (data.containsKey('last_at')) {
      context.handle(
        _lastAtMeta,
        lastAt.isAcceptableOrUnknown(data['last_at']!, _lastAtMeta),
      );
    } else if (isInserting) {
      context.missing(_lastAtMeta);
    }
    if (data.containsKey('label_id')) {
      context.handle(
        _labelIdMeta,
        labelId.isAcceptableOrUnknown(data['label_id']!, _labelIdMeta),
      );
    }
    if (data.containsKey('excluded')) {
      context.handle(
        _excludedMeta,
        excluded.isAcceptableOrUnknown(data['excluded']!, _excludedMeta),
      );
    }
    if (data.containsKey('privacy_mode')) {
      context.handle(
        _privacyModeMeta,
        privacyMode.isAcceptableOrUnknown(
          data['privacy_mode']!,
          _privacyModeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlaceClusterRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaceClusterRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      stableKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stable_key'],
      )!,
      centroidLatE7: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}centroid_lat_e7'],
      )!,
      centroidLngE7: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}centroid_lng_e7'],
      )!,
      radiusM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}radius_m'],
      )!,
      visitCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}visit_count'],
      )!,
      dwellSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dwell_seconds'],
      )!,
      firstAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}first_at'],
      )!,
      lastAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_at'],
      )!,
      labelId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}label_id'],
      ),
      excluded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}excluded'],
      )!,
      privacyMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}privacy_mode'],
      )!,
    );
  }

  @override
  $PlaceClustersTable createAlias(String alias) {
    return $PlaceClustersTable(attachedDatabase, alias);
  }
}

class PlaceClusterRow extends DataClass implements Insertable<PlaceClusterRow> {
  final int id;
  final String stableKey;
  final int centroidLatE7;
  final int centroidLngE7;
  final double radiusM;
  final int visitCount;
  final int dwellSeconds;
  final DateTime firstAt;
  final DateTime lastAt;
  final int? labelId;

  /// Legacy compatibility. New code synchronizes this with privacyMode=exclude.
  final bool excluded;

  /// visible | hideName | blurMap | exclude
  final String privacyMode;
  const PlaceClusterRow({
    required this.id,
    required this.stableKey,
    required this.centroidLatE7,
    required this.centroidLngE7,
    required this.radiusM,
    required this.visitCount,
    required this.dwellSeconds,
    required this.firstAt,
    required this.lastAt,
    this.labelId,
    required this.excluded,
    required this.privacyMode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['stable_key'] = Variable<String>(stableKey);
    map['centroid_lat_e7'] = Variable<int>(centroidLatE7);
    map['centroid_lng_e7'] = Variable<int>(centroidLngE7);
    map['radius_m'] = Variable<double>(radiusM);
    map['visit_count'] = Variable<int>(visitCount);
    map['dwell_seconds'] = Variable<int>(dwellSeconds);
    map['first_at'] = Variable<DateTime>(firstAt);
    map['last_at'] = Variable<DateTime>(lastAt);
    if (!nullToAbsent || labelId != null) {
      map['label_id'] = Variable<int>(labelId);
    }
    map['excluded'] = Variable<bool>(excluded);
    map['privacy_mode'] = Variable<String>(privacyMode);
    return map;
  }

  PlaceClustersCompanion toCompanion(bool nullToAbsent) {
    return PlaceClustersCompanion(
      id: Value(id),
      stableKey: Value(stableKey),
      centroidLatE7: Value(centroidLatE7),
      centroidLngE7: Value(centroidLngE7),
      radiusM: Value(radiusM),
      visitCount: Value(visitCount),
      dwellSeconds: Value(dwellSeconds),
      firstAt: Value(firstAt),
      lastAt: Value(lastAt),
      labelId: labelId == null && nullToAbsent
          ? const Value.absent()
          : Value(labelId),
      excluded: Value(excluded),
      privacyMode: Value(privacyMode),
    );
  }

  factory PlaceClusterRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaceClusterRow(
      id: serializer.fromJson<int>(json['id']),
      stableKey: serializer.fromJson<String>(json['stableKey']),
      centroidLatE7: serializer.fromJson<int>(json['centroidLatE7']),
      centroidLngE7: serializer.fromJson<int>(json['centroidLngE7']),
      radiusM: serializer.fromJson<double>(json['radiusM']),
      visitCount: serializer.fromJson<int>(json['visitCount']),
      dwellSeconds: serializer.fromJson<int>(json['dwellSeconds']),
      firstAt: serializer.fromJson<DateTime>(json['firstAt']),
      lastAt: serializer.fromJson<DateTime>(json['lastAt']),
      labelId: serializer.fromJson<int?>(json['labelId']),
      excluded: serializer.fromJson<bool>(json['excluded']),
      privacyMode: serializer.fromJson<String>(json['privacyMode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'stableKey': serializer.toJson<String>(stableKey),
      'centroidLatE7': serializer.toJson<int>(centroidLatE7),
      'centroidLngE7': serializer.toJson<int>(centroidLngE7),
      'radiusM': serializer.toJson<double>(radiusM),
      'visitCount': serializer.toJson<int>(visitCount),
      'dwellSeconds': serializer.toJson<int>(dwellSeconds),
      'firstAt': serializer.toJson<DateTime>(firstAt),
      'lastAt': serializer.toJson<DateTime>(lastAt),
      'labelId': serializer.toJson<int?>(labelId),
      'excluded': serializer.toJson<bool>(excluded),
      'privacyMode': serializer.toJson<String>(privacyMode),
    };
  }

  PlaceClusterRow copyWith({
    int? id,
    String? stableKey,
    int? centroidLatE7,
    int? centroidLngE7,
    double? radiusM,
    int? visitCount,
    int? dwellSeconds,
    DateTime? firstAt,
    DateTime? lastAt,
    Value<int?> labelId = const Value.absent(),
    bool? excluded,
    String? privacyMode,
  }) => PlaceClusterRow(
    id: id ?? this.id,
    stableKey: stableKey ?? this.stableKey,
    centroidLatE7: centroidLatE7 ?? this.centroidLatE7,
    centroidLngE7: centroidLngE7 ?? this.centroidLngE7,
    radiusM: radiusM ?? this.radiusM,
    visitCount: visitCount ?? this.visitCount,
    dwellSeconds: dwellSeconds ?? this.dwellSeconds,
    firstAt: firstAt ?? this.firstAt,
    lastAt: lastAt ?? this.lastAt,
    labelId: labelId.present ? labelId.value : this.labelId,
    excluded: excluded ?? this.excluded,
    privacyMode: privacyMode ?? this.privacyMode,
  );
  PlaceClusterRow copyWithCompanion(PlaceClustersCompanion data) {
    return PlaceClusterRow(
      id: data.id.present ? data.id.value : this.id,
      stableKey: data.stableKey.present ? data.stableKey.value : this.stableKey,
      centroidLatE7: data.centroidLatE7.present
          ? data.centroidLatE7.value
          : this.centroidLatE7,
      centroidLngE7: data.centroidLngE7.present
          ? data.centroidLngE7.value
          : this.centroidLngE7,
      radiusM: data.radiusM.present ? data.radiusM.value : this.radiusM,
      visitCount: data.visitCount.present
          ? data.visitCount.value
          : this.visitCount,
      dwellSeconds: data.dwellSeconds.present
          ? data.dwellSeconds.value
          : this.dwellSeconds,
      firstAt: data.firstAt.present ? data.firstAt.value : this.firstAt,
      lastAt: data.lastAt.present ? data.lastAt.value : this.lastAt,
      labelId: data.labelId.present ? data.labelId.value : this.labelId,
      excluded: data.excluded.present ? data.excluded.value : this.excluded,
      privacyMode: data.privacyMode.present
          ? data.privacyMode.value
          : this.privacyMode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaceClusterRow(')
          ..write('id: $id, ')
          ..write('stableKey: $stableKey, ')
          ..write('centroidLatE7: $centroidLatE7, ')
          ..write('centroidLngE7: $centroidLngE7, ')
          ..write('radiusM: $radiusM, ')
          ..write('visitCount: $visitCount, ')
          ..write('dwellSeconds: $dwellSeconds, ')
          ..write('firstAt: $firstAt, ')
          ..write('lastAt: $lastAt, ')
          ..write('labelId: $labelId, ')
          ..write('excluded: $excluded, ')
          ..write('privacyMode: $privacyMode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    stableKey,
    centroidLatE7,
    centroidLngE7,
    radiusM,
    visitCount,
    dwellSeconds,
    firstAt,
    lastAt,
    labelId,
    excluded,
    privacyMode,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaceClusterRow &&
          other.id == this.id &&
          other.stableKey == this.stableKey &&
          other.centroidLatE7 == this.centroidLatE7 &&
          other.centroidLngE7 == this.centroidLngE7 &&
          other.radiusM == this.radiusM &&
          other.visitCount == this.visitCount &&
          other.dwellSeconds == this.dwellSeconds &&
          other.firstAt == this.firstAt &&
          other.lastAt == this.lastAt &&
          other.labelId == this.labelId &&
          other.excluded == this.excluded &&
          other.privacyMode == this.privacyMode);
}

class PlaceClustersCompanion extends UpdateCompanion<PlaceClusterRow> {
  final Value<int> id;
  final Value<String> stableKey;
  final Value<int> centroidLatE7;
  final Value<int> centroidLngE7;
  final Value<double> radiusM;
  final Value<int> visitCount;
  final Value<int> dwellSeconds;
  final Value<DateTime> firstAt;
  final Value<DateTime> lastAt;
  final Value<int?> labelId;
  final Value<bool> excluded;
  final Value<String> privacyMode;
  const PlaceClustersCompanion({
    this.id = const Value.absent(),
    this.stableKey = const Value.absent(),
    this.centroidLatE7 = const Value.absent(),
    this.centroidLngE7 = const Value.absent(),
    this.radiusM = const Value.absent(),
    this.visitCount = const Value.absent(),
    this.dwellSeconds = const Value.absent(),
    this.firstAt = const Value.absent(),
    this.lastAt = const Value.absent(),
    this.labelId = const Value.absent(),
    this.excluded = const Value.absent(),
    this.privacyMode = const Value.absent(),
  });
  PlaceClustersCompanion.insert({
    this.id = const Value.absent(),
    required String stableKey,
    required int centroidLatE7,
    required int centroidLngE7,
    required double radiusM,
    required int visitCount,
    required int dwellSeconds,
    required DateTime firstAt,
    required DateTime lastAt,
    this.labelId = const Value.absent(),
    this.excluded = const Value.absent(),
    this.privacyMode = const Value.absent(),
  }) : stableKey = Value(stableKey),
       centroidLatE7 = Value(centroidLatE7),
       centroidLngE7 = Value(centroidLngE7),
       radiusM = Value(radiusM),
       visitCount = Value(visitCount),
       dwellSeconds = Value(dwellSeconds),
       firstAt = Value(firstAt),
       lastAt = Value(lastAt);
  static Insertable<PlaceClusterRow> custom({
    Expression<int>? id,
    Expression<String>? stableKey,
    Expression<int>? centroidLatE7,
    Expression<int>? centroidLngE7,
    Expression<double>? radiusM,
    Expression<int>? visitCount,
    Expression<int>? dwellSeconds,
    Expression<DateTime>? firstAt,
    Expression<DateTime>? lastAt,
    Expression<int>? labelId,
    Expression<bool>? excluded,
    Expression<String>? privacyMode,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (stableKey != null) 'stable_key': stableKey,
      if (centroidLatE7 != null) 'centroid_lat_e7': centroidLatE7,
      if (centroidLngE7 != null) 'centroid_lng_e7': centroidLngE7,
      if (radiusM != null) 'radius_m': radiusM,
      if (visitCount != null) 'visit_count': visitCount,
      if (dwellSeconds != null) 'dwell_seconds': dwellSeconds,
      if (firstAt != null) 'first_at': firstAt,
      if (lastAt != null) 'last_at': lastAt,
      if (labelId != null) 'label_id': labelId,
      if (excluded != null) 'excluded': excluded,
      if (privacyMode != null) 'privacy_mode': privacyMode,
    });
  }

  PlaceClustersCompanion copyWith({
    Value<int>? id,
    Value<String>? stableKey,
    Value<int>? centroidLatE7,
    Value<int>? centroidLngE7,
    Value<double>? radiusM,
    Value<int>? visitCount,
    Value<int>? dwellSeconds,
    Value<DateTime>? firstAt,
    Value<DateTime>? lastAt,
    Value<int?>? labelId,
    Value<bool>? excluded,
    Value<String>? privacyMode,
  }) {
    return PlaceClustersCompanion(
      id: id ?? this.id,
      stableKey: stableKey ?? this.stableKey,
      centroidLatE7: centroidLatE7 ?? this.centroidLatE7,
      centroidLngE7: centroidLngE7 ?? this.centroidLngE7,
      radiusM: radiusM ?? this.radiusM,
      visitCount: visitCount ?? this.visitCount,
      dwellSeconds: dwellSeconds ?? this.dwellSeconds,
      firstAt: firstAt ?? this.firstAt,
      lastAt: lastAt ?? this.lastAt,
      labelId: labelId ?? this.labelId,
      excluded: excluded ?? this.excluded,
      privacyMode: privacyMode ?? this.privacyMode,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (stableKey.present) {
      map['stable_key'] = Variable<String>(stableKey.value);
    }
    if (centroidLatE7.present) {
      map['centroid_lat_e7'] = Variable<int>(centroidLatE7.value);
    }
    if (centroidLngE7.present) {
      map['centroid_lng_e7'] = Variable<int>(centroidLngE7.value);
    }
    if (radiusM.present) {
      map['radius_m'] = Variable<double>(radiusM.value);
    }
    if (visitCount.present) {
      map['visit_count'] = Variable<int>(visitCount.value);
    }
    if (dwellSeconds.present) {
      map['dwell_seconds'] = Variable<int>(dwellSeconds.value);
    }
    if (firstAt.present) {
      map['first_at'] = Variable<DateTime>(firstAt.value);
    }
    if (lastAt.present) {
      map['last_at'] = Variable<DateTime>(lastAt.value);
    }
    if (labelId.present) {
      map['label_id'] = Variable<int>(labelId.value);
    }
    if (excluded.present) {
      map['excluded'] = Variable<bool>(excluded.value);
    }
    if (privacyMode.present) {
      map['privacy_mode'] = Variable<String>(privacyMode.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaceClustersCompanion(')
          ..write('id: $id, ')
          ..write('stableKey: $stableKey, ')
          ..write('centroidLatE7: $centroidLatE7, ')
          ..write('centroidLngE7: $centroidLngE7, ')
          ..write('radiusM: $radiusM, ')
          ..write('visitCount: $visitCount, ')
          ..write('dwellSeconds: $dwellSeconds, ')
          ..write('firstAt: $firstAt, ')
          ..write('lastAt: $lastAt, ')
          ..write('labelId: $labelId, ')
          ..write('excluded: $excluded, ')
          ..write('privacyMode: $privacyMode')
          ..write(')'))
        .toString();
  }
}

class $PlaceLabelsTable extends PlaceLabels
    with TableInfo<$PlaceLabelsTable, PlaceLabelRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaceLabelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isBasePlaceMeta = const VerificationMeta(
    'isBasePlace',
  );
  @override
  late final GeneratedColumn<bool> isBasePlace = GeneratedColumn<bool>(
    'is_base_place',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_base_place" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    displayName,
    category,
    isBasePlace,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'place_labels';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaceLabelRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('is_base_place')) {
      context.handle(
        _isBasePlaceMeta,
        isBasePlace.isAcceptableOrUnknown(
          data['is_base_place']!,
          _isBasePlaceMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlaceLabelRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaceLabelRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      isBasePlace: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_base_place'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PlaceLabelsTable createAlias(String alias) {
    return $PlaceLabelsTable(attachedDatabase, alias);
  }
}

class PlaceLabelRow extends DataClass implements Insertable<PlaceLabelRow> {
  final int id;
  final String displayName;
  final String? category;
  final bool isBasePlace;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PlaceLabelRow({
    required this.id,
    required this.displayName,
    this.category,
    required this.isBasePlace,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['is_base_place'] = Variable<bool>(isBasePlace);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PlaceLabelsCompanion toCompanion(bool nullToAbsent) {
    return PlaceLabelsCompanion(
      id: Value(id),
      displayName: Value(displayName),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      isBasePlace: Value(isBasePlace),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PlaceLabelRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaceLabelRow(
      id: serializer.fromJson<int>(json['id']),
      displayName: serializer.fromJson<String>(json['displayName']),
      category: serializer.fromJson<String?>(json['category']),
      isBasePlace: serializer.fromJson<bool>(json['isBasePlace']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'displayName': serializer.toJson<String>(displayName),
      'category': serializer.toJson<String?>(category),
      'isBasePlace': serializer.toJson<bool>(isBasePlace),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PlaceLabelRow copyWith({
    int? id,
    String? displayName,
    Value<String?> category = const Value.absent(),
    bool? isBasePlace,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PlaceLabelRow(
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    category: category.present ? category.value : this.category,
    isBasePlace: isBasePlace ?? this.isBasePlace,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PlaceLabelRow copyWithCompanion(PlaceLabelsCompanion data) {
    return PlaceLabelRow(
      id: data.id.present ? data.id.value : this.id,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      category: data.category.present ? data.category.value : this.category,
      isBasePlace: data.isBasePlace.present
          ? data.isBasePlace.value
          : this.isBasePlace,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaceLabelRow(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('category: $category, ')
          ..write('isBasePlace: $isBasePlace, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, displayName, category, isBasePlace, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaceLabelRow &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.category == this.category &&
          other.isBasePlace == this.isBasePlace &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PlaceLabelsCompanion extends UpdateCompanion<PlaceLabelRow> {
  final Value<int> id;
  final Value<String> displayName;
  final Value<String?> category;
  final Value<bool> isBasePlace;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const PlaceLabelsCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.category = const Value.absent(),
    this.isBasePlace = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PlaceLabelsCompanion.insert({
    this.id = const Value.absent(),
    required String displayName,
    this.category = const Value.absent(),
    this.isBasePlace = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : displayName = Value(displayName),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PlaceLabelRow> custom({
    Expression<int>? id,
    Expression<String>? displayName,
    Expression<String>? category,
    Expression<bool>? isBasePlace,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (category != null) 'category': category,
      if (isBasePlace != null) 'is_base_place': isBasePlace,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PlaceLabelsCompanion copyWith({
    Value<int>? id,
    Value<String>? displayName,
    Value<String?>? category,
    Value<bool>? isBasePlace,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return PlaceLabelsCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      category: category ?? this.category,
      isBasePlace: isBasePlace ?? this.isBasePlace,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (isBasePlace.present) {
      map['is_base_place'] = Variable<bool>(isBasePlace.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaceLabelsCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('category: $category, ')
          ..write('isBasePlace: $isBasePlace, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $DailySummariesTable extends DailySummaries
    with TableInfo<$DailySummariesTable, DailySummaryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailySummariesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localDateMeta = const VerificationMeta(
    'localDate',
  );
  @override
  late final GeneratedColumn<String> localDate = GeneratedColumn<String>(
    'local_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outingFlagMeta = const VerificationMeta(
    'outingFlag',
  );
  @override
  late final GeneratedColumn<bool> outingFlag = GeneratedColumn<bool>(
    'outing_flag',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("outing_flag" IN (0, 1))',
    ),
  );
  static const VerificationMeta _visitCountMeta = const VerificationMeta(
    'visitCount',
  );
  @override
  late final GeneratedColumn<int> visitCount = GeneratedColumn<int>(
    'visit_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clusterCountMeta = const VerificationMeta(
    'clusterCount',
  );
  @override
  late final GeneratedColumn<int> clusterCount = GeneratedColumn<int>(
    'cluster_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _distanceMMeta = const VerificationMeta(
    'distanceM',
  );
  @override
  late final GeneratedColumn<int> distanceM = GeneratedColumn<int>(
    'distance_m',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _distanceMethodMeta = const VerificationMeta(
    'distanceMethod',
  );
  @override
  late final GeneratedColumn<String> distanceMethod = GeneratedColumn<String>(
    'distance_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firstAtMeta = const VerificationMeta(
    'firstAt',
  );
  @override
  late final GeneratedColumn<DateTime> firstAt = GeneratedColumn<DateTime>(
    'first_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastAtMeta = const VerificationMeta('lastAt');
  @override
  late final GeneratedColumn<DateTime> lastAt = GeneratedColumn<DateTime>(
    'last_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _qualityMeta = const VerificationMeta(
    'quality',
  );
  @override
  late final GeneratedColumn<int> quality = GeneratedColumn<int>(
    'quality',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    localDate,
    outingFlag,
    visitCount,
    clusterCount,
    distanceM,
    distanceMethod,
    firstAt,
    lastAt,
    quality,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_summaries';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailySummaryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_date')) {
      context.handle(
        _localDateMeta,
        localDate.isAcceptableOrUnknown(data['local_date']!, _localDateMeta),
      );
    } else if (isInserting) {
      context.missing(_localDateMeta);
    }
    if (data.containsKey('outing_flag')) {
      context.handle(
        _outingFlagMeta,
        outingFlag.isAcceptableOrUnknown(data['outing_flag']!, _outingFlagMeta),
      );
    } else if (isInserting) {
      context.missing(_outingFlagMeta);
    }
    if (data.containsKey('visit_count')) {
      context.handle(
        _visitCountMeta,
        visitCount.isAcceptableOrUnknown(data['visit_count']!, _visitCountMeta),
      );
    } else if (isInserting) {
      context.missing(_visitCountMeta);
    }
    if (data.containsKey('cluster_count')) {
      context.handle(
        _clusterCountMeta,
        clusterCount.isAcceptableOrUnknown(
          data['cluster_count']!,
          _clusterCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clusterCountMeta);
    }
    if (data.containsKey('distance_m')) {
      context.handle(
        _distanceMMeta,
        distanceM.isAcceptableOrUnknown(data['distance_m']!, _distanceMMeta),
      );
    } else if (isInserting) {
      context.missing(_distanceMMeta);
    }
    if (data.containsKey('distance_method')) {
      context.handle(
        _distanceMethodMeta,
        distanceMethod.isAcceptableOrUnknown(
          data['distance_method']!,
          _distanceMethodMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_distanceMethodMeta);
    }
    if (data.containsKey('first_at')) {
      context.handle(
        _firstAtMeta,
        firstAt.isAcceptableOrUnknown(data['first_at']!, _firstAtMeta),
      );
    }
    if (data.containsKey('last_at')) {
      context.handle(
        _lastAtMeta,
        lastAt.isAcceptableOrUnknown(data['last_at']!, _lastAtMeta),
      );
    }
    if (data.containsKey('quality')) {
      context.handle(
        _qualityMeta,
        quality.isAcceptableOrUnknown(data['quality']!, _qualityMeta),
      );
    } else if (isInserting) {
      context.missing(_qualityMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localDate};
  @override
  DailySummaryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailySummaryRow(
      localDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_date'],
      )!,
      outingFlag: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}outing_flag'],
      )!,
      visitCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}visit_count'],
      )!,
      clusterCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cluster_count'],
      )!,
      distanceM: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}distance_m'],
      )!,
      distanceMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}distance_method'],
      )!,
      firstAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}first_at'],
      ),
      lastAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_at'],
      ),
      quality: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quality'],
      )!,
    );
  }

  @override
  $DailySummariesTable createAlias(String alias) {
    return $DailySummariesTable(attachedDatabase, alias);
  }
}

class DailySummaryRow extends DataClass implements Insertable<DailySummaryRow> {
  final String localDate;
  final bool outingFlag;
  final int visitCount;
  final int clusterCount;
  final int distanceM;
  final String distanceMethod;
  final DateTime? firstAt;
  final DateTime? lastAt;
  final int quality;
  const DailySummaryRow({
    required this.localDate,
    required this.outingFlag,
    required this.visitCount,
    required this.clusterCount,
    required this.distanceM,
    required this.distanceMethod,
    this.firstAt,
    this.lastAt,
    required this.quality,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_date'] = Variable<String>(localDate);
    map['outing_flag'] = Variable<bool>(outingFlag);
    map['visit_count'] = Variable<int>(visitCount);
    map['cluster_count'] = Variable<int>(clusterCount);
    map['distance_m'] = Variable<int>(distanceM);
    map['distance_method'] = Variable<String>(distanceMethod);
    if (!nullToAbsent || firstAt != null) {
      map['first_at'] = Variable<DateTime>(firstAt);
    }
    if (!nullToAbsent || lastAt != null) {
      map['last_at'] = Variable<DateTime>(lastAt);
    }
    map['quality'] = Variable<int>(quality);
    return map;
  }

  DailySummariesCompanion toCompanion(bool nullToAbsent) {
    return DailySummariesCompanion(
      localDate: Value(localDate),
      outingFlag: Value(outingFlag),
      visitCount: Value(visitCount),
      clusterCount: Value(clusterCount),
      distanceM: Value(distanceM),
      distanceMethod: Value(distanceMethod),
      firstAt: firstAt == null && nullToAbsent
          ? const Value.absent()
          : Value(firstAt),
      lastAt: lastAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAt),
      quality: Value(quality),
    );
  }

  factory DailySummaryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailySummaryRow(
      localDate: serializer.fromJson<String>(json['localDate']),
      outingFlag: serializer.fromJson<bool>(json['outingFlag']),
      visitCount: serializer.fromJson<int>(json['visitCount']),
      clusterCount: serializer.fromJson<int>(json['clusterCount']),
      distanceM: serializer.fromJson<int>(json['distanceM']),
      distanceMethod: serializer.fromJson<String>(json['distanceMethod']),
      firstAt: serializer.fromJson<DateTime?>(json['firstAt']),
      lastAt: serializer.fromJson<DateTime?>(json['lastAt']),
      quality: serializer.fromJson<int>(json['quality']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localDate': serializer.toJson<String>(localDate),
      'outingFlag': serializer.toJson<bool>(outingFlag),
      'visitCount': serializer.toJson<int>(visitCount),
      'clusterCount': serializer.toJson<int>(clusterCount),
      'distanceM': serializer.toJson<int>(distanceM),
      'distanceMethod': serializer.toJson<String>(distanceMethod),
      'firstAt': serializer.toJson<DateTime?>(firstAt),
      'lastAt': serializer.toJson<DateTime?>(lastAt),
      'quality': serializer.toJson<int>(quality),
    };
  }

  DailySummaryRow copyWith({
    String? localDate,
    bool? outingFlag,
    int? visitCount,
    int? clusterCount,
    int? distanceM,
    String? distanceMethod,
    Value<DateTime?> firstAt = const Value.absent(),
    Value<DateTime?> lastAt = const Value.absent(),
    int? quality,
  }) => DailySummaryRow(
    localDate: localDate ?? this.localDate,
    outingFlag: outingFlag ?? this.outingFlag,
    visitCount: visitCount ?? this.visitCount,
    clusterCount: clusterCount ?? this.clusterCount,
    distanceM: distanceM ?? this.distanceM,
    distanceMethod: distanceMethod ?? this.distanceMethod,
    firstAt: firstAt.present ? firstAt.value : this.firstAt,
    lastAt: lastAt.present ? lastAt.value : this.lastAt,
    quality: quality ?? this.quality,
  );
  DailySummaryRow copyWithCompanion(DailySummariesCompanion data) {
    return DailySummaryRow(
      localDate: data.localDate.present ? data.localDate.value : this.localDate,
      outingFlag: data.outingFlag.present
          ? data.outingFlag.value
          : this.outingFlag,
      visitCount: data.visitCount.present
          ? data.visitCount.value
          : this.visitCount,
      clusterCount: data.clusterCount.present
          ? data.clusterCount.value
          : this.clusterCount,
      distanceM: data.distanceM.present ? data.distanceM.value : this.distanceM,
      distanceMethod: data.distanceMethod.present
          ? data.distanceMethod.value
          : this.distanceMethod,
      firstAt: data.firstAt.present ? data.firstAt.value : this.firstAt,
      lastAt: data.lastAt.present ? data.lastAt.value : this.lastAt,
      quality: data.quality.present ? data.quality.value : this.quality,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailySummaryRow(')
          ..write('localDate: $localDate, ')
          ..write('outingFlag: $outingFlag, ')
          ..write('visitCount: $visitCount, ')
          ..write('clusterCount: $clusterCount, ')
          ..write('distanceM: $distanceM, ')
          ..write('distanceMethod: $distanceMethod, ')
          ..write('firstAt: $firstAt, ')
          ..write('lastAt: $lastAt, ')
          ..write('quality: $quality')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localDate,
    outingFlag,
    visitCount,
    clusterCount,
    distanceM,
    distanceMethod,
    firstAt,
    lastAt,
    quality,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailySummaryRow &&
          other.localDate == this.localDate &&
          other.outingFlag == this.outingFlag &&
          other.visitCount == this.visitCount &&
          other.clusterCount == this.clusterCount &&
          other.distanceM == this.distanceM &&
          other.distanceMethod == this.distanceMethod &&
          other.firstAt == this.firstAt &&
          other.lastAt == this.lastAt &&
          other.quality == this.quality);
}

class DailySummariesCompanion extends UpdateCompanion<DailySummaryRow> {
  final Value<String> localDate;
  final Value<bool> outingFlag;
  final Value<int> visitCount;
  final Value<int> clusterCount;
  final Value<int> distanceM;
  final Value<String> distanceMethod;
  final Value<DateTime?> firstAt;
  final Value<DateTime?> lastAt;
  final Value<int> quality;
  final Value<int> rowid;
  const DailySummariesCompanion({
    this.localDate = const Value.absent(),
    this.outingFlag = const Value.absent(),
    this.visitCount = const Value.absent(),
    this.clusterCount = const Value.absent(),
    this.distanceM = const Value.absent(),
    this.distanceMethod = const Value.absent(),
    this.firstAt = const Value.absent(),
    this.lastAt = const Value.absent(),
    this.quality = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailySummariesCompanion.insert({
    required String localDate,
    required bool outingFlag,
    required int visitCount,
    required int clusterCount,
    required int distanceM,
    required String distanceMethod,
    this.firstAt = const Value.absent(),
    this.lastAt = const Value.absent(),
    required int quality,
    this.rowid = const Value.absent(),
  }) : localDate = Value(localDate),
       outingFlag = Value(outingFlag),
       visitCount = Value(visitCount),
       clusterCount = Value(clusterCount),
       distanceM = Value(distanceM),
       distanceMethod = Value(distanceMethod),
       quality = Value(quality);
  static Insertable<DailySummaryRow> custom({
    Expression<String>? localDate,
    Expression<bool>? outingFlag,
    Expression<int>? visitCount,
    Expression<int>? clusterCount,
    Expression<int>? distanceM,
    Expression<String>? distanceMethod,
    Expression<DateTime>? firstAt,
    Expression<DateTime>? lastAt,
    Expression<int>? quality,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localDate != null) 'local_date': localDate,
      if (outingFlag != null) 'outing_flag': outingFlag,
      if (visitCount != null) 'visit_count': visitCount,
      if (clusterCount != null) 'cluster_count': clusterCount,
      if (distanceM != null) 'distance_m': distanceM,
      if (distanceMethod != null) 'distance_method': distanceMethod,
      if (firstAt != null) 'first_at': firstAt,
      if (lastAt != null) 'last_at': lastAt,
      if (quality != null) 'quality': quality,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailySummariesCompanion copyWith({
    Value<String>? localDate,
    Value<bool>? outingFlag,
    Value<int>? visitCount,
    Value<int>? clusterCount,
    Value<int>? distanceM,
    Value<String>? distanceMethod,
    Value<DateTime?>? firstAt,
    Value<DateTime?>? lastAt,
    Value<int>? quality,
    Value<int>? rowid,
  }) {
    return DailySummariesCompanion(
      localDate: localDate ?? this.localDate,
      outingFlag: outingFlag ?? this.outingFlag,
      visitCount: visitCount ?? this.visitCount,
      clusterCount: clusterCount ?? this.clusterCount,
      distanceM: distanceM ?? this.distanceM,
      distanceMethod: distanceMethod ?? this.distanceMethod,
      firstAt: firstAt ?? this.firstAt,
      lastAt: lastAt ?? this.lastAt,
      quality: quality ?? this.quality,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localDate.present) {
      map['local_date'] = Variable<String>(localDate.value);
    }
    if (outingFlag.present) {
      map['outing_flag'] = Variable<bool>(outingFlag.value);
    }
    if (visitCount.present) {
      map['visit_count'] = Variable<int>(visitCount.value);
    }
    if (clusterCount.present) {
      map['cluster_count'] = Variable<int>(clusterCount.value);
    }
    if (distanceM.present) {
      map['distance_m'] = Variable<int>(distanceM.value);
    }
    if (distanceMethod.present) {
      map['distance_method'] = Variable<String>(distanceMethod.value);
    }
    if (firstAt.present) {
      map['first_at'] = Variable<DateTime>(firstAt.value);
    }
    if (lastAt.present) {
      map['last_at'] = Variable<DateTime>(lastAt.value);
    }
    if (quality.present) {
      map['quality'] = Variable<int>(quality.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailySummariesCompanion(')
          ..write('localDate: $localDate, ')
          ..write('outingFlag: $outingFlag, ')
          ..write('visitCount: $visitCount, ')
          ..write('clusterCount: $clusterCount, ')
          ..write('distanceM: $distanceM, ')
          ..write('distanceMethod: $distanceMethod, ')
          ..write('firstAt: $firstAt, ')
          ..write('lastAt: $lastAt, ')
          ..write('quality: $quality, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MonthlySummariesTable extends MonthlySummaries
    with TableInfo<$MonthlySummariesTable, MonthlySummaryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MonthlySummariesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _yearMonthMeta = const VerificationMeta(
    'yearMonth',
  );
  @override
  late final GeneratedColumn<String> yearMonth = GeneratedColumn<String>(
    'year_month',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outingDaysMeta = const VerificationMeta(
    'outingDays',
  );
  @override
  late final GeneratedColumn<int> outingDays = GeneratedColumn<int>(
    'outing_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _distanceMMeta = const VerificationMeta(
    'distanceM',
  );
  @override
  late final GeneratedColumn<int> distanceM = GeneratedColumn<int>(
    'distance_m',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uniqueClustersMeta = const VerificationMeta(
    'uniqueClusters',
  );
  @override
  late final GeneratedColumn<int> uniqueClusters = GeneratedColumn<int>(
    'unique_clusters',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _newClustersMeta = const VerificationMeta(
    'newClusters',
  );
  @override
  late final GeneratedColumn<int> newClusters = GeneratedColumn<int>(
    'new_clusters',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maxDistanceDateMeta = const VerificationMeta(
    'maxDistanceDate',
  );
  @override
  late final GeneratedColumn<String> maxDistanceDate = GeneratedColumn<String>(
    'max_distance_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _calculatedAtMeta = const VerificationMeta(
    'calculatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> calculatedAt = GeneratedColumn<DateTime>(
    'calculated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clusterIdsJsonMeta = const VerificationMeta(
    'clusterIdsJson',
  );
  @override
  late final GeneratedColumn<String> clusterIdsJson = GeneratedColumn<String>(
    'cluster_ids_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    yearMonth,
    outingDays,
    distanceM,
    uniqueClusters,
    newClusters,
    maxDistanceDate,
    calculatedAt,
    clusterIdsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'monthly_summaries';
  @override
  VerificationContext validateIntegrity(
    Insertable<MonthlySummaryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('year_month')) {
      context.handle(
        _yearMonthMeta,
        yearMonth.isAcceptableOrUnknown(data['year_month']!, _yearMonthMeta),
      );
    } else if (isInserting) {
      context.missing(_yearMonthMeta);
    }
    if (data.containsKey('outing_days')) {
      context.handle(
        _outingDaysMeta,
        outingDays.isAcceptableOrUnknown(data['outing_days']!, _outingDaysMeta),
      );
    } else if (isInserting) {
      context.missing(_outingDaysMeta);
    }
    if (data.containsKey('distance_m')) {
      context.handle(
        _distanceMMeta,
        distanceM.isAcceptableOrUnknown(data['distance_m']!, _distanceMMeta),
      );
    } else if (isInserting) {
      context.missing(_distanceMMeta);
    }
    if (data.containsKey('unique_clusters')) {
      context.handle(
        _uniqueClustersMeta,
        uniqueClusters.isAcceptableOrUnknown(
          data['unique_clusters']!,
          _uniqueClustersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_uniqueClustersMeta);
    }
    if (data.containsKey('new_clusters')) {
      context.handle(
        _newClustersMeta,
        newClusters.isAcceptableOrUnknown(
          data['new_clusters']!,
          _newClustersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_newClustersMeta);
    }
    if (data.containsKey('max_distance_date')) {
      context.handle(
        _maxDistanceDateMeta,
        maxDistanceDate.isAcceptableOrUnknown(
          data['max_distance_date']!,
          _maxDistanceDateMeta,
        ),
      );
    }
    if (data.containsKey('calculated_at')) {
      context.handle(
        _calculatedAtMeta,
        calculatedAt.isAcceptableOrUnknown(
          data['calculated_at']!,
          _calculatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_calculatedAtMeta);
    }
    if (data.containsKey('cluster_ids_json')) {
      context.handle(
        _clusterIdsJsonMeta,
        clusterIdsJson.isAcceptableOrUnknown(
          data['cluster_ids_json']!,
          _clusterIdsJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {yearMonth};
  @override
  MonthlySummaryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MonthlySummaryRow(
      yearMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}year_month'],
      )!,
      outingDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}outing_days'],
      )!,
      distanceM: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}distance_m'],
      )!,
      uniqueClusters: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unique_clusters'],
      )!,
      newClusters: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}new_clusters'],
      )!,
      maxDistanceDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}max_distance_date'],
      ),
      calculatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}calculated_at'],
      )!,
      clusterIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cluster_ids_json'],
      )!,
    );
  }

  @override
  $MonthlySummariesTable createAlias(String alias) {
    return $MonthlySummariesTable(attachedDatabase, alias);
  }
}

class MonthlySummaryRow extends DataClass
    implements Insertable<MonthlySummaryRow> {
  final String yearMonth;
  final int outingDays;
  final int distanceM;
  final int uniqueClusters;
  final int newClusters;
  final String? maxDistanceDate;
  final DateTime calculatedAt;
  final String clusterIdsJson;
  const MonthlySummaryRow({
    required this.yearMonth,
    required this.outingDays,
    required this.distanceM,
    required this.uniqueClusters,
    required this.newClusters,
    this.maxDistanceDate,
    required this.calculatedAt,
    required this.clusterIdsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['year_month'] = Variable<String>(yearMonth);
    map['outing_days'] = Variable<int>(outingDays);
    map['distance_m'] = Variable<int>(distanceM);
    map['unique_clusters'] = Variable<int>(uniqueClusters);
    map['new_clusters'] = Variable<int>(newClusters);
    if (!nullToAbsent || maxDistanceDate != null) {
      map['max_distance_date'] = Variable<String>(maxDistanceDate);
    }
    map['calculated_at'] = Variable<DateTime>(calculatedAt);
    map['cluster_ids_json'] = Variable<String>(clusterIdsJson);
    return map;
  }

  MonthlySummariesCompanion toCompanion(bool nullToAbsent) {
    return MonthlySummariesCompanion(
      yearMonth: Value(yearMonth),
      outingDays: Value(outingDays),
      distanceM: Value(distanceM),
      uniqueClusters: Value(uniqueClusters),
      newClusters: Value(newClusters),
      maxDistanceDate: maxDistanceDate == null && nullToAbsent
          ? const Value.absent()
          : Value(maxDistanceDate),
      calculatedAt: Value(calculatedAt),
      clusterIdsJson: Value(clusterIdsJson),
    );
  }

  factory MonthlySummaryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MonthlySummaryRow(
      yearMonth: serializer.fromJson<String>(json['yearMonth']),
      outingDays: serializer.fromJson<int>(json['outingDays']),
      distanceM: serializer.fromJson<int>(json['distanceM']),
      uniqueClusters: serializer.fromJson<int>(json['uniqueClusters']),
      newClusters: serializer.fromJson<int>(json['newClusters']),
      maxDistanceDate: serializer.fromJson<String?>(json['maxDistanceDate']),
      calculatedAt: serializer.fromJson<DateTime>(json['calculatedAt']),
      clusterIdsJson: serializer.fromJson<String>(json['clusterIdsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'yearMonth': serializer.toJson<String>(yearMonth),
      'outingDays': serializer.toJson<int>(outingDays),
      'distanceM': serializer.toJson<int>(distanceM),
      'uniqueClusters': serializer.toJson<int>(uniqueClusters),
      'newClusters': serializer.toJson<int>(newClusters),
      'maxDistanceDate': serializer.toJson<String?>(maxDistanceDate),
      'calculatedAt': serializer.toJson<DateTime>(calculatedAt),
      'clusterIdsJson': serializer.toJson<String>(clusterIdsJson),
    };
  }

  MonthlySummaryRow copyWith({
    String? yearMonth,
    int? outingDays,
    int? distanceM,
    int? uniqueClusters,
    int? newClusters,
    Value<String?> maxDistanceDate = const Value.absent(),
    DateTime? calculatedAt,
    String? clusterIdsJson,
  }) => MonthlySummaryRow(
    yearMonth: yearMonth ?? this.yearMonth,
    outingDays: outingDays ?? this.outingDays,
    distanceM: distanceM ?? this.distanceM,
    uniqueClusters: uniqueClusters ?? this.uniqueClusters,
    newClusters: newClusters ?? this.newClusters,
    maxDistanceDate: maxDistanceDate.present
        ? maxDistanceDate.value
        : this.maxDistanceDate,
    calculatedAt: calculatedAt ?? this.calculatedAt,
    clusterIdsJson: clusterIdsJson ?? this.clusterIdsJson,
  );
  MonthlySummaryRow copyWithCompanion(MonthlySummariesCompanion data) {
    return MonthlySummaryRow(
      yearMonth: data.yearMonth.present ? data.yearMonth.value : this.yearMonth,
      outingDays: data.outingDays.present
          ? data.outingDays.value
          : this.outingDays,
      distanceM: data.distanceM.present ? data.distanceM.value : this.distanceM,
      uniqueClusters: data.uniqueClusters.present
          ? data.uniqueClusters.value
          : this.uniqueClusters,
      newClusters: data.newClusters.present
          ? data.newClusters.value
          : this.newClusters,
      maxDistanceDate: data.maxDistanceDate.present
          ? data.maxDistanceDate.value
          : this.maxDistanceDate,
      calculatedAt: data.calculatedAt.present
          ? data.calculatedAt.value
          : this.calculatedAt,
      clusterIdsJson: data.clusterIdsJson.present
          ? data.clusterIdsJson.value
          : this.clusterIdsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MonthlySummaryRow(')
          ..write('yearMonth: $yearMonth, ')
          ..write('outingDays: $outingDays, ')
          ..write('distanceM: $distanceM, ')
          ..write('uniqueClusters: $uniqueClusters, ')
          ..write('newClusters: $newClusters, ')
          ..write('maxDistanceDate: $maxDistanceDate, ')
          ..write('calculatedAt: $calculatedAt, ')
          ..write('clusterIdsJson: $clusterIdsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    yearMonth,
    outingDays,
    distanceM,
    uniqueClusters,
    newClusters,
    maxDistanceDate,
    calculatedAt,
    clusterIdsJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MonthlySummaryRow &&
          other.yearMonth == this.yearMonth &&
          other.outingDays == this.outingDays &&
          other.distanceM == this.distanceM &&
          other.uniqueClusters == this.uniqueClusters &&
          other.newClusters == this.newClusters &&
          other.maxDistanceDate == this.maxDistanceDate &&
          other.calculatedAt == this.calculatedAt &&
          other.clusterIdsJson == this.clusterIdsJson);
}

class MonthlySummariesCompanion extends UpdateCompanion<MonthlySummaryRow> {
  final Value<String> yearMonth;
  final Value<int> outingDays;
  final Value<int> distanceM;
  final Value<int> uniqueClusters;
  final Value<int> newClusters;
  final Value<String?> maxDistanceDate;
  final Value<DateTime> calculatedAt;
  final Value<String> clusterIdsJson;
  final Value<int> rowid;
  const MonthlySummariesCompanion({
    this.yearMonth = const Value.absent(),
    this.outingDays = const Value.absent(),
    this.distanceM = const Value.absent(),
    this.uniqueClusters = const Value.absent(),
    this.newClusters = const Value.absent(),
    this.maxDistanceDate = const Value.absent(),
    this.calculatedAt = const Value.absent(),
    this.clusterIdsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MonthlySummariesCompanion.insert({
    required String yearMonth,
    required int outingDays,
    required int distanceM,
    required int uniqueClusters,
    required int newClusters,
    this.maxDistanceDate = const Value.absent(),
    required DateTime calculatedAt,
    this.clusterIdsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : yearMonth = Value(yearMonth),
       outingDays = Value(outingDays),
       distanceM = Value(distanceM),
       uniqueClusters = Value(uniqueClusters),
       newClusters = Value(newClusters),
       calculatedAt = Value(calculatedAt);
  static Insertable<MonthlySummaryRow> custom({
    Expression<String>? yearMonth,
    Expression<int>? outingDays,
    Expression<int>? distanceM,
    Expression<int>? uniqueClusters,
    Expression<int>? newClusters,
    Expression<String>? maxDistanceDate,
    Expression<DateTime>? calculatedAt,
    Expression<String>? clusterIdsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (yearMonth != null) 'year_month': yearMonth,
      if (outingDays != null) 'outing_days': outingDays,
      if (distanceM != null) 'distance_m': distanceM,
      if (uniqueClusters != null) 'unique_clusters': uniqueClusters,
      if (newClusters != null) 'new_clusters': newClusters,
      if (maxDistanceDate != null) 'max_distance_date': maxDistanceDate,
      if (calculatedAt != null) 'calculated_at': calculatedAt,
      if (clusterIdsJson != null) 'cluster_ids_json': clusterIdsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MonthlySummariesCompanion copyWith({
    Value<String>? yearMonth,
    Value<int>? outingDays,
    Value<int>? distanceM,
    Value<int>? uniqueClusters,
    Value<int>? newClusters,
    Value<String?>? maxDistanceDate,
    Value<DateTime>? calculatedAt,
    Value<String>? clusterIdsJson,
    Value<int>? rowid,
  }) {
    return MonthlySummariesCompanion(
      yearMonth: yearMonth ?? this.yearMonth,
      outingDays: outingDays ?? this.outingDays,
      distanceM: distanceM ?? this.distanceM,
      uniqueClusters: uniqueClusters ?? this.uniqueClusters,
      newClusters: newClusters ?? this.newClusters,
      maxDistanceDate: maxDistanceDate ?? this.maxDistanceDate,
      calculatedAt: calculatedAt ?? this.calculatedAt,
      clusterIdsJson: clusterIdsJson ?? this.clusterIdsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (yearMonth.present) {
      map['year_month'] = Variable<String>(yearMonth.value);
    }
    if (outingDays.present) {
      map['outing_days'] = Variable<int>(outingDays.value);
    }
    if (distanceM.present) {
      map['distance_m'] = Variable<int>(distanceM.value);
    }
    if (uniqueClusters.present) {
      map['unique_clusters'] = Variable<int>(uniqueClusters.value);
    }
    if (newClusters.present) {
      map['new_clusters'] = Variable<int>(newClusters.value);
    }
    if (maxDistanceDate.present) {
      map['max_distance_date'] = Variable<String>(maxDistanceDate.value);
    }
    if (calculatedAt.present) {
      map['calculated_at'] = Variable<DateTime>(calculatedAt.value);
    }
    if (clusterIdsJson.present) {
      map['cluster_ids_json'] = Variable<String>(clusterIdsJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MonthlySummariesCompanion(')
          ..write('yearMonth: $yearMonth, ')
          ..write('outingDays: $outingDays, ')
          ..write('distanceM: $distanceM, ')
          ..write('uniqueClusters: $uniqueClusters, ')
          ..write('newClusters: $newClusters, ')
          ..write('maxDistanceDate: $maxDistanceDate, ')
          ..write('calculatedAt: $calculatedAt, ')
          ..write('clusterIdsJson: $clusterIdsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InsightsTable extends Insights
    with TableInfo<$InsightsTable, InsightRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InsightsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _periodKeyMeta = const VerificationMeta(
    'periodKey',
  );
  @override
  late final GeneratedColumn<String> periodKey = GeneratedColumn<String>(
    'period_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ruleIdMeta = const VerificationMeta('ruleId');
  @override
  late final GeneratedColumn<String> ruleId = GeneratedColumn<String>(
    'rule_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _severityMeta = const VerificationMeta(
    'severity',
  );
  @override
  late final GeneratedColumn<String> severity = GeneratedColumn<String>(
    'severity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _metricJsonMeta = const VerificationMeta(
    'metricJson',
  );
  @override
  late final GeneratedColumn<String> metricJson = GeneratedColumn<String>(
    'metric_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dismissedMeta = const VerificationMeta(
    'dismissed',
  );
  @override
  late final GeneratedColumn<bool> dismissed = GeneratedColumn<bool>(
    'dismissed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dismissed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    periodKey,
    ruleId,
    severity,
    title,
    body,
    metricJson,
    createdAt,
    dismissed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'insights';
  @override
  VerificationContext validateIntegrity(
    Insertable<InsightRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('period_key')) {
      context.handle(
        _periodKeyMeta,
        periodKey.isAcceptableOrUnknown(data['period_key']!, _periodKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_periodKeyMeta);
    }
    if (data.containsKey('rule_id')) {
      context.handle(
        _ruleIdMeta,
        ruleId.isAcceptableOrUnknown(data['rule_id']!, _ruleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ruleIdMeta);
    }
    if (data.containsKey('severity')) {
      context.handle(
        _severityMeta,
        severity.isAcceptableOrUnknown(data['severity']!, _severityMeta),
      );
    } else if (isInserting) {
      context.missing(_severityMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('metric_json')) {
      context.handle(
        _metricJsonMeta,
        metricJson.isAcceptableOrUnknown(data['metric_json']!, _metricJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_metricJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('dismissed')) {
      context.handle(
        _dismissedMeta,
        dismissed.isAcceptableOrUnknown(data['dismissed']!, _dismissedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {periodKey, ruleId},
  ];
  @override
  InsightRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InsightRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      periodKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}period_key'],
      )!,
      ruleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rule_id'],
      )!,
      severity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}severity'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      metricJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metric_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      dismissed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dismissed'],
      )!,
    );
  }

  @override
  $InsightsTable createAlias(String alias) {
    return $InsightsTable(attachedDatabase, alias);
  }
}

class InsightRow extends DataClass implements Insertable<InsightRow> {
  final int id;
  final String periodKey;
  final String ruleId;
  final String severity;
  final String title;
  final String body;
  final String metricJson;
  final DateTime createdAt;
  final bool dismissed;
  const InsightRow({
    required this.id,
    required this.periodKey,
    required this.ruleId,
    required this.severity,
    required this.title,
    required this.body,
    required this.metricJson,
    required this.createdAt,
    required this.dismissed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['period_key'] = Variable<String>(periodKey);
    map['rule_id'] = Variable<String>(ruleId);
    map['severity'] = Variable<String>(severity);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    map['metric_json'] = Variable<String>(metricJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['dismissed'] = Variable<bool>(dismissed);
    return map;
  }

  InsightsCompanion toCompanion(bool nullToAbsent) {
    return InsightsCompanion(
      id: Value(id),
      periodKey: Value(periodKey),
      ruleId: Value(ruleId),
      severity: Value(severity),
      title: Value(title),
      body: Value(body),
      metricJson: Value(metricJson),
      createdAt: Value(createdAt),
      dismissed: Value(dismissed),
    );
  }

  factory InsightRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InsightRow(
      id: serializer.fromJson<int>(json['id']),
      periodKey: serializer.fromJson<String>(json['periodKey']),
      ruleId: serializer.fromJson<String>(json['ruleId']),
      severity: serializer.fromJson<String>(json['severity']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      metricJson: serializer.fromJson<String>(json['metricJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      dismissed: serializer.fromJson<bool>(json['dismissed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'periodKey': serializer.toJson<String>(periodKey),
      'ruleId': serializer.toJson<String>(ruleId),
      'severity': serializer.toJson<String>(severity),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'metricJson': serializer.toJson<String>(metricJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'dismissed': serializer.toJson<bool>(dismissed),
    };
  }

  InsightRow copyWith({
    int? id,
    String? periodKey,
    String? ruleId,
    String? severity,
    String? title,
    String? body,
    String? metricJson,
    DateTime? createdAt,
    bool? dismissed,
  }) => InsightRow(
    id: id ?? this.id,
    periodKey: periodKey ?? this.periodKey,
    ruleId: ruleId ?? this.ruleId,
    severity: severity ?? this.severity,
    title: title ?? this.title,
    body: body ?? this.body,
    metricJson: metricJson ?? this.metricJson,
    createdAt: createdAt ?? this.createdAt,
    dismissed: dismissed ?? this.dismissed,
  );
  InsightRow copyWithCompanion(InsightsCompanion data) {
    return InsightRow(
      id: data.id.present ? data.id.value : this.id,
      periodKey: data.periodKey.present ? data.periodKey.value : this.periodKey,
      ruleId: data.ruleId.present ? data.ruleId.value : this.ruleId,
      severity: data.severity.present ? data.severity.value : this.severity,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      metricJson: data.metricJson.present
          ? data.metricJson.value
          : this.metricJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      dismissed: data.dismissed.present ? data.dismissed.value : this.dismissed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InsightRow(')
          ..write('id: $id, ')
          ..write('periodKey: $periodKey, ')
          ..write('ruleId: $ruleId, ')
          ..write('severity: $severity, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('metricJson: $metricJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('dismissed: $dismissed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    periodKey,
    ruleId,
    severity,
    title,
    body,
    metricJson,
    createdAt,
    dismissed,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InsightRow &&
          other.id == this.id &&
          other.periodKey == this.periodKey &&
          other.ruleId == this.ruleId &&
          other.severity == this.severity &&
          other.title == this.title &&
          other.body == this.body &&
          other.metricJson == this.metricJson &&
          other.createdAt == this.createdAt &&
          other.dismissed == this.dismissed);
}

class InsightsCompanion extends UpdateCompanion<InsightRow> {
  final Value<int> id;
  final Value<String> periodKey;
  final Value<String> ruleId;
  final Value<String> severity;
  final Value<String> title;
  final Value<String> body;
  final Value<String> metricJson;
  final Value<DateTime> createdAt;
  final Value<bool> dismissed;
  const InsightsCompanion({
    this.id = const Value.absent(),
    this.periodKey = const Value.absent(),
    this.ruleId = const Value.absent(),
    this.severity = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.metricJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.dismissed = const Value.absent(),
  });
  InsightsCompanion.insert({
    this.id = const Value.absent(),
    required String periodKey,
    required String ruleId,
    required String severity,
    required String title,
    required String body,
    required String metricJson,
    required DateTime createdAt,
    this.dismissed = const Value.absent(),
  }) : periodKey = Value(periodKey),
       ruleId = Value(ruleId),
       severity = Value(severity),
       title = Value(title),
       body = Value(body),
       metricJson = Value(metricJson),
       createdAt = Value(createdAt);
  static Insertable<InsightRow> custom({
    Expression<int>? id,
    Expression<String>? periodKey,
    Expression<String>? ruleId,
    Expression<String>? severity,
    Expression<String>? title,
    Expression<String>? body,
    Expression<String>? metricJson,
    Expression<DateTime>? createdAt,
    Expression<bool>? dismissed,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (periodKey != null) 'period_key': periodKey,
      if (ruleId != null) 'rule_id': ruleId,
      if (severity != null) 'severity': severity,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (metricJson != null) 'metric_json': metricJson,
      if (createdAt != null) 'created_at': createdAt,
      if (dismissed != null) 'dismissed': dismissed,
    });
  }

  InsightsCompanion copyWith({
    Value<int>? id,
    Value<String>? periodKey,
    Value<String>? ruleId,
    Value<String>? severity,
    Value<String>? title,
    Value<String>? body,
    Value<String>? metricJson,
    Value<DateTime>? createdAt,
    Value<bool>? dismissed,
  }) {
    return InsightsCompanion(
      id: id ?? this.id,
      periodKey: periodKey ?? this.periodKey,
      ruleId: ruleId ?? this.ruleId,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      body: body ?? this.body,
      metricJson: metricJson ?? this.metricJson,
      createdAt: createdAt ?? this.createdAt,
      dismissed: dismissed ?? this.dismissed,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (periodKey.present) {
      map['period_key'] = Variable<String>(periodKey.value);
    }
    if (ruleId.present) {
      map['rule_id'] = Variable<String>(ruleId.value);
    }
    if (severity.present) {
      map['severity'] = Variable<String>(severity.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (metricJson.present) {
      map['metric_json'] = Variable<String>(metricJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (dismissed.present) {
      map['dismissed'] = Variable<bool>(dismissed.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InsightsCompanion(')
          ..write('id: $id, ')
          ..write('periodKey: $periodKey, ')
          ..write('ruleId: $ruleId, ')
          ..write('severity: $severity, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('metricJson: $metricJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('dismissed: $dismissed')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSettingRow extends DataClass implements Insertable<AppSettingRow> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const AppSettingRow({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppSettingRow copyWith({String? key, String? value, DateTime? updatedAt}) =>
      AppSettingRow(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AppSettingRow copyWithCompanion(AppSettingsCompanion data) {
    return AppSettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingRow(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingRow &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       updatedAt = Value(updatedAt);
  static Insertable<AppSettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserMilestonesTable extends UserMilestones
    with TableInfo<$UserMilestonesTable, UserMilestoneRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserMilestonesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timeZoneIdMeta = const VerificationMeta(
    'timeZoneId',
  );
  @override
  late final GeneratedColumn<String> timeZoneId = GeneratedColumn<String>(
    'time_zone_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceCandidateKeyMeta =
      const VerificationMeta('sourceCandidateKey');
  @override
  late final GeneratedColumn<String> sourceCandidateKey =
      GeneratedColumn<String>(
        'source_candidate_key',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startDate,
    endDate,
    timeZoneId,
    title,
    note,
    sourceCandidateKey,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_milestones';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserMilestoneRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    if (data.containsKey('time_zone_id')) {
      context.handle(
        _timeZoneIdMeta,
        timeZoneId.isAcceptableOrUnknown(
          data['time_zone_id']!,
          _timeZoneIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timeZoneIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('source_candidate_key')) {
      context.handle(
        _sourceCandidateKeyMeta,
        sourceCandidateKey.isAcceptableOrUnknown(
          data['source_candidate_key']!,
          _sourceCandidateKeyMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserMilestoneRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserMilestoneRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_date'],
      ),
      timeZoneId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_zone_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      sourceCandidateKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_candidate_key'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $UserMilestonesTable createAlias(String alias) {
    return $UserMilestonesTable(attachedDatabase, alias);
  }
}

class UserMilestoneRow extends DataClass
    implements Insertable<UserMilestoneRow> {
  final String id;
  final String startDate;
  final String? endDate;
  final String timeZoneId;
  final String title;
  final String? note;
  final String? sourceCandidateKey;
  final DateTime createdAt;
  final DateTime updatedAt;
  const UserMilestoneRow({
    required this.id,
    required this.startDate,
    this.endDate,
    required this.timeZoneId,
    required this.title,
    this.note,
    this.sourceCandidateKey,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['start_date'] = Variable<String>(startDate);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<String>(endDate);
    }
    map['time_zone_id'] = Variable<String>(timeZoneId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || sourceCandidateKey != null) {
      map['source_candidate_key'] = Variable<String>(sourceCandidateKey);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UserMilestonesCompanion toCompanion(bool nullToAbsent) {
    return UserMilestonesCompanion(
      id: Value(id),
      startDate: Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      timeZoneId: Value(timeZoneId),
      title: Value(title),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      sourceCandidateKey: sourceCandidateKey == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceCandidateKey),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserMilestoneRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserMilestoneRow(
      id: serializer.fromJson<String>(json['id']),
      startDate: serializer.fromJson<String>(json['startDate']),
      endDate: serializer.fromJson<String?>(json['endDate']),
      timeZoneId: serializer.fromJson<String>(json['timeZoneId']),
      title: serializer.fromJson<String>(json['title']),
      note: serializer.fromJson<String?>(json['note']),
      sourceCandidateKey: serializer.fromJson<String?>(
        json['sourceCandidateKey'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'startDate': serializer.toJson<String>(startDate),
      'endDate': serializer.toJson<String?>(endDate),
      'timeZoneId': serializer.toJson<String>(timeZoneId),
      'title': serializer.toJson<String>(title),
      'note': serializer.toJson<String?>(note),
      'sourceCandidateKey': serializer.toJson<String?>(sourceCandidateKey),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UserMilestoneRow copyWith({
    String? id,
    String? startDate,
    Value<String?> endDate = const Value.absent(),
    String? timeZoneId,
    String? title,
    Value<String?> note = const Value.absent(),
    Value<String?> sourceCandidateKey = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UserMilestoneRow(
    id: id ?? this.id,
    startDate: startDate ?? this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
    timeZoneId: timeZoneId ?? this.timeZoneId,
    title: title ?? this.title,
    note: note.present ? note.value : this.note,
    sourceCandidateKey: sourceCandidateKey.present
        ? sourceCandidateKey.value
        : this.sourceCandidateKey,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  UserMilestoneRow copyWithCompanion(UserMilestonesCompanion data) {
    return UserMilestoneRow(
      id: data.id.present ? data.id.value : this.id,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      timeZoneId: data.timeZoneId.present
          ? data.timeZoneId.value
          : this.timeZoneId,
      title: data.title.present ? data.title.value : this.title,
      note: data.note.present ? data.note.value : this.note,
      sourceCandidateKey: data.sourceCandidateKey.present
          ? data.sourceCandidateKey.value
          : this.sourceCandidateKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserMilestoneRow(')
          ..write('id: $id, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('timeZoneId: $timeZoneId, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('sourceCandidateKey: $sourceCandidateKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    startDate,
    endDate,
    timeZoneId,
    title,
    note,
    sourceCandidateKey,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserMilestoneRow &&
          other.id == this.id &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.timeZoneId == this.timeZoneId &&
          other.title == this.title &&
          other.note == this.note &&
          other.sourceCandidateKey == this.sourceCandidateKey &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class UserMilestonesCompanion extends UpdateCompanion<UserMilestoneRow> {
  final Value<String> id;
  final Value<String> startDate;
  final Value<String?> endDate;
  final Value<String> timeZoneId;
  final Value<String> title;
  final Value<String?> note;
  final Value<String?> sourceCandidateKey;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UserMilestonesCompanion({
    this.id = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.timeZoneId = const Value.absent(),
    this.title = const Value.absent(),
    this.note = const Value.absent(),
    this.sourceCandidateKey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserMilestonesCompanion.insert({
    required String id,
    required String startDate,
    this.endDate = const Value.absent(),
    required String timeZoneId,
    required String title,
    this.note = const Value.absent(),
    this.sourceCandidateKey = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       startDate = Value(startDate),
       timeZoneId = Value(timeZoneId),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<UserMilestoneRow> custom({
    Expression<String>? id,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<String>? timeZoneId,
    Expression<String>? title,
    Expression<String>? note,
    Expression<String>? sourceCandidateKey,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (timeZoneId != null) 'time_zone_id': timeZoneId,
      if (title != null) 'title': title,
      if (note != null) 'note': note,
      if (sourceCandidateKey != null)
        'source_candidate_key': sourceCandidateKey,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserMilestonesCompanion copyWith({
    Value<String>? id,
    Value<String>? startDate,
    Value<String?>? endDate,
    Value<String>? timeZoneId,
    Value<String>? title,
    Value<String?>? note,
    Value<String?>? sourceCandidateKey,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return UserMilestonesCompanion(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      timeZoneId: timeZoneId ?? this.timeZoneId,
      title: title ?? this.title,
      note: note ?? this.note,
      sourceCandidateKey: sourceCandidateKey ?? this.sourceCandidateKey,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    if (timeZoneId.present) {
      map['time_zone_id'] = Variable<String>(timeZoneId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (sourceCandidateKey.present) {
      map['source_candidate_key'] = Variable<String>(sourceCandidateKey.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserMilestonesCompanion(')
          ..write('id: $id, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('timeZoneId: $timeZoneId, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('sourceCandidateKey: $sourceCandidateKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TimelineImportsTable timelineImports = $TimelineImportsTable(
    this,
  );
  late final $VisitsTable visits = $VisitsTable(this);
  late final $MovementsTable movements = $MovementsTable(this);
  late final $PlaceClustersTable placeClusters = $PlaceClustersTable(this);
  late final $PlaceLabelsTable placeLabels = $PlaceLabelsTable(this);
  late final $DailySummariesTable dailySummaries = $DailySummariesTable(this);
  late final $MonthlySummariesTable monthlySummaries = $MonthlySummariesTable(
    this,
  );
  late final $InsightsTable insights = $InsightsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $UserMilestonesTable userMilestones = $UserMilestonesTable(this);
  late final Index visitsStartIdx = Index(
    'visits_start_idx',
    'CREATE INDEX visits_start_idx ON visits (start_at_utc)',
  );
  late final Index visitsClusterIdx = Index(
    'visits_cluster_idx',
    'CREATE INDEX visits_cluster_idx ON visits (cluster_id, start_at_utc)',
  );
  late final Index movementsStartIdx = Index(
    'movements_start_idx',
    'CREATE INDEX movements_start_idx ON movements (start_at_utc)',
  );
  late final Index clustersStableIdx = Index(
    'clusters_stable_idx',
    'CREATE INDEX clusters_stable_idx ON place_clusters (stable_key)',
  );
  late final Index clustersLastIdx = Index(
    'clusters_last_idx',
    'CREATE INDEX clusters_last_idx ON place_clusters (last_at)',
  );
  late final Index insightsPeriodIdx = Index(
    'insights_period_idx',
    'CREATE INDEX insights_period_idx ON insights (period_key, rule_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    timelineImports,
    visits,
    movements,
    placeClusters,
    placeLabels,
    dailySummaries,
    monthlySummaries,
    insights,
    appSettings,
    userMilestones,
    visitsStartIdx,
    visitsClusterIdx,
    movementsStartIdx,
    clustersStableIdx,
    clustersLastIdx,
    insightsPeriodIdx,
  ];
}

typedef $$TimelineImportsTableCreateCompanionBuilder =
    TimelineImportsCompanion Function({
      Value<int> id,
      required String fileHash,
      required String schemaType,
      required DateTime startedAt,
      Value<DateTime?> completedAt,
      Value<DateTime?> sourceMinAt,
      Value<DateTime?> sourceMaxAt,
      required String status,
      Value<int> warningCount,
      Value<int> addedVisits,
      Value<int> addedMovements,
      Value<int> updatedVisits,
      Value<int> updatedMovements,
      Value<String> reconciliationKind,
      Value<bool> requiresFullReconciliation,
    });
typedef $$TimelineImportsTableUpdateCompanionBuilder =
    TimelineImportsCompanion Function({
      Value<int> id,
      Value<String> fileHash,
      Value<String> schemaType,
      Value<DateTime> startedAt,
      Value<DateTime?> completedAt,
      Value<DateTime?> sourceMinAt,
      Value<DateTime?> sourceMaxAt,
      Value<String> status,
      Value<int> warningCount,
      Value<int> addedVisits,
      Value<int> addedMovements,
      Value<int> updatedVisits,
      Value<int> updatedMovements,
      Value<String> reconciliationKind,
      Value<bool> requiresFullReconciliation,
    });

class $$TimelineImportsTableFilterComposer
    extends Composer<_$AppDatabase, $TimelineImportsTable> {
  $$TimelineImportsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileHash => $composableBuilder(
    column: $table.fileHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get schemaType => $composableBuilder(
    column: $table.schemaType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sourceMinAt => $composableBuilder(
    column: $table.sourceMinAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sourceMaxAt => $composableBuilder(
    column: $table.sourceMaxAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get warningCount => $composableBuilder(
    column: $table.warningCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get addedVisits => $composableBuilder(
    column: $table.addedVisits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get addedMovements => $composableBuilder(
    column: $table.addedMovements,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedVisits => $composableBuilder(
    column: $table.updatedVisits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedMovements => $composableBuilder(
    column: $table.updatedMovements,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reconciliationKind => $composableBuilder(
    column: $table.reconciliationKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get requiresFullReconciliation => $composableBuilder(
    column: $table.requiresFullReconciliation,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TimelineImportsTableOrderingComposer
    extends Composer<_$AppDatabase, $TimelineImportsTable> {
  $$TimelineImportsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileHash => $composableBuilder(
    column: $table.fileHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get schemaType => $composableBuilder(
    column: $table.schemaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sourceMinAt => $composableBuilder(
    column: $table.sourceMinAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sourceMaxAt => $composableBuilder(
    column: $table.sourceMaxAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get warningCount => $composableBuilder(
    column: $table.warningCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get addedVisits => $composableBuilder(
    column: $table.addedVisits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get addedMovements => $composableBuilder(
    column: $table.addedMovements,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedVisits => $composableBuilder(
    column: $table.updatedVisits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedMovements => $composableBuilder(
    column: $table.updatedMovements,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reconciliationKind => $composableBuilder(
    column: $table.reconciliationKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get requiresFullReconciliation => $composableBuilder(
    column: $table.requiresFullReconciliation,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TimelineImportsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TimelineImportsTable> {
  $$TimelineImportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fileHash =>
      $composableBuilder(column: $table.fileHash, builder: (column) => column);

  GeneratedColumn<String> get schemaType => $composableBuilder(
    column: $table.schemaType,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get sourceMinAt => $composableBuilder(
    column: $table.sourceMinAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get sourceMaxAt => $composableBuilder(
    column: $table.sourceMaxAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get warningCount => $composableBuilder(
    column: $table.warningCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get addedVisits => $composableBuilder(
    column: $table.addedVisits,
    builder: (column) => column,
  );

  GeneratedColumn<int> get addedMovements => $composableBuilder(
    column: $table.addedMovements,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedVisits => $composableBuilder(
    column: $table.updatedVisits,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedMovements => $composableBuilder(
    column: $table.updatedMovements,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reconciliationKind => $composableBuilder(
    column: $table.reconciliationKind,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get requiresFullReconciliation => $composableBuilder(
    column: $table.requiresFullReconciliation,
    builder: (column) => column,
  );
}

class $$TimelineImportsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TimelineImportsTable,
          TimelineImportRow,
          $$TimelineImportsTableFilterComposer,
          $$TimelineImportsTableOrderingComposer,
          $$TimelineImportsTableAnnotationComposer,
          $$TimelineImportsTableCreateCompanionBuilder,
          $$TimelineImportsTableUpdateCompanionBuilder,
          (
            TimelineImportRow,
            BaseReferences<
              _$AppDatabase,
              $TimelineImportsTable,
              TimelineImportRow
            >,
          ),
          TimelineImportRow,
          PrefetchHooks Function()
        > {
  $$TimelineImportsTableTableManager(
    _$AppDatabase db,
    $TimelineImportsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimelineImportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TimelineImportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TimelineImportsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> fileHash = const Value.absent(),
                Value<String> schemaType = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime?> sourceMinAt = const Value.absent(),
                Value<DateTime?> sourceMaxAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> warningCount = const Value.absent(),
                Value<int> addedVisits = const Value.absent(),
                Value<int> addedMovements = const Value.absent(),
                Value<int> updatedVisits = const Value.absent(),
                Value<int> updatedMovements = const Value.absent(),
                Value<String> reconciliationKind = const Value.absent(),
                Value<bool> requiresFullReconciliation = const Value.absent(),
              }) => TimelineImportsCompanion(
                id: id,
                fileHash: fileHash,
                schemaType: schemaType,
                startedAt: startedAt,
                completedAt: completedAt,
                sourceMinAt: sourceMinAt,
                sourceMaxAt: sourceMaxAt,
                status: status,
                warningCount: warningCount,
                addedVisits: addedVisits,
                addedMovements: addedMovements,
                updatedVisits: updatedVisits,
                updatedMovements: updatedMovements,
                reconciliationKind: reconciliationKind,
                requiresFullReconciliation: requiresFullReconciliation,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String fileHash,
                required String schemaType,
                required DateTime startedAt,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime?> sourceMinAt = const Value.absent(),
                Value<DateTime?> sourceMaxAt = const Value.absent(),
                required String status,
                Value<int> warningCount = const Value.absent(),
                Value<int> addedVisits = const Value.absent(),
                Value<int> addedMovements = const Value.absent(),
                Value<int> updatedVisits = const Value.absent(),
                Value<int> updatedMovements = const Value.absent(),
                Value<String> reconciliationKind = const Value.absent(),
                Value<bool> requiresFullReconciliation = const Value.absent(),
              }) => TimelineImportsCompanion.insert(
                id: id,
                fileHash: fileHash,
                schemaType: schemaType,
                startedAt: startedAt,
                completedAt: completedAt,
                sourceMinAt: sourceMinAt,
                sourceMaxAt: sourceMaxAt,
                status: status,
                warningCount: warningCount,
                addedVisits: addedVisits,
                addedMovements: addedMovements,
                updatedVisits: updatedVisits,
                updatedMovements: updatedMovements,
                reconciliationKind: reconciliationKind,
                requiresFullReconciliation: requiresFullReconciliation,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TimelineImportsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TimelineImportsTable,
      TimelineImportRow,
      $$TimelineImportsTableFilterComposer,
      $$TimelineImportsTableOrderingComposer,
      $$TimelineImportsTableAnnotationComposer,
      $$TimelineImportsTableCreateCompanionBuilder,
      $$TimelineImportsTableUpdateCompanionBuilder,
      (
        TimelineImportRow,
        BaseReferences<_$AppDatabase, $TimelineImportsTable, TimelineImportRow>,
      ),
      TimelineImportRow,
      PrefetchHooks Function()
    >;
typedef $$VisitsTableCreateCompanionBuilder =
    VisitsCompanion Function({
      Value<int> id,
      required String sourceKey,
      required DateTime startAtUtc,
      required DateTime endAtUtc,
      required int latE7,
      required int lngE7,
      Value<int?> accuracyM,
      Value<String?> sourceLabel,
      Value<int?> clusterId,
      Value<double?> confidence,
    });
typedef $$VisitsTableUpdateCompanionBuilder =
    VisitsCompanion Function({
      Value<int> id,
      Value<String> sourceKey,
      Value<DateTime> startAtUtc,
      Value<DateTime> endAtUtc,
      Value<int> latE7,
      Value<int> lngE7,
      Value<int?> accuracyM,
      Value<String?> sourceLabel,
      Value<int?> clusterId,
      Value<double?> confidence,
    });

class $$VisitsTableFilterComposer
    extends Composer<_$AppDatabase, $VisitsTable> {
  $$VisitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceKey => $composableBuilder(
    column: $table.sourceKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startAtUtc => $composableBuilder(
    column: $table.startAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endAtUtc => $composableBuilder(
    column: $table.endAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get latE7 => $composableBuilder(
    column: $table.latE7,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lngE7 => $composableBuilder(
    column: $table.lngE7,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get accuracyM => $composableBuilder(
    column: $table.accuracyM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceLabel => $composableBuilder(
    column: $table.sourceLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clusterId => $composableBuilder(
    column: $table.clusterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VisitsTableOrderingComposer
    extends Composer<_$AppDatabase, $VisitsTable> {
  $$VisitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceKey => $composableBuilder(
    column: $table.sourceKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startAtUtc => $composableBuilder(
    column: $table.startAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endAtUtc => $composableBuilder(
    column: $table.endAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get latE7 => $composableBuilder(
    column: $table.latE7,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lngE7 => $composableBuilder(
    column: $table.lngE7,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get accuracyM => $composableBuilder(
    column: $table.accuracyM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceLabel => $composableBuilder(
    column: $table.sourceLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clusterId => $composableBuilder(
    column: $table.clusterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VisitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VisitsTable> {
  $$VisitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceKey =>
      $composableBuilder(column: $table.sourceKey, builder: (column) => column);

  GeneratedColumn<DateTime> get startAtUtc => $composableBuilder(
    column: $table.startAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get endAtUtc =>
      $composableBuilder(column: $table.endAtUtc, builder: (column) => column);

  GeneratedColumn<int> get latE7 =>
      $composableBuilder(column: $table.latE7, builder: (column) => column);

  GeneratedColumn<int> get lngE7 =>
      $composableBuilder(column: $table.lngE7, builder: (column) => column);

  GeneratedColumn<int> get accuracyM =>
      $composableBuilder(column: $table.accuracyM, builder: (column) => column);

  GeneratedColumn<String> get sourceLabel => $composableBuilder(
    column: $table.sourceLabel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get clusterId =>
      $composableBuilder(column: $table.clusterId, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );
}

class $$VisitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VisitsTable,
          VisitRow,
          $$VisitsTableFilterComposer,
          $$VisitsTableOrderingComposer,
          $$VisitsTableAnnotationComposer,
          $$VisitsTableCreateCompanionBuilder,
          $$VisitsTableUpdateCompanionBuilder,
          (VisitRow, BaseReferences<_$AppDatabase, $VisitsTable, VisitRow>),
          VisitRow,
          PrefetchHooks Function()
        > {
  $$VisitsTableTableManager(_$AppDatabase db, $VisitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VisitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VisitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VisitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sourceKey = const Value.absent(),
                Value<DateTime> startAtUtc = const Value.absent(),
                Value<DateTime> endAtUtc = const Value.absent(),
                Value<int> latE7 = const Value.absent(),
                Value<int> lngE7 = const Value.absent(),
                Value<int?> accuracyM = const Value.absent(),
                Value<String?> sourceLabel = const Value.absent(),
                Value<int?> clusterId = const Value.absent(),
                Value<double?> confidence = const Value.absent(),
              }) => VisitsCompanion(
                id: id,
                sourceKey: sourceKey,
                startAtUtc: startAtUtc,
                endAtUtc: endAtUtc,
                latE7: latE7,
                lngE7: lngE7,
                accuracyM: accuracyM,
                sourceLabel: sourceLabel,
                clusterId: clusterId,
                confidence: confidence,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sourceKey,
                required DateTime startAtUtc,
                required DateTime endAtUtc,
                required int latE7,
                required int lngE7,
                Value<int?> accuracyM = const Value.absent(),
                Value<String?> sourceLabel = const Value.absent(),
                Value<int?> clusterId = const Value.absent(),
                Value<double?> confidence = const Value.absent(),
              }) => VisitsCompanion.insert(
                id: id,
                sourceKey: sourceKey,
                startAtUtc: startAtUtc,
                endAtUtc: endAtUtc,
                latE7: latE7,
                lngE7: lngE7,
                accuracyM: accuracyM,
                sourceLabel: sourceLabel,
                clusterId: clusterId,
                confidence: confidence,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VisitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VisitsTable,
      VisitRow,
      $$VisitsTableFilterComposer,
      $$VisitsTableOrderingComposer,
      $$VisitsTableAnnotationComposer,
      $$VisitsTableCreateCompanionBuilder,
      $$VisitsTableUpdateCompanionBuilder,
      (VisitRow, BaseReferences<_$AppDatabase, $VisitsTable, VisitRow>),
      VisitRow,
      PrefetchHooks Function()
    >;
typedef $$MovementsTableCreateCompanionBuilder =
    MovementsCompanion Function({
      Value<int> id,
      required String sourceKey,
      required DateTime startAtUtc,
      required DateTime endAtUtc,
      Value<int?> startLatE7,
      Value<int?> startLngE7,
      Value<int?> endLatE7,
      Value<int?> endLngE7,
      Value<int?> distanceM,
      required String distanceMethod,
      Value<String?> activityType,
      Value<double?> confidence,
      Value<String?> pathJson,
      Value<bool> validDistance,
    });
typedef $$MovementsTableUpdateCompanionBuilder =
    MovementsCompanion Function({
      Value<int> id,
      Value<String> sourceKey,
      Value<DateTime> startAtUtc,
      Value<DateTime> endAtUtc,
      Value<int?> startLatE7,
      Value<int?> startLngE7,
      Value<int?> endLatE7,
      Value<int?> endLngE7,
      Value<int?> distanceM,
      Value<String> distanceMethod,
      Value<String?> activityType,
      Value<double?> confidence,
      Value<String?> pathJson,
      Value<bool> validDistance,
    });

class $$MovementsTableFilterComposer
    extends Composer<_$AppDatabase, $MovementsTable> {
  $$MovementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceKey => $composableBuilder(
    column: $table.sourceKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startAtUtc => $composableBuilder(
    column: $table.startAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endAtUtc => $composableBuilder(
    column: $table.endAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startLatE7 => $composableBuilder(
    column: $table.startLatE7,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startLngE7 => $composableBuilder(
    column: $table.startLngE7,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endLatE7 => $composableBuilder(
    column: $table.endLatE7,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endLngE7 => $composableBuilder(
    column: $table.endLngE7,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get distanceM => $composableBuilder(
    column: $table.distanceM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get distanceMethod => $composableBuilder(
    column: $table.distanceMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activityType => $composableBuilder(
    column: $table.activityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pathJson => $composableBuilder(
    column: $table.pathJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get validDistance => $composableBuilder(
    column: $table.validDistance,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MovementsTableOrderingComposer
    extends Composer<_$AppDatabase, $MovementsTable> {
  $$MovementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceKey => $composableBuilder(
    column: $table.sourceKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startAtUtc => $composableBuilder(
    column: $table.startAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endAtUtc => $composableBuilder(
    column: $table.endAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startLatE7 => $composableBuilder(
    column: $table.startLatE7,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startLngE7 => $composableBuilder(
    column: $table.startLngE7,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endLatE7 => $composableBuilder(
    column: $table.endLatE7,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endLngE7 => $composableBuilder(
    column: $table.endLngE7,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get distanceM => $composableBuilder(
    column: $table.distanceM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get distanceMethod => $composableBuilder(
    column: $table.distanceMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityType => $composableBuilder(
    column: $table.activityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pathJson => $composableBuilder(
    column: $table.pathJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get validDistance => $composableBuilder(
    column: $table.validDistance,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MovementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MovementsTable> {
  $$MovementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceKey =>
      $composableBuilder(column: $table.sourceKey, builder: (column) => column);

  GeneratedColumn<DateTime> get startAtUtc => $composableBuilder(
    column: $table.startAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get endAtUtc =>
      $composableBuilder(column: $table.endAtUtc, builder: (column) => column);

  GeneratedColumn<int> get startLatE7 => $composableBuilder(
    column: $table.startLatE7,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startLngE7 => $composableBuilder(
    column: $table.startLngE7,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endLatE7 =>
      $composableBuilder(column: $table.endLatE7, builder: (column) => column);

  GeneratedColumn<int> get endLngE7 =>
      $composableBuilder(column: $table.endLngE7, builder: (column) => column);

  GeneratedColumn<int> get distanceM =>
      $composableBuilder(column: $table.distanceM, builder: (column) => column);

  GeneratedColumn<String> get distanceMethod => $composableBuilder(
    column: $table.distanceMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get activityType => $composableBuilder(
    column: $table.activityType,
    builder: (column) => column,
  );

  GeneratedColumn<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pathJson =>
      $composableBuilder(column: $table.pathJson, builder: (column) => column);

  GeneratedColumn<bool> get validDistance => $composableBuilder(
    column: $table.validDistance,
    builder: (column) => column,
  );
}

class $$MovementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MovementsTable,
          MovementRow,
          $$MovementsTableFilterComposer,
          $$MovementsTableOrderingComposer,
          $$MovementsTableAnnotationComposer,
          $$MovementsTableCreateCompanionBuilder,
          $$MovementsTableUpdateCompanionBuilder,
          (
            MovementRow,
            BaseReferences<_$AppDatabase, $MovementsTable, MovementRow>,
          ),
          MovementRow,
          PrefetchHooks Function()
        > {
  $$MovementsTableTableManager(_$AppDatabase db, $MovementsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MovementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MovementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MovementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sourceKey = const Value.absent(),
                Value<DateTime> startAtUtc = const Value.absent(),
                Value<DateTime> endAtUtc = const Value.absent(),
                Value<int?> startLatE7 = const Value.absent(),
                Value<int?> startLngE7 = const Value.absent(),
                Value<int?> endLatE7 = const Value.absent(),
                Value<int?> endLngE7 = const Value.absent(),
                Value<int?> distanceM = const Value.absent(),
                Value<String> distanceMethod = const Value.absent(),
                Value<String?> activityType = const Value.absent(),
                Value<double?> confidence = const Value.absent(),
                Value<String?> pathJson = const Value.absent(),
                Value<bool> validDistance = const Value.absent(),
              }) => MovementsCompanion(
                id: id,
                sourceKey: sourceKey,
                startAtUtc: startAtUtc,
                endAtUtc: endAtUtc,
                startLatE7: startLatE7,
                startLngE7: startLngE7,
                endLatE7: endLatE7,
                endLngE7: endLngE7,
                distanceM: distanceM,
                distanceMethod: distanceMethod,
                activityType: activityType,
                confidence: confidence,
                pathJson: pathJson,
                validDistance: validDistance,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sourceKey,
                required DateTime startAtUtc,
                required DateTime endAtUtc,
                Value<int?> startLatE7 = const Value.absent(),
                Value<int?> startLngE7 = const Value.absent(),
                Value<int?> endLatE7 = const Value.absent(),
                Value<int?> endLngE7 = const Value.absent(),
                Value<int?> distanceM = const Value.absent(),
                required String distanceMethod,
                Value<String?> activityType = const Value.absent(),
                Value<double?> confidence = const Value.absent(),
                Value<String?> pathJson = const Value.absent(),
                Value<bool> validDistance = const Value.absent(),
              }) => MovementsCompanion.insert(
                id: id,
                sourceKey: sourceKey,
                startAtUtc: startAtUtc,
                endAtUtc: endAtUtc,
                startLatE7: startLatE7,
                startLngE7: startLngE7,
                endLatE7: endLatE7,
                endLngE7: endLngE7,
                distanceM: distanceM,
                distanceMethod: distanceMethod,
                activityType: activityType,
                confidence: confidence,
                pathJson: pathJson,
                validDistance: validDistance,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MovementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MovementsTable,
      MovementRow,
      $$MovementsTableFilterComposer,
      $$MovementsTableOrderingComposer,
      $$MovementsTableAnnotationComposer,
      $$MovementsTableCreateCompanionBuilder,
      $$MovementsTableUpdateCompanionBuilder,
      (
        MovementRow,
        BaseReferences<_$AppDatabase, $MovementsTable, MovementRow>,
      ),
      MovementRow,
      PrefetchHooks Function()
    >;
typedef $$PlaceClustersTableCreateCompanionBuilder =
    PlaceClustersCompanion Function({
      Value<int> id,
      required String stableKey,
      required int centroidLatE7,
      required int centroidLngE7,
      required double radiusM,
      required int visitCount,
      required int dwellSeconds,
      required DateTime firstAt,
      required DateTime lastAt,
      Value<int?> labelId,
      Value<bool> excluded,
      Value<String> privacyMode,
    });
typedef $$PlaceClustersTableUpdateCompanionBuilder =
    PlaceClustersCompanion Function({
      Value<int> id,
      Value<String> stableKey,
      Value<int> centroidLatE7,
      Value<int> centroidLngE7,
      Value<double> radiusM,
      Value<int> visitCount,
      Value<int> dwellSeconds,
      Value<DateTime> firstAt,
      Value<DateTime> lastAt,
      Value<int?> labelId,
      Value<bool> excluded,
      Value<String> privacyMode,
    });

class $$PlaceClustersTableFilterComposer
    extends Composer<_$AppDatabase, $PlaceClustersTable> {
  $$PlaceClustersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stableKey => $composableBuilder(
    column: $table.stableKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get centroidLatE7 => $composableBuilder(
    column: $table.centroidLatE7,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get centroidLngE7 => $composableBuilder(
    column: $table.centroidLngE7,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get radiusM => $composableBuilder(
    column: $table.radiusM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get visitCount => $composableBuilder(
    column: $table.visitCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dwellSeconds => $composableBuilder(
    column: $table.dwellSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get firstAt => $composableBuilder(
    column: $table.firstAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAt => $composableBuilder(
    column: $table.lastAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get labelId => $composableBuilder(
    column: $table.labelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get excluded => $composableBuilder(
    column: $table.excluded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get privacyMode => $composableBuilder(
    column: $table.privacyMode,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlaceClustersTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaceClustersTable> {
  $$PlaceClustersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stableKey => $composableBuilder(
    column: $table.stableKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get centroidLatE7 => $composableBuilder(
    column: $table.centroidLatE7,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get centroidLngE7 => $composableBuilder(
    column: $table.centroidLngE7,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get radiusM => $composableBuilder(
    column: $table.radiusM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get visitCount => $composableBuilder(
    column: $table.visitCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dwellSeconds => $composableBuilder(
    column: $table.dwellSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get firstAt => $composableBuilder(
    column: $table.firstAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAt => $composableBuilder(
    column: $table.lastAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get labelId => $composableBuilder(
    column: $table.labelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get excluded => $composableBuilder(
    column: $table.excluded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get privacyMode => $composableBuilder(
    column: $table.privacyMode,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlaceClustersTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaceClustersTable> {
  $$PlaceClustersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get stableKey =>
      $composableBuilder(column: $table.stableKey, builder: (column) => column);

  GeneratedColumn<int> get centroidLatE7 => $composableBuilder(
    column: $table.centroidLatE7,
    builder: (column) => column,
  );

  GeneratedColumn<int> get centroidLngE7 => $composableBuilder(
    column: $table.centroidLngE7,
    builder: (column) => column,
  );

  GeneratedColumn<double> get radiusM =>
      $composableBuilder(column: $table.radiusM, builder: (column) => column);

  GeneratedColumn<int> get visitCount => $composableBuilder(
    column: $table.visitCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dwellSeconds => $composableBuilder(
    column: $table.dwellSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get firstAt =>
      $composableBuilder(column: $table.firstAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAt =>
      $composableBuilder(column: $table.lastAt, builder: (column) => column);

  GeneratedColumn<int> get labelId =>
      $composableBuilder(column: $table.labelId, builder: (column) => column);

  GeneratedColumn<bool> get excluded =>
      $composableBuilder(column: $table.excluded, builder: (column) => column);

  GeneratedColumn<String> get privacyMode => $composableBuilder(
    column: $table.privacyMode,
    builder: (column) => column,
  );
}

class $$PlaceClustersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaceClustersTable,
          PlaceClusterRow,
          $$PlaceClustersTableFilterComposer,
          $$PlaceClustersTableOrderingComposer,
          $$PlaceClustersTableAnnotationComposer,
          $$PlaceClustersTableCreateCompanionBuilder,
          $$PlaceClustersTableUpdateCompanionBuilder,
          (
            PlaceClusterRow,
            BaseReferences<_$AppDatabase, $PlaceClustersTable, PlaceClusterRow>,
          ),
          PlaceClusterRow,
          PrefetchHooks Function()
        > {
  $$PlaceClustersTableTableManager(_$AppDatabase db, $PlaceClustersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaceClustersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaceClustersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaceClustersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> stableKey = const Value.absent(),
                Value<int> centroidLatE7 = const Value.absent(),
                Value<int> centroidLngE7 = const Value.absent(),
                Value<double> radiusM = const Value.absent(),
                Value<int> visitCount = const Value.absent(),
                Value<int> dwellSeconds = const Value.absent(),
                Value<DateTime> firstAt = const Value.absent(),
                Value<DateTime> lastAt = const Value.absent(),
                Value<int?> labelId = const Value.absent(),
                Value<bool> excluded = const Value.absent(),
                Value<String> privacyMode = const Value.absent(),
              }) => PlaceClustersCompanion(
                id: id,
                stableKey: stableKey,
                centroidLatE7: centroidLatE7,
                centroidLngE7: centroidLngE7,
                radiusM: radiusM,
                visitCount: visitCount,
                dwellSeconds: dwellSeconds,
                firstAt: firstAt,
                lastAt: lastAt,
                labelId: labelId,
                excluded: excluded,
                privacyMode: privacyMode,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String stableKey,
                required int centroidLatE7,
                required int centroidLngE7,
                required double radiusM,
                required int visitCount,
                required int dwellSeconds,
                required DateTime firstAt,
                required DateTime lastAt,
                Value<int?> labelId = const Value.absent(),
                Value<bool> excluded = const Value.absent(),
                Value<String> privacyMode = const Value.absent(),
              }) => PlaceClustersCompanion.insert(
                id: id,
                stableKey: stableKey,
                centroidLatE7: centroidLatE7,
                centroidLngE7: centroidLngE7,
                radiusM: radiusM,
                visitCount: visitCount,
                dwellSeconds: dwellSeconds,
                firstAt: firstAt,
                lastAt: lastAt,
                labelId: labelId,
                excluded: excluded,
                privacyMode: privacyMode,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlaceClustersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaceClustersTable,
      PlaceClusterRow,
      $$PlaceClustersTableFilterComposer,
      $$PlaceClustersTableOrderingComposer,
      $$PlaceClustersTableAnnotationComposer,
      $$PlaceClustersTableCreateCompanionBuilder,
      $$PlaceClustersTableUpdateCompanionBuilder,
      (
        PlaceClusterRow,
        BaseReferences<_$AppDatabase, $PlaceClustersTable, PlaceClusterRow>,
      ),
      PlaceClusterRow,
      PrefetchHooks Function()
    >;
typedef $$PlaceLabelsTableCreateCompanionBuilder =
    PlaceLabelsCompanion Function({
      Value<int> id,
      required String displayName,
      Value<String?> category,
      Value<bool> isBasePlace,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$PlaceLabelsTableUpdateCompanionBuilder =
    PlaceLabelsCompanion Function({
      Value<int> id,
      Value<String> displayName,
      Value<String?> category,
      Value<bool> isBasePlace,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$PlaceLabelsTableFilterComposer
    extends Composer<_$AppDatabase, $PlaceLabelsTable> {
  $$PlaceLabelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBasePlace => $composableBuilder(
    column: $table.isBasePlace,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlaceLabelsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaceLabelsTable> {
  $$PlaceLabelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBasePlace => $composableBuilder(
    column: $table.isBasePlace,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlaceLabelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaceLabelsTable> {
  $$PlaceLabelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<bool> get isBasePlace => $composableBuilder(
    column: $table.isBasePlace,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PlaceLabelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaceLabelsTable,
          PlaceLabelRow,
          $$PlaceLabelsTableFilterComposer,
          $$PlaceLabelsTableOrderingComposer,
          $$PlaceLabelsTableAnnotationComposer,
          $$PlaceLabelsTableCreateCompanionBuilder,
          $$PlaceLabelsTableUpdateCompanionBuilder,
          (
            PlaceLabelRow,
            BaseReferences<_$AppDatabase, $PlaceLabelsTable, PlaceLabelRow>,
          ),
          PlaceLabelRow,
          PrefetchHooks Function()
        > {
  $$PlaceLabelsTableTableManager(_$AppDatabase db, $PlaceLabelsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaceLabelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaceLabelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaceLabelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<bool> isBasePlace = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PlaceLabelsCompanion(
                id: id,
                displayName: displayName,
                category: category,
                isBasePlace: isBasePlace,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String displayName,
                Value<String?> category = const Value.absent(),
                Value<bool> isBasePlace = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => PlaceLabelsCompanion.insert(
                id: id,
                displayName: displayName,
                category: category,
                isBasePlace: isBasePlace,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlaceLabelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaceLabelsTable,
      PlaceLabelRow,
      $$PlaceLabelsTableFilterComposer,
      $$PlaceLabelsTableOrderingComposer,
      $$PlaceLabelsTableAnnotationComposer,
      $$PlaceLabelsTableCreateCompanionBuilder,
      $$PlaceLabelsTableUpdateCompanionBuilder,
      (
        PlaceLabelRow,
        BaseReferences<_$AppDatabase, $PlaceLabelsTable, PlaceLabelRow>,
      ),
      PlaceLabelRow,
      PrefetchHooks Function()
    >;
typedef $$DailySummariesTableCreateCompanionBuilder =
    DailySummariesCompanion Function({
      required String localDate,
      required bool outingFlag,
      required int visitCount,
      required int clusterCount,
      required int distanceM,
      required String distanceMethod,
      Value<DateTime?> firstAt,
      Value<DateTime?> lastAt,
      required int quality,
      Value<int> rowid,
    });
typedef $$DailySummariesTableUpdateCompanionBuilder =
    DailySummariesCompanion Function({
      Value<String> localDate,
      Value<bool> outingFlag,
      Value<int> visitCount,
      Value<int> clusterCount,
      Value<int> distanceM,
      Value<String> distanceMethod,
      Value<DateTime?> firstAt,
      Value<DateTime?> lastAt,
      Value<int> quality,
      Value<int> rowid,
    });

class $$DailySummariesTableFilterComposer
    extends Composer<_$AppDatabase, $DailySummariesTable> {
  $$DailySummariesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get outingFlag => $composableBuilder(
    column: $table.outingFlag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get visitCount => $composableBuilder(
    column: $table.visitCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clusterCount => $composableBuilder(
    column: $table.clusterCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get distanceM => $composableBuilder(
    column: $table.distanceM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get distanceMethod => $composableBuilder(
    column: $table.distanceMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get firstAt => $composableBuilder(
    column: $table.firstAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAt => $composableBuilder(
    column: $table.lastAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quality => $composableBuilder(
    column: $table.quality,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailySummariesTableOrderingComposer
    extends Composer<_$AppDatabase, $DailySummariesTable> {
  $$DailySummariesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get outingFlag => $composableBuilder(
    column: $table.outingFlag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get visitCount => $composableBuilder(
    column: $table.visitCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clusterCount => $composableBuilder(
    column: $table.clusterCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get distanceM => $composableBuilder(
    column: $table.distanceM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get distanceMethod => $composableBuilder(
    column: $table.distanceMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get firstAt => $composableBuilder(
    column: $table.firstAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAt => $composableBuilder(
    column: $table.lastAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quality => $composableBuilder(
    column: $table.quality,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailySummariesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailySummariesTable> {
  $$DailySummariesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localDate =>
      $composableBuilder(column: $table.localDate, builder: (column) => column);

  GeneratedColumn<bool> get outingFlag => $composableBuilder(
    column: $table.outingFlag,
    builder: (column) => column,
  );

  GeneratedColumn<int> get visitCount => $composableBuilder(
    column: $table.visitCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get clusterCount => $composableBuilder(
    column: $table.clusterCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get distanceM =>
      $composableBuilder(column: $table.distanceM, builder: (column) => column);

  GeneratedColumn<String> get distanceMethod => $composableBuilder(
    column: $table.distanceMethod,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get firstAt =>
      $composableBuilder(column: $table.firstAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAt =>
      $composableBuilder(column: $table.lastAt, builder: (column) => column);

  GeneratedColumn<int> get quality =>
      $composableBuilder(column: $table.quality, builder: (column) => column);
}

class $$DailySummariesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailySummariesTable,
          DailySummaryRow,
          $$DailySummariesTableFilterComposer,
          $$DailySummariesTableOrderingComposer,
          $$DailySummariesTableAnnotationComposer,
          $$DailySummariesTableCreateCompanionBuilder,
          $$DailySummariesTableUpdateCompanionBuilder,
          (
            DailySummaryRow,
            BaseReferences<
              _$AppDatabase,
              $DailySummariesTable,
              DailySummaryRow
            >,
          ),
          DailySummaryRow,
          PrefetchHooks Function()
        > {
  $$DailySummariesTableTableManager(
    _$AppDatabase db,
    $DailySummariesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailySummariesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailySummariesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailySummariesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> localDate = const Value.absent(),
                Value<bool> outingFlag = const Value.absent(),
                Value<int> visitCount = const Value.absent(),
                Value<int> clusterCount = const Value.absent(),
                Value<int> distanceM = const Value.absent(),
                Value<String> distanceMethod = const Value.absent(),
                Value<DateTime?> firstAt = const Value.absent(),
                Value<DateTime?> lastAt = const Value.absent(),
                Value<int> quality = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailySummariesCompanion(
                localDate: localDate,
                outingFlag: outingFlag,
                visitCount: visitCount,
                clusterCount: clusterCount,
                distanceM: distanceM,
                distanceMethod: distanceMethod,
                firstAt: firstAt,
                lastAt: lastAt,
                quality: quality,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localDate,
                required bool outingFlag,
                required int visitCount,
                required int clusterCount,
                required int distanceM,
                required String distanceMethod,
                Value<DateTime?> firstAt = const Value.absent(),
                Value<DateTime?> lastAt = const Value.absent(),
                required int quality,
                Value<int> rowid = const Value.absent(),
              }) => DailySummariesCompanion.insert(
                localDate: localDate,
                outingFlag: outingFlag,
                visitCount: visitCount,
                clusterCount: clusterCount,
                distanceM: distanceM,
                distanceMethod: distanceMethod,
                firstAt: firstAt,
                lastAt: lastAt,
                quality: quality,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailySummariesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailySummariesTable,
      DailySummaryRow,
      $$DailySummariesTableFilterComposer,
      $$DailySummariesTableOrderingComposer,
      $$DailySummariesTableAnnotationComposer,
      $$DailySummariesTableCreateCompanionBuilder,
      $$DailySummariesTableUpdateCompanionBuilder,
      (
        DailySummaryRow,
        BaseReferences<_$AppDatabase, $DailySummariesTable, DailySummaryRow>,
      ),
      DailySummaryRow,
      PrefetchHooks Function()
    >;
typedef $$MonthlySummariesTableCreateCompanionBuilder =
    MonthlySummariesCompanion Function({
      required String yearMonth,
      required int outingDays,
      required int distanceM,
      required int uniqueClusters,
      required int newClusters,
      Value<String?> maxDistanceDate,
      required DateTime calculatedAt,
      Value<String> clusterIdsJson,
      Value<int> rowid,
    });
typedef $$MonthlySummariesTableUpdateCompanionBuilder =
    MonthlySummariesCompanion Function({
      Value<String> yearMonth,
      Value<int> outingDays,
      Value<int> distanceM,
      Value<int> uniqueClusters,
      Value<int> newClusters,
      Value<String?> maxDistanceDate,
      Value<DateTime> calculatedAt,
      Value<String> clusterIdsJson,
      Value<int> rowid,
    });

class $$MonthlySummariesTableFilterComposer
    extends Composer<_$AppDatabase, $MonthlySummariesTable> {
  $$MonthlySummariesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get yearMonth => $composableBuilder(
    column: $table.yearMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get outingDays => $composableBuilder(
    column: $table.outingDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get distanceM => $composableBuilder(
    column: $table.distanceM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get uniqueClusters => $composableBuilder(
    column: $table.uniqueClusters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get newClusters => $composableBuilder(
    column: $table.newClusters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get maxDistanceDate => $composableBuilder(
    column: $table.maxDistanceDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get calculatedAt => $composableBuilder(
    column: $table.calculatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clusterIdsJson => $composableBuilder(
    column: $table.clusterIdsJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MonthlySummariesTableOrderingComposer
    extends Composer<_$AppDatabase, $MonthlySummariesTable> {
  $$MonthlySummariesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get yearMonth => $composableBuilder(
    column: $table.yearMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get outingDays => $composableBuilder(
    column: $table.outingDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get distanceM => $composableBuilder(
    column: $table.distanceM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get uniqueClusters => $composableBuilder(
    column: $table.uniqueClusters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get newClusters => $composableBuilder(
    column: $table.newClusters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get maxDistanceDate => $composableBuilder(
    column: $table.maxDistanceDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get calculatedAt => $composableBuilder(
    column: $table.calculatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clusterIdsJson => $composableBuilder(
    column: $table.clusterIdsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MonthlySummariesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MonthlySummariesTable> {
  $$MonthlySummariesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get yearMonth =>
      $composableBuilder(column: $table.yearMonth, builder: (column) => column);

  GeneratedColumn<int> get outingDays => $composableBuilder(
    column: $table.outingDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get distanceM =>
      $composableBuilder(column: $table.distanceM, builder: (column) => column);

  GeneratedColumn<int> get uniqueClusters => $composableBuilder(
    column: $table.uniqueClusters,
    builder: (column) => column,
  );

  GeneratedColumn<int> get newClusters => $composableBuilder(
    column: $table.newClusters,
    builder: (column) => column,
  );

  GeneratedColumn<String> get maxDistanceDate => $composableBuilder(
    column: $table.maxDistanceDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get calculatedAt => $composableBuilder(
    column: $table.calculatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clusterIdsJson => $composableBuilder(
    column: $table.clusterIdsJson,
    builder: (column) => column,
  );
}

class $$MonthlySummariesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MonthlySummariesTable,
          MonthlySummaryRow,
          $$MonthlySummariesTableFilterComposer,
          $$MonthlySummariesTableOrderingComposer,
          $$MonthlySummariesTableAnnotationComposer,
          $$MonthlySummariesTableCreateCompanionBuilder,
          $$MonthlySummariesTableUpdateCompanionBuilder,
          (
            MonthlySummaryRow,
            BaseReferences<
              _$AppDatabase,
              $MonthlySummariesTable,
              MonthlySummaryRow
            >,
          ),
          MonthlySummaryRow,
          PrefetchHooks Function()
        > {
  $$MonthlySummariesTableTableManager(
    _$AppDatabase db,
    $MonthlySummariesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MonthlySummariesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MonthlySummariesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MonthlySummariesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> yearMonth = const Value.absent(),
                Value<int> outingDays = const Value.absent(),
                Value<int> distanceM = const Value.absent(),
                Value<int> uniqueClusters = const Value.absent(),
                Value<int> newClusters = const Value.absent(),
                Value<String?> maxDistanceDate = const Value.absent(),
                Value<DateTime> calculatedAt = const Value.absent(),
                Value<String> clusterIdsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MonthlySummariesCompanion(
                yearMonth: yearMonth,
                outingDays: outingDays,
                distanceM: distanceM,
                uniqueClusters: uniqueClusters,
                newClusters: newClusters,
                maxDistanceDate: maxDistanceDate,
                calculatedAt: calculatedAt,
                clusterIdsJson: clusterIdsJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String yearMonth,
                required int outingDays,
                required int distanceM,
                required int uniqueClusters,
                required int newClusters,
                Value<String?> maxDistanceDate = const Value.absent(),
                required DateTime calculatedAt,
                Value<String> clusterIdsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MonthlySummariesCompanion.insert(
                yearMonth: yearMonth,
                outingDays: outingDays,
                distanceM: distanceM,
                uniqueClusters: uniqueClusters,
                newClusters: newClusters,
                maxDistanceDate: maxDistanceDate,
                calculatedAt: calculatedAt,
                clusterIdsJson: clusterIdsJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MonthlySummariesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MonthlySummariesTable,
      MonthlySummaryRow,
      $$MonthlySummariesTableFilterComposer,
      $$MonthlySummariesTableOrderingComposer,
      $$MonthlySummariesTableAnnotationComposer,
      $$MonthlySummariesTableCreateCompanionBuilder,
      $$MonthlySummariesTableUpdateCompanionBuilder,
      (
        MonthlySummaryRow,
        BaseReferences<
          _$AppDatabase,
          $MonthlySummariesTable,
          MonthlySummaryRow
        >,
      ),
      MonthlySummaryRow,
      PrefetchHooks Function()
    >;
typedef $$InsightsTableCreateCompanionBuilder =
    InsightsCompanion Function({
      Value<int> id,
      required String periodKey,
      required String ruleId,
      required String severity,
      required String title,
      required String body,
      required String metricJson,
      required DateTime createdAt,
      Value<bool> dismissed,
    });
typedef $$InsightsTableUpdateCompanionBuilder =
    InsightsCompanion Function({
      Value<int> id,
      Value<String> periodKey,
      Value<String> ruleId,
      Value<String> severity,
      Value<String> title,
      Value<String> body,
      Value<String> metricJson,
      Value<DateTime> createdAt,
      Value<bool> dismissed,
    });

class $$InsightsTableFilterComposer
    extends Composer<_$AppDatabase, $InsightsTable> {
  $$InsightsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get periodKey => $composableBuilder(
    column: $table.periodKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ruleId => $composableBuilder(
    column: $table.ruleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metricJson => $composableBuilder(
    column: $table.metricJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dismissed => $composableBuilder(
    column: $table.dismissed,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InsightsTableOrderingComposer
    extends Composer<_$AppDatabase, $InsightsTable> {
  $$InsightsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get periodKey => $composableBuilder(
    column: $table.periodKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ruleId => $composableBuilder(
    column: $table.ruleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metricJson => $composableBuilder(
    column: $table.metricJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dismissed => $composableBuilder(
    column: $table.dismissed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InsightsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InsightsTable> {
  $$InsightsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get periodKey =>
      $composableBuilder(column: $table.periodKey, builder: (column) => column);

  GeneratedColumn<String> get ruleId =>
      $composableBuilder(column: $table.ruleId, builder: (column) => column);

  GeneratedColumn<String> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get metricJson => $composableBuilder(
    column: $table.metricJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get dismissed =>
      $composableBuilder(column: $table.dismissed, builder: (column) => column);
}

class $$InsightsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InsightsTable,
          InsightRow,
          $$InsightsTableFilterComposer,
          $$InsightsTableOrderingComposer,
          $$InsightsTableAnnotationComposer,
          $$InsightsTableCreateCompanionBuilder,
          $$InsightsTableUpdateCompanionBuilder,
          (
            InsightRow,
            BaseReferences<_$AppDatabase, $InsightsTable, InsightRow>,
          ),
          InsightRow,
          PrefetchHooks Function()
        > {
  $$InsightsTableTableManager(_$AppDatabase db, $InsightsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InsightsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InsightsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InsightsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> periodKey = const Value.absent(),
                Value<String> ruleId = const Value.absent(),
                Value<String> severity = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String> metricJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> dismissed = const Value.absent(),
              }) => InsightsCompanion(
                id: id,
                periodKey: periodKey,
                ruleId: ruleId,
                severity: severity,
                title: title,
                body: body,
                metricJson: metricJson,
                createdAt: createdAt,
                dismissed: dismissed,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String periodKey,
                required String ruleId,
                required String severity,
                required String title,
                required String body,
                required String metricJson,
                required DateTime createdAt,
                Value<bool> dismissed = const Value.absent(),
              }) => InsightsCompanion.insert(
                id: id,
                periodKey: periodKey,
                ruleId: ruleId,
                severity: severity,
                title: title,
                body: body,
                metricJson: metricJson,
                createdAt: createdAt,
                dismissed: dismissed,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InsightsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InsightsTable,
      InsightRow,
      $$InsightsTableFilterComposer,
      $$InsightsTableOrderingComposer,
      $$InsightsTableAnnotationComposer,
      $$InsightsTableCreateCompanionBuilder,
      $$InsightsTableUpdateCompanionBuilder,
      (InsightRow, BaseReferences<_$AppDatabase, $InsightsTable, InsightRow>),
      InsightRow,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSettingRow,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSettingRow,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingRow>,
          ),
          AppSettingRow,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSettingRow,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSettingRow,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingRow>,
      ),
      AppSettingRow,
      PrefetchHooks Function()
    >;
typedef $$UserMilestonesTableCreateCompanionBuilder =
    UserMilestonesCompanion Function({
      required String id,
      required String startDate,
      Value<String?> endDate,
      required String timeZoneId,
      required String title,
      Value<String?> note,
      Value<String?> sourceCandidateKey,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$UserMilestonesTableUpdateCompanionBuilder =
    UserMilestonesCompanion Function({
      Value<String> id,
      Value<String> startDate,
      Value<String?> endDate,
      Value<String> timeZoneId,
      Value<String> title,
      Value<String?> note,
      Value<String?> sourceCandidateKey,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$UserMilestonesTableFilterComposer
    extends Composer<_$AppDatabase, $UserMilestonesTable> {
  $$UserMilestonesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeZoneId => $composableBuilder(
    column: $table.timeZoneId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceCandidateKey => $composableBuilder(
    column: $table.sourceCandidateKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserMilestonesTableOrderingComposer
    extends Composer<_$AppDatabase, $UserMilestonesTable> {
  $$UserMilestonesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeZoneId => $composableBuilder(
    column: $table.timeZoneId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceCandidateKey => $composableBuilder(
    column: $table.sourceCandidateKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserMilestonesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserMilestonesTable> {
  $$UserMilestonesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get timeZoneId => $composableBuilder(
    column: $table.timeZoneId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get sourceCandidateKey => $composableBuilder(
    column: $table.sourceCandidateKey,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UserMilestonesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserMilestonesTable,
          UserMilestoneRow,
          $$UserMilestonesTableFilterComposer,
          $$UserMilestonesTableOrderingComposer,
          $$UserMilestonesTableAnnotationComposer,
          $$UserMilestonesTableCreateCompanionBuilder,
          $$UserMilestonesTableUpdateCompanionBuilder,
          (
            UserMilestoneRow,
            BaseReferences<
              _$AppDatabase,
              $UserMilestonesTable,
              UserMilestoneRow
            >,
          ),
          UserMilestoneRow,
          PrefetchHooks Function()
        > {
  $$UserMilestonesTableTableManager(
    _$AppDatabase db,
    $UserMilestonesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserMilestonesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserMilestonesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserMilestonesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<String?> endDate = const Value.absent(),
                Value<String> timeZoneId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> sourceCandidateKey = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserMilestonesCompanion(
                id: id,
                startDate: startDate,
                endDate: endDate,
                timeZoneId: timeZoneId,
                title: title,
                note: note,
                sourceCandidateKey: sourceCandidateKey,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String startDate,
                Value<String?> endDate = const Value.absent(),
                required String timeZoneId,
                required String title,
                Value<String?> note = const Value.absent(),
                Value<String?> sourceCandidateKey = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => UserMilestonesCompanion.insert(
                id: id,
                startDate: startDate,
                endDate: endDate,
                timeZoneId: timeZoneId,
                title: title,
                note: note,
                sourceCandidateKey: sourceCandidateKey,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserMilestonesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserMilestonesTable,
      UserMilestoneRow,
      $$UserMilestonesTableFilterComposer,
      $$UserMilestonesTableOrderingComposer,
      $$UserMilestonesTableAnnotationComposer,
      $$UserMilestonesTableCreateCompanionBuilder,
      $$UserMilestonesTableUpdateCompanionBuilder,
      (
        UserMilestoneRow,
        BaseReferences<_$AppDatabase, $UserMilestonesTable, UserMilestoneRow>,
      ),
      UserMilestoneRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TimelineImportsTableTableManager get timelineImports =>
      $$TimelineImportsTableTableManager(_db, _db.timelineImports);
  $$VisitsTableTableManager get visits =>
      $$VisitsTableTableManager(_db, _db.visits);
  $$MovementsTableTableManager get movements =>
      $$MovementsTableTableManager(_db, _db.movements);
  $$PlaceClustersTableTableManager get placeClusters =>
      $$PlaceClustersTableTableManager(_db, _db.placeClusters);
  $$PlaceLabelsTableTableManager get placeLabels =>
      $$PlaceLabelsTableTableManager(_db, _db.placeLabels);
  $$DailySummariesTableTableManager get dailySummaries =>
      $$DailySummariesTableTableManager(_db, _db.dailySummaries);
  $$MonthlySummariesTableTableManager get monthlySummaries =>
      $$MonthlySummariesTableTableManager(_db, _db.monthlySummaries);
  $$InsightsTableTableManager get insights =>
      $$InsightsTableTableManager(_db, _db.insights);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$UserMilestonesTableTableManager get userMilestones =>
      $$UserMilestonesTableTableManager(_db, _db.userMilestones);
}
