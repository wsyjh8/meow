// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $WordRecordsTable extends WordRecords
    with TableInfo<$WordRecordsTable, WordRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<String> wordId = GeneratedColumn<String>(
      'word_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
      'book_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _studyTypeMeta =
      const VerificationMeta('studyType');
  @override
  late final GeneratedColumn<String> studyType = GeneratedColumn<String>(
      'study_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('new'));
  static const VerificationMeta _actionResultMeta =
      const VerificationMeta('actionResult');
  @override
  late final GeneratedColumn<String> actionResult = GeneratedColumn<String>(
      'action_result', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<int> synced = GeneratedColumn<int>(
      'synced', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, wordId, bookId, studyType, actionResult, createdAt, synced];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word_records';
  @override
  VerificationContext validateIntegrity(Insertable<WordRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('word_id')) {
      context.handle(_wordIdMeta,
          wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta));
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(_bookIdMeta,
          bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta));
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('study_type')) {
      context.handle(_studyTypeMeta,
          studyType.isAcceptableOrUnknown(data['study_type']!, _studyTypeMeta));
    }
    if (data.containsKey('action_result')) {
      context.handle(
          _actionResultMeta,
          actionResult.isAcceptableOrUnknown(
              data['action_result']!, _actionResultMeta));
    } else if (isInserting) {
      context.missing(_actionResultMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WordRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      wordId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}word_id'])!,
      bookId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}book_id'])!,
      studyType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}study_type'])!,
      actionResult: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}action_result'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}synced'])!,
    );
  }

  @override
  $WordRecordsTable createAlias(String alias) {
    return $WordRecordsTable(attachedDatabase, alias);
  }
}

class WordRecord extends DataClass implements Insertable<WordRecord> {
  final int id;
  final String wordId;
  final String bookId;
  final String studyType;
  final String actionResult;
  final String createdAt;
  final int synced;
  const WordRecord(
      {required this.id,
      required this.wordId,
      required this.bookId,
      required this.studyType,
      required this.actionResult,
      required this.createdAt,
      required this.synced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['word_id'] = Variable<String>(wordId);
    map['book_id'] = Variable<String>(bookId);
    map['study_type'] = Variable<String>(studyType);
    map['action_result'] = Variable<String>(actionResult);
    map['created_at'] = Variable<String>(createdAt);
    map['synced'] = Variable<int>(synced);
    return map;
  }

  WordRecordsCompanion toCompanion(bool nullToAbsent) {
    return WordRecordsCompanion(
      id: Value(id),
      wordId: Value(wordId),
      bookId: Value(bookId),
      studyType: Value(studyType),
      actionResult: Value(actionResult),
      createdAt: Value(createdAt),
      synced: Value(synced),
    );
  }

  factory WordRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordRecord(
      id: serializer.fromJson<int>(json['id']),
      wordId: serializer.fromJson<String>(json['wordId']),
      bookId: serializer.fromJson<String>(json['bookId']),
      studyType: serializer.fromJson<String>(json['studyType']),
      actionResult: serializer.fromJson<String>(json['actionResult']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      synced: serializer.fromJson<int>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'wordId': serializer.toJson<String>(wordId),
      'bookId': serializer.toJson<String>(bookId),
      'studyType': serializer.toJson<String>(studyType),
      'actionResult': serializer.toJson<String>(actionResult),
      'createdAt': serializer.toJson<String>(createdAt),
      'synced': serializer.toJson<int>(synced),
    };
  }

  WordRecord copyWith(
          {int? id,
          String? wordId,
          String? bookId,
          String? studyType,
          String? actionResult,
          String? createdAt,
          int? synced}) =>
      WordRecord(
        id: id ?? this.id,
        wordId: wordId ?? this.wordId,
        bookId: bookId ?? this.bookId,
        studyType: studyType ?? this.studyType,
        actionResult: actionResult ?? this.actionResult,
        createdAt: createdAt ?? this.createdAt,
        synced: synced ?? this.synced,
      );
  WordRecord copyWithCompanion(WordRecordsCompanion data) {
    return WordRecord(
      id: data.id.present ? data.id.value : this.id,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      studyType: data.studyType.present ? data.studyType.value : this.studyType,
      actionResult: data.actionResult.present
          ? data.actionResult.value
          : this.actionResult,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordRecord(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('bookId: $bookId, ')
          ..write('studyType: $studyType, ')
          ..write('actionResult: $actionResult, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, wordId, bookId, studyType, actionResult, createdAt, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordRecord &&
          other.id == this.id &&
          other.wordId == this.wordId &&
          other.bookId == this.bookId &&
          other.studyType == this.studyType &&
          other.actionResult == this.actionResult &&
          other.createdAt == this.createdAt &&
          other.synced == this.synced);
}

class WordRecordsCompanion extends UpdateCompanion<WordRecord> {
  final Value<int> id;
  final Value<String> wordId;
  final Value<String> bookId;
  final Value<String> studyType;
  final Value<String> actionResult;
  final Value<String> createdAt;
  final Value<int> synced;
  const WordRecordsCompanion({
    this.id = const Value.absent(),
    this.wordId = const Value.absent(),
    this.bookId = const Value.absent(),
    this.studyType = const Value.absent(),
    this.actionResult = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
  });
  WordRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String wordId,
    required String bookId,
    this.studyType = const Value.absent(),
    required String actionResult,
    required String createdAt,
    this.synced = const Value.absent(),
  })  : wordId = Value(wordId),
        bookId = Value(bookId),
        actionResult = Value(actionResult),
        createdAt = Value(createdAt);
  static Insertable<WordRecord> custom({
    Expression<int>? id,
    Expression<String>? wordId,
    Expression<String>? bookId,
    Expression<String>? studyType,
    Expression<String>? actionResult,
    Expression<String>? createdAt,
    Expression<int>? synced,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (wordId != null) 'word_id': wordId,
      if (bookId != null) 'book_id': bookId,
      if (studyType != null) 'study_type': studyType,
      if (actionResult != null) 'action_result': actionResult,
      if (createdAt != null) 'created_at': createdAt,
      if (synced != null) 'synced': synced,
    });
  }

  WordRecordsCompanion copyWith(
      {Value<int>? id,
      Value<String>? wordId,
      Value<String>? bookId,
      Value<String>? studyType,
      Value<String>? actionResult,
      Value<String>? createdAt,
      Value<int>? synced}) {
    return WordRecordsCompanion(
      id: id ?? this.id,
      wordId: wordId ?? this.wordId,
      bookId: bookId ?? this.bookId,
      studyType: studyType ?? this.studyType,
      actionResult: actionResult ?? this.actionResult,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (wordId.present) {
      map['word_id'] = Variable<String>(wordId.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (studyType.present) {
      map['study_type'] = Variable<String>(studyType.value);
    }
    if (actionResult.present) {
      map['action_result'] = Variable<String>(actionResult.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<int>(synced.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordRecordsCompanion(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('bookId: $bookId, ')
          ..write('studyType: $studyType, ')
          ..write('actionResult: $actionResult, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }
}

class $WordbookProgressTable extends WordbookProgress
    with TableInfo<$WordbookProgressTable, WordbookProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordbookProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
      'book_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _totalWordsMeta =
      const VerificationMeta('totalWords');
  @override
  late final GeneratedColumn<int> totalWords = GeneratedColumn<int>(
      'total_words', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _completedWordsMeta =
      const VerificationMeta('completedWords');
  @override
  late final GeneratedColumn<int> completedWords = GeneratedColumn<int>(
      'completed_words', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, bookId, totalWords, completedWords, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wordbook_progress';
  @override
  VerificationContext validateIntegrity(
      Insertable<WordbookProgressData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('book_id')) {
      context.handle(_bookIdMeta,
          bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta));
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('total_words')) {
      context.handle(
          _totalWordsMeta,
          totalWords.isAcceptableOrUnknown(
              data['total_words']!, _totalWordsMeta));
    }
    if (data.containsKey('completed_words')) {
      context.handle(
          _completedWordsMeta,
          completedWords.isAcceptableOrUnknown(
              data['completed_words']!, _completedWordsMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WordbookProgressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordbookProgressData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      bookId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}book_id'])!,
      totalWords: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_words'])!,
      completedWords: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}completed_words'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $WordbookProgressTable createAlias(String alias) {
    return $WordbookProgressTable(attachedDatabase, alias);
  }
}

class WordbookProgressData extends DataClass
    implements Insertable<WordbookProgressData> {
  final int id;
  final String bookId;
  final int totalWords;
  final int completedWords;
  final String updatedAt;
  const WordbookProgressData(
      {required this.id,
      required this.bookId,
      required this.totalWords,
      required this.completedWords,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['book_id'] = Variable<String>(bookId);
    map['total_words'] = Variable<int>(totalWords);
    map['completed_words'] = Variable<int>(completedWords);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  WordbookProgressCompanion toCompanion(bool nullToAbsent) {
    return WordbookProgressCompanion(
      id: Value(id),
      bookId: Value(bookId),
      totalWords: Value(totalWords),
      completedWords: Value(completedWords),
      updatedAt: Value(updatedAt),
    );
  }

  factory WordbookProgressData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordbookProgressData(
      id: serializer.fromJson<int>(json['id']),
      bookId: serializer.fromJson<String>(json['bookId']),
      totalWords: serializer.fromJson<int>(json['totalWords']),
      completedWords: serializer.fromJson<int>(json['completedWords']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'bookId': serializer.toJson<String>(bookId),
      'totalWords': serializer.toJson<int>(totalWords),
      'completedWords': serializer.toJson<int>(completedWords),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  WordbookProgressData copyWith(
          {int? id,
          String? bookId,
          int? totalWords,
          int? completedWords,
          String? updatedAt}) =>
      WordbookProgressData(
        id: id ?? this.id,
        bookId: bookId ?? this.bookId,
        totalWords: totalWords ?? this.totalWords,
        completedWords: completedWords ?? this.completedWords,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  WordbookProgressData copyWithCompanion(WordbookProgressCompanion data) {
    return WordbookProgressData(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      totalWords:
          data.totalWords.present ? data.totalWords.value : this.totalWords,
      completedWords: data.completedWords.present
          ? data.completedWords.value
          : this.completedWords,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordbookProgressData(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('totalWords: $totalWords, ')
          ..write('completedWords: $completedWords, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, bookId, totalWords, completedWords, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordbookProgressData &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.totalWords == this.totalWords &&
          other.completedWords == this.completedWords &&
          other.updatedAt == this.updatedAt);
}

class WordbookProgressCompanion extends UpdateCompanion<WordbookProgressData> {
  final Value<int> id;
  final Value<String> bookId;
  final Value<int> totalWords;
  final Value<int> completedWords;
  final Value<String> updatedAt;
  const WordbookProgressCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.totalWords = const Value.absent(),
    this.completedWords = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  WordbookProgressCompanion.insert({
    this.id = const Value.absent(),
    required String bookId,
    this.totalWords = const Value.absent(),
    this.completedWords = const Value.absent(),
    required String updatedAt,
  })  : bookId = Value(bookId),
        updatedAt = Value(updatedAt);
  static Insertable<WordbookProgressData> custom({
    Expression<int>? id,
    Expression<String>? bookId,
    Expression<int>? totalWords,
    Expression<int>? completedWords,
    Expression<String>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (totalWords != null) 'total_words': totalWords,
      if (completedWords != null) 'completed_words': completedWords,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  WordbookProgressCompanion copyWith(
      {Value<int>? id,
      Value<String>? bookId,
      Value<int>? totalWords,
      Value<int>? completedWords,
      Value<String>? updatedAt}) {
    return WordbookProgressCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      totalWords: totalWords ?? this.totalWords,
      completedWords: completedWords ?? this.completedWords,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (totalWords.present) {
      map['total_words'] = Variable<int>(totalWords.value);
    }
    if (completedWords.present) {
      map['completed_words'] = Variable<int>(completedWords.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordbookProgressCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('totalWords: $totalWords, ')
          ..write('completedWords: $completedWords, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $DailyCheckinsTable extends DailyCheckins
    with TableInfo<$DailyCheckinsTable, DailyCheckin> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyCheckinsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
      'date', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _checkedInMeta =
      const VerificationMeta('checkedIn');
  @override
  late final GeneratedColumn<int> checkedIn = GeneratedColumn<int>(
      'checked_in', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, date, checkedIn, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_checkins';
  @override
  VerificationContext validateIntegrity(Insertable<DailyCheckin> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('checked_in')) {
      context.handle(_checkedInMeta,
          checkedIn.isAcceptableOrUnknown(data['checked_in']!, _checkedInMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DailyCheckin map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyCheckin(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date'])!,
      checkedIn: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}checked_in'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $DailyCheckinsTable createAlias(String alias) {
    return $DailyCheckinsTable(attachedDatabase, alias);
  }
}

class DailyCheckin extends DataClass implements Insertable<DailyCheckin> {
  final int id;
  final String date;
  final int checkedIn;
  final String createdAt;
  const DailyCheckin(
      {required this.id,
      required this.date,
      required this.checkedIn,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<String>(date);
    map['checked_in'] = Variable<int>(checkedIn);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  DailyCheckinsCompanion toCompanion(bool nullToAbsent) {
    return DailyCheckinsCompanion(
      id: Value(id),
      date: Value(date),
      checkedIn: Value(checkedIn),
      createdAt: Value(createdAt),
    );
  }

  factory DailyCheckin.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyCheckin(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      checkedIn: serializer.fromJson<int>(json['checkedIn']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<String>(date),
      'checkedIn': serializer.toJson<int>(checkedIn),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  DailyCheckin copyWith(
          {int? id, String? date, int? checkedIn, String? createdAt}) =>
      DailyCheckin(
        id: id ?? this.id,
        date: date ?? this.date,
        checkedIn: checkedIn ?? this.checkedIn,
        createdAt: createdAt ?? this.createdAt,
      );
  DailyCheckin copyWithCompanion(DailyCheckinsCompanion data) {
    return DailyCheckin(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      checkedIn: data.checkedIn.present ? data.checkedIn.value : this.checkedIn,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyCheckin(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('checkedIn: $checkedIn, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, checkedIn, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyCheckin &&
          other.id == this.id &&
          other.date == this.date &&
          other.checkedIn == this.checkedIn &&
          other.createdAt == this.createdAt);
}

class DailyCheckinsCompanion extends UpdateCompanion<DailyCheckin> {
  final Value<int> id;
  final Value<String> date;
  final Value<int> checkedIn;
  final Value<String> createdAt;
  const DailyCheckinsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.checkedIn = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  DailyCheckinsCompanion.insert({
    this.id = const Value.absent(),
    required String date,
    this.checkedIn = const Value.absent(),
    required String createdAt,
  })  : date = Value(date),
        createdAt = Value(createdAt);
  static Insertable<DailyCheckin> custom({
    Expression<int>? id,
    Expression<String>? date,
    Expression<int>? checkedIn,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (checkedIn != null) 'checked_in': checkedIn,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  DailyCheckinsCompanion copyWith(
      {Value<int>? id,
      Value<String>? date,
      Value<int>? checkedIn,
      Value<String>? createdAt}) {
    return DailyCheckinsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      checkedIn: checkedIn ?? this.checkedIn,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (checkedIn.present) {
      map['checked_in'] = Variable<int>(checkedIn.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyCheckinsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('checkedIn: $checkedIn, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CustomWordbooksTable extends CustomWordbooks
    with TableInfo<$CustomWordbooksTable, CustomWordbook> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomWordbooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _wordCountMeta =
      const VerificationMeta('wordCount');
  @override
  late final GeneratedColumn<int> wordCount = GeneratedColumn<int>(
      'word_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name, wordCount, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_wordbooks';
  @override
  VerificationContext validateIntegrity(Insertable<CustomWordbook> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('word_count')) {
      context.handle(_wordCountMeta,
          wordCount.isAcceptableOrUnknown(data['word_count']!, _wordCountMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomWordbook map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomWordbook(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      wordCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}word_count'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $CustomWordbooksTable createAlias(String alias) {
    return $CustomWordbooksTable(attachedDatabase, alias);
  }
}

class CustomWordbook extends DataClass implements Insertable<CustomWordbook> {
  final int id;
  final String name;
  final int wordCount;
  final String createdAt;
  const CustomWordbook(
      {required this.id,
      required this.name,
      required this.wordCount,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['word_count'] = Variable<int>(wordCount);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  CustomWordbooksCompanion toCompanion(bool nullToAbsent) {
    return CustomWordbooksCompanion(
      id: Value(id),
      name: Value(name),
      wordCount: Value(wordCount),
      createdAt: Value(createdAt),
    );
  }

  factory CustomWordbook.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomWordbook(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      wordCount: serializer.fromJson<int>(json['wordCount']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'wordCount': serializer.toJson<int>(wordCount),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  CustomWordbook copyWith(
          {int? id, String? name, int? wordCount, String? createdAt}) =>
      CustomWordbook(
        id: id ?? this.id,
        name: name ?? this.name,
        wordCount: wordCount ?? this.wordCount,
        createdAt: createdAt ?? this.createdAt,
      );
  CustomWordbook copyWithCompanion(CustomWordbooksCompanion data) {
    return CustomWordbook(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      wordCount: data.wordCount.present ? data.wordCount.value : this.wordCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomWordbook(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('wordCount: $wordCount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, wordCount, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomWordbook &&
          other.id == this.id &&
          other.name == this.name &&
          other.wordCount == this.wordCount &&
          other.createdAt == this.createdAt);
}

class CustomWordbooksCompanion extends UpdateCompanion<CustomWordbook> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> wordCount;
  final Value<String> createdAt;
  const CustomWordbooksCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.wordCount = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CustomWordbooksCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.wordCount = const Value.absent(),
    required String createdAt,
  })  : name = Value(name),
        createdAt = Value(createdAt);
  static Insertable<CustomWordbook> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? wordCount,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (wordCount != null) 'word_count': wordCount,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CustomWordbooksCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<int>? wordCount,
      Value<String>? createdAt}) {
    return CustomWordbooksCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      wordCount: wordCount ?? this.wordCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (wordCount.present) {
      map['word_count'] = Variable<int>(wordCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomWordbooksCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('wordCount: $wordCount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $VocabularyNotebookTable extends VocabularyNotebook
    with TableInfo<$VocabularyNotebookTable, VocabularyNotebookData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VocabularyNotebookTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
      'word', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _meaningMeta =
      const VerificationMeta('meaning');
  @override
  late final GeneratedColumn<String> meaning = GeneratedColumn<String>(
      'meaning', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, word, meaning, note, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vocabulary_notebook';
  @override
  VerificationContext validateIntegrity(
      Insertable<VocabularyNotebookData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('word')) {
      context.handle(
          _wordMeta, word.isAcceptableOrUnknown(data['word']!, _wordMeta));
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('meaning')) {
      context.handle(_meaningMeta,
          meaning.isAcceptableOrUnknown(data['meaning']!, _meaningMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VocabularyNotebookData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VocabularyNotebookData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      word: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}word'])!,
      meaning: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meaning']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $VocabularyNotebookTable createAlias(String alias) {
    return $VocabularyNotebookTable(attachedDatabase, alias);
  }
}

class VocabularyNotebookData extends DataClass
    implements Insertable<VocabularyNotebookData> {
  final int id;
  final String word;
  final String? meaning;
  final String? note;
  final String createdAt;
  const VocabularyNotebookData(
      {required this.id,
      required this.word,
      this.meaning,
      this.note,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['word'] = Variable<String>(word);
    if (!nullToAbsent || meaning != null) {
      map['meaning'] = Variable<String>(meaning);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  VocabularyNotebookCompanion toCompanion(bool nullToAbsent) {
    return VocabularyNotebookCompanion(
      id: Value(id),
      word: Value(word),
      meaning: meaning == null && nullToAbsent
          ? const Value.absent()
          : Value(meaning),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory VocabularyNotebookData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VocabularyNotebookData(
      id: serializer.fromJson<int>(json['id']),
      word: serializer.fromJson<String>(json['word']),
      meaning: serializer.fromJson<String?>(json['meaning']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'word': serializer.toJson<String>(word),
      'meaning': serializer.toJson<String?>(meaning),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  VocabularyNotebookData copyWith(
          {int? id,
          String? word,
          Value<String?> meaning = const Value.absent(),
          Value<String?> note = const Value.absent(),
          String? createdAt}) =>
      VocabularyNotebookData(
        id: id ?? this.id,
        word: word ?? this.word,
        meaning: meaning.present ? meaning.value : this.meaning,
        note: note.present ? note.value : this.note,
        createdAt: createdAt ?? this.createdAt,
      );
  VocabularyNotebookData copyWithCompanion(VocabularyNotebookCompanion data) {
    return VocabularyNotebookData(
      id: data.id.present ? data.id.value : this.id,
      word: data.word.present ? data.word.value : this.word,
      meaning: data.meaning.present ? data.meaning.value : this.meaning,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VocabularyNotebookData(')
          ..write('id: $id, ')
          ..write('word: $word, ')
          ..write('meaning: $meaning, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, word, meaning, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VocabularyNotebookData &&
          other.id == this.id &&
          other.word == this.word &&
          other.meaning == this.meaning &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class VocabularyNotebookCompanion
    extends UpdateCompanion<VocabularyNotebookData> {
  final Value<int> id;
  final Value<String> word;
  final Value<String?> meaning;
  final Value<String?> note;
  final Value<String> createdAt;
  const VocabularyNotebookCompanion({
    this.id = const Value.absent(),
    this.word = const Value.absent(),
    this.meaning = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  VocabularyNotebookCompanion.insert({
    this.id = const Value.absent(),
    required String word,
    this.meaning = const Value.absent(),
    this.note = const Value.absent(),
    required String createdAt,
  })  : word = Value(word),
        createdAt = Value(createdAt);
  static Insertable<VocabularyNotebookData> custom({
    Expression<int>? id,
    Expression<String>? word,
    Expression<String>? meaning,
    Expression<String>? note,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (word != null) 'word': word,
      if (meaning != null) 'meaning': meaning,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  VocabularyNotebookCompanion copyWith(
      {Value<int>? id,
      Value<String>? word,
      Value<String?>? meaning,
      Value<String?>? note,
      Value<String>? createdAt}) {
    return VocabularyNotebookCompanion(
      id: id ?? this.id,
      word: word ?? this.word,
      meaning: meaning ?? this.meaning,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (meaning.present) {
      map['meaning'] = Variable<String>(meaning.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VocabularyNotebookCompanion(')
          ..write('id: $id, ')
          ..write('word: $word, ')
          ..write('meaning: $meaning, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CardStatesTable extends CardStates
    with TableInfo<$CardStatesTable, CardState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<String> wordId = GeneratedColumn<String>(
      'word_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _stabilityMeta =
      const VerificationMeta('stability');
  @override
  late final GeneratedColumn<double> stability = GeneratedColumn<double>(
      'stability', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _difficultyMeta =
      const VerificationMeta('difficulty');
  @override
  late final GeneratedColumn<double> difficulty = GeneratedColumn<double>(
      'difficulty', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _dueMeta = const VerificationMeta('due');
  @override
  late final GeneratedColumn<int> due = GeneratedColumn<int>(
      'due', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _lastReviewMeta =
      const VerificationMeta('lastReview');
  @override
  late final GeneratedColumn<int> lastReview = GeneratedColumn<int>(
      'last_review', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<int> state = GeneratedColumn<int>(
      'state', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _stepMeta = const VerificationMeta('step');
  @override
  late final GeneratedColumn<int> step = GeneratedColumn<int>(
      'step', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
      'reps', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lapsesMeta = const VerificationMeta('lapses');
  @override
  late final GeneratedColumn<int> lapses = GeneratedColumn<int>(
      'lapses', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        wordId,
        stability,
        difficulty,
        due,
        lastReview,
        state,
        step,
        reps,
        lapses,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'card_states';
  @override
  VerificationContext validateIntegrity(Insertable<CardState> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('word_id')) {
      context.handle(_wordIdMeta,
          wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta));
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('stability')) {
      context.handle(_stabilityMeta,
          stability.isAcceptableOrUnknown(data['stability']!, _stabilityMeta));
    }
    if (data.containsKey('difficulty')) {
      context.handle(
          _difficultyMeta,
          difficulty.isAcceptableOrUnknown(
              data['difficulty']!, _difficultyMeta));
    }
    if (data.containsKey('due')) {
      context.handle(
          _dueMeta, due.isAcceptableOrUnknown(data['due']!, _dueMeta));
    } else if (isInserting) {
      context.missing(_dueMeta);
    }
    if (data.containsKey('last_review')) {
      context.handle(
          _lastReviewMeta,
          lastReview.isAcceptableOrUnknown(
              data['last_review']!, _lastReviewMeta));
    }
    if (data.containsKey('state')) {
      context.handle(
          _stateMeta, state.isAcceptableOrUnknown(data['state']!, _stateMeta));
    }
    if (data.containsKey('step')) {
      context.handle(
          _stepMeta, step.isAcceptableOrUnknown(data['step']!, _stepMeta));
    }
    if (data.containsKey('reps')) {
      context.handle(
          _repsMeta, reps.isAcceptableOrUnknown(data['reps']!, _repsMeta));
    }
    if (data.containsKey('lapses')) {
      context.handle(_lapsesMeta,
          lapses.isAcceptableOrUnknown(data['lapses']!, _lapsesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CardState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CardState(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      wordId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}word_id'])!,
      stability: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}stability']),
      difficulty: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}difficulty']),
      due: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}due'])!,
      lastReview: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_review']),
      state: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}state'])!,
      step: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}step']),
      reps: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}reps'])!,
      lapses: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}lapses'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $CardStatesTable createAlias(String alias) {
    return $CardStatesTable(attachedDatabase, alias);
  }
}

class CardState extends DataClass implements Insertable<CardState> {
  final int id;

  /// Word identifier, e.g. 'cet4-abandon'. UNIQUE — one card per word.
  final String wordId;

  /// FSRS stability parameter. Nullable for brand-new cards.
  final double? stability;

  /// FSRS difficulty parameter. Nullable for brand-new cards.
  final double? difficulty;

  /// Next due date as UTC epoch milliseconds.
  final int due;

  /// Last review date as UTC epoch ms. Null if never reviewed.
  final int? lastReview;

  /// Card state: 1=Learning, 2=Review, 3=Relearning
  /// (fsrs library has no State.new; new cards start as State.learning=1)
  final int state;

  /// Learning/relearning step index. Null when in Review state.
  final int? step;

  /// Number of consecutive successful reviews.
  final int reps;

  /// Number of times the card was forgotten (lapsed).
  final int lapses;

  /// When this card_state row was created. UTC epoch ms.
  /// Used by countNewCardsToday() to track daily new card introductions.
  final int createdAt;
  const CardState(
      {required this.id,
      required this.wordId,
      this.stability,
      this.difficulty,
      required this.due,
      this.lastReview,
      required this.state,
      this.step,
      required this.reps,
      required this.lapses,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['word_id'] = Variable<String>(wordId);
    if (!nullToAbsent || stability != null) {
      map['stability'] = Variable<double>(stability);
    }
    if (!nullToAbsent || difficulty != null) {
      map['difficulty'] = Variable<double>(difficulty);
    }
    map['due'] = Variable<int>(due);
    if (!nullToAbsent || lastReview != null) {
      map['last_review'] = Variable<int>(lastReview);
    }
    map['state'] = Variable<int>(state);
    if (!nullToAbsent || step != null) {
      map['step'] = Variable<int>(step);
    }
    map['reps'] = Variable<int>(reps);
    map['lapses'] = Variable<int>(lapses);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  CardStatesCompanion toCompanion(bool nullToAbsent) {
    return CardStatesCompanion(
      id: Value(id),
      wordId: Value(wordId),
      stability: stability == null && nullToAbsent
          ? const Value.absent()
          : Value(stability),
      difficulty: difficulty == null && nullToAbsent
          ? const Value.absent()
          : Value(difficulty),
      due: Value(due),
      lastReview: lastReview == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReview),
      state: Value(state),
      step: step == null && nullToAbsent ? const Value.absent() : Value(step),
      reps: Value(reps),
      lapses: Value(lapses),
      createdAt: Value(createdAt),
    );
  }

  factory CardState.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CardState(
      id: serializer.fromJson<int>(json['id']),
      wordId: serializer.fromJson<String>(json['wordId']),
      stability: serializer.fromJson<double?>(json['stability']),
      difficulty: serializer.fromJson<double?>(json['difficulty']),
      due: serializer.fromJson<int>(json['due']),
      lastReview: serializer.fromJson<int?>(json['lastReview']),
      state: serializer.fromJson<int>(json['state']),
      step: serializer.fromJson<int?>(json['step']),
      reps: serializer.fromJson<int>(json['reps']),
      lapses: serializer.fromJson<int>(json['lapses']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'wordId': serializer.toJson<String>(wordId),
      'stability': serializer.toJson<double?>(stability),
      'difficulty': serializer.toJson<double?>(difficulty),
      'due': serializer.toJson<int>(due),
      'lastReview': serializer.toJson<int?>(lastReview),
      'state': serializer.toJson<int>(state),
      'step': serializer.toJson<int?>(step),
      'reps': serializer.toJson<int>(reps),
      'lapses': serializer.toJson<int>(lapses),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  CardState copyWith(
          {int? id,
          String? wordId,
          Value<double?> stability = const Value.absent(),
          Value<double?> difficulty = const Value.absent(),
          int? due,
          Value<int?> lastReview = const Value.absent(),
          int? state,
          Value<int?> step = const Value.absent(),
          int? reps,
          int? lapses,
          int? createdAt}) =>
      CardState(
        id: id ?? this.id,
        wordId: wordId ?? this.wordId,
        stability: stability.present ? stability.value : this.stability,
        difficulty: difficulty.present ? difficulty.value : this.difficulty,
        due: due ?? this.due,
        lastReview: lastReview.present ? lastReview.value : this.lastReview,
        state: state ?? this.state,
        step: step.present ? step.value : this.step,
        reps: reps ?? this.reps,
        lapses: lapses ?? this.lapses,
        createdAt: createdAt ?? this.createdAt,
      );
  CardState copyWithCompanion(CardStatesCompanion data) {
    return CardState(
      id: data.id.present ? data.id.value : this.id,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      stability: data.stability.present ? data.stability.value : this.stability,
      difficulty:
          data.difficulty.present ? data.difficulty.value : this.difficulty,
      due: data.due.present ? data.due.value : this.due,
      lastReview:
          data.lastReview.present ? data.lastReview.value : this.lastReview,
      state: data.state.present ? data.state.value : this.state,
      step: data.step.present ? data.step.value : this.step,
      reps: data.reps.present ? data.reps.value : this.reps,
      lapses: data.lapses.present ? data.lapses.value : this.lapses,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CardState(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('stability: $stability, ')
          ..write('difficulty: $difficulty, ')
          ..write('due: $due, ')
          ..write('lastReview: $lastReview, ')
          ..write('state: $state, ')
          ..write('step: $step, ')
          ..write('reps: $reps, ')
          ..write('lapses: $lapses, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, wordId, stability, difficulty, due,
      lastReview, state, step, reps, lapses, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CardState &&
          other.id == this.id &&
          other.wordId == this.wordId &&
          other.stability == this.stability &&
          other.difficulty == this.difficulty &&
          other.due == this.due &&
          other.lastReview == this.lastReview &&
          other.state == this.state &&
          other.step == this.step &&
          other.reps == this.reps &&
          other.lapses == this.lapses &&
          other.createdAt == this.createdAt);
}

class CardStatesCompanion extends UpdateCompanion<CardState> {
  final Value<int> id;
  final Value<String> wordId;
  final Value<double?> stability;
  final Value<double?> difficulty;
  final Value<int> due;
  final Value<int?> lastReview;
  final Value<int> state;
  final Value<int?> step;
  final Value<int> reps;
  final Value<int> lapses;
  final Value<int> createdAt;
  const CardStatesCompanion({
    this.id = const Value.absent(),
    this.wordId = const Value.absent(),
    this.stability = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.due = const Value.absent(),
    this.lastReview = const Value.absent(),
    this.state = const Value.absent(),
    this.step = const Value.absent(),
    this.reps = const Value.absent(),
    this.lapses = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CardStatesCompanion.insert({
    this.id = const Value.absent(),
    required String wordId,
    this.stability = const Value.absent(),
    this.difficulty = const Value.absent(),
    required int due,
    this.lastReview = const Value.absent(),
    this.state = const Value.absent(),
    this.step = const Value.absent(),
    this.reps = const Value.absent(),
    this.lapses = const Value.absent(),
    required int createdAt,
  })  : wordId = Value(wordId),
        due = Value(due),
        createdAt = Value(createdAt);
  static Insertable<CardState> custom({
    Expression<int>? id,
    Expression<String>? wordId,
    Expression<double>? stability,
    Expression<double>? difficulty,
    Expression<int>? due,
    Expression<int>? lastReview,
    Expression<int>? state,
    Expression<int>? step,
    Expression<int>? reps,
    Expression<int>? lapses,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (wordId != null) 'word_id': wordId,
      if (stability != null) 'stability': stability,
      if (difficulty != null) 'difficulty': difficulty,
      if (due != null) 'due': due,
      if (lastReview != null) 'last_review': lastReview,
      if (state != null) 'state': state,
      if (step != null) 'step': step,
      if (reps != null) 'reps': reps,
      if (lapses != null) 'lapses': lapses,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CardStatesCompanion copyWith(
      {Value<int>? id,
      Value<String>? wordId,
      Value<double?>? stability,
      Value<double?>? difficulty,
      Value<int>? due,
      Value<int?>? lastReview,
      Value<int>? state,
      Value<int?>? step,
      Value<int>? reps,
      Value<int>? lapses,
      Value<int>? createdAt}) {
    return CardStatesCompanion(
      id: id ?? this.id,
      wordId: wordId ?? this.wordId,
      stability: stability ?? this.stability,
      difficulty: difficulty ?? this.difficulty,
      due: due ?? this.due,
      lastReview: lastReview ?? this.lastReview,
      state: state ?? this.state,
      step: step ?? this.step,
      reps: reps ?? this.reps,
      lapses: lapses ?? this.lapses,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (wordId.present) {
      map['word_id'] = Variable<String>(wordId.value);
    }
    if (stability.present) {
      map['stability'] = Variable<double>(stability.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<double>(difficulty.value);
    }
    if (due.present) {
      map['due'] = Variable<int>(due.value);
    }
    if (lastReview.present) {
      map['last_review'] = Variable<int>(lastReview.value);
    }
    if (state.present) {
      map['state'] = Variable<int>(state.value);
    }
    if (step.present) {
      map['step'] = Variable<int>(step.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (lapses.present) {
      map['lapses'] = Variable<int>(lapses.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardStatesCompanion(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('stability: $stability, ')
          ..write('difficulty: $difficulty, ')
          ..write('due: $due, ')
          ..write('lastReview: $lastReview, ')
          ..write('state: $state, ')
          ..write('step: $step, ')
          ..write('reps: $reps, ')
          ..write('lapses: $lapses, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ReviewLogsTable extends ReviewLogs
    with TableInfo<$ReviewLogsTable, ReviewLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _cardStateIdMeta =
      const VerificationMeta('cardStateId');
  @override
  late final GeneratedColumn<int> cardStateId = GeneratedColumn<int>(
      'card_state_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES card_states (id)'));
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<String> wordId = GeneratedColumn<String>(
      'word_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
      'rating', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _reviewTimeUtcMeta =
      const VerificationMeta('reviewTimeUtc');
  @override
  late final GeneratedColumn<int> reviewTimeUtc = GeneratedColumn<int>(
      'review_time_utc', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _elapsedDaysMeta =
      const VerificationMeta('elapsedDays');
  @override
  late final GeneratedColumn<double> elapsedDays = GeneratedColumn<double>(
      'elapsed_days', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _scheduledDaysMeta =
      const VerificationMeta('scheduledDays');
  @override
  late final GeneratedColumn<double> scheduledDays = GeneratedColumn<double>(
      'scheduled_days', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _stateBeforeMeta =
      const VerificationMeta('stateBefore');
  @override
  late final GeneratedColumn<int> stateBefore = GeneratedColumn<int>(
      'state_before', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _stabilityBeforeMeta =
      const VerificationMeta('stabilityBefore');
  @override
  late final GeneratedColumn<double> stabilityBefore = GeneratedColumn<double>(
      'stability_before', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _difficultyBeforeMeta =
      const VerificationMeta('difficultyBefore');
  @override
  late final GeneratedColumn<double> difficultyBefore = GeneratedColumn<double>(
      'difficulty_before', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _clientVersionMeta =
      const VerificationMeta('clientVersion');
  @override
  late final GeneratedColumn<String> clientVersion = GeneratedColumn<String>(
      'client_version', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        cardStateId,
        wordId,
        rating,
        reviewTimeUtc,
        elapsedDays,
        scheduledDays,
        stateBefore,
        stabilityBefore,
        difficultyBefore,
        clientVersion
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_logs';
  @override
  VerificationContext validateIntegrity(Insertable<ReviewLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('card_state_id')) {
      context.handle(
          _cardStateIdMeta,
          cardStateId.isAcceptableOrUnknown(
              data['card_state_id']!, _cardStateIdMeta));
    } else if (isInserting) {
      context.missing(_cardStateIdMeta);
    }
    if (data.containsKey('word_id')) {
      context.handle(_wordIdMeta,
          wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta));
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(_ratingMeta,
          rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta));
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('review_time_utc')) {
      context.handle(
          _reviewTimeUtcMeta,
          reviewTimeUtc.isAcceptableOrUnknown(
              data['review_time_utc']!, _reviewTimeUtcMeta));
    } else if (isInserting) {
      context.missing(_reviewTimeUtcMeta);
    }
    if (data.containsKey('elapsed_days')) {
      context.handle(
          _elapsedDaysMeta,
          elapsedDays.isAcceptableOrUnknown(
              data['elapsed_days']!, _elapsedDaysMeta));
    } else if (isInserting) {
      context.missing(_elapsedDaysMeta);
    }
    if (data.containsKey('scheduled_days')) {
      context.handle(
          _scheduledDaysMeta,
          scheduledDays.isAcceptableOrUnknown(
              data['scheduled_days']!, _scheduledDaysMeta));
    } else if (isInserting) {
      context.missing(_scheduledDaysMeta);
    }
    if (data.containsKey('state_before')) {
      context.handle(
          _stateBeforeMeta,
          stateBefore.isAcceptableOrUnknown(
              data['state_before']!, _stateBeforeMeta));
    } else if (isInserting) {
      context.missing(_stateBeforeMeta);
    }
    if (data.containsKey('stability_before')) {
      context.handle(
          _stabilityBeforeMeta,
          stabilityBefore.isAcceptableOrUnknown(
              data['stability_before']!, _stabilityBeforeMeta));
    }
    if (data.containsKey('difficulty_before')) {
      context.handle(
          _difficultyBeforeMeta,
          difficultyBefore.isAcceptableOrUnknown(
              data['difficulty_before']!, _difficultyBeforeMeta));
    }
    if (data.containsKey('client_version')) {
      context.handle(
          _clientVersionMeta,
          clientVersion.isAcceptableOrUnknown(
              data['client_version']!, _clientVersionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReviewLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewLog(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      cardStateId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}card_state_id'])!,
      wordId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}word_id'])!,
      rating: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rating'])!,
      reviewTimeUtc: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}review_time_utc'])!,
      elapsedDays: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}elapsed_days'])!,
      scheduledDays: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}scheduled_days'])!,
      stateBefore: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}state_before'])!,
      stabilityBefore: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}stability_before']),
      difficultyBefore: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}difficulty_before']),
      clientVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}client_version']),
    );
  }

  @override
  $ReviewLogsTable createAlias(String alias) {
    return $ReviewLogsTable(attachedDatabase, alias);
  }
}

class ReviewLog extends DataClass implements Insertable<ReviewLog> {
  final int id;

  /// FK to card_states.id
  final int cardStateId;

  /// Redundant word_id for convenient querying without JOIN.
  final String wordId;

  /// Rating: 1=Again, 2=Hard, 3=Good, 4=Easy
  final int rating;

  /// When this review happened. UTC epoch ms.
  final int reviewTimeUtc;

  /// Days elapsed since last review.
  final double elapsedDays;

  /// Days that FSRS had scheduled before this review.
  final double scheduledDays;

  /// Card state before this review (1/2/3).
  final int stateBefore;

  /// Card stability before this review.
  final double? stabilityBefore;

  /// Card difficulty before this review.
  final double? difficultyBefore;

  /// App version string for traceability.
  final String? clientVersion;
  const ReviewLog(
      {required this.id,
      required this.cardStateId,
      required this.wordId,
      required this.rating,
      required this.reviewTimeUtc,
      required this.elapsedDays,
      required this.scheduledDays,
      required this.stateBefore,
      this.stabilityBefore,
      this.difficultyBefore,
      this.clientVersion});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['card_state_id'] = Variable<int>(cardStateId);
    map['word_id'] = Variable<String>(wordId);
    map['rating'] = Variable<int>(rating);
    map['review_time_utc'] = Variable<int>(reviewTimeUtc);
    map['elapsed_days'] = Variable<double>(elapsedDays);
    map['scheduled_days'] = Variable<double>(scheduledDays);
    map['state_before'] = Variable<int>(stateBefore);
    if (!nullToAbsent || stabilityBefore != null) {
      map['stability_before'] = Variable<double>(stabilityBefore);
    }
    if (!nullToAbsent || difficultyBefore != null) {
      map['difficulty_before'] = Variable<double>(difficultyBefore);
    }
    if (!nullToAbsent || clientVersion != null) {
      map['client_version'] = Variable<String>(clientVersion);
    }
    return map;
  }

  ReviewLogsCompanion toCompanion(bool nullToAbsent) {
    return ReviewLogsCompanion(
      id: Value(id),
      cardStateId: Value(cardStateId),
      wordId: Value(wordId),
      rating: Value(rating),
      reviewTimeUtc: Value(reviewTimeUtc),
      elapsedDays: Value(elapsedDays),
      scheduledDays: Value(scheduledDays),
      stateBefore: Value(stateBefore),
      stabilityBefore: stabilityBefore == null && nullToAbsent
          ? const Value.absent()
          : Value(stabilityBefore),
      difficultyBefore: difficultyBefore == null && nullToAbsent
          ? const Value.absent()
          : Value(difficultyBefore),
      clientVersion: clientVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(clientVersion),
    );
  }

  factory ReviewLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewLog(
      id: serializer.fromJson<int>(json['id']),
      cardStateId: serializer.fromJson<int>(json['cardStateId']),
      wordId: serializer.fromJson<String>(json['wordId']),
      rating: serializer.fromJson<int>(json['rating']),
      reviewTimeUtc: serializer.fromJson<int>(json['reviewTimeUtc']),
      elapsedDays: serializer.fromJson<double>(json['elapsedDays']),
      scheduledDays: serializer.fromJson<double>(json['scheduledDays']),
      stateBefore: serializer.fromJson<int>(json['stateBefore']),
      stabilityBefore: serializer.fromJson<double?>(json['stabilityBefore']),
      difficultyBefore: serializer.fromJson<double?>(json['difficultyBefore']),
      clientVersion: serializer.fromJson<String?>(json['clientVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cardStateId': serializer.toJson<int>(cardStateId),
      'wordId': serializer.toJson<String>(wordId),
      'rating': serializer.toJson<int>(rating),
      'reviewTimeUtc': serializer.toJson<int>(reviewTimeUtc),
      'elapsedDays': serializer.toJson<double>(elapsedDays),
      'scheduledDays': serializer.toJson<double>(scheduledDays),
      'stateBefore': serializer.toJson<int>(stateBefore),
      'stabilityBefore': serializer.toJson<double?>(stabilityBefore),
      'difficultyBefore': serializer.toJson<double?>(difficultyBefore),
      'clientVersion': serializer.toJson<String?>(clientVersion),
    };
  }

  ReviewLog copyWith(
          {int? id,
          int? cardStateId,
          String? wordId,
          int? rating,
          int? reviewTimeUtc,
          double? elapsedDays,
          double? scheduledDays,
          int? stateBefore,
          Value<double?> stabilityBefore = const Value.absent(),
          Value<double?> difficultyBefore = const Value.absent(),
          Value<String?> clientVersion = const Value.absent()}) =>
      ReviewLog(
        id: id ?? this.id,
        cardStateId: cardStateId ?? this.cardStateId,
        wordId: wordId ?? this.wordId,
        rating: rating ?? this.rating,
        reviewTimeUtc: reviewTimeUtc ?? this.reviewTimeUtc,
        elapsedDays: elapsedDays ?? this.elapsedDays,
        scheduledDays: scheduledDays ?? this.scheduledDays,
        stateBefore: stateBefore ?? this.stateBefore,
        stabilityBefore: stabilityBefore.present
            ? stabilityBefore.value
            : this.stabilityBefore,
        difficultyBefore: difficultyBefore.present
            ? difficultyBefore.value
            : this.difficultyBefore,
        clientVersion:
            clientVersion.present ? clientVersion.value : this.clientVersion,
      );
  ReviewLog copyWithCompanion(ReviewLogsCompanion data) {
    return ReviewLog(
      id: data.id.present ? data.id.value : this.id,
      cardStateId:
          data.cardStateId.present ? data.cardStateId.value : this.cardStateId,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      rating: data.rating.present ? data.rating.value : this.rating,
      reviewTimeUtc: data.reviewTimeUtc.present
          ? data.reviewTimeUtc.value
          : this.reviewTimeUtc,
      elapsedDays:
          data.elapsedDays.present ? data.elapsedDays.value : this.elapsedDays,
      scheduledDays: data.scheduledDays.present
          ? data.scheduledDays.value
          : this.scheduledDays,
      stateBefore:
          data.stateBefore.present ? data.stateBefore.value : this.stateBefore,
      stabilityBefore: data.stabilityBefore.present
          ? data.stabilityBefore.value
          : this.stabilityBefore,
      difficultyBefore: data.difficultyBefore.present
          ? data.difficultyBefore.value
          : this.difficultyBefore,
      clientVersion: data.clientVersion.present
          ? data.clientVersion.value
          : this.clientVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLog(')
          ..write('id: $id, ')
          ..write('cardStateId: $cardStateId, ')
          ..write('wordId: $wordId, ')
          ..write('rating: $rating, ')
          ..write('reviewTimeUtc: $reviewTimeUtc, ')
          ..write('elapsedDays: $elapsedDays, ')
          ..write('scheduledDays: $scheduledDays, ')
          ..write('stateBefore: $stateBefore, ')
          ..write('stabilityBefore: $stabilityBefore, ')
          ..write('difficultyBefore: $difficultyBefore, ')
          ..write('clientVersion: $clientVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      cardStateId,
      wordId,
      rating,
      reviewTimeUtc,
      elapsedDays,
      scheduledDays,
      stateBefore,
      stabilityBefore,
      difficultyBefore,
      clientVersion);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewLog &&
          other.id == this.id &&
          other.cardStateId == this.cardStateId &&
          other.wordId == this.wordId &&
          other.rating == this.rating &&
          other.reviewTimeUtc == this.reviewTimeUtc &&
          other.elapsedDays == this.elapsedDays &&
          other.scheduledDays == this.scheduledDays &&
          other.stateBefore == this.stateBefore &&
          other.stabilityBefore == this.stabilityBefore &&
          other.difficultyBefore == this.difficultyBefore &&
          other.clientVersion == this.clientVersion);
}

class ReviewLogsCompanion extends UpdateCompanion<ReviewLog> {
  final Value<int> id;
  final Value<int> cardStateId;
  final Value<String> wordId;
  final Value<int> rating;
  final Value<int> reviewTimeUtc;
  final Value<double> elapsedDays;
  final Value<double> scheduledDays;
  final Value<int> stateBefore;
  final Value<double?> stabilityBefore;
  final Value<double?> difficultyBefore;
  final Value<String?> clientVersion;
  const ReviewLogsCompanion({
    this.id = const Value.absent(),
    this.cardStateId = const Value.absent(),
    this.wordId = const Value.absent(),
    this.rating = const Value.absent(),
    this.reviewTimeUtc = const Value.absent(),
    this.elapsedDays = const Value.absent(),
    this.scheduledDays = const Value.absent(),
    this.stateBefore = const Value.absent(),
    this.stabilityBefore = const Value.absent(),
    this.difficultyBefore = const Value.absent(),
    this.clientVersion = const Value.absent(),
  });
  ReviewLogsCompanion.insert({
    this.id = const Value.absent(),
    required int cardStateId,
    required String wordId,
    required int rating,
    required int reviewTimeUtc,
    required double elapsedDays,
    required double scheduledDays,
    required int stateBefore,
    this.stabilityBefore = const Value.absent(),
    this.difficultyBefore = const Value.absent(),
    this.clientVersion = const Value.absent(),
  })  : cardStateId = Value(cardStateId),
        wordId = Value(wordId),
        rating = Value(rating),
        reviewTimeUtc = Value(reviewTimeUtc),
        elapsedDays = Value(elapsedDays),
        scheduledDays = Value(scheduledDays),
        stateBefore = Value(stateBefore);
  static Insertable<ReviewLog> custom({
    Expression<int>? id,
    Expression<int>? cardStateId,
    Expression<String>? wordId,
    Expression<int>? rating,
    Expression<int>? reviewTimeUtc,
    Expression<double>? elapsedDays,
    Expression<double>? scheduledDays,
    Expression<int>? stateBefore,
    Expression<double>? stabilityBefore,
    Expression<double>? difficultyBefore,
    Expression<String>? clientVersion,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cardStateId != null) 'card_state_id': cardStateId,
      if (wordId != null) 'word_id': wordId,
      if (rating != null) 'rating': rating,
      if (reviewTimeUtc != null) 'review_time_utc': reviewTimeUtc,
      if (elapsedDays != null) 'elapsed_days': elapsedDays,
      if (scheduledDays != null) 'scheduled_days': scheduledDays,
      if (stateBefore != null) 'state_before': stateBefore,
      if (stabilityBefore != null) 'stability_before': stabilityBefore,
      if (difficultyBefore != null) 'difficulty_before': difficultyBefore,
      if (clientVersion != null) 'client_version': clientVersion,
    });
  }

  ReviewLogsCompanion copyWith(
      {Value<int>? id,
      Value<int>? cardStateId,
      Value<String>? wordId,
      Value<int>? rating,
      Value<int>? reviewTimeUtc,
      Value<double>? elapsedDays,
      Value<double>? scheduledDays,
      Value<int>? stateBefore,
      Value<double?>? stabilityBefore,
      Value<double?>? difficultyBefore,
      Value<String?>? clientVersion}) {
    return ReviewLogsCompanion(
      id: id ?? this.id,
      cardStateId: cardStateId ?? this.cardStateId,
      wordId: wordId ?? this.wordId,
      rating: rating ?? this.rating,
      reviewTimeUtc: reviewTimeUtc ?? this.reviewTimeUtc,
      elapsedDays: elapsedDays ?? this.elapsedDays,
      scheduledDays: scheduledDays ?? this.scheduledDays,
      stateBefore: stateBefore ?? this.stateBefore,
      stabilityBefore: stabilityBefore ?? this.stabilityBefore,
      difficultyBefore: difficultyBefore ?? this.difficultyBefore,
      clientVersion: clientVersion ?? this.clientVersion,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cardStateId.present) {
      map['card_state_id'] = Variable<int>(cardStateId.value);
    }
    if (wordId.present) {
      map['word_id'] = Variable<String>(wordId.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (reviewTimeUtc.present) {
      map['review_time_utc'] = Variable<int>(reviewTimeUtc.value);
    }
    if (elapsedDays.present) {
      map['elapsed_days'] = Variable<double>(elapsedDays.value);
    }
    if (scheduledDays.present) {
      map['scheduled_days'] = Variable<double>(scheduledDays.value);
    }
    if (stateBefore.present) {
      map['state_before'] = Variable<int>(stateBefore.value);
    }
    if (stabilityBefore.present) {
      map['stability_before'] = Variable<double>(stabilityBefore.value);
    }
    if (difficultyBefore.present) {
      map['difficulty_before'] = Variable<double>(difficultyBefore.value);
    }
    if (clientVersion.present) {
      map['client_version'] = Variable<String>(clientVersion.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLogsCompanion(')
          ..write('id: $id, ')
          ..write('cardStateId: $cardStateId, ')
          ..write('wordId: $wordId, ')
          ..write('rating: $rating, ')
          ..write('reviewTimeUtc: $reviewTimeUtc, ')
          ..write('elapsedDays: $elapsedDays, ')
          ..write('scheduledDays: $scheduledDays, ')
          ..write('stateBefore: $stateBefore, ')
          ..write('stabilityBefore: $stabilityBefore, ')
          ..write('difficultyBefore: $difficultyBefore, ')
          ..write('clientVersion: $clientVersion')
          ..write(')'))
        .toString();
  }
}

class $CachedWordsTable extends CachedWords
    with TableInfo<$CachedWordsTable, CachedWord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedWordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<String> wordId = GeneratedColumn<String>(
      'word_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
      'book_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _wordTextMeta =
      const VerificationMeta('wordText');
  @override
  late final GeneratedColumn<String> wordText = GeneratedColumn<String>(
      'word_text', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _meaningMeta =
      const VerificationMeta('meaning');
  @override
  late final GeneratedColumn<String> meaning = GeneratedColumn<String>(
      'meaning', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _phoneticMeta =
      const VerificationMeta('phonetic');
  @override
  late final GeneratedColumn<String> phonetic = GeneratedColumn<String>(
      'phonetic', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _translationMeta =
      const VerificationMeta('translation');
  @override
  late final GeneratedColumn<String> translation = GeneratedColumn<String>(
      'translation', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _frequencyRankMeta =
      const VerificationMeta('frequencyRank');
  @override
  late final GeneratedColumn<int> frequencyRank = GeneratedColumn<int>(
      'frequency_rank', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<int> cachedAt = GeneratedColumn<int>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        wordId,
        bookId,
        wordText,
        meaning,
        phonetic,
        translation,
        frequencyRank,
        sortOrder,
        cachedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_words';
  @override
  VerificationContext validateIntegrity(Insertable<CachedWord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('word_id')) {
      context.handle(_wordIdMeta,
          wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta));
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(_bookIdMeta,
          bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta));
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('word_text')) {
      context.handle(_wordTextMeta,
          wordText.isAcceptableOrUnknown(data['word_text']!, _wordTextMeta));
    } else if (isInserting) {
      context.missing(_wordTextMeta);
    }
    if (data.containsKey('meaning')) {
      context.handle(_meaningMeta,
          meaning.isAcceptableOrUnknown(data['meaning']!, _meaningMeta));
    } else if (isInserting) {
      context.missing(_meaningMeta);
    }
    if (data.containsKey('phonetic')) {
      context.handle(_phoneticMeta,
          phonetic.isAcceptableOrUnknown(data['phonetic']!, _phoneticMeta));
    }
    if (data.containsKey('translation')) {
      context.handle(
          _translationMeta,
          translation.isAcceptableOrUnknown(
              data['translation']!, _translationMeta));
    }
    if (data.containsKey('frequency_rank')) {
      context.handle(
          _frequencyRankMeta,
          frequencyRank.isAcceptableOrUnknown(
              data['frequency_rank']!, _frequencyRankMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {wordId};
  @override
  CachedWord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedWord(
      wordId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}word_id'])!,
      bookId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}book_id'])!,
      wordText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}word_text'])!,
      meaning: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meaning'])!,
      phonetic: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phonetic']),
      translation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}translation']),
      frequencyRank: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}frequency_rank'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cached_at'])!,
    );
  }

  @override
  $CachedWordsTable createAlias(String alias) {
    return $CachedWordsTable(attachedDatabase, alias);
  }
}

class CachedWord extends DataClass implements Insertable<CachedWord> {
  /// Word identifier, e.g. 'cet4-abandon'. Primary key.
  final String wordId;

  /// Which book this word belongs to, e.g. 'book-001'.
  final String bookId;

  /// The word text, e.g. 'abandon'.
  final String wordText;

  /// Short Chinese meaning, e.g. '放弃'.
  final String meaning;

  /// Phonetic notation, e.g. '/əˈbændən/'.
  final String? phonetic;

  /// Full Chinese translation (multi-POS).
  final String? translation;

  /// Frequency rank (lower = more common). Used for sort_order.
  final int frequencyRank;

  /// Learning order (typically same as frequency_rank).
  final int sortOrder;

  /// When this word was cached locally. UTC epoch ms.
  final int cachedAt;
  const CachedWord(
      {required this.wordId,
      required this.bookId,
      required this.wordText,
      required this.meaning,
      this.phonetic,
      this.translation,
      required this.frequencyRank,
      required this.sortOrder,
      required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['word_id'] = Variable<String>(wordId);
    map['book_id'] = Variable<String>(bookId);
    map['word_text'] = Variable<String>(wordText);
    map['meaning'] = Variable<String>(meaning);
    if (!nullToAbsent || phonetic != null) {
      map['phonetic'] = Variable<String>(phonetic);
    }
    if (!nullToAbsent || translation != null) {
      map['translation'] = Variable<String>(translation);
    }
    map['frequency_rank'] = Variable<int>(frequencyRank);
    map['sort_order'] = Variable<int>(sortOrder);
    map['cached_at'] = Variable<int>(cachedAt);
    return map;
  }

  CachedWordsCompanion toCompanion(bool nullToAbsent) {
    return CachedWordsCompanion(
      wordId: Value(wordId),
      bookId: Value(bookId),
      wordText: Value(wordText),
      meaning: Value(meaning),
      phonetic: phonetic == null && nullToAbsent
          ? const Value.absent()
          : Value(phonetic),
      translation: translation == null && nullToAbsent
          ? const Value.absent()
          : Value(translation),
      frequencyRank: Value(frequencyRank),
      sortOrder: Value(sortOrder),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedWord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedWord(
      wordId: serializer.fromJson<String>(json['wordId']),
      bookId: serializer.fromJson<String>(json['bookId']),
      wordText: serializer.fromJson<String>(json['wordText']),
      meaning: serializer.fromJson<String>(json['meaning']),
      phonetic: serializer.fromJson<String?>(json['phonetic']),
      translation: serializer.fromJson<String?>(json['translation']),
      frequencyRank: serializer.fromJson<int>(json['frequencyRank']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      cachedAt: serializer.fromJson<int>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'wordId': serializer.toJson<String>(wordId),
      'bookId': serializer.toJson<String>(bookId),
      'wordText': serializer.toJson<String>(wordText),
      'meaning': serializer.toJson<String>(meaning),
      'phonetic': serializer.toJson<String?>(phonetic),
      'translation': serializer.toJson<String?>(translation),
      'frequencyRank': serializer.toJson<int>(frequencyRank),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'cachedAt': serializer.toJson<int>(cachedAt),
    };
  }

  CachedWord copyWith(
          {String? wordId,
          String? bookId,
          String? wordText,
          String? meaning,
          Value<String?> phonetic = const Value.absent(),
          Value<String?> translation = const Value.absent(),
          int? frequencyRank,
          int? sortOrder,
          int? cachedAt}) =>
      CachedWord(
        wordId: wordId ?? this.wordId,
        bookId: bookId ?? this.bookId,
        wordText: wordText ?? this.wordText,
        meaning: meaning ?? this.meaning,
        phonetic: phonetic.present ? phonetic.value : this.phonetic,
        translation: translation.present ? translation.value : this.translation,
        frequencyRank: frequencyRank ?? this.frequencyRank,
        sortOrder: sortOrder ?? this.sortOrder,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  CachedWord copyWithCompanion(CachedWordsCompanion data) {
    return CachedWord(
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      wordText: data.wordText.present ? data.wordText.value : this.wordText,
      meaning: data.meaning.present ? data.meaning.value : this.meaning,
      phonetic: data.phonetic.present ? data.phonetic.value : this.phonetic,
      translation:
          data.translation.present ? data.translation.value : this.translation,
      frequencyRank: data.frequencyRank.present
          ? data.frequencyRank.value
          : this.frequencyRank,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedWord(')
          ..write('wordId: $wordId, ')
          ..write('bookId: $bookId, ')
          ..write('wordText: $wordText, ')
          ..write('meaning: $meaning, ')
          ..write('phonetic: $phonetic, ')
          ..write('translation: $translation, ')
          ..write('frequencyRank: $frequencyRank, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(wordId, bookId, wordText, meaning, phonetic,
      translation, frequencyRank, sortOrder, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedWord &&
          other.wordId == this.wordId &&
          other.bookId == this.bookId &&
          other.wordText == this.wordText &&
          other.meaning == this.meaning &&
          other.phonetic == this.phonetic &&
          other.translation == this.translation &&
          other.frequencyRank == this.frequencyRank &&
          other.sortOrder == this.sortOrder &&
          other.cachedAt == this.cachedAt);
}

class CachedWordsCompanion extends UpdateCompanion<CachedWord> {
  final Value<String> wordId;
  final Value<String> bookId;
  final Value<String> wordText;
  final Value<String> meaning;
  final Value<String?> phonetic;
  final Value<String?> translation;
  final Value<int> frequencyRank;
  final Value<int> sortOrder;
  final Value<int> cachedAt;
  final Value<int> rowid;
  const CachedWordsCompanion({
    this.wordId = const Value.absent(),
    this.bookId = const Value.absent(),
    this.wordText = const Value.absent(),
    this.meaning = const Value.absent(),
    this.phonetic = const Value.absent(),
    this.translation = const Value.absent(),
    this.frequencyRank = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedWordsCompanion.insert({
    required String wordId,
    required String bookId,
    required String wordText,
    required String meaning,
    this.phonetic = const Value.absent(),
    this.translation = const Value.absent(),
    this.frequencyRank = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required int cachedAt,
    this.rowid = const Value.absent(),
  })  : wordId = Value(wordId),
        bookId = Value(bookId),
        wordText = Value(wordText),
        meaning = Value(meaning),
        cachedAt = Value(cachedAt);
  static Insertable<CachedWord> custom({
    Expression<String>? wordId,
    Expression<String>? bookId,
    Expression<String>? wordText,
    Expression<String>? meaning,
    Expression<String>? phonetic,
    Expression<String>? translation,
    Expression<int>? frequencyRank,
    Expression<int>? sortOrder,
    Expression<int>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (wordId != null) 'word_id': wordId,
      if (bookId != null) 'book_id': bookId,
      if (wordText != null) 'word_text': wordText,
      if (meaning != null) 'meaning': meaning,
      if (phonetic != null) 'phonetic': phonetic,
      if (translation != null) 'translation': translation,
      if (frequencyRank != null) 'frequency_rank': frequencyRank,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedWordsCompanion copyWith(
      {Value<String>? wordId,
      Value<String>? bookId,
      Value<String>? wordText,
      Value<String>? meaning,
      Value<String?>? phonetic,
      Value<String?>? translation,
      Value<int>? frequencyRank,
      Value<int>? sortOrder,
      Value<int>? cachedAt,
      Value<int>? rowid}) {
    return CachedWordsCompanion(
      wordId: wordId ?? this.wordId,
      bookId: bookId ?? this.bookId,
      wordText: wordText ?? this.wordText,
      meaning: meaning ?? this.meaning,
      phonetic: phonetic ?? this.phonetic,
      translation: translation ?? this.translation,
      frequencyRank: frequencyRank ?? this.frequencyRank,
      sortOrder: sortOrder ?? this.sortOrder,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (wordId.present) {
      map['word_id'] = Variable<String>(wordId.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (wordText.present) {
      map['word_text'] = Variable<String>(wordText.value);
    }
    if (meaning.present) {
      map['meaning'] = Variable<String>(meaning.value);
    }
    if (phonetic.present) {
      map['phonetic'] = Variable<String>(phonetic.value);
    }
    if (translation.present) {
      map['translation'] = Variable<String>(translation.value);
    }
    if (frequencyRank.present) {
      map['frequency_rank'] = Variable<int>(frequencyRank.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<int>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedWordsCompanion(')
          ..write('wordId: $wordId, ')
          ..write('bookId: $bookId, ')
          ..write('wordText: $wordText, ')
          ..write('meaning: $meaning, ')
          ..write('phonetic: $phonetic, ')
          ..write('translation: $translation, ')
          ..write('frequencyRank: $frequencyRank, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WordRecordsTable wordRecords = $WordRecordsTable(this);
  late final $WordbookProgressTable wordbookProgress =
      $WordbookProgressTable(this);
  late final $DailyCheckinsTable dailyCheckins = $DailyCheckinsTable(this);
  late final $CustomWordbooksTable customWordbooks =
      $CustomWordbooksTable(this);
  late final $VocabularyNotebookTable vocabularyNotebook =
      $VocabularyNotebookTable(this);
  late final $CardStatesTable cardStates = $CardStatesTable(this);
  late final $ReviewLogsTable reviewLogs = $ReviewLogsTable(this);
  late final $CachedWordsTable cachedWords = $CachedWordsTable(this);
  late final Index idxCardStatesDue = Index('idx_card_states_due',
      'CREATE INDEX idx_card_states_due ON card_states (due)');
  late final Index idxCardStatesState = Index('idx_card_states_state',
      'CREATE INDEX idx_card_states_state ON card_states (state)');
  late final Index idxReviewLogsWordId = Index('idx_review_logs_word_id',
      'CREATE INDEX idx_review_logs_word_id ON review_logs (word_id)');
  late final Index idxReviewLogsReviewTime = Index(
      'idx_review_logs_review_time',
      'CREATE INDEX idx_review_logs_review_time ON review_logs (review_time_utc)');
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        wordRecords,
        wordbookProgress,
        dailyCheckins,
        customWordbooks,
        vocabularyNotebook,
        cardStates,
        reviewLogs,
        cachedWords,
        idxCardStatesDue,
        idxCardStatesState,
        idxReviewLogsWordId,
        idxReviewLogsReviewTime
      ];
}

typedef $$WordRecordsTableCreateCompanionBuilder = WordRecordsCompanion
    Function({
  Value<int> id,
  required String wordId,
  required String bookId,
  Value<String> studyType,
  required String actionResult,
  required String createdAt,
  Value<int> synced,
});
typedef $$WordRecordsTableUpdateCompanionBuilder = WordRecordsCompanion
    Function({
  Value<int> id,
  Value<String> wordId,
  Value<String> bookId,
  Value<String> studyType,
  Value<String> actionResult,
  Value<String> createdAt,
  Value<int> synced,
});

class $$WordRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $WordRecordsTable> {
  $$WordRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get wordId => $composableBuilder(
      column: $table.wordId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bookId => $composableBuilder(
      column: $table.bookId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get studyType => $composableBuilder(
      column: $table.studyType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get actionResult => $composableBuilder(
      column: $table.actionResult, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnFilters(column));
}

class $$WordRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $WordRecordsTable> {
  $$WordRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get wordId => $composableBuilder(
      column: $table.wordId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bookId => $composableBuilder(
      column: $table.bookId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get studyType => $composableBuilder(
      column: $table.studyType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get actionResult => $composableBuilder(
      column: $table.actionResult,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnOrderings(column));
}

class $$WordRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordRecordsTable> {
  $$WordRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get wordId =>
      $composableBuilder(column: $table.wordId, builder: (column) => column);

  GeneratedColumn<String> get bookId =>
      $composableBuilder(column: $table.bookId, builder: (column) => column);

  GeneratedColumn<String> get studyType =>
      $composableBuilder(column: $table.studyType, builder: (column) => column);

  GeneratedColumn<String> get actionResult => $composableBuilder(
      column: $table.actionResult, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$WordRecordsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WordRecordsTable,
    WordRecord,
    $$WordRecordsTableFilterComposer,
    $$WordRecordsTableOrderingComposer,
    $$WordRecordsTableAnnotationComposer,
    $$WordRecordsTableCreateCompanionBuilder,
    $$WordRecordsTableUpdateCompanionBuilder,
    (WordRecord, BaseReferences<_$AppDatabase, $WordRecordsTable, WordRecord>),
    WordRecord,
    PrefetchHooks Function()> {
  $$WordRecordsTableTableManager(_$AppDatabase db, $WordRecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> wordId = const Value.absent(),
            Value<String> bookId = const Value.absent(),
            Value<String> studyType = const Value.absent(),
            Value<String> actionResult = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<int> synced = const Value.absent(),
          }) =>
              WordRecordsCompanion(
            id: id,
            wordId: wordId,
            bookId: bookId,
            studyType: studyType,
            actionResult: actionResult,
            createdAt: createdAt,
            synced: synced,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String wordId,
            required String bookId,
            Value<String> studyType = const Value.absent(),
            required String actionResult,
            required String createdAt,
            Value<int> synced = const Value.absent(),
          }) =>
              WordRecordsCompanion.insert(
            id: id,
            wordId: wordId,
            bookId: bookId,
            studyType: studyType,
            actionResult: actionResult,
            createdAt: createdAt,
            synced: synced,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WordRecordsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WordRecordsTable,
    WordRecord,
    $$WordRecordsTableFilterComposer,
    $$WordRecordsTableOrderingComposer,
    $$WordRecordsTableAnnotationComposer,
    $$WordRecordsTableCreateCompanionBuilder,
    $$WordRecordsTableUpdateCompanionBuilder,
    (WordRecord, BaseReferences<_$AppDatabase, $WordRecordsTable, WordRecord>),
    WordRecord,
    PrefetchHooks Function()>;
typedef $$WordbookProgressTableCreateCompanionBuilder
    = WordbookProgressCompanion Function({
  Value<int> id,
  required String bookId,
  Value<int> totalWords,
  Value<int> completedWords,
  required String updatedAt,
});
typedef $$WordbookProgressTableUpdateCompanionBuilder
    = WordbookProgressCompanion Function({
  Value<int> id,
  Value<String> bookId,
  Value<int> totalWords,
  Value<int> completedWords,
  Value<String> updatedAt,
});

class $$WordbookProgressTableFilterComposer
    extends Composer<_$AppDatabase, $WordbookProgressTable> {
  $$WordbookProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bookId => $composableBuilder(
      column: $table.bookId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalWords => $composableBuilder(
      column: $table.totalWords, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get completedWords => $composableBuilder(
      column: $table.completedWords,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$WordbookProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $WordbookProgressTable> {
  $$WordbookProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bookId => $composableBuilder(
      column: $table.bookId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalWords => $composableBuilder(
      column: $table.totalWords, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get completedWords => $composableBuilder(
      column: $table.completedWords,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$WordbookProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordbookProgressTable> {
  $$WordbookProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bookId =>
      $composableBuilder(column: $table.bookId, builder: (column) => column);

  GeneratedColumn<int> get totalWords => $composableBuilder(
      column: $table.totalWords, builder: (column) => column);

  GeneratedColumn<int> get completedWords => $composableBuilder(
      column: $table.completedWords, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$WordbookProgressTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WordbookProgressTable,
    WordbookProgressData,
    $$WordbookProgressTableFilterComposer,
    $$WordbookProgressTableOrderingComposer,
    $$WordbookProgressTableAnnotationComposer,
    $$WordbookProgressTableCreateCompanionBuilder,
    $$WordbookProgressTableUpdateCompanionBuilder,
    (
      WordbookProgressData,
      BaseReferences<_$AppDatabase, $WordbookProgressTable,
          WordbookProgressData>
    ),
    WordbookProgressData,
    PrefetchHooks Function()> {
  $$WordbookProgressTableTableManager(
      _$AppDatabase db, $WordbookProgressTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordbookProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordbookProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordbookProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> bookId = const Value.absent(),
            Value<int> totalWords = const Value.absent(),
            Value<int> completedWords = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
          }) =>
              WordbookProgressCompanion(
            id: id,
            bookId: bookId,
            totalWords: totalWords,
            completedWords: completedWords,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String bookId,
            Value<int> totalWords = const Value.absent(),
            Value<int> completedWords = const Value.absent(),
            required String updatedAt,
          }) =>
              WordbookProgressCompanion.insert(
            id: id,
            bookId: bookId,
            totalWords: totalWords,
            completedWords: completedWords,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WordbookProgressTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WordbookProgressTable,
    WordbookProgressData,
    $$WordbookProgressTableFilterComposer,
    $$WordbookProgressTableOrderingComposer,
    $$WordbookProgressTableAnnotationComposer,
    $$WordbookProgressTableCreateCompanionBuilder,
    $$WordbookProgressTableUpdateCompanionBuilder,
    (
      WordbookProgressData,
      BaseReferences<_$AppDatabase, $WordbookProgressTable,
          WordbookProgressData>
    ),
    WordbookProgressData,
    PrefetchHooks Function()>;
typedef $$DailyCheckinsTableCreateCompanionBuilder = DailyCheckinsCompanion
    Function({
  Value<int> id,
  required String date,
  Value<int> checkedIn,
  required String createdAt,
});
typedef $$DailyCheckinsTableUpdateCompanionBuilder = DailyCheckinsCompanion
    Function({
  Value<int> id,
  Value<String> date,
  Value<int> checkedIn,
  Value<String> createdAt,
});

class $$DailyCheckinsTableFilterComposer
    extends Composer<_$AppDatabase, $DailyCheckinsTable> {
  $$DailyCheckinsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get checkedIn => $composableBuilder(
      column: $table.checkedIn, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$DailyCheckinsTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyCheckinsTable> {
  $$DailyCheckinsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get checkedIn => $composableBuilder(
      column: $table.checkedIn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$DailyCheckinsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyCheckinsTable> {
  $$DailyCheckinsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get checkedIn =>
      $composableBuilder(column: $table.checkedIn, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DailyCheckinsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DailyCheckinsTable,
    DailyCheckin,
    $$DailyCheckinsTableFilterComposer,
    $$DailyCheckinsTableOrderingComposer,
    $$DailyCheckinsTableAnnotationComposer,
    $$DailyCheckinsTableCreateCompanionBuilder,
    $$DailyCheckinsTableUpdateCompanionBuilder,
    (
      DailyCheckin,
      BaseReferences<_$AppDatabase, $DailyCheckinsTable, DailyCheckin>
    ),
    DailyCheckin,
    PrefetchHooks Function()> {
  $$DailyCheckinsTableTableManager(_$AppDatabase db, $DailyCheckinsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyCheckinsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyCheckinsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyCheckinsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> date = const Value.absent(),
            Value<int> checkedIn = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
          }) =>
              DailyCheckinsCompanion(
            id: id,
            date: date,
            checkedIn: checkedIn,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String date,
            Value<int> checkedIn = const Value.absent(),
            required String createdAt,
          }) =>
              DailyCheckinsCompanion.insert(
            id: id,
            date: date,
            checkedIn: checkedIn,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DailyCheckinsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DailyCheckinsTable,
    DailyCheckin,
    $$DailyCheckinsTableFilterComposer,
    $$DailyCheckinsTableOrderingComposer,
    $$DailyCheckinsTableAnnotationComposer,
    $$DailyCheckinsTableCreateCompanionBuilder,
    $$DailyCheckinsTableUpdateCompanionBuilder,
    (
      DailyCheckin,
      BaseReferences<_$AppDatabase, $DailyCheckinsTable, DailyCheckin>
    ),
    DailyCheckin,
    PrefetchHooks Function()>;
typedef $$CustomWordbooksTableCreateCompanionBuilder = CustomWordbooksCompanion
    Function({
  Value<int> id,
  required String name,
  Value<int> wordCount,
  required String createdAt,
});
typedef $$CustomWordbooksTableUpdateCompanionBuilder = CustomWordbooksCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<int> wordCount,
  Value<String> createdAt,
});

class $$CustomWordbooksTableFilterComposer
    extends Composer<_$AppDatabase, $CustomWordbooksTable> {
  $$CustomWordbooksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get wordCount => $composableBuilder(
      column: $table.wordCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$CustomWordbooksTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomWordbooksTable> {
  $$CustomWordbooksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get wordCount => $composableBuilder(
      column: $table.wordCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$CustomWordbooksTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomWordbooksTable> {
  $$CustomWordbooksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get wordCount =>
      $composableBuilder(column: $table.wordCount, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CustomWordbooksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CustomWordbooksTable,
    CustomWordbook,
    $$CustomWordbooksTableFilterComposer,
    $$CustomWordbooksTableOrderingComposer,
    $$CustomWordbooksTableAnnotationComposer,
    $$CustomWordbooksTableCreateCompanionBuilder,
    $$CustomWordbooksTableUpdateCompanionBuilder,
    (
      CustomWordbook,
      BaseReferences<_$AppDatabase, $CustomWordbooksTable, CustomWordbook>
    ),
    CustomWordbook,
    PrefetchHooks Function()> {
  $$CustomWordbooksTableTableManager(
      _$AppDatabase db, $CustomWordbooksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomWordbooksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomWordbooksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomWordbooksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> wordCount = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
          }) =>
              CustomWordbooksCompanion(
            id: id,
            name: name,
            wordCount: wordCount,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<int> wordCount = const Value.absent(),
            required String createdAt,
          }) =>
              CustomWordbooksCompanion.insert(
            id: id,
            name: name,
            wordCount: wordCount,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CustomWordbooksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CustomWordbooksTable,
    CustomWordbook,
    $$CustomWordbooksTableFilterComposer,
    $$CustomWordbooksTableOrderingComposer,
    $$CustomWordbooksTableAnnotationComposer,
    $$CustomWordbooksTableCreateCompanionBuilder,
    $$CustomWordbooksTableUpdateCompanionBuilder,
    (
      CustomWordbook,
      BaseReferences<_$AppDatabase, $CustomWordbooksTable, CustomWordbook>
    ),
    CustomWordbook,
    PrefetchHooks Function()>;
typedef $$VocabularyNotebookTableCreateCompanionBuilder
    = VocabularyNotebookCompanion Function({
  Value<int> id,
  required String word,
  Value<String?> meaning,
  Value<String?> note,
  required String createdAt,
});
typedef $$VocabularyNotebookTableUpdateCompanionBuilder
    = VocabularyNotebookCompanion Function({
  Value<int> id,
  Value<String> word,
  Value<String?> meaning,
  Value<String?> note,
  Value<String> createdAt,
});

class $$VocabularyNotebookTableFilterComposer
    extends Composer<_$AppDatabase, $VocabularyNotebookTable> {
  $$VocabularyNotebookTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get word => $composableBuilder(
      column: $table.word, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get meaning => $composableBuilder(
      column: $table.meaning, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$VocabularyNotebookTableOrderingComposer
    extends Composer<_$AppDatabase, $VocabularyNotebookTable> {
  $$VocabularyNotebookTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get word => $composableBuilder(
      column: $table.word, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get meaning => $composableBuilder(
      column: $table.meaning, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$VocabularyNotebookTableAnnotationComposer
    extends Composer<_$AppDatabase, $VocabularyNotebookTable> {
  $$VocabularyNotebookTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<String> get meaning =>
      $composableBuilder(column: $table.meaning, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$VocabularyNotebookTableTableManager extends RootTableManager<
    _$AppDatabase,
    $VocabularyNotebookTable,
    VocabularyNotebookData,
    $$VocabularyNotebookTableFilterComposer,
    $$VocabularyNotebookTableOrderingComposer,
    $$VocabularyNotebookTableAnnotationComposer,
    $$VocabularyNotebookTableCreateCompanionBuilder,
    $$VocabularyNotebookTableUpdateCompanionBuilder,
    (
      VocabularyNotebookData,
      BaseReferences<_$AppDatabase, $VocabularyNotebookTable,
          VocabularyNotebookData>
    ),
    VocabularyNotebookData,
    PrefetchHooks Function()> {
  $$VocabularyNotebookTableTableManager(
      _$AppDatabase db, $VocabularyNotebookTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VocabularyNotebookTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VocabularyNotebookTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VocabularyNotebookTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> word = const Value.absent(),
            Value<String?> meaning = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
          }) =>
              VocabularyNotebookCompanion(
            id: id,
            word: word,
            meaning: meaning,
            note: note,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String word,
            Value<String?> meaning = const Value.absent(),
            Value<String?> note = const Value.absent(),
            required String createdAt,
          }) =>
              VocabularyNotebookCompanion.insert(
            id: id,
            word: word,
            meaning: meaning,
            note: note,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$VocabularyNotebookTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $VocabularyNotebookTable,
    VocabularyNotebookData,
    $$VocabularyNotebookTableFilterComposer,
    $$VocabularyNotebookTableOrderingComposer,
    $$VocabularyNotebookTableAnnotationComposer,
    $$VocabularyNotebookTableCreateCompanionBuilder,
    $$VocabularyNotebookTableUpdateCompanionBuilder,
    (
      VocabularyNotebookData,
      BaseReferences<_$AppDatabase, $VocabularyNotebookTable,
          VocabularyNotebookData>
    ),
    VocabularyNotebookData,
    PrefetchHooks Function()>;
typedef $$CardStatesTableCreateCompanionBuilder = CardStatesCompanion Function({
  Value<int> id,
  required String wordId,
  Value<double?> stability,
  Value<double?> difficulty,
  required int due,
  Value<int?> lastReview,
  Value<int> state,
  Value<int?> step,
  Value<int> reps,
  Value<int> lapses,
  required int createdAt,
});
typedef $$CardStatesTableUpdateCompanionBuilder = CardStatesCompanion Function({
  Value<int> id,
  Value<String> wordId,
  Value<double?> stability,
  Value<double?> difficulty,
  Value<int> due,
  Value<int?> lastReview,
  Value<int> state,
  Value<int?> step,
  Value<int> reps,
  Value<int> lapses,
  Value<int> createdAt,
});

final class $$CardStatesTableReferences
    extends BaseReferences<_$AppDatabase, $CardStatesTable, CardState> {
  $$CardStatesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ReviewLogsTable, List<ReviewLog>>
      _reviewLogsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.reviewLogs,
              aliasName: $_aliasNameGenerator(
                  db.cardStates.id, db.reviewLogs.cardStateId));

  $$ReviewLogsTableProcessedTableManager get reviewLogsRefs {
    final manager = $$ReviewLogsTableTableManager($_db, $_db.reviewLogs)
        .filter((f) => f.cardStateId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_reviewLogsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CardStatesTableFilterComposer
    extends Composer<_$AppDatabase, $CardStatesTable> {
  $$CardStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get wordId => $composableBuilder(
      column: $table.wordId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get stability => $composableBuilder(
      column: $table.stability, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get due => $composableBuilder(
      column: $table.due, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastReview => $composableBuilder(
      column: $table.lastReview, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get step => $composableBuilder(
      column: $table.step, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reps => $composableBuilder(
      column: $table.reps, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lapses => $composableBuilder(
      column: $table.lapses, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> reviewLogsRefs(
      Expression<bool> Function($$ReviewLogsTableFilterComposer f) f) {
    final $$ReviewLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.reviewLogs,
        getReferencedColumn: (t) => t.cardStateId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReviewLogsTableFilterComposer(
              $db: $db,
              $table: $db.reviewLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CardStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $CardStatesTable> {
  $$CardStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get wordId => $composableBuilder(
      column: $table.wordId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get stability => $composableBuilder(
      column: $table.stability, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get due => $composableBuilder(
      column: $table.due, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastReview => $composableBuilder(
      column: $table.lastReview, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get step => $composableBuilder(
      column: $table.step, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reps => $composableBuilder(
      column: $table.reps, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lapses => $composableBuilder(
      column: $table.lapses, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$CardStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CardStatesTable> {
  $$CardStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get wordId =>
      $composableBuilder(column: $table.wordId, builder: (column) => column);

  GeneratedColumn<double> get stability =>
      $composableBuilder(column: $table.stability, builder: (column) => column);

  GeneratedColumn<double> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => column);

  GeneratedColumn<int> get due =>
      $composableBuilder(column: $table.due, builder: (column) => column);

  GeneratedColumn<int> get lastReview => $composableBuilder(
      column: $table.lastReview, builder: (column) => column);

  GeneratedColumn<int> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get step =>
      $composableBuilder(column: $table.step, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<int> get lapses =>
      $composableBuilder(column: $table.lapses, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> reviewLogsRefs<T extends Object>(
      Expression<T> Function($$ReviewLogsTableAnnotationComposer a) f) {
    final $$ReviewLogsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.reviewLogs,
        getReferencedColumn: (t) => t.cardStateId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReviewLogsTableAnnotationComposer(
              $db: $db,
              $table: $db.reviewLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CardStatesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CardStatesTable,
    CardState,
    $$CardStatesTableFilterComposer,
    $$CardStatesTableOrderingComposer,
    $$CardStatesTableAnnotationComposer,
    $$CardStatesTableCreateCompanionBuilder,
    $$CardStatesTableUpdateCompanionBuilder,
    (CardState, $$CardStatesTableReferences),
    CardState,
    PrefetchHooks Function({bool reviewLogsRefs})> {
  $$CardStatesTableTableManager(_$AppDatabase db, $CardStatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CardStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CardStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CardStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> wordId = const Value.absent(),
            Value<double?> stability = const Value.absent(),
            Value<double?> difficulty = const Value.absent(),
            Value<int> due = const Value.absent(),
            Value<int?> lastReview = const Value.absent(),
            Value<int> state = const Value.absent(),
            Value<int?> step = const Value.absent(),
            Value<int> reps = const Value.absent(),
            Value<int> lapses = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
          }) =>
              CardStatesCompanion(
            id: id,
            wordId: wordId,
            stability: stability,
            difficulty: difficulty,
            due: due,
            lastReview: lastReview,
            state: state,
            step: step,
            reps: reps,
            lapses: lapses,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String wordId,
            Value<double?> stability = const Value.absent(),
            Value<double?> difficulty = const Value.absent(),
            required int due,
            Value<int?> lastReview = const Value.absent(),
            Value<int> state = const Value.absent(),
            Value<int?> step = const Value.absent(),
            Value<int> reps = const Value.absent(),
            Value<int> lapses = const Value.absent(),
            required int createdAt,
          }) =>
              CardStatesCompanion.insert(
            id: id,
            wordId: wordId,
            stability: stability,
            difficulty: difficulty,
            due: due,
            lastReview: lastReview,
            state: state,
            step: step,
            reps: reps,
            lapses: lapses,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CardStatesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({reviewLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (reviewLogsRefs) db.reviewLogs],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (reviewLogsRefs)
                    await $_getPrefetchedData<CardState, $CardStatesTable,
                            ReviewLog>(
                        currentTable: table,
                        referencedTable: $$CardStatesTableReferences
                            ._reviewLogsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CardStatesTableReferences(db, table, p0)
                                .reviewLogsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.cardStateId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$CardStatesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CardStatesTable,
    CardState,
    $$CardStatesTableFilterComposer,
    $$CardStatesTableOrderingComposer,
    $$CardStatesTableAnnotationComposer,
    $$CardStatesTableCreateCompanionBuilder,
    $$CardStatesTableUpdateCompanionBuilder,
    (CardState, $$CardStatesTableReferences),
    CardState,
    PrefetchHooks Function({bool reviewLogsRefs})>;
typedef $$ReviewLogsTableCreateCompanionBuilder = ReviewLogsCompanion Function({
  Value<int> id,
  required int cardStateId,
  required String wordId,
  required int rating,
  required int reviewTimeUtc,
  required double elapsedDays,
  required double scheduledDays,
  required int stateBefore,
  Value<double?> stabilityBefore,
  Value<double?> difficultyBefore,
  Value<String?> clientVersion,
});
typedef $$ReviewLogsTableUpdateCompanionBuilder = ReviewLogsCompanion Function({
  Value<int> id,
  Value<int> cardStateId,
  Value<String> wordId,
  Value<int> rating,
  Value<int> reviewTimeUtc,
  Value<double> elapsedDays,
  Value<double> scheduledDays,
  Value<int> stateBefore,
  Value<double?> stabilityBefore,
  Value<double?> difficultyBefore,
  Value<String?> clientVersion,
});

final class $$ReviewLogsTableReferences
    extends BaseReferences<_$AppDatabase, $ReviewLogsTable, ReviewLog> {
  $$ReviewLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CardStatesTable _cardStateIdTable(_$AppDatabase db) =>
      db.cardStates.createAlias(
          $_aliasNameGenerator(db.reviewLogs.cardStateId, db.cardStates.id));

  $$CardStatesTableProcessedTableManager get cardStateId {
    final $_column = $_itemColumn<int>('card_state_id')!;

    final manager = $$CardStatesTableTableManager($_db, $_db.cardStates)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cardStateIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ReviewLogsTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get wordId => $composableBuilder(
      column: $table.wordId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reviewTimeUtc => $composableBuilder(
      column: $table.reviewTimeUtc, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get elapsedDays => $composableBuilder(
      column: $table.elapsedDays, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get scheduledDays => $composableBuilder(
      column: $table.scheduledDays, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get stateBefore => $composableBuilder(
      column: $table.stateBefore, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get stabilityBefore => $composableBuilder(
      column: $table.stabilityBefore,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get difficultyBefore => $composableBuilder(
      column: $table.difficultyBefore,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clientVersion => $composableBuilder(
      column: $table.clientVersion, builder: (column) => ColumnFilters(column));

  $$CardStatesTableFilterComposer get cardStateId {
    final $$CardStatesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cardStateId,
        referencedTable: $db.cardStates,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CardStatesTableFilterComposer(
              $db: $db,
              $table: $db.cardStates,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReviewLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get wordId => $composableBuilder(
      column: $table.wordId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reviewTimeUtc => $composableBuilder(
      column: $table.reviewTimeUtc,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get elapsedDays => $composableBuilder(
      column: $table.elapsedDays, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get scheduledDays => $composableBuilder(
      column: $table.scheduledDays,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get stateBefore => $composableBuilder(
      column: $table.stateBefore, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get stabilityBefore => $composableBuilder(
      column: $table.stabilityBefore,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get difficultyBefore => $composableBuilder(
      column: $table.difficultyBefore,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clientVersion => $composableBuilder(
      column: $table.clientVersion,
      builder: (column) => ColumnOrderings(column));

  $$CardStatesTableOrderingComposer get cardStateId {
    final $$CardStatesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cardStateId,
        referencedTable: $db.cardStates,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CardStatesTableOrderingComposer(
              $db: $db,
              $table: $db.cardStates,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReviewLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get wordId =>
      $composableBuilder(column: $table.wordId, builder: (column) => column);

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<int> get reviewTimeUtc => $composableBuilder(
      column: $table.reviewTimeUtc, builder: (column) => column);

  GeneratedColumn<double> get elapsedDays => $composableBuilder(
      column: $table.elapsedDays, builder: (column) => column);

  GeneratedColumn<double> get scheduledDays => $composableBuilder(
      column: $table.scheduledDays, builder: (column) => column);

  GeneratedColumn<int> get stateBefore => $composableBuilder(
      column: $table.stateBefore, builder: (column) => column);

  GeneratedColumn<double> get stabilityBefore => $composableBuilder(
      column: $table.stabilityBefore, builder: (column) => column);

  GeneratedColumn<double> get difficultyBefore => $composableBuilder(
      column: $table.difficultyBefore, builder: (column) => column);

  GeneratedColumn<String> get clientVersion => $composableBuilder(
      column: $table.clientVersion, builder: (column) => column);

  $$CardStatesTableAnnotationComposer get cardStateId {
    final $$CardStatesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cardStateId,
        referencedTable: $db.cardStates,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CardStatesTableAnnotationComposer(
              $db: $db,
              $table: $db.cardStates,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReviewLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ReviewLogsTable,
    ReviewLog,
    $$ReviewLogsTableFilterComposer,
    $$ReviewLogsTableOrderingComposer,
    $$ReviewLogsTableAnnotationComposer,
    $$ReviewLogsTableCreateCompanionBuilder,
    $$ReviewLogsTableUpdateCompanionBuilder,
    (ReviewLog, $$ReviewLogsTableReferences),
    ReviewLog,
    PrefetchHooks Function({bool cardStateId})> {
  $$ReviewLogsTableTableManager(_$AppDatabase db, $ReviewLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> cardStateId = const Value.absent(),
            Value<String> wordId = const Value.absent(),
            Value<int> rating = const Value.absent(),
            Value<int> reviewTimeUtc = const Value.absent(),
            Value<double> elapsedDays = const Value.absent(),
            Value<double> scheduledDays = const Value.absent(),
            Value<int> stateBefore = const Value.absent(),
            Value<double?> stabilityBefore = const Value.absent(),
            Value<double?> difficultyBefore = const Value.absent(),
            Value<String?> clientVersion = const Value.absent(),
          }) =>
              ReviewLogsCompanion(
            id: id,
            cardStateId: cardStateId,
            wordId: wordId,
            rating: rating,
            reviewTimeUtc: reviewTimeUtc,
            elapsedDays: elapsedDays,
            scheduledDays: scheduledDays,
            stateBefore: stateBefore,
            stabilityBefore: stabilityBefore,
            difficultyBefore: difficultyBefore,
            clientVersion: clientVersion,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int cardStateId,
            required String wordId,
            required int rating,
            required int reviewTimeUtc,
            required double elapsedDays,
            required double scheduledDays,
            required int stateBefore,
            Value<double?> stabilityBefore = const Value.absent(),
            Value<double?> difficultyBefore = const Value.absent(),
            Value<String?> clientVersion = const Value.absent(),
          }) =>
              ReviewLogsCompanion.insert(
            id: id,
            cardStateId: cardStateId,
            wordId: wordId,
            rating: rating,
            reviewTimeUtc: reviewTimeUtc,
            elapsedDays: elapsedDays,
            scheduledDays: scheduledDays,
            stateBefore: stateBefore,
            stabilityBefore: stabilityBefore,
            difficultyBefore: difficultyBefore,
            clientVersion: clientVersion,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ReviewLogsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({cardStateId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (cardStateId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.cardStateId,
                    referencedTable:
                        $$ReviewLogsTableReferences._cardStateIdTable(db),
                    referencedColumn:
                        $$ReviewLogsTableReferences._cardStateIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ReviewLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ReviewLogsTable,
    ReviewLog,
    $$ReviewLogsTableFilterComposer,
    $$ReviewLogsTableOrderingComposer,
    $$ReviewLogsTableAnnotationComposer,
    $$ReviewLogsTableCreateCompanionBuilder,
    $$ReviewLogsTableUpdateCompanionBuilder,
    (ReviewLog, $$ReviewLogsTableReferences),
    ReviewLog,
    PrefetchHooks Function({bool cardStateId})>;
typedef $$CachedWordsTableCreateCompanionBuilder = CachedWordsCompanion
    Function({
  required String wordId,
  required String bookId,
  required String wordText,
  required String meaning,
  Value<String?> phonetic,
  Value<String?> translation,
  Value<int> frequencyRank,
  Value<int> sortOrder,
  required int cachedAt,
  Value<int> rowid,
});
typedef $$CachedWordsTableUpdateCompanionBuilder = CachedWordsCompanion
    Function({
  Value<String> wordId,
  Value<String> bookId,
  Value<String> wordText,
  Value<String> meaning,
  Value<String?> phonetic,
  Value<String?> translation,
  Value<int> frequencyRank,
  Value<int> sortOrder,
  Value<int> cachedAt,
  Value<int> rowid,
});

class $$CachedWordsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedWordsTable> {
  $$CachedWordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get wordId => $composableBuilder(
      column: $table.wordId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bookId => $composableBuilder(
      column: $table.bookId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get wordText => $composableBuilder(
      column: $table.wordText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get meaning => $composableBuilder(
      column: $table.meaning, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phonetic => $composableBuilder(
      column: $table.phonetic, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get translation => $composableBuilder(
      column: $table.translation, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get frequencyRank => $composableBuilder(
      column: $table.frequencyRank, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));
}

class $$CachedWordsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedWordsTable> {
  $$CachedWordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get wordId => $composableBuilder(
      column: $table.wordId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bookId => $composableBuilder(
      column: $table.bookId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get wordText => $composableBuilder(
      column: $table.wordText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get meaning => $composableBuilder(
      column: $table.meaning, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phonetic => $composableBuilder(
      column: $table.phonetic, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get translation => $composableBuilder(
      column: $table.translation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get frequencyRank => $composableBuilder(
      column: $table.frequencyRank,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));
}

class $$CachedWordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedWordsTable> {
  $$CachedWordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get wordId =>
      $composableBuilder(column: $table.wordId, builder: (column) => column);

  GeneratedColumn<String> get bookId =>
      $composableBuilder(column: $table.bookId, builder: (column) => column);

  GeneratedColumn<String> get wordText =>
      $composableBuilder(column: $table.wordText, builder: (column) => column);

  GeneratedColumn<String> get meaning =>
      $composableBuilder(column: $table.meaning, builder: (column) => column);

  GeneratedColumn<String> get phonetic =>
      $composableBuilder(column: $table.phonetic, builder: (column) => column);

  GeneratedColumn<String> get translation => $composableBuilder(
      column: $table.translation, builder: (column) => column);

  GeneratedColumn<int> get frequencyRank => $composableBuilder(
      column: $table.frequencyRank, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedWordsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedWordsTable,
    CachedWord,
    $$CachedWordsTableFilterComposer,
    $$CachedWordsTableOrderingComposer,
    $$CachedWordsTableAnnotationComposer,
    $$CachedWordsTableCreateCompanionBuilder,
    $$CachedWordsTableUpdateCompanionBuilder,
    (CachedWord, BaseReferences<_$AppDatabase, $CachedWordsTable, CachedWord>),
    CachedWord,
    PrefetchHooks Function()> {
  $$CachedWordsTableTableManager(_$AppDatabase db, $CachedWordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedWordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedWordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedWordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> wordId = const Value.absent(),
            Value<String> bookId = const Value.absent(),
            Value<String> wordText = const Value.absent(),
            Value<String> meaning = const Value.absent(),
            Value<String?> phonetic = const Value.absent(),
            Value<String?> translation = const Value.absent(),
            Value<int> frequencyRank = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> cachedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedWordsCompanion(
            wordId: wordId,
            bookId: bookId,
            wordText: wordText,
            meaning: meaning,
            phonetic: phonetic,
            translation: translation,
            frequencyRank: frequencyRank,
            sortOrder: sortOrder,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String wordId,
            required String bookId,
            required String wordText,
            required String meaning,
            Value<String?> phonetic = const Value.absent(),
            Value<String?> translation = const Value.absent(),
            Value<int> frequencyRank = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            required int cachedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedWordsCompanion.insert(
            wordId: wordId,
            bookId: bookId,
            wordText: wordText,
            meaning: meaning,
            phonetic: phonetic,
            translation: translation,
            frequencyRank: frequencyRank,
            sortOrder: sortOrder,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedWordsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CachedWordsTable,
    CachedWord,
    $$CachedWordsTableFilterComposer,
    $$CachedWordsTableOrderingComposer,
    $$CachedWordsTableAnnotationComposer,
    $$CachedWordsTableCreateCompanionBuilder,
    $$CachedWordsTableUpdateCompanionBuilder,
    (CachedWord, BaseReferences<_$AppDatabase, $CachedWordsTable, CachedWord>),
    CachedWord,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WordRecordsTableTableManager get wordRecords =>
      $$WordRecordsTableTableManager(_db, _db.wordRecords);
  $$WordbookProgressTableTableManager get wordbookProgress =>
      $$WordbookProgressTableTableManager(_db, _db.wordbookProgress);
  $$DailyCheckinsTableTableManager get dailyCheckins =>
      $$DailyCheckinsTableTableManager(_db, _db.dailyCheckins);
  $$CustomWordbooksTableTableManager get customWordbooks =>
      $$CustomWordbooksTableTableManager(_db, _db.customWordbooks);
  $$VocabularyNotebookTableTableManager get vocabularyNotebook =>
      $$VocabularyNotebookTableTableManager(_db, _db.vocabularyNotebook);
  $$CardStatesTableTableManager get cardStates =>
      $$CardStatesTableTableManager(_db, _db.cardStates);
  $$ReviewLogsTableTableManager get reviewLogs =>
      $$ReviewLogsTableTableManager(_db, _db.reviewLogs);
  $$CachedWordsTableTableManager get cachedWords =>
      $$CachedWordsTableTableManager(_db, _db.cachedWords);
}
