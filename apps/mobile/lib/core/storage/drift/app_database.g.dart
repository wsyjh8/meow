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
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        wordId,
        bookId,
        studyType,
        actionResult,
        createdAt,
        synced,
        sessionId
      ];
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
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
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
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id']),
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
  final String? sessionId;
  const WordRecord(
      {required this.id,
      required this.wordId,
      required this.bookId,
      required this.studyType,
      required this.actionResult,
      required this.createdAt,
      required this.synced,
      this.sessionId});
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
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<String>(sessionId);
    }
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
      sessionId: sessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionId),
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
      sessionId: serializer.fromJson<String?>(json['sessionId']),
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
      'sessionId': serializer.toJson<String?>(sessionId),
    };
  }

  WordRecord copyWith(
          {int? id,
          String? wordId,
          String? bookId,
          String? studyType,
          String? actionResult,
          String? createdAt,
          int? synced,
          Value<String?> sessionId = const Value.absent()}) =>
      WordRecord(
        id: id ?? this.id,
        wordId: wordId ?? this.wordId,
        bookId: bookId ?? this.bookId,
        studyType: studyType ?? this.studyType,
        actionResult: actionResult ?? this.actionResult,
        createdAt: createdAt ?? this.createdAt,
        synced: synced ?? this.synced,
        sessionId: sessionId.present ? sessionId.value : this.sessionId,
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
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
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
          ..write('synced: $synced, ')
          ..write('sessionId: $sessionId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, wordId, bookId, studyType, actionResult,
      createdAt, synced, sessionId);
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
          other.synced == this.synced &&
          other.sessionId == this.sessionId);
}

class WordRecordsCompanion extends UpdateCompanion<WordRecord> {
  final Value<int> id;
  final Value<String> wordId;
  final Value<String> bookId;
  final Value<String> studyType;
  final Value<String> actionResult;
  final Value<String> createdAt;
  final Value<int> synced;
  final Value<String?> sessionId;
  const WordRecordsCompanion({
    this.id = const Value.absent(),
    this.wordId = const Value.absent(),
    this.bookId = const Value.absent(),
    this.studyType = const Value.absent(),
    this.actionResult = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.sessionId = const Value.absent(),
  });
  WordRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String wordId,
    required String bookId,
    this.studyType = const Value.absent(),
    required String actionResult,
    required String createdAt,
    this.synced = const Value.absent(),
    this.sessionId = const Value.absent(),
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
    Expression<String>? sessionId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (wordId != null) 'word_id': wordId,
      if (bookId != null) 'book_id': bookId,
      if (studyType != null) 'study_type': studyType,
      if (actionResult != null) 'action_result': actionResult,
      if (createdAt != null) 'created_at': createdAt,
      if (synced != null) 'synced': synced,
      if (sessionId != null) 'session_id': sessionId,
    });
  }

  WordRecordsCompanion copyWith(
      {Value<int>? id,
      Value<String>? wordId,
      Value<String>? bookId,
      Value<String>? studyType,
      Value<String>? actionResult,
      Value<String>? createdAt,
      Value<int>? synced,
      Value<String?>? sessionId}) {
    return WordRecordsCompanion(
      id: id ?? this.id,
      wordId: wordId ?? this.wordId,
      bookId: bookId ?? this.bookId,
      studyType: studyType ?? this.studyType,
      actionResult: actionResult ?? this.actionResult,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
      sessionId: sessionId ?? this.sessionId,
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
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
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
          ..write('synced: $synced, ')
          ..write('sessionId: $sessionId')
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

class $PresetWordbooksTable extends PresetWordbooks
    with TableInfo<$PresetWordbooksTable, PresetWordbook> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PresetWordbooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
      'slug', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _totalWordsMeta =
      const VerificationMeta('totalWords');
  @override
  late final GeneratedColumn<int> totalWords = GeneratedColumn<int>(
      'total_words', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _contentVersionMeta =
      const VerificationMeta('contentVersion');
  @override
  late final GeneratedColumn<String> contentVersion = GeneratedColumn<String>(
      'content_version', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [slug, displayName, totalWords, description, sortOrder, contentVersion];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'preset_wordbooks';
  @override
  VerificationContext validateIntegrity(Insertable<PresetWordbook> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('slug')) {
      context.handle(
          _slugMeta, slug.isAcceptableOrUnknown(data['slug']!, _slugMeta));
    } else if (isInserting) {
      context.missing(_slugMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('total_words')) {
      context.handle(
          _totalWordsMeta,
          totalWords.isAcceptableOrUnknown(
              data['total_words']!, _totalWordsMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('content_version')) {
      context.handle(
          _contentVersionMeta,
          contentVersion.isAcceptableOrUnknown(
              data['content_version']!, _contentVersionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {slug};
  @override
  PresetWordbook map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PresetWordbook(
      slug: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}slug'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      totalWords: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_words'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      contentVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_version']),
    );
  }

  @override
  $PresetWordbooksTable createAlias(String alias) {
    return $PresetWordbooksTable(attachedDatabase, alias);
  }
}

class PresetWordbook extends DataClass implements Insertable<PresetWordbook> {
  /// Stable identifier, e.g. 'zk', 'gk'.
  final String slug;

  /// Human-readable name, e.g. '中考', '高考'.
  final String displayName;

  /// Total number of words in this book.
  final int totalWords;

  /// Optional description of the book.
  final String? description;

  /// Display ordering (smaller = shown first).
  final int sortOrder;

  /// Content version from the bundled asset JSON (e.g. '2').
  /// WordbookLoader re-imports when this differs from the JSON's contentVersion.
  final String? contentVersion;
  const PresetWordbook(
      {required this.slug,
      required this.displayName,
      required this.totalWords,
      this.description,
      required this.sortOrder,
      this.contentVersion});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['slug'] = Variable<String>(slug);
    map['display_name'] = Variable<String>(displayName);
    map['total_words'] = Variable<int>(totalWords);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || contentVersion != null) {
      map['content_version'] = Variable<String>(contentVersion);
    }
    return map;
  }

  PresetWordbooksCompanion toCompanion(bool nullToAbsent) {
    return PresetWordbooksCompanion(
      slug: Value(slug),
      displayName: Value(displayName),
      totalWords: Value(totalWords),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      sortOrder: Value(sortOrder),
      contentVersion: contentVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(contentVersion),
    );
  }

  factory PresetWordbook.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PresetWordbook(
      slug: serializer.fromJson<String>(json['slug']),
      displayName: serializer.fromJson<String>(json['displayName']),
      totalWords: serializer.fromJson<int>(json['totalWords']),
      description: serializer.fromJson<String?>(json['description']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      contentVersion: serializer.fromJson<String?>(json['contentVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'slug': serializer.toJson<String>(slug),
      'displayName': serializer.toJson<String>(displayName),
      'totalWords': serializer.toJson<int>(totalWords),
      'description': serializer.toJson<String?>(description),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'contentVersion': serializer.toJson<String?>(contentVersion),
    };
  }

  PresetWordbook copyWith(
          {String? slug,
          String? displayName,
          int? totalWords,
          Value<String?> description = const Value.absent(),
          int? sortOrder,
          Value<String?> contentVersion = const Value.absent()}) =>
      PresetWordbook(
        slug: slug ?? this.slug,
        displayName: displayName ?? this.displayName,
        totalWords: totalWords ?? this.totalWords,
        description: description.present ? description.value : this.description,
        sortOrder: sortOrder ?? this.sortOrder,
        contentVersion:
            contentVersion.present ? contentVersion.value : this.contentVersion,
      );
  PresetWordbook copyWithCompanion(PresetWordbooksCompanion data) {
    return PresetWordbook(
      slug: data.slug.present ? data.slug.value : this.slug,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      totalWords:
          data.totalWords.present ? data.totalWords.value : this.totalWords,
      description:
          data.description.present ? data.description.value : this.description,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      contentVersion: data.contentVersion.present
          ? data.contentVersion.value
          : this.contentVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PresetWordbook(')
          ..write('slug: $slug, ')
          ..write('displayName: $displayName, ')
          ..write('totalWords: $totalWords, ')
          ..write('description: $description, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('contentVersion: $contentVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      slug, displayName, totalWords, description, sortOrder, contentVersion);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PresetWordbook &&
          other.slug == this.slug &&
          other.displayName == this.displayName &&
          other.totalWords == this.totalWords &&
          other.description == this.description &&
          other.sortOrder == this.sortOrder &&
          other.contentVersion == this.contentVersion);
}

class PresetWordbooksCompanion extends UpdateCompanion<PresetWordbook> {
  final Value<String> slug;
  final Value<String> displayName;
  final Value<int> totalWords;
  final Value<String?> description;
  final Value<int> sortOrder;
  final Value<String?> contentVersion;
  final Value<int> rowid;
  const PresetWordbooksCompanion({
    this.slug = const Value.absent(),
    this.displayName = const Value.absent(),
    this.totalWords = const Value.absent(),
    this.description = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.contentVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PresetWordbooksCompanion.insert({
    required String slug,
    required String displayName,
    this.totalWords = const Value.absent(),
    this.description = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.contentVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : slug = Value(slug),
        displayName = Value(displayName);
  static Insertable<PresetWordbook> custom({
    Expression<String>? slug,
    Expression<String>? displayName,
    Expression<int>? totalWords,
    Expression<String>? description,
    Expression<int>? sortOrder,
    Expression<String>? contentVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (slug != null) 'slug': slug,
      if (displayName != null) 'display_name': displayName,
      if (totalWords != null) 'total_words': totalWords,
      if (description != null) 'description': description,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (contentVersion != null) 'content_version': contentVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PresetWordbooksCompanion copyWith(
      {Value<String>? slug,
      Value<String>? displayName,
      Value<int>? totalWords,
      Value<String?>? description,
      Value<int>? sortOrder,
      Value<String?>? contentVersion,
      Value<int>? rowid}) {
    return PresetWordbooksCompanion(
      slug: slug ?? this.slug,
      displayName: displayName ?? this.displayName,
      totalWords: totalWords ?? this.totalWords,
      description: description ?? this.description,
      sortOrder: sortOrder ?? this.sortOrder,
      contentVersion: contentVersion ?? this.contentVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (totalWords.present) {
      map['total_words'] = Variable<int>(totalWords.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (contentVersion.present) {
      map['content_version'] = Variable<String>(contentVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PresetWordbooksCompanion(')
          ..write('slug: $slug, ')
          ..write('displayName: $displayName, ')
          ..write('totalWords: $totalWords, ')
          ..write('description: $description, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('contentVersion: $contentVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WordEntriesTable extends WordEntries
    with TableInfo<$WordEntriesTable, WordEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<String> wordId = GeneratedColumn<String>(
      'word_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _wordTextMeta =
      const VerificationMeta('wordText');
  @override
  late final GeneratedColumn<String> wordText = GeneratedColumn<String>(
      'word_text', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _phoneticMeta =
      const VerificationMeta('phonetic');
  @override
  late final GeneratedColumn<String> phonetic = GeneratedColumn<String>(
      'phonetic', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _meaningMeta =
      const VerificationMeta('meaning');
  @override
  late final GeneratedColumn<String> meaning = GeneratedColumn<String>(
      'meaning', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _translationMeta =
      const VerificationMeta('translation');
  @override
  late final GeneratedColumn<String> translation = GeneratedColumn<String>(
      'translation', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _definitionMeta =
      const VerificationMeta('definition');
  @override
  late final GeneratedColumn<String> definition = GeneratedColumn<String>(
      'definition', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _frequencyRankMeta =
      const VerificationMeta('frequencyRank');
  @override
  late final GeneratedColumn<int> frequencyRank = GeneratedColumn<int>(
      'frequency_rank', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _wordFormsMeta =
      const VerificationMeta('wordForms');
  @override
  late final GeneratedColumn<String> wordForms = GeneratedColumn<String>(
      'word_forms', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _importedAtMeta =
      const VerificationMeta('importedAt');
  @override
  late final GeneratedColumn<int> importedAt = GeneratedColumn<int>(
      'imported_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        wordId,
        wordText,
        phonetic,
        meaning,
        translation,
        definition,
        frequencyRank,
        wordForms,
        importedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word_entries';
  @override
  VerificationContext validateIntegrity(Insertable<WordEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('word_id')) {
      context.handle(_wordIdMeta,
          wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta));
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('word_text')) {
      context.handle(_wordTextMeta,
          wordText.isAcceptableOrUnknown(data['word_text']!, _wordTextMeta));
    } else if (isInserting) {
      context.missing(_wordTextMeta);
    }
    if (data.containsKey('phonetic')) {
      context.handle(_phoneticMeta,
          phonetic.isAcceptableOrUnknown(data['phonetic']!, _phoneticMeta));
    }
    if (data.containsKey('meaning')) {
      context.handle(_meaningMeta,
          meaning.isAcceptableOrUnknown(data['meaning']!, _meaningMeta));
    } else if (isInserting) {
      context.missing(_meaningMeta);
    }
    if (data.containsKey('translation')) {
      context.handle(
          _translationMeta,
          translation.isAcceptableOrUnknown(
              data['translation']!, _translationMeta));
    }
    if (data.containsKey('definition')) {
      context.handle(
          _definitionMeta,
          definition.isAcceptableOrUnknown(
              data['definition']!, _definitionMeta));
    }
    if (data.containsKey('frequency_rank')) {
      context.handle(
          _frequencyRankMeta,
          frequencyRank.isAcceptableOrUnknown(
              data['frequency_rank']!, _frequencyRankMeta));
    }
    if (data.containsKey('word_forms')) {
      context.handle(_wordFormsMeta,
          wordForms.isAcceptableOrUnknown(data['word_forms']!, _wordFormsMeta));
    }
    if (data.containsKey('imported_at')) {
      context.handle(
          _importedAtMeta,
          importedAt.isAcceptableOrUnknown(
              data['imported_at']!, _importedAtMeta));
    } else if (isInserting) {
      context.missing(_importedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {wordId};
  @override
  WordEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordEntry(
      wordId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}word_id'])!,
      wordText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}word_text'])!,
      phonetic: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phonetic']),
      meaning: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meaning'])!,
      translation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}translation']),
      definition: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}definition']),
      frequencyRank: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}frequency_rank'])!,
      wordForms: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}word_forms']),
      importedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}imported_at'])!,
    );
  }

  @override
  $WordEntriesTable createAlias(String alias) {
    return $WordEntriesTable(attachedDatabase, alias);
  }
}

class WordEntry extends DataClass implements Insertable<WordEntry> {
  /// Canonical word identifier: lowercase word text, e.g. 'ability'.
  final String wordId;

  /// Display form of the word, e.g. 'ability'.
  final String wordText;

  /// IPA or simplified phonetic notation. Nullable.
  final String? phonetic;

  /// Short Chinese meaning (one phrase), e.g. '能力'.
  final String meaning;

  /// Full multi-POS Chinese translation (newline-separated). Nullable.
  final String? translation;

  /// English definition from CSV. Nullable.
  final String? definition;

  /// BNC frequency rank (lower = more common). Default 0 = unknown.
  final int frequencyRank;

  /// Exchange / word-forms field from CSV (e.g. 's:abilities'). Nullable.
  final String? wordForms;

  /// When this word was imported from the bundled asset. UTC epoch ms.
  /// Named imported_at (not cached_at) to distinguish from cloud-cache semantics.
  final int importedAt;
  const WordEntry(
      {required this.wordId,
      required this.wordText,
      this.phonetic,
      required this.meaning,
      this.translation,
      this.definition,
      required this.frequencyRank,
      this.wordForms,
      required this.importedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['word_id'] = Variable<String>(wordId);
    map['word_text'] = Variable<String>(wordText);
    if (!nullToAbsent || phonetic != null) {
      map['phonetic'] = Variable<String>(phonetic);
    }
    map['meaning'] = Variable<String>(meaning);
    if (!nullToAbsent || translation != null) {
      map['translation'] = Variable<String>(translation);
    }
    if (!nullToAbsent || definition != null) {
      map['definition'] = Variable<String>(definition);
    }
    map['frequency_rank'] = Variable<int>(frequencyRank);
    if (!nullToAbsent || wordForms != null) {
      map['word_forms'] = Variable<String>(wordForms);
    }
    map['imported_at'] = Variable<int>(importedAt);
    return map;
  }

  WordEntriesCompanion toCompanion(bool nullToAbsent) {
    return WordEntriesCompanion(
      wordId: Value(wordId),
      wordText: Value(wordText),
      phonetic: phonetic == null && nullToAbsent
          ? const Value.absent()
          : Value(phonetic),
      meaning: Value(meaning),
      translation: translation == null && nullToAbsent
          ? const Value.absent()
          : Value(translation),
      definition: definition == null && nullToAbsent
          ? const Value.absent()
          : Value(definition),
      frequencyRank: Value(frequencyRank),
      wordForms: wordForms == null && nullToAbsent
          ? const Value.absent()
          : Value(wordForms),
      importedAt: Value(importedAt),
    );
  }

  factory WordEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordEntry(
      wordId: serializer.fromJson<String>(json['wordId']),
      wordText: serializer.fromJson<String>(json['wordText']),
      phonetic: serializer.fromJson<String?>(json['phonetic']),
      meaning: serializer.fromJson<String>(json['meaning']),
      translation: serializer.fromJson<String?>(json['translation']),
      definition: serializer.fromJson<String?>(json['definition']),
      frequencyRank: serializer.fromJson<int>(json['frequencyRank']),
      wordForms: serializer.fromJson<String?>(json['wordForms']),
      importedAt: serializer.fromJson<int>(json['importedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'wordId': serializer.toJson<String>(wordId),
      'wordText': serializer.toJson<String>(wordText),
      'phonetic': serializer.toJson<String?>(phonetic),
      'meaning': serializer.toJson<String>(meaning),
      'translation': serializer.toJson<String?>(translation),
      'definition': serializer.toJson<String?>(definition),
      'frequencyRank': serializer.toJson<int>(frequencyRank),
      'wordForms': serializer.toJson<String?>(wordForms),
      'importedAt': serializer.toJson<int>(importedAt),
    };
  }

  WordEntry copyWith(
          {String? wordId,
          String? wordText,
          Value<String?> phonetic = const Value.absent(),
          String? meaning,
          Value<String?> translation = const Value.absent(),
          Value<String?> definition = const Value.absent(),
          int? frequencyRank,
          Value<String?> wordForms = const Value.absent(),
          int? importedAt}) =>
      WordEntry(
        wordId: wordId ?? this.wordId,
        wordText: wordText ?? this.wordText,
        phonetic: phonetic.present ? phonetic.value : this.phonetic,
        meaning: meaning ?? this.meaning,
        translation: translation.present ? translation.value : this.translation,
        definition: definition.present ? definition.value : this.definition,
        frequencyRank: frequencyRank ?? this.frequencyRank,
        wordForms: wordForms.present ? wordForms.value : this.wordForms,
        importedAt: importedAt ?? this.importedAt,
      );
  WordEntry copyWithCompanion(WordEntriesCompanion data) {
    return WordEntry(
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      wordText: data.wordText.present ? data.wordText.value : this.wordText,
      phonetic: data.phonetic.present ? data.phonetic.value : this.phonetic,
      meaning: data.meaning.present ? data.meaning.value : this.meaning,
      translation:
          data.translation.present ? data.translation.value : this.translation,
      definition:
          data.definition.present ? data.definition.value : this.definition,
      frequencyRank: data.frequencyRank.present
          ? data.frequencyRank.value
          : this.frequencyRank,
      wordForms: data.wordForms.present ? data.wordForms.value : this.wordForms,
      importedAt:
          data.importedAt.present ? data.importedAt.value : this.importedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordEntry(')
          ..write('wordId: $wordId, ')
          ..write('wordText: $wordText, ')
          ..write('phonetic: $phonetic, ')
          ..write('meaning: $meaning, ')
          ..write('translation: $translation, ')
          ..write('definition: $definition, ')
          ..write('frequencyRank: $frequencyRank, ')
          ..write('wordForms: $wordForms, ')
          ..write('importedAt: $importedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(wordId, wordText, phonetic, meaning,
      translation, definition, frequencyRank, wordForms, importedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordEntry &&
          other.wordId == this.wordId &&
          other.wordText == this.wordText &&
          other.phonetic == this.phonetic &&
          other.meaning == this.meaning &&
          other.translation == this.translation &&
          other.definition == this.definition &&
          other.frequencyRank == this.frequencyRank &&
          other.wordForms == this.wordForms &&
          other.importedAt == this.importedAt);
}

class WordEntriesCompanion extends UpdateCompanion<WordEntry> {
  final Value<String> wordId;
  final Value<String> wordText;
  final Value<String?> phonetic;
  final Value<String> meaning;
  final Value<String?> translation;
  final Value<String?> definition;
  final Value<int> frequencyRank;
  final Value<String?> wordForms;
  final Value<int> importedAt;
  final Value<int> rowid;
  const WordEntriesCompanion({
    this.wordId = const Value.absent(),
    this.wordText = const Value.absent(),
    this.phonetic = const Value.absent(),
    this.meaning = const Value.absent(),
    this.translation = const Value.absent(),
    this.definition = const Value.absent(),
    this.frequencyRank = const Value.absent(),
    this.wordForms = const Value.absent(),
    this.importedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WordEntriesCompanion.insert({
    required String wordId,
    required String wordText,
    this.phonetic = const Value.absent(),
    required String meaning,
    this.translation = const Value.absent(),
    this.definition = const Value.absent(),
    this.frequencyRank = const Value.absent(),
    this.wordForms = const Value.absent(),
    required int importedAt,
    this.rowid = const Value.absent(),
  })  : wordId = Value(wordId),
        wordText = Value(wordText),
        meaning = Value(meaning),
        importedAt = Value(importedAt);
  static Insertable<WordEntry> custom({
    Expression<String>? wordId,
    Expression<String>? wordText,
    Expression<String>? phonetic,
    Expression<String>? meaning,
    Expression<String>? translation,
    Expression<String>? definition,
    Expression<int>? frequencyRank,
    Expression<String>? wordForms,
    Expression<int>? importedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (wordId != null) 'word_id': wordId,
      if (wordText != null) 'word_text': wordText,
      if (phonetic != null) 'phonetic': phonetic,
      if (meaning != null) 'meaning': meaning,
      if (translation != null) 'translation': translation,
      if (definition != null) 'definition': definition,
      if (frequencyRank != null) 'frequency_rank': frequencyRank,
      if (wordForms != null) 'word_forms': wordForms,
      if (importedAt != null) 'imported_at': importedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WordEntriesCompanion copyWith(
      {Value<String>? wordId,
      Value<String>? wordText,
      Value<String?>? phonetic,
      Value<String>? meaning,
      Value<String?>? translation,
      Value<String?>? definition,
      Value<int>? frequencyRank,
      Value<String?>? wordForms,
      Value<int>? importedAt,
      Value<int>? rowid}) {
    return WordEntriesCompanion(
      wordId: wordId ?? this.wordId,
      wordText: wordText ?? this.wordText,
      phonetic: phonetic ?? this.phonetic,
      meaning: meaning ?? this.meaning,
      translation: translation ?? this.translation,
      definition: definition ?? this.definition,
      frequencyRank: frequencyRank ?? this.frequencyRank,
      wordForms: wordForms ?? this.wordForms,
      importedAt: importedAt ?? this.importedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (wordId.present) {
      map['word_id'] = Variable<String>(wordId.value);
    }
    if (wordText.present) {
      map['word_text'] = Variable<String>(wordText.value);
    }
    if (phonetic.present) {
      map['phonetic'] = Variable<String>(phonetic.value);
    }
    if (meaning.present) {
      map['meaning'] = Variable<String>(meaning.value);
    }
    if (translation.present) {
      map['translation'] = Variable<String>(translation.value);
    }
    if (definition.present) {
      map['definition'] = Variable<String>(definition.value);
    }
    if (frequencyRank.present) {
      map['frequency_rank'] = Variable<int>(frequencyRank.value);
    }
    if (wordForms.present) {
      map['word_forms'] = Variable<String>(wordForms.value);
    }
    if (importedAt.present) {
      map['imported_at'] = Variable<int>(importedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordEntriesCompanion(')
          ..write('wordId: $wordId, ')
          ..write('wordText: $wordText, ')
          ..write('phonetic: $phonetic, ')
          ..write('meaning: $meaning, ')
          ..write('translation: $translation, ')
          ..write('definition: $definition, ')
          ..write('frequencyRank: $frequencyRank, ')
          ..write('wordForms: $wordForms, ')
          ..write('importedAt: $importedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WordBookAssignmentsTable extends WordBookAssignments
    with TableInfo<$WordBookAssignmentsTable, WordBookAssignment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordBookAssignmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<String> wordId = GeneratedColumn<String>(
      'word_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bookSlugMeta =
      const VerificationMeta('bookSlug');
  @override
  late final GeneratedColumn<String> bookSlug = GeneratedColumn<String>(
      'book_slug', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _sourceKeyMeta =
      const VerificationMeta('sourceKey');
  @override
  late final GeneratedColumn<String> sourceKey = GeneratedColumn<String>(
      'source_key', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [wordId, bookSlug, sortOrder, sourceKey];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word_book_assignments';
  @override
  VerificationContext validateIntegrity(Insertable<WordBookAssignment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('word_id')) {
      context.handle(_wordIdMeta,
          wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta));
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('book_slug')) {
      context.handle(_bookSlugMeta,
          bookSlug.isAcceptableOrUnknown(data['book_slug']!, _bookSlugMeta));
    } else if (isInserting) {
      context.missing(_bookSlugMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('source_key')) {
      context.handle(_sourceKeyMeta,
          sourceKey.isAcceptableOrUnknown(data['source_key']!, _sourceKeyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {wordId, bookSlug};
  @override
  WordBookAssignment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordBookAssignment(
      wordId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}word_id'])!,
      bookSlug: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}book_slug'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      sourceKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_key']),
    );
  }

  @override
  $WordBookAssignmentsTable createAlias(String alias) {
    return $WordBookAssignmentsTable(attachedDatabase, alias);
  }
}

class WordBookAssignment extends DataClass
    implements Insertable<WordBookAssignment> {
  /// FK → word_entries.word_id (canonical, book-insensitive).
  final String wordId;

  /// FK → preset_wordbooks.slug, e.g. 'zk'.
  final String bookSlug;

  /// Position of this word within the book (CSV row order, 1-based).
  final int sortOrder;

  /// Traceable source key from the original CSV, e.g. 'zk-3'.
  /// Allows tracing word_id back to its original CSV row independent of
  /// the canonical key. Nullable for backwards compat with older assets.
  final String? sourceKey;
  const WordBookAssignment(
      {required this.wordId,
      required this.bookSlug,
      required this.sortOrder,
      this.sourceKey});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['word_id'] = Variable<String>(wordId);
    map['book_slug'] = Variable<String>(bookSlug);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || sourceKey != null) {
      map['source_key'] = Variable<String>(sourceKey);
    }
    return map;
  }

  WordBookAssignmentsCompanion toCompanion(bool nullToAbsent) {
    return WordBookAssignmentsCompanion(
      wordId: Value(wordId),
      bookSlug: Value(bookSlug),
      sortOrder: Value(sortOrder),
      sourceKey: sourceKey == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceKey),
    );
  }

  factory WordBookAssignment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordBookAssignment(
      wordId: serializer.fromJson<String>(json['wordId']),
      bookSlug: serializer.fromJson<String>(json['bookSlug']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      sourceKey: serializer.fromJson<String?>(json['sourceKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'wordId': serializer.toJson<String>(wordId),
      'bookSlug': serializer.toJson<String>(bookSlug),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'sourceKey': serializer.toJson<String?>(sourceKey),
    };
  }

  WordBookAssignment copyWith(
          {String? wordId,
          String? bookSlug,
          int? sortOrder,
          Value<String?> sourceKey = const Value.absent()}) =>
      WordBookAssignment(
        wordId: wordId ?? this.wordId,
        bookSlug: bookSlug ?? this.bookSlug,
        sortOrder: sortOrder ?? this.sortOrder,
        sourceKey: sourceKey.present ? sourceKey.value : this.sourceKey,
      );
  WordBookAssignment copyWithCompanion(WordBookAssignmentsCompanion data) {
    return WordBookAssignment(
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      bookSlug: data.bookSlug.present ? data.bookSlug.value : this.bookSlug,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      sourceKey: data.sourceKey.present ? data.sourceKey.value : this.sourceKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordBookAssignment(')
          ..write('wordId: $wordId, ')
          ..write('bookSlug: $bookSlug, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('sourceKey: $sourceKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(wordId, bookSlug, sortOrder, sourceKey);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordBookAssignment &&
          other.wordId == this.wordId &&
          other.bookSlug == this.bookSlug &&
          other.sortOrder == this.sortOrder &&
          other.sourceKey == this.sourceKey);
}

class WordBookAssignmentsCompanion extends UpdateCompanion<WordBookAssignment> {
  final Value<String> wordId;
  final Value<String> bookSlug;
  final Value<int> sortOrder;
  final Value<String?> sourceKey;
  final Value<int> rowid;
  const WordBookAssignmentsCompanion({
    this.wordId = const Value.absent(),
    this.bookSlug = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.sourceKey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WordBookAssignmentsCompanion.insert({
    required String wordId,
    required String bookSlug,
    this.sortOrder = const Value.absent(),
    this.sourceKey = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : wordId = Value(wordId),
        bookSlug = Value(bookSlug);
  static Insertable<WordBookAssignment> custom({
    Expression<String>? wordId,
    Expression<String>? bookSlug,
    Expression<int>? sortOrder,
    Expression<String>? sourceKey,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (wordId != null) 'word_id': wordId,
      if (bookSlug != null) 'book_slug': bookSlug,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (sourceKey != null) 'source_key': sourceKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WordBookAssignmentsCompanion copyWith(
      {Value<String>? wordId,
      Value<String>? bookSlug,
      Value<int>? sortOrder,
      Value<String?>? sourceKey,
      Value<int>? rowid}) {
    return WordBookAssignmentsCompanion(
      wordId: wordId ?? this.wordId,
      bookSlug: bookSlug ?? this.bookSlug,
      sortOrder: sortOrder ?? this.sortOrder,
      sourceKey: sourceKey ?? this.sourceKey,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (wordId.present) {
      map['word_id'] = Variable<String>(wordId.value);
    }
    if (bookSlug.present) {
      map['book_slug'] = Variable<String>(bookSlug.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (sourceKey.present) {
      map['source_key'] = Variable<String>(sourceKey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordBookAssignmentsCompanion(')
          ..write('wordId: $wordId, ')
          ..write('bookSlug: $bookSlug, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('sourceKey: $sourceKey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExampleSentencesTable extends ExampleSentences
    with TableInfo<$ExampleSentencesTable, ExampleSentence> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExampleSentencesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _stableIdMeta =
      const VerificationMeta('stableId');
  @override
  late final GeneratedColumn<String> stableId = GeneratedColumn<String>(
      'stable_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _senseMeta = const VerificationMeta('sense');
  @override
  late final GeneratedColumn<String> sense = GeneratedColumn<String>(
      'sense', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _enMeta = const VerificationMeta('en');
  @override
  late final GeneratedColumn<String> en = GeneratedColumn<String>(
      'en', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cnMeta = const VerificationMeta('cn');
  @override
  late final GeneratedColumn<String> cn = GeneratedColumn<String>(
      'cn', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, wordId, stableId, sense, en, cn, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'example_sentences';
  @override
  VerificationContext validateIntegrity(Insertable<ExampleSentence> instance,
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
    if (data.containsKey('stable_id')) {
      context.handle(_stableIdMeta,
          stableId.isAcceptableOrUnknown(data['stable_id']!, _stableIdMeta));
    }
    if (data.containsKey('sense')) {
      context.handle(
          _senseMeta, sense.isAcceptableOrUnknown(data['sense']!, _senseMeta));
    } else if (isInserting) {
      context.missing(_senseMeta);
    }
    if (data.containsKey('en')) {
      context.handle(_enMeta, en.isAcceptableOrUnknown(data['en']!, _enMeta));
    } else if (isInserting) {
      context.missing(_enMeta);
    }
    if (data.containsKey('cn')) {
      context.handle(_cnMeta, cn.isAcceptableOrUnknown(data['cn']!, _cnMeta));
    } else if (isInserting) {
      context.missing(_cnMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExampleSentence map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExampleSentence(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      wordId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}word_id'])!,
      stableId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stable_id']),
      sense: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sense'])!,
      en: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}en'])!,
      cn: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cn'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $ExampleSentencesTable createAlias(String alias) {
    return $ExampleSentencesTable(attachedDatabase, alias);
  }
}

class ExampleSentence extends DataClass implements Insertable<ExampleSentence> {
  final int id;

  /// FK → word_entries.word_id.
  final String wordId;

  /// v0.3.0 P0: content-addressable stable ID.
  /// = sha256_24(canonical_json([normalize_word(word_text), normalize_text(en)]))
  /// Nullable for legacy rows imported before v9 migration; populated by all
  /// new WordbookLoader imports.
  final String? stableId;

  /// Sense/义项 label, e.g. 'v. 放弃；抛弃'.
  final String sense;

  /// English example sentence (may contain [bracket] highlight markers).
  final String en;

  /// Chinese translation (may contain [bracket] highlight markers).
  final String cn;

  /// Display order within the word (0 = first example shown).
  final int sortOrder;
  const ExampleSentence(
      {required this.id,
      required this.wordId,
      this.stableId,
      required this.sense,
      required this.en,
      required this.cn,
      required this.sortOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['word_id'] = Variable<String>(wordId);
    if (!nullToAbsent || stableId != null) {
      map['stable_id'] = Variable<String>(stableId);
    }
    map['sense'] = Variable<String>(sense);
    map['en'] = Variable<String>(en);
    map['cn'] = Variable<String>(cn);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  ExampleSentencesCompanion toCompanion(bool nullToAbsent) {
    return ExampleSentencesCompanion(
      id: Value(id),
      wordId: Value(wordId),
      stableId: stableId == null && nullToAbsent
          ? const Value.absent()
          : Value(stableId),
      sense: Value(sense),
      en: Value(en),
      cn: Value(cn),
      sortOrder: Value(sortOrder),
    );
  }

  factory ExampleSentence.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExampleSentence(
      id: serializer.fromJson<int>(json['id']),
      wordId: serializer.fromJson<String>(json['wordId']),
      stableId: serializer.fromJson<String?>(json['stableId']),
      sense: serializer.fromJson<String>(json['sense']),
      en: serializer.fromJson<String>(json['en']),
      cn: serializer.fromJson<String>(json['cn']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'wordId': serializer.toJson<String>(wordId),
      'stableId': serializer.toJson<String?>(stableId),
      'sense': serializer.toJson<String>(sense),
      'en': serializer.toJson<String>(en),
      'cn': serializer.toJson<String>(cn),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  ExampleSentence copyWith(
          {int? id,
          String? wordId,
          Value<String?> stableId = const Value.absent(),
          String? sense,
          String? en,
          String? cn,
          int? sortOrder}) =>
      ExampleSentence(
        id: id ?? this.id,
        wordId: wordId ?? this.wordId,
        stableId: stableId.present ? stableId.value : this.stableId,
        sense: sense ?? this.sense,
        en: en ?? this.en,
        cn: cn ?? this.cn,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  ExampleSentence copyWithCompanion(ExampleSentencesCompanion data) {
    return ExampleSentence(
      id: data.id.present ? data.id.value : this.id,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      stableId: data.stableId.present ? data.stableId.value : this.stableId,
      sense: data.sense.present ? data.sense.value : this.sense,
      en: data.en.present ? data.en.value : this.en,
      cn: data.cn.present ? data.cn.value : this.cn,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExampleSentence(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('stableId: $stableId, ')
          ..write('sense: $sense, ')
          ..write('en: $en, ')
          ..write('cn: $cn, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, wordId, stableId, sense, en, cn, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExampleSentence &&
          other.id == this.id &&
          other.wordId == this.wordId &&
          other.stableId == this.stableId &&
          other.sense == this.sense &&
          other.en == this.en &&
          other.cn == this.cn &&
          other.sortOrder == this.sortOrder);
}

class ExampleSentencesCompanion extends UpdateCompanion<ExampleSentence> {
  final Value<int> id;
  final Value<String> wordId;
  final Value<String?> stableId;
  final Value<String> sense;
  final Value<String> en;
  final Value<String> cn;
  final Value<int> sortOrder;
  const ExampleSentencesCompanion({
    this.id = const Value.absent(),
    this.wordId = const Value.absent(),
    this.stableId = const Value.absent(),
    this.sense = const Value.absent(),
    this.en = const Value.absent(),
    this.cn = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  ExampleSentencesCompanion.insert({
    this.id = const Value.absent(),
    required String wordId,
    this.stableId = const Value.absent(),
    required String sense,
    required String en,
    required String cn,
    this.sortOrder = const Value.absent(),
  })  : wordId = Value(wordId),
        sense = Value(sense),
        en = Value(en),
        cn = Value(cn);
  static Insertable<ExampleSentence> custom({
    Expression<int>? id,
    Expression<String>? wordId,
    Expression<String>? stableId,
    Expression<String>? sense,
    Expression<String>? en,
    Expression<String>? cn,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (wordId != null) 'word_id': wordId,
      if (stableId != null) 'stable_id': stableId,
      if (sense != null) 'sense': sense,
      if (en != null) 'en': en,
      if (cn != null) 'cn': cn,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  ExampleSentencesCompanion copyWith(
      {Value<int>? id,
      Value<String>? wordId,
      Value<String?>? stableId,
      Value<String>? sense,
      Value<String>? en,
      Value<String>? cn,
      Value<int>? sortOrder}) {
    return ExampleSentencesCompanion(
      id: id ?? this.id,
      wordId: wordId ?? this.wordId,
      stableId: stableId ?? this.stableId,
      sense: sense ?? this.sense,
      en: en ?? this.en,
      cn: cn ?? this.cn,
      sortOrder: sortOrder ?? this.sortOrder,
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
    if (stableId.present) {
      map['stable_id'] = Variable<String>(stableId.value);
    }
    if (sense.present) {
      map['sense'] = Variable<String>(sense.value);
    }
    if (en.present) {
      map['en'] = Variable<String>(en.value);
    }
    if (cn.present) {
      map['cn'] = Variable<String>(cn.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExampleSentencesCompanion(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('stableId: $stableId, ')
          ..write('sense: $sense, ')
          ..write('en: $en, ')
          ..write('cn: $cn, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<String> startedAt = GeneratedColumn<String>(
      'started_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _endedAtMeta =
      const VerificationMeta('endedAt');
  @override
  late final GeneratedColumn<String> endedAt = GeneratedColumn<String>(
      'ended_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _durationSecondsMeta =
      const VerificationMeta('durationSeconds');
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
      'duration_seconds', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _sessionMinutesTargetMeta =
      const VerificationMeta('sessionMinutesTarget');
  @override
  late final GeneratedColumn<int> sessionMinutesTarget = GeneratedColumn<int>(
      'session_minutes_target', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(15));
  static const VerificationMeta _cachedValidationStatusMeta =
      const VerificationMeta('cachedValidationStatus');
  @override
  late final GeneratedColumn<String> cachedValidationStatus =
      GeneratedColumn<String>('cached_validation_status', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<int> synced = GeneratedColumn<int>(
      'synced', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        kind,
        startedAt,
        endedAt,
        durationSeconds,
        sessionMinutesTarget,
        cachedValidationStatus,
        synced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(Insertable<Session> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(_endedAtMeta,
          endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta));
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
          _durationSecondsMeta,
          durationSeconds.isAcceptableOrUnknown(
              data['duration_seconds']!, _durationSecondsMeta));
    }
    if (data.containsKey('session_minutes_target')) {
      context.handle(
          _sessionMinutesTargetMeta,
          sessionMinutesTarget.isAcceptableOrUnknown(
              data['session_minutes_target']!, _sessionMinutesTargetMeta));
    }
    if (data.containsKey('cached_validation_status')) {
      context.handle(
          _cachedValidationStatusMeta,
          cachedValidationStatus.isAcceptableOrUnknown(
              data['cached_validation_status']!, _cachedValidationStatusMeta));
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
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}started_at'])!,
      endedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ended_at']),
      durationSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_seconds']),
      sessionMinutesTarget: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}session_minutes_target'])!,
      cachedValidationStatus: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}cached_validation_status']),
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}synced'])!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class Session extends DataClass implements Insertable<Session> {
  final String id;
  final String kind;
  final String startedAt;
  final String? endedAt;
  final int? durationSeconds;
  final int sessionMinutesTarget;
  final String? cachedValidationStatus;
  final int synced;
  const Session(
      {required this.id,
      required this.kind,
      required this.startedAt,
      this.endedAt,
      this.durationSeconds,
      required this.sessionMinutesTarget,
      this.cachedValidationStatus,
      required this.synced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['started_at'] = Variable<String>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<String>(endedAt);
    }
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    map['session_minutes_target'] = Variable<int>(sessionMinutesTarget);
    if (!nullToAbsent || cachedValidationStatus != null) {
      map['cached_validation_status'] =
          Variable<String>(cachedValidationStatus);
    }
    map['synced'] = Variable<int>(synced);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      kind: Value(kind),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      sessionMinutesTarget: Value(sessionMinutesTarget),
      cachedValidationStatus: cachedValidationStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(cachedValidationStatus),
      synced: Value(synced),
    );
  }

  factory Session.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      startedAt: serializer.fromJson<String>(json['startedAt']),
      endedAt: serializer.fromJson<String?>(json['endedAt']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
      sessionMinutesTarget:
          serializer.fromJson<int>(json['sessionMinutesTarget']),
      cachedValidationStatus:
          serializer.fromJson<String?>(json['cachedValidationStatus']),
      synced: serializer.fromJson<int>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'startedAt': serializer.toJson<String>(startedAt),
      'endedAt': serializer.toJson<String?>(endedAt),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
      'sessionMinutesTarget': serializer.toJson<int>(sessionMinutesTarget),
      'cachedValidationStatus':
          serializer.toJson<String?>(cachedValidationStatus),
      'synced': serializer.toJson<int>(synced),
    };
  }

  Session copyWith(
          {String? id,
          String? kind,
          String? startedAt,
          Value<String?> endedAt = const Value.absent(),
          Value<int?> durationSeconds = const Value.absent(),
          int? sessionMinutesTarget,
          Value<String?> cachedValidationStatus = const Value.absent(),
          int? synced}) =>
      Session(
        id: id ?? this.id,
        kind: kind ?? this.kind,
        startedAt: startedAt ?? this.startedAt,
        endedAt: endedAt.present ? endedAt.value : this.endedAt,
        durationSeconds: durationSeconds.present
            ? durationSeconds.value
            : this.durationSeconds,
        sessionMinutesTarget: sessionMinutesTarget ?? this.sessionMinutesTarget,
        cachedValidationStatus: cachedValidationStatus.present
            ? cachedValidationStatus.value
            : this.cachedValidationStatus,
        synced: synced ?? this.synced,
      );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      sessionMinutesTarget: data.sessionMinutesTarget.present
          ? data.sessionMinutesTarget.value
          : this.sessionMinutesTarget,
      cachedValidationStatus: data.cachedValidationStatus.present
          ? data.cachedValidationStatus.value
          : this.cachedValidationStatus,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('sessionMinutesTarget: $sessionMinutesTarget, ')
          ..write('cachedValidationStatus: $cachedValidationStatus, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, kind, startedAt, endedAt, durationSeconds,
      sessionMinutesTarget, cachedValidationStatus, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.durationSeconds == this.durationSeconds &&
          other.sessionMinutesTarget == this.sessionMinutesTarget &&
          other.cachedValidationStatus == this.cachedValidationStatus &&
          other.synced == this.synced);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String> startedAt;
  final Value<String?> endedAt;
  final Value<int?> durationSeconds;
  final Value<int> sessionMinutesTarget;
  final Value<String?> cachedValidationStatus;
  final Value<int> synced;
  final Value<int> rowid;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.sessionMinutesTarget = const Value.absent(),
    this.cachedValidationStatus = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionsCompanion.insert({
    required String id,
    required String kind,
    required String startedAt,
    this.endedAt = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.sessionMinutesTarget = const Value.absent(),
    this.cachedValidationStatus = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        kind = Value(kind),
        startedAt = Value(startedAt);
  static Insertable<Session> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? startedAt,
    Expression<String>? endedAt,
    Expression<int>? durationSeconds,
    Expression<int>? sessionMinutesTarget,
    Expression<String>? cachedValidationStatus,
    Expression<int>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (sessionMinutesTarget != null)
        'session_minutes_target': sessionMinutesTarget,
      if (cachedValidationStatus != null)
        'cached_validation_status': cachedValidationStatus,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? kind,
      Value<String>? startedAt,
      Value<String?>? endedAt,
      Value<int?>? durationSeconds,
      Value<int>? sessionMinutesTarget,
      Value<String?>? cachedValidationStatus,
      Value<int>? synced,
      Value<int>? rowid}) {
    return SessionsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      sessionMinutesTarget: sessionMinutesTarget ?? this.sessionMinutesTarget,
      cachedValidationStatus:
          cachedValidationStatus ?? this.cachedValidationStatus,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<String>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<String>(endedAt.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (sessionMinutesTarget.present) {
      map['session_minutes_target'] = Variable<int>(sessionMinutesTarget.value);
    }
    if (cachedValidationStatus.present) {
      map['cached_validation_status'] =
          Variable<String>(cachedValidationStatus.value);
    }
    if (synced.present) {
      map['synced'] = Variable<int>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('sessionMinutesTarget: $sessionMinutesTarget, ')
          ..write('cachedValidationStatus: $cachedValidationStatus, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReviewRecordsTable extends ReviewRecords
    with TableInfo<$ReviewRecordsTable, ReviewRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _reviewGroupIdMeta =
      const VerificationMeta('reviewGroupId');
  @override
  late final GeneratedColumn<String> reviewGroupId = GeneratedColumn<String>(
      'review_group_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<String> wordId = GeneratedColumn<String>(
      'word_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _actionResultMeta =
      const VerificationMeta('actionResult');
  @override
  late final GeneratedColumn<String> actionResult = GeneratedColumn<String>(
      'action_result', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
      'rating', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        reviewGroupId,
        wordId,
        actionResult,
        sessionId,
        createdAt,
        synced,
        rating
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_records';
  @override
  VerificationContext validateIntegrity(Insertable<ReviewRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('review_group_id')) {
      context.handle(
          _reviewGroupIdMeta,
          reviewGroupId.isAcceptableOrUnknown(
              data['review_group_id']!, _reviewGroupIdMeta));
    } else if (isInserting) {
      context.missing(_reviewGroupIdMeta);
    }
    if (data.containsKey('word_id')) {
      context.handle(_wordIdMeta,
          wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta));
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('action_result')) {
      context.handle(
          _actionResultMeta,
          actionResult.isAcceptableOrUnknown(
              data['action_result']!, _actionResultMeta));
    } else if (isInserting) {
      context.missing(_actionResultMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
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
    if (data.containsKey('rating')) {
      context.handle(_ratingMeta,
          rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReviewRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      reviewGroupId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}review_group_id'])!,
      wordId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}word_id'])!,
      actionResult: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}action_result'])!,
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}synced'])!,
      rating: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rating']),
    );
  }

  @override
  $ReviewRecordsTable createAlias(String alias) {
    return $ReviewRecordsTable(attachedDatabase, alias);
  }
}

class ReviewRecord extends DataClass implements Insertable<ReviewRecord> {
  final int id;
  final String reviewGroupId;
  final String wordId;
  final String actionResult;
  final String? sessionId;
  final String createdAt;
  final int synced;
  final int? rating;
  const ReviewRecord(
      {required this.id,
      required this.reviewGroupId,
      required this.wordId,
      required this.actionResult,
      this.sessionId,
      required this.createdAt,
      required this.synced,
      this.rating});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['review_group_id'] = Variable<String>(reviewGroupId);
    map['word_id'] = Variable<String>(wordId);
    map['action_result'] = Variable<String>(actionResult);
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<String>(sessionId);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['synced'] = Variable<int>(synced);
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<int>(rating);
    }
    return map;
  }

  ReviewRecordsCompanion toCompanion(bool nullToAbsent) {
    return ReviewRecordsCompanion(
      id: Value(id),
      reviewGroupId: Value(reviewGroupId),
      wordId: Value(wordId),
      actionResult: Value(actionResult),
      sessionId: sessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionId),
      createdAt: Value(createdAt),
      synced: Value(synced),
      rating:
          rating == null && nullToAbsent ? const Value.absent() : Value(rating),
    );
  }

  factory ReviewRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewRecord(
      id: serializer.fromJson<int>(json['id']),
      reviewGroupId: serializer.fromJson<String>(json['reviewGroupId']),
      wordId: serializer.fromJson<String>(json['wordId']),
      actionResult: serializer.fromJson<String>(json['actionResult']),
      sessionId: serializer.fromJson<String?>(json['sessionId']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      synced: serializer.fromJson<int>(json['synced']),
      rating: serializer.fromJson<int?>(json['rating']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'reviewGroupId': serializer.toJson<String>(reviewGroupId),
      'wordId': serializer.toJson<String>(wordId),
      'actionResult': serializer.toJson<String>(actionResult),
      'sessionId': serializer.toJson<String?>(sessionId),
      'createdAt': serializer.toJson<String>(createdAt),
      'synced': serializer.toJson<int>(synced),
      'rating': serializer.toJson<int?>(rating),
    };
  }

  ReviewRecord copyWith(
          {int? id,
          String? reviewGroupId,
          String? wordId,
          String? actionResult,
          Value<String?> sessionId = const Value.absent(),
          String? createdAt,
          int? synced,
          Value<int?> rating = const Value.absent()}) =>
      ReviewRecord(
        id: id ?? this.id,
        reviewGroupId: reviewGroupId ?? this.reviewGroupId,
        wordId: wordId ?? this.wordId,
        actionResult: actionResult ?? this.actionResult,
        sessionId: sessionId.present ? sessionId.value : this.sessionId,
        createdAt: createdAt ?? this.createdAt,
        synced: synced ?? this.synced,
        rating: rating.present ? rating.value : this.rating,
      );
  ReviewRecord copyWithCompanion(ReviewRecordsCompanion data) {
    return ReviewRecord(
      id: data.id.present ? data.id.value : this.id,
      reviewGroupId: data.reviewGroupId.present
          ? data.reviewGroupId.value
          : this.reviewGroupId,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      actionResult: data.actionResult.present
          ? data.actionResult.value
          : this.actionResult,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      synced: data.synced.present ? data.synced.value : this.synced,
      rating: data.rating.present ? data.rating.value : this.rating,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewRecord(')
          ..write('id: $id, ')
          ..write('reviewGroupId: $reviewGroupId, ')
          ..write('wordId: $wordId, ')
          ..write('actionResult: $actionResult, ')
          ..write('sessionId: $sessionId, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced, ')
          ..write('rating: $rating')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, reviewGroupId, wordId, actionResult,
      sessionId, createdAt, synced, rating);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewRecord &&
          other.id == this.id &&
          other.reviewGroupId == this.reviewGroupId &&
          other.wordId == this.wordId &&
          other.actionResult == this.actionResult &&
          other.sessionId == this.sessionId &&
          other.createdAt == this.createdAt &&
          other.synced == this.synced &&
          other.rating == this.rating);
}

class ReviewRecordsCompanion extends UpdateCompanion<ReviewRecord> {
  final Value<int> id;
  final Value<String> reviewGroupId;
  final Value<String> wordId;
  final Value<String> actionResult;
  final Value<String?> sessionId;
  final Value<String> createdAt;
  final Value<int> synced;
  final Value<int?> rating;
  const ReviewRecordsCompanion({
    this.id = const Value.absent(),
    this.reviewGroupId = const Value.absent(),
    this.wordId = const Value.absent(),
    this.actionResult = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rating = const Value.absent(),
  });
  ReviewRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String reviewGroupId,
    required String wordId,
    required String actionResult,
    this.sessionId = const Value.absent(),
    required String createdAt,
    this.synced = const Value.absent(),
    this.rating = const Value.absent(),
  })  : reviewGroupId = Value(reviewGroupId),
        wordId = Value(wordId),
        actionResult = Value(actionResult),
        createdAt = Value(createdAt);
  static Insertable<ReviewRecord> custom({
    Expression<int>? id,
    Expression<String>? reviewGroupId,
    Expression<String>? wordId,
    Expression<String>? actionResult,
    Expression<String>? sessionId,
    Expression<String>? createdAt,
    Expression<int>? synced,
    Expression<int>? rating,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (reviewGroupId != null) 'review_group_id': reviewGroupId,
      if (wordId != null) 'word_id': wordId,
      if (actionResult != null) 'action_result': actionResult,
      if (sessionId != null) 'session_id': sessionId,
      if (createdAt != null) 'created_at': createdAt,
      if (synced != null) 'synced': synced,
      if (rating != null) 'rating': rating,
    });
  }

  ReviewRecordsCompanion copyWith(
      {Value<int>? id,
      Value<String>? reviewGroupId,
      Value<String>? wordId,
      Value<String>? actionResult,
      Value<String?>? sessionId,
      Value<String>? createdAt,
      Value<int>? synced,
      Value<int?>? rating}) {
    return ReviewRecordsCompanion(
      id: id ?? this.id,
      reviewGroupId: reviewGroupId ?? this.reviewGroupId,
      wordId: wordId ?? this.wordId,
      actionResult: actionResult ?? this.actionResult,
      sessionId: sessionId ?? this.sessionId,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
      rating: rating ?? this.rating,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (reviewGroupId.present) {
      map['review_group_id'] = Variable<String>(reviewGroupId.value);
    }
    if (wordId.present) {
      map['word_id'] = Variable<String>(wordId.value);
    }
    if (actionResult.present) {
      map['action_result'] = Variable<String>(actionResult.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<int>(synced.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewRecordsCompanion(')
          ..write('id: $id, ')
          ..write('reviewGroupId: $reviewGroupId, ')
          ..write('wordId: $wordId, ')
          ..write('actionResult: $actionResult, ')
          ..write('sessionId: $sessionId, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced, ')
          ..write('rating: $rating')
          ..write(')'))
        .toString();
  }
}

class $WordFormsTable extends WordForms
    with TableInfo<$WordFormsTable, WordForm> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordFormsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _formTextMeta =
      const VerificationMeta('formText');
  @override
  late final GeneratedColumn<String> formText = GeneratedColumn<String>(
      'form_text', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _formTypeMeta =
      const VerificationMeta('formType');
  @override
  late final GeneratedColumn<String> formType = GeneratedColumn<String>(
      'form_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _posMeta = const VerificationMeta('pos');
  @override
  late final GeneratedColumn<String> pos = GeneratedColumn<String>(
      'pos', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, word, formText, formType, pos, source];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word_forms';
  @override
  VerificationContext validateIntegrity(Insertable<WordForm> instance,
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
    if (data.containsKey('form_text')) {
      context.handle(_formTextMeta,
          formText.isAcceptableOrUnknown(data['form_text']!, _formTextMeta));
    } else if (isInserting) {
      context.missing(_formTextMeta);
    }
    if (data.containsKey('form_type')) {
      context.handle(_formTypeMeta,
          formType.isAcceptableOrUnknown(data['form_type']!, _formTypeMeta));
    } else if (isInserting) {
      context.missing(_formTypeMeta);
    }
    if (data.containsKey('pos')) {
      context.handle(
          _posMeta, pos.isAcceptableOrUnknown(data['pos']!, _posMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WordForm map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordForm(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      word: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}word'])!,
      formText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}form_text'])!,
      formType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}form_type'])!,
      pos: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pos']),
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source']),
    );
  }

  @override
  $WordFormsTable createAlias(String alias) {
    return $WordFormsTable(attachedDatabase, alias);
  }
}

class WordForm extends DataClass implements Insertable<WordForm> {
  final int id;
  final String word;
  final String formText;
  final String formType;
  final String? pos;
  final String? source;
  const WordForm(
      {required this.id,
      required this.word,
      required this.formText,
      required this.formType,
      this.pos,
      this.source});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['word'] = Variable<String>(word);
    map['form_text'] = Variable<String>(formText);
    map['form_type'] = Variable<String>(formType);
    if (!nullToAbsent || pos != null) {
      map['pos'] = Variable<String>(pos);
    }
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    return map;
  }

  WordFormsCompanion toCompanion(bool nullToAbsent) {
    return WordFormsCompanion(
      id: Value(id),
      word: Value(word),
      formText: Value(formText),
      formType: Value(formType),
      pos: pos == null && nullToAbsent ? const Value.absent() : Value(pos),
      source:
          source == null && nullToAbsent ? const Value.absent() : Value(source),
    );
  }

  factory WordForm.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordForm(
      id: serializer.fromJson<int>(json['id']),
      word: serializer.fromJson<String>(json['word']),
      formText: serializer.fromJson<String>(json['formText']),
      formType: serializer.fromJson<String>(json['formType']),
      pos: serializer.fromJson<String?>(json['pos']),
      source: serializer.fromJson<String?>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'word': serializer.toJson<String>(word),
      'formText': serializer.toJson<String>(formText),
      'formType': serializer.toJson<String>(formType),
      'pos': serializer.toJson<String?>(pos),
      'source': serializer.toJson<String?>(source),
    };
  }

  WordForm copyWith(
          {int? id,
          String? word,
          String? formText,
          String? formType,
          Value<String?> pos = const Value.absent(),
          Value<String?> source = const Value.absent()}) =>
      WordForm(
        id: id ?? this.id,
        word: word ?? this.word,
        formText: formText ?? this.formText,
        formType: formType ?? this.formType,
        pos: pos.present ? pos.value : this.pos,
        source: source.present ? source.value : this.source,
      );
  WordForm copyWithCompanion(WordFormsCompanion data) {
    return WordForm(
      id: data.id.present ? data.id.value : this.id,
      word: data.word.present ? data.word.value : this.word,
      formText: data.formText.present ? data.formText.value : this.formText,
      formType: data.formType.present ? data.formType.value : this.formType,
      pos: data.pos.present ? data.pos.value : this.pos,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordForm(')
          ..write('id: $id, ')
          ..write('word: $word, ')
          ..write('formText: $formText, ')
          ..write('formType: $formType, ')
          ..write('pos: $pos, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, word, formText, formType, pos, source);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordForm &&
          other.id == this.id &&
          other.word == this.word &&
          other.formText == this.formText &&
          other.formType == this.formType &&
          other.pos == this.pos &&
          other.source == this.source);
}

class WordFormsCompanion extends UpdateCompanion<WordForm> {
  final Value<int> id;
  final Value<String> word;
  final Value<String> formText;
  final Value<String> formType;
  final Value<String?> pos;
  final Value<String?> source;
  const WordFormsCompanion({
    this.id = const Value.absent(),
    this.word = const Value.absent(),
    this.formText = const Value.absent(),
    this.formType = const Value.absent(),
    this.pos = const Value.absent(),
    this.source = const Value.absent(),
  });
  WordFormsCompanion.insert({
    this.id = const Value.absent(),
    required String word,
    required String formText,
    required String formType,
    this.pos = const Value.absent(),
    this.source = const Value.absent(),
  })  : word = Value(word),
        formText = Value(formText),
        formType = Value(formType);
  static Insertable<WordForm> custom({
    Expression<int>? id,
    Expression<String>? word,
    Expression<String>? formText,
    Expression<String>? formType,
    Expression<String>? pos,
    Expression<String>? source,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (word != null) 'word': word,
      if (formText != null) 'form_text': formText,
      if (formType != null) 'form_type': formType,
      if (pos != null) 'pos': pos,
      if (source != null) 'source': source,
    });
  }

  WordFormsCompanion copyWith(
      {Value<int>? id,
      Value<String>? word,
      Value<String>? formText,
      Value<String>? formType,
      Value<String?>? pos,
      Value<String?>? source}) {
    return WordFormsCompanion(
      id: id ?? this.id,
      word: word ?? this.word,
      formText: formText ?? this.formText,
      formType: formType ?? this.formType,
      pos: pos ?? this.pos,
      source: source ?? this.source,
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
    if (formText.present) {
      map['form_text'] = Variable<String>(formText.value);
    }
    if (formType.present) {
      map['form_type'] = Variable<String>(formType.value);
    }
    if (pos.present) {
      map['pos'] = Variable<String>(pos.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordFormsCompanion(')
          ..write('id: $id, ')
          ..write('word: $word, ')
          ..write('formText: $formText, ')
          ..write('formType: $formType, ')
          ..write('pos: $pos, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }
}

class $WordRelationsTable extends WordRelations
    with TableInfo<$WordRelationsTable, WordRelation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordRelationsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _targetWordMeta =
      const VerificationMeta('targetWord');
  @override
  late final GeneratedColumn<String> targetWord = GeneratedColumn<String>(
      'target_word', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _relationTypeMeta =
      const VerificationMeta('relationType');
  @override
  late final GeneratedColumn<String> relationType = GeneratedColumn<String>(
      'relation_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _posMeta = const VerificationMeta('pos');
  @override
  late final GeneratedColumn<String> pos = GeneratedColumn<String>(
      'pos', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _confidenceMeta =
      const VerificationMeta('confidence');
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
      'confidence', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, word, targetWord, relationType, pos, confidence, source];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word_relations';
  @override
  VerificationContext validateIntegrity(Insertable<WordRelation> instance,
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
    if (data.containsKey('target_word')) {
      context.handle(
          _targetWordMeta,
          targetWord.isAcceptableOrUnknown(
              data['target_word']!, _targetWordMeta));
    } else if (isInserting) {
      context.missing(_targetWordMeta);
    }
    if (data.containsKey('relation_type')) {
      context.handle(
          _relationTypeMeta,
          relationType.isAcceptableOrUnknown(
              data['relation_type']!, _relationTypeMeta));
    } else if (isInserting) {
      context.missing(_relationTypeMeta);
    }
    if (data.containsKey('pos')) {
      context.handle(
          _posMeta, pos.isAcceptableOrUnknown(data['pos']!, _posMeta));
    }
    if (data.containsKey('confidence')) {
      context.handle(
          _confidenceMeta,
          confidence.isAcceptableOrUnknown(
              data['confidence']!, _confidenceMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WordRelation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordRelation(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      word: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}word'])!,
      targetWord: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}target_word'])!,
      relationType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}relation_type'])!,
      pos: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pos']),
      confidence: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}confidence']),
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source']),
    );
  }

  @override
  $WordRelationsTable createAlias(String alias) {
    return $WordRelationsTable(attachedDatabase, alias);
  }
}

class WordRelation extends DataClass implements Insertable<WordRelation> {
  final int id;
  final String word;
  final String targetWord;
  final String relationType;
  final String? pos;
  final double? confidence;
  final String? source;
  const WordRelation(
      {required this.id,
      required this.word,
      required this.targetWord,
      required this.relationType,
      this.pos,
      this.confidence,
      this.source});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['word'] = Variable<String>(word);
    map['target_word'] = Variable<String>(targetWord);
    map['relation_type'] = Variable<String>(relationType);
    if (!nullToAbsent || pos != null) {
      map['pos'] = Variable<String>(pos);
    }
    if (!nullToAbsent || confidence != null) {
      map['confidence'] = Variable<double>(confidence);
    }
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    return map;
  }

  WordRelationsCompanion toCompanion(bool nullToAbsent) {
    return WordRelationsCompanion(
      id: Value(id),
      word: Value(word),
      targetWord: Value(targetWord),
      relationType: Value(relationType),
      pos: pos == null && nullToAbsent ? const Value.absent() : Value(pos),
      confidence: confidence == null && nullToAbsent
          ? const Value.absent()
          : Value(confidence),
      source:
          source == null && nullToAbsent ? const Value.absent() : Value(source),
    );
  }

  factory WordRelation.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordRelation(
      id: serializer.fromJson<int>(json['id']),
      word: serializer.fromJson<String>(json['word']),
      targetWord: serializer.fromJson<String>(json['targetWord']),
      relationType: serializer.fromJson<String>(json['relationType']),
      pos: serializer.fromJson<String?>(json['pos']),
      confidence: serializer.fromJson<double?>(json['confidence']),
      source: serializer.fromJson<String?>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'word': serializer.toJson<String>(word),
      'targetWord': serializer.toJson<String>(targetWord),
      'relationType': serializer.toJson<String>(relationType),
      'pos': serializer.toJson<String?>(pos),
      'confidence': serializer.toJson<double?>(confidence),
      'source': serializer.toJson<String?>(source),
    };
  }

  WordRelation copyWith(
          {int? id,
          String? word,
          String? targetWord,
          String? relationType,
          Value<String?> pos = const Value.absent(),
          Value<double?> confidence = const Value.absent(),
          Value<String?> source = const Value.absent()}) =>
      WordRelation(
        id: id ?? this.id,
        word: word ?? this.word,
        targetWord: targetWord ?? this.targetWord,
        relationType: relationType ?? this.relationType,
        pos: pos.present ? pos.value : this.pos,
        confidence: confidence.present ? confidence.value : this.confidence,
        source: source.present ? source.value : this.source,
      );
  WordRelation copyWithCompanion(WordRelationsCompanion data) {
    return WordRelation(
      id: data.id.present ? data.id.value : this.id,
      word: data.word.present ? data.word.value : this.word,
      targetWord:
          data.targetWord.present ? data.targetWord.value : this.targetWord,
      relationType: data.relationType.present
          ? data.relationType.value
          : this.relationType,
      pos: data.pos.present ? data.pos.value : this.pos,
      confidence:
          data.confidence.present ? data.confidence.value : this.confidence,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordRelation(')
          ..write('id: $id, ')
          ..write('word: $word, ')
          ..write('targetWord: $targetWord, ')
          ..write('relationType: $relationType, ')
          ..write('pos: $pos, ')
          ..write('confidence: $confidence, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, word, targetWord, relationType, pos, confidence, source);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordRelation &&
          other.id == this.id &&
          other.word == this.word &&
          other.targetWord == this.targetWord &&
          other.relationType == this.relationType &&
          other.pos == this.pos &&
          other.confidence == this.confidence &&
          other.source == this.source);
}

class WordRelationsCompanion extends UpdateCompanion<WordRelation> {
  final Value<int> id;
  final Value<String> word;
  final Value<String> targetWord;
  final Value<String> relationType;
  final Value<String?> pos;
  final Value<double?> confidence;
  final Value<String?> source;
  const WordRelationsCompanion({
    this.id = const Value.absent(),
    this.word = const Value.absent(),
    this.targetWord = const Value.absent(),
    this.relationType = const Value.absent(),
    this.pos = const Value.absent(),
    this.confidence = const Value.absent(),
    this.source = const Value.absent(),
  });
  WordRelationsCompanion.insert({
    this.id = const Value.absent(),
    required String word,
    required String targetWord,
    required String relationType,
    this.pos = const Value.absent(),
    this.confidence = const Value.absent(),
    this.source = const Value.absent(),
  })  : word = Value(word),
        targetWord = Value(targetWord),
        relationType = Value(relationType);
  static Insertable<WordRelation> custom({
    Expression<int>? id,
    Expression<String>? word,
    Expression<String>? targetWord,
    Expression<String>? relationType,
    Expression<String>? pos,
    Expression<double>? confidence,
    Expression<String>? source,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (word != null) 'word': word,
      if (targetWord != null) 'target_word': targetWord,
      if (relationType != null) 'relation_type': relationType,
      if (pos != null) 'pos': pos,
      if (confidence != null) 'confidence': confidence,
      if (source != null) 'source': source,
    });
  }

  WordRelationsCompanion copyWith(
      {Value<int>? id,
      Value<String>? word,
      Value<String>? targetWord,
      Value<String>? relationType,
      Value<String?>? pos,
      Value<double?>? confidence,
      Value<String?>? source}) {
    return WordRelationsCompanion(
      id: id ?? this.id,
      word: word ?? this.word,
      targetWord: targetWord ?? this.targetWord,
      relationType: relationType ?? this.relationType,
      pos: pos ?? this.pos,
      confidence: confidence ?? this.confidence,
      source: source ?? this.source,
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
    if (targetWord.present) {
      map['target_word'] = Variable<String>(targetWord.value);
    }
    if (relationType.present) {
      map['relation_type'] = Variable<String>(relationType.value);
    }
    if (pos.present) {
      map['pos'] = Variable<String>(pos.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordRelationsCompanion(')
          ..write('id: $id, ')
          ..write('word: $word, ')
          ..write('targetWord: $targetWord, ')
          ..write('relationType: $relationType, ')
          ..write('pos: $pos, ')
          ..write('confidence: $confidence, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }
}

class $WordPhrasesTable extends WordPhrases
    with TableInfo<$WordPhrasesTable, WordPhrase> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordPhrasesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _phraseTextMeta =
      const VerificationMeta('phraseText');
  @override
  late final GeneratedColumn<String> phraseText = GeneratedColumn<String>(
      'phrase_text', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _phraseTypeMeta =
      const VerificationMeta('phraseType');
  @override
  late final GeneratedColumn<String> phraseType = GeneratedColumn<String>(
      'phrase_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('common_phrase'));
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
      'score', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, word, phraseText, phraseType, score, source];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word_phrases';
  @override
  VerificationContext validateIntegrity(Insertable<WordPhrase> instance,
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
    if (data.containsKey('phrase_text')) {
      context.handle(
          _phraseTextMeta,
          phraseText.isAcceptableOrUnknown(
              data['phrase_text']!, _phraseTextMeta));
    } else if (isInserting) {
      context.missing(_phraseTextMeta);
    }
    if (data.containsKey('phrase_type')) {
      context.handle(
          _phraseTypeMeta,
          phraseType.isAcceptableOrUnknown(
              data['phrase_type']!, _phraseTypeMeta));
    }
    if (data.containsKey('score')) {
      context.handle(
          _scoreMeta, score.isAcceptableOrUnknown(data['score']!, _scoreMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WordPhrase map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordPhrase(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      word: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}word'])!,
      phraseText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phrase_text'])!,
      phraseType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phrase_type'])!,
      score: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}score']),
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source']),
    );
  }

  @override
  $WordPhrasesTable createAlias(String alias) {
    return $WordPhrasesTable(attachedDatabase, alias);
  }
}

class WordPhrase extends DataClass implements Insertable<WordPhrase> {
  final int id;
  final String word;
  final String phraseText;
  final String phraseType;
  final int? score;
  final String? source;
  const WordPhrase(
      {required this.id,
      required this.word,
      required this.phraseText,
      required this.phraseType,
      this.score,
      this.source});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['word'] = Variable<String>(word);
    map['phrase_text'] = Variable<String>(phraseText);
    map['phrase_type'] = Variable<String>(phraseType);
    if (!nullToAbsent || score != null) {
      map['score'] = Variable<int>(score);
    }
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    return map;
  }

  WordPhrasesCompanion toCompanion(bool nullToAbsent) {
    return WordPhrasesCompanion(
      id: Value(id),
      word: Value(word),
      phraseText: Value(phraseText),
      phraseType: Value(phraseType),
      score:
          score == null && nullToAbsent ? const Value.absent() : Value(score),
      source:
          source == null && nullToAbsent ? const Value.absent() : Value(source),
    );
  }

  factory WordPhrase.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordPhrase(
      id: serializer.fromJson<int>(json['id']),
      word: serializer.fromJson<String>(json['word']),
      phraseText: serializer.fromJson<String>(json['phraseText']),
      phraseType: serializer.fromJson<String>(json['phraseType']),
      score: serializer.fromJson<int?>(json['score']),
      source: serializer.fromJson<String?>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'word': serializer.toJson<String>(word),
      'phraseText': serializer.toJson<String>(phraseText),
      'phraseType': serializer.toJson<String>(phraseType),
      'score': serializer.toJson<int?>(score),
      'source': serializer.toJson<String?>(source),
    };
  }

  WordPhrase copyWith(
          {int? id,
          String? word,
          String? phraseText,
          String? phraseType,
          Value<int?> score = const Value.absent(),
          Value<String?> source = const Value.absent()}) =>
      WordPhrase(
        id: id ?? this.id,
        word: word ?? this.word,
        phraseText: phraseText ?? this.phraseText,
        phraseType: phraseType ?? this.phraseType,
        score: score.present ? score.value : this.score,
        source: source.present ? source.value : this.source,
      );
  WordPhrase copyWithCompanion(WordPhrasesCompanion data) {
    return WordPhrase(
      id: data.id.present ? data.id.value : this.id,
      word: data.word.present ? data.word.value : this.word,
      phraseText:
          data.phraseText.present ? data.phraseText.value : this.phraseText,
      phraseType:
          data.phraseType.present ? data.phraseType.value : this.phraseType,
      score: data.score.present ? data.score.value : this.score,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordPhrase(')
          ..write('id: $id, ')
          ..write('word: $word, ')
          ..write('phraseText: $phraseText, ')
          ..write('phraseType: $phraseType, ')
          ..write('score: $score, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, word, phraseText, phraseType, score, source);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordPhrase &&
          other.id == this.id &&
          other.word == this.word &&
          other.phraseText == this.phraseText &&
          other.phraseType == this.phraseType &&
          other.score == this.score &&
          other.source == this.source);
}

class WordPhrasesCompanion extends UpdateCompanion<WordPhrase> {
  final Value<int> id;
  final Value<String> word;
  final Value<String> phraseText;
  final Value<String> phraseType;
  final Value<int?> score;
  final Value<String?> source;
  const WordPhrasesCompanion({
    this.id = const Value.absent(),
    this.word = const Value.absent(),
    this.phraseText = const Value.absent(),
    this.phraseType = const Value.absent(),
    this.score = const Value.absent(),
    this.source = const Value.absent(),
  });
  WordPhrasesCompanion.insert({
    this.id = const Value.absent(),
    required String word,
    required String phraseText,
    this.phraseType = const Value.absent(),
    this.score = const Value.absent(),
    this.source = const Value.absent(),
  })  : word = Value(word),
        phraseText = Value(phraseText);
  static Insertable<WordPhrase> custom({
    Expression<int>? id,
    Expression<String>? word,
    Expression<String>? phraseText,
    Expression<String>? phraseType,
    Expression<int>? score,
    Expression<String>? source,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (word != null) 'word': word,
      if (phraseText != null) 'phrase_text': phraseText,
      if (phraseType != null) 'phrase_type': phraseType,
      if (score != null) 'score': score,
      if (source != null) 'source': source,
    });
  }

  WordPhrasesCompanion copyWith(
      {Value<int>? id,
      Value<String>? word,
      Value<String>? phraseText,
      Value<String>? phraseType,
      Value<int?>? score,
      Value<String?>? source}) {
    return WordPhrasesCompanion(
      id: id ?? this.id,
      word: word ?? this.word,
      phraseText: phraseText ?? this.phraseText,
      phraseType: phraseType ?? this.phraseType,
      score: score ?? this.score,
      source: source ?? this.source,
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
    if (phraseText.present) {
      map['phrase_text'] = Variable<String>(phraseText.value);
    }
    if (phraseType.present) {
      map['phrase_type'] = Variable<String>(phraseType.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordPhrasesCompanion(')
          ..write('id: $id, ')
          ..write('word: $word, ')
          ..write('phraseText: $phraseText, ')
          ..write('phraseType: $phraseType, ')
          ..write('score: $score, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }
}

class $MorphemeEntriesTable extends MorphemeEntries
    with TableInfo<$MorphemeEntriesTable, MorphemeEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MorphemeEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _morphemeMeta =
      const VerificationMeta('morpheme');
  @override
  late final GeneratedColumn<String> morpheme = GeneratedColumn<String>(
      'morpheme', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _normalizedMorphemeMeta =
      const VerificationMeta('normalizedMorpheme');
  @override
  late final GeneratedColumn<String> normalizedMorpheme =
      GeneratedColumn<String>('normalized_morpheme', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _morphemeTypeMeta =
      const VerificationMeta('morphemeType');
  @override
  late final GeneratedColumn<String> morphemeType = GeneratedColumn<String>(
      'morpheme_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _meaningsJsonMeta =
      const VerificationMeta('meaningsJson');
  @override
  late final GeneratedColumn<String> meaningsJson = GeneratedColumn<String>(
      'meanings_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _examplesJsonMeta =
      const VerificationMeta('examplesJson');
  @override
  late final GeneratedColumn<String> examplesJson = GeneratedColumn<String>(
      'examples_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _licenseMeta =
      const VerificationMeta('license');
  @override
  late final GeneratedColumn<String> license = GeneratedColumn<String>(
      'license', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        morpheme,
        normalizedMorpheme,
        morphemeType,
        meaningsJson,
        examplesJson,
        source,
        license
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'morpheme_entries';
  @override
  VerificationContext validateIntegrity(Insertable<MorphemeEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('morpheme')) {
      context.handle(_morphemeMeta,
          morpheme.isAcceptableOrUnknown(data['morpheme']!, _morphemeMeta));
    } else if (isInserting) {
      context.missing(_morphemeMeta);
    }
    if (data.containsKey('normalized_morpheme')) {
      context.handle(
          _normalizedMorphemeMeta,
          normalizedMorpheme.isAcceptableOrUnknown(
              data['normalized_morpheme']!, _normalizedMorphemeMeta));
    } else if (isInserting) {
      context.missing(_normalizedMorphemeMeta);
    }
    if (data.containsKey('morpheme_type')) {
      context.handle(
          _morphemeTypeMeta,
          morphemeType.isAcceptableOrUnknown(
              data['morpheme_type']!, _morphemeTypeMeta));
    } else if (isInserting) {
      context.missing(_morphemeTypeMeta);
    }
    if (data.containsKey('meanings_json')) {
      context.handle(
          _meaningsJsonMeta,
          meaningsJson.isAcceptableOrUnknown(
              data['meanings_json']!, _meaningsJsonMeta));
    } else if (isInserting) {
      context.missing(_meaningsJsonMeta);
    }
    if (data.containsKey('examples_json')) {
      context.handle(
          _examplesJsonMeta,
          examplesJson.isAcceptableOrUnknown(
              data['examples_json']!, _examplesJsonMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    if (data.containsKey('license')) {
      context.handle(_licenseMeta,
          license.isAcceptableOrUnknown(data['license']!, _licenseMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MorphemeEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MorphemeEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      morpheme: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}morpheme'])!,
      normalizedMorpheme: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}normalized_morpheme'])!,
      morphemeType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}morpheme_type'])!,
      meaningsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meanings_json'])!,
      examplesJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}examples_json']),
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source']),
      license: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}license']),
    );
  }

  @override
  $MorphemeEntriesTable createAlias(String alias) {
    return $MorphemeEntriesTable(attachedDatabase, alias);
  }
}

class MorphemeEntry extends DataClass implements Insertable<MorphemeEntry> {
  final int id;
  final String morpheme;
  final String normalizedMorpheme;
  final String morphemeType;
  final String meaningsJson;
  final String? examplesJson;
  final String? source;
  final String? license;
  const MorphemeEntry(
      {required this.id,
      required this.morpheme,
      required this.normalizedMorpheme,
      required this.morphemeType,
      required this.meaningsJson,
      this.examplesJson,
      this.source,
      this.license});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['morpheme'] = Variable<String>(morpheme);
    map['normalized_morpheme'] = Variable<String>(normalizedMorpheme);
    map['morpheme_type'] = Variable<String>(morphemeType);
    map['meanings_json'] = Variable<String>(meaningsJson);
    if (!nullToAbsent || examplesJson != null) {
      map['examples_json'] = Variable<String>(examplesJson);
    }
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    if (!nullToAbsent || license != null) {
      map['license'] = Variable<String>(license);
    }
    return map;
  }

  MorphemeEntriesCompanion toCompanion(bool nullToAbsent) {
    return MorphemeEntriesCompanion(
      id: Value(id),
      morpheme: Value(morpheme),
      normalizedMorpheme: Value(normalizedMorpheme),
      morphemeType: Value(morphemeType),
      meaningsJson: Value(meaningsJson),
      examplesJson: examplesJson == null && nullToAbsent
          ? const Value.absent()
          : Value(examplesJson),
      source:
          source == null && nullToAbsent ? const Value.absent() : Value(source),
      license: license == null && nullToAbsent
          ? const Value.absent()
          : Value(license),
    );
  }

  factory MorphemeEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MorphemeEntry(
      id: serializer.fromJson<int>(json['id']),
      morpheme: serializer.fromJson<String>(json['morpheme']),
      normalizedMorpheme:
          serializer.fromJson<String>(json['normalizedMorpheme']),
      morphemeType: serializer.fromJson<String>(json['morphemeType']),
      meaningsJson: serializer.fromJson<String>(json['meaningsJson']),
      examplesJson: serializer.fromJson<String?>(json['examplesJson']),
      source: serializer.fromJson<String?>(json['source']),
      license: serializer.fromJson<String?>(json['license']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'morpheme': serializer.toJson<String>(morpheme),
      'normalizedMorpheme': serializer.toJson<String>(normalizedMorpheme),
      'morphemeType': serializer.toJson<String>(morphemeType),
      'meaningsJson': serializer.toJson<String>(meaningsJson),
      'examplesJson': serializer.toJson<String?>(examplesJson),
      'source': serializer.toJson<String?>(source),
      'license': serializer.toJson<String?>(license),
    };
  }

  MorphemeEntry copyWith(
          {int? id,
          String? morpheme,
          String? normalizedMorpheme,
          String? morphemeType,
          String? meaningsJson,
          Value<String?> examplesJson = const Value.absent(),
          Value<String?> source = const Value.absent(),
          Value<String?> license = const Value.absent()}) =>
      MorphemeEntry(
        id: id ?? this.id,
        morpheme: morpheme ?? this.morpheme,
        normalizedMorpheme: normalizedMorpheme ?? this.normalizedMorpheme,
        morphemeType: morphemeType ?? this.morphemeType,
        meaningsJson: meaningsJson ?? this.meaningsJson,
        examplesJson:
            examplesJson.present ? examplesJson.value : this.examplesJson,
        source: source.present ? source.value : this.source,
        license: license.present ? license.value : this.license,
      );
  MorphemeEntry copyWithCompanion(MorphemeEntriesCompanion data) {
    return MorphemeEntry(
      id: data.id.present ? data.id.value : this.id,
      morpheme: data.morpheme.present ? data.morpheme.value : this.morpheme,
      normalizedMorpheme: data.normalizedMorpheme.present
          ? data.normalizedMorpheme.value
          : this.normalizedMorpheme,
      morphemeType: data.morphemeType.present
          ? data.morphemeType.value
          : this.morphemeType,
      meaningsJson: data.meaningsJson.present
          ? data.meaningsJson.value
          : this.meaningsJson,
      examplesJson: data.examplesJson.present
          ? data.examplesJson.value
          : this.examplesJson,
      source: data.source.present ? data.source.value : this.source,
      license: data.license.present ? data.license.value : this.license,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MorphemeEntry(')
          ..write('id: $id, ')
          ..write('morpheme: $morpheme, ')
          ..write('normalizedMorpheme: $normalizedMorpheme, ')
          ..write('morphemeType: $morphemeType, ')
          ..write('meaningsJson: $meaningsJson, ')
          ..write('examplesJson: $examplesJson, ')
          ..write('source: $source, ')
          ..write('license: $license')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, morpheme, normalizedMorpheme,
      morphemeType, meaningsJson, examplesJson, source, license);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MorphemeEntry &&
          other.id == this.id &&
          other.morpheme == this.morpheme &&
          other.normalizedMorpheme == this.normalizedMorpheme &&
          other.morphemeType == this.morphemeType &&
          other.meaningsJson == this.meaningsJson &&
          other.examplesJson == this.examplesJson &&
          other.source == this.source &&
          other.license == this.license);
}

class MorphemeEntriesCompanion extends UpdateCompanion<MorphemeEntry> {
  final Value<int> id;
  final Value<String> morpheme;
  final Value<String> normalizedMorpheme;
  final Value<String> morphemeType;
  final Value<String> meaningsJson;
  final Value<String?> examplesJson;
  final Value<String?> source;
  final Value<String?> license;
  const MorphemeEntriesCompanion({
    this.id = const Value.absent(),
    this.morpheme = const Value.absent(),
    this.normalizedMorpheme = const Value.absent(),
    this.morphemeType = const Value.absent(),
    this.meaningsJson = const Value.absent(),
    this.examplesJson = const Value.absent(),
    this.source = const Value.absent(),
    this.license = const Value.absent(),
  });
  MorphemeEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String morpheme,
    required String normalizedMorpheme,
    required String morphemeType,
    required String meaningsJson,
    this.examplesJson = const Value.absent(),
    this.source = const Value.absent(),
    this.license = const Value.absent(),
  })  : morpheme = Value(morpheme),
        normalizedMorpheme = Value(normalizedMorpheme),
        morphemeType = Value(morphemeType),
        meaningsJson = Value(meaningsJson);
  static Insertable<MorphemeEntry> custom({
    Expression<int>? id,
    Expression<String>? morpheme,
    Expression<String>? normalizedMorpheme,
    Expression<String>? morphemeType,
    Expression<String>? meaningsJson,
    Expression<String>? examplesJson,
    Expression<String>? source,
    Expression<String>? license,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (morpheme != null) 'morpheme': morpheme,
      if (normalizedMorpheme != null) 'normalized_morpheme': normalizedMorpheme,
      if (morphemeType != null) 'morpheme_type': morphemeType,
      if (meaningsJson != null) 'meanings_json': meaningsJson,
      if (examplesJson != null) 'examples_json': examplesJson,
      if (source != null) 'source': source,
      if (license != null) 'license': license,
    });
  }

  MorphemeEntriesCompanion copyWith(
      {Value<int>? id,
      Value<String>? morpheme,
      Value<String>? normalizedMorpheme,
      Value<String>? morphemeType,
      Value<String>? meaningsJson,
      Value<String?>? examplesJson,
      Value<String?>? source,
      Value<String?>? license}) {
    return MorphemeEntriesCompanion(
      id: id ?? this.id,
      morpheme: morpheme ?? this.morpheme,
      normalizedMorpheme: normalizedMorpheme ?? this.normalizedMorpheme,
      morphemeType: morphemeType ?? this.morphemeType,
      meaningsJson: meaningsJson ?? this.meaningsJson,
      examplesJson: examplesJson ?? this.examplesJson,
      source: source ?? this.source,
      license: license ?? this.license,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (morpheme.present) {
      map['morpheme'] = Variable<String>(morpheme.value);
    }
    if (normalizedMorpheme.present) {
      map['normalized_morpheme'] = Variable<String>(normalizedMorpheme.value);
    }
    if (morphemeType.present) {
      map['morpheme_type'] = Variable<String>(morphemeType.value);
    }
    if (meaningsJson.present) {
      map['meanings_json'] = Variable<String>(meaningsJson.value);
    }
    if (examplesJson.present) {
      map['examples_json'] = Variable<String>(examplesJson.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (license.present) {
      map['license'] = Variable<String>(license.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MorphemeEntriesCompanion(')
          ..write('id: $id, ')
          ..write('morpheme: $morpheme, ')
          ..write('normalizedMorpheme: $normalizedMorpheme, ')
          ..write('morphemeType: $morphemeType, ')
          ..write('meaningsJson: $meaningsJson, ')
          ..write('examplesJson: $examplesJson, ')
          ..write('source: $source, ')
          ..write('license: $license')
          ..write(')'))
        .toString();
  }
}

class $WordMorphemeMatchesTable extends WordMorphemeMatches
    with TableInfo<$WordMorphemeMatchesTable, WordMorphemeMatche> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordMorphemeMatchesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _morphemeMeta =
      const VerificationMeta('morpheme');
  @override
  late final GeneratedColumn<String> morpheme = GeneratedColumn<String>(
      'morpheme', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _normalizedMorphemeMeta =
      const VerificationMeta('normalizedMorpheme');
  @override
  late final GeneratedColumn<String> normalizedMorpheme =
      GeneratedColumn<String>('normalized_morpheme', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _morphemeTypeMeta =
      const VerificationMeta('morphemeType');
  @override
  late final GeneratedColumn<String> morphemeType = GeneratedColumn<String>(
      'morpheme_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<String> position = GeneratedColumn<String>(
      'position', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _meaningsJsonMeta =
      const VerificationMeta('meaningsJson');
  @override
  late final GeneratedColumn<String> meaningsJson = GeneratedColumn<String>(
      'meanings_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _matchMethodMeta =
      const VerificationMeta('matchMethod');
  @override
  late final GeneratedColumn<String> matchMethod = GeneratedColumn<String>(
      'match_method', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _confidenceMeta =
      const VerificationMeta('confidence');
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
      'confidence', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        word,
        morpheme,
        normalizedMorpheme,
        morphemeType,
        position,
        meaningsJson,
        matchMethod,
        confidence,
        source
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word_morpheme_matches';
  @override
  VerificationContext validateIntegrity(Insertable<WordMorphemeMatche> instance,
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
    if (data.containsKey('morpheme')) {
      context.handle(_morphemeMeta,
          morpheme.isAcceptableOrUnknown(data['morpheme']!, _morphemeMeta));
    } else if (isInserting) {
      context.missing(_morphemeMeta);
    }
    if (data.containsKey('normalized_morpheme')) {
      context.handle(
          _normalizedMorphemeMeta,
          normalizedMorpheme.isAcceptableOrUnknown(
              data['normalized_morpheme']!, _normalizedMorphemeMeta));
    } else if (isInserting) {
      context.missing(_normalizedMorphemeMeta);
    }
    if (data.containsKey('morpheme_type')) {
      context.handle(
          _morphemeTypeMeta,
          morphemeType.isAcceptableOrUnknown(
              data['morpheme_type']!, _morphemeTypeMeta));
    } else if (isInserting) {
      context.missing(_morphemeTypeMeta);
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('meanings_json')) {
      context.handle(
          _meaningsJsonMeta,
          meaningsJson.isAcceptableOrUnknown(
              data['meanings_json']!, _meaningsJsonMeta));
    } else if (isInserting) {
      context.missing(_meaningsJsonMeta);
    }
    if (data.containsKey('match_method')) {
      context.handle(
          _matchMethodMeta,
          matchMethod.isAcceptableOrUnknown(
              data['match_method']!, _matchMethodMeta));
    }
    if (data.containsKey('confidence')) {
      context.handle(
          _confidenceMeta,
          confidence.isAcceptableOrUnknown(
              data['confidence']!, _confidenceMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WordMorphemeMatche map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordMorphemeMatche(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      word: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}word'])!,
      morpheme: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}morpheme'])!,
      normalizedMorpheme: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}normalized_morpheme'])!,
      morphemeType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}morpheme_type'])!,
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}position'])!,
      meaningsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meanings_json'])!,
      matchMethod: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}match_method']),
      confidence: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}confidence']),
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source']),
    );
  }

  @override
  $WordMorphemeMatchesTable createAlias(String alias) {
    return $WordMorphemeMatchesTable(attachedDatabase, alias);
  }
}

class WordMorphemeMatche extends DataClass
    implements Insertable<WordMorphemeMatche> {
  final int id;
  final String word;
  final String morpheme;
  final String normalizedMorpheme;
  final String morphemeType;
  final String position;
  final String meaningsJson;
  final String? matchMethod;
  final double? confidence;
  final String? source;
  const WordMorphemeMatche(
      {required this.id,
      required this.word,
      required this.morpheme,
      required this.normalizedMorpheme,
      required this.morphemeType,
      required this.position,
      required this.meaningsJson,
      this.matchMethod,
      this.confidence,
      this.source});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['word'] = Variable<String>(word);
    map['morpheme'] = Variable<String>(morpheme);
    map['normalized_morpheme'] = Variable<String>(normalizedMorpheme);
    map['morpheme_type'] = Variable<String>(morphemeType);
    map['position'] = Variable<String>(position);
    map['meanings_json'] = Variable<String>(meaningsJson);
    if (!nullToAbsent || matchMethod != null) {
      map['match_method'] = Variable<String>(matchMethod);
    }
    if (!nullToAbsent || confidence != null) {
      map['confidence'] = Variable<double>(confidence);
    }
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    return map;
  }

  WordMorphemeMatchesCompanion toCompanion(bool nullToAbsent) {
    return WordMorphemeMatchesCompanion(
      id: Value(id),
      word: Value(word),
      morpheme: Value(morpheme),
      normalizedMorpheme: Value(normalizedMorpheme),
      morphemeType: Value(morphemeType),
      position: Value(position),
      meaningsJson: Value(meaningsJson),
      matchMethod: matchMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(matchMethod),
      confidence: confidence == null && nullToAbsent
          ? const Value.absent()
          : Value(confidence),
      source:
          source == null && nullToAbsent ? const Value.absent() : Value(source),
    );
  }

  factory WordMorphemeMatche.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordMorphemeMatche(
      id: serializer.fromJson<int>(json['id']),
      word: serializer.fromJson<String>(json['word']),
      morpheme: serializer.fromJson<String>(json['morpheme']),
      normalizedMorpheme:
          serializer.fromJson<String>(json['normalizedMorpheme']),
      morphemeType: serializer.fromJson<String>(json['morphemeType']),
      position: serializer.fromJson<String>(json['position']),
      meaningsJson: serializer.fromJson<String>(json['meaningsJson']),
      matchMethod: serializer.fromJson<String?>(json['matchMethod']),
      confidence: serializer.fromJson<double?>(json['confidence']),
      source: serializer.fromJson<String?>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'word': serializer.toJson<String>(word),
      'morpheme': serializer.toJson<String>(morpheme),
      'normalizedMorpheme': serializer.toJson<String>(normalizedMorpheme),
      'morphemeType': serializer.toJson<String>(morphemeType),
      'position': serializer.toJson<String>(position),
      'meaningsJson': serializer.toJson<String>(meaningsJson),
      'matchMethod': serializer.toJson<String?>(matchMethod),
      'confidence': serializer.toJson<double?>(confidence),
      'source': serializer.toJson<String?>(source),
    };
  }

  WordMorphemeMatche copyWith(
          {int? id,
          String? word,
          String? morpheme,
          String? normalizedMorpheme,
          String? morphemeType,
          String? position,
          String? meaningsJson,
          Value<String?> matchMethod = const Value.absent(),
          Value<double?> confidence = const Value.absent(),
          Value<String?> source = const Value.absent()}) =>
      WordMorphemeMatche(
        id: id ?? this.id,
        word: word ?? this.word,
        morpheme: morpheme ?? this.morpheme,
        normalizedMorpheme: normalizedMorpheme ?? this.normalizedMorpheme,
        morphemeType: morphemeType ?? this.morphemeType,
        position: position ?? this.position,
        meaningsJson: meaningsJson ?? this.meaningsJson,
        matchMethod: matchMethod.present ? matchMethod.value : this.matchMethod,
        confidence: confidence.present ? confidence.value : this.confidence,
        source: source.present ? source.value : this.source,
      );
  WordMorphemeMatche copyWithCompanion(WordMorphemeMatchesCompanion data) {
    return WordMorphemeMatche(
      id: data.id.present ? data.id.value : this.id,
      word: data.word.present ? data.word.value : this.word,
      morpheme: data.morpheme.present ? data.morpheme.value : this.morpheme,
      normalizedMorpheme: data.normalizedMorpheme.present
          ? data.normalizedMorpheme.value
          : this.normalizedMorpheme,
      morphemeType: data.morphemeType.present
          ? data.morphemeType.value
          : this.morphemeType,
      position: data.position.present ? data.position.value : this.position,
      meaningsJson: data.meaningsJson.present
          ? data.meaningsJson.value
          : this.meaningsJson,
      matchMethod:
          data.matchMethod.present ? data.matchMethod.value : this.matchMethod,
      confidence:
          data.confidence.present ? data.confidence.value : this.confidence,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordMorphemeMatche(')
          ..write('id: $id, ')
          ..write('word: $word, ')
          ..write('morpheme: $morpheme, ')
          ..write('normalizedMorpheme: $normalizedMorpheme, ')
          ..write('morphemeType: $morphemeType, ')
          ..write('position: $position, ')
          ..write('meaningsJson: $meaningsJson, ')
          ..write('matchMethod: $matchMethod, ')
          ..write('confidence: $confidence, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, word, morpheme, normalizedMorpheme,
      morphemeType, position, meaningsJson, matchMethod, confidence, source);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordMorphemeMatche &&
          other.id == this.id &&
          other.word == this.word &&
          other.morpheme == this.morpheme &&
          other.normalizedMorpheme == this.normalizedMorpheme &&
          other.morphemeType == this.morphemeType &&
          other.position == this.position &&
          other.meaningsJson == this.meaningsJson &&
          other.matchMethod == this.matchMethod &&
          other.confidence == this.confidence &&
          other.source == this.source);
}

class WordMorphemeMatchesCompanion extends UpdateCompanion<WordMorphemeMatche> {
  final Value<int> id;
  final Value<String> word;
  final Value<String> morpheme;
  final Value<String> normalizedMorpheme;
  final Value<String> morphemeType;
  final Value<String> position;
  final Value<String> meaningsJson;
  final Value<String?> matchMethod;
  final Value<double?> confidence;
  final Value<String?> source;
  const WordMorphemeMatchesCompanion({
    this.id = const Value.absent(),
    this.word = const Value.absent(),
    this.morpheme = const Value.absent(),
    this.normalizedMorpheme = const Value.absent(),
    this.morphemeType = const Value.absent(),
    this.position = const Value.absent(),
    this.meaningsJson = const Value.absent(),
    this.matchMethod = const Value.absent(),
    this.confidence = const Value.absent(),
    this.source = const Value.absent(),
  });
  WordMorphemeMatchesCompanion.insert({
    this.id = const Value.absent(),
    required String word,
    required String morpheme,
    required String normalizedMorpheme,
    required String morphemeType,
    required String position,
    required String meaningsJson,
    this.matchMethod = const Value.absent(),
    this.confidence = const Value.absent(),
    this.source = const Value.absent(),
  })  : word = Value(word),
        morpheme = Value(morpheme),
        normalizedMorpheme = Value(normalizedMorpheme),
        morphemeType = Value(morphemeType),
        position = Value(position),
        meaningsJson = Value(meaningsJson);
  static Insertable<WordMorphemeMatche> custom({
    Expression<int>? id,
    Expression<String>? word,
    Expression<String>? morpheme,
    Expression<String>? normalizedMorpheme,
    Expression<String>? morphemeType,
    Expression<String>? position,
    Expression<String>? meaningsJson,
    Expression<String>? matchMethod,
    Expression<double>? confidence,
    Expression<String>? source,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (word != null) 'word': word,
      if (morpheme != null) 'morpheme': morpheme,
      if (normalizedMorpheme != null) 'normalized_morpheme': normalizedMorpheme,
      if (morphemeType != null) 'morpheme_type': morphemeType,
      if (position != null) 'position': position,
      if (meaningsJson != null) 'meanings_json': meaningsJson,
      if (matchMethod != null) 'match_method': matchMethod,
      if (confidence != null) 'confidence': confidence,
      if (source != null) 'source': source,
    });
  }

  WordMorphemeMatchesCompanion copyWith(
      {Value<int>? id,
      Value<String>? word,
      Value<String>? morpheme,
      Value<String>? normalizedMorpheme,
      Value<String>? morphemeType,
      Value<String>? position,
      Value<String>? meaningsJson,
      Value<String?>? matchMethod,
      Value<double?>? confidence,
      Value<String?>? source}) {
    return WordMorphemeMatchesCompanion(
      id: id ?? this.id,
      word: word ?? this.word,
      morpheme: morpheme ?? this.morpheme,
      normalizedMorpheme: normalizedMorpheme ?? this.normalizedMorpheme,
      morphemeType: morphemeType ?? this.morphemeType,
      position: position ?? this.position,
      meaningsJson: meaningsJson ?? this.meaningsJson,
      matchMethod: matchMethod ?? this.matchMethod,
      confidence: confidence ?? this.confidence,
      source: source ?? this.source,
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
    if (morpheme.present) {
      map['morpheme'] = Variable<String>(morpheme.value);
    }
    if (normalizedMorpheme.present) {
      map['normalized_morpheme'] = Variable<String>(normalizedMorpheme.value);
    }
    if (morphemeType.present) {
      map['morpheme_type'] = Variable<String>(morphemeType.value);
    }
    if (position.present) {
      map['position'] = Variable<String>(position.value);
    }
    if (meaningsJson.present) {
      map['meanings_json'] = Variable<String>(meaningsJson.value);
    }
    if (matchMethod.present) {
      map['match_method'] = Variable<String>(matchMethod.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordMorphemeMatchesCompanion(')
          ..write('id: $id, ')
          ..write('word: $word, ')
          ..write('morpheme: $morpheme, ')
          ..write('normalizedMorpheme: $normalizedMorpheme, ')
          ..write('morphemeType: $morphemeType, ')
          ..write('position: $position, ')
          ..write('meaningsJson: $meaningsJson, ')
          ..write('matchMethod: $matchMethod, ')
          ..write('confidence: $confidence, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }
}

class $AudioFileCacheTable extends AudioFileCache
    with TableInfo<$AudioFileCacheTable, AudioFileCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AudioFileCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _audioIdMeta =
      const VerificationMeta('audioId');
  @override
  late final GeneratedColumn<String> audioId = GeneratedColumn<String>(
      'audio_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _localPathMeta =
      const VerificationMeta('localPath');
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
      'local_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bytesMeta = const VerificationMeta('bytes');
  @override
  late final GeneratedColumn<int> bytes = GeneratedColumn<int>(
      'bytes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<int> cachedAt = GeneratedColumn<int>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _lastPlayedAtMeta =
      const VerificationMeta('lastPlayedAt');
  @override
  late final GeneratedColumn<int> lastPlayedAt = GeneratedColumn<int>(
      'last_played_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _cachedChecksumMeta =
      const VerificationMeta('cachedChecksum');
  @override
  late final GeneratedColumn<String> cachedChecksum = GeneratedColumn<String>(
      'cached_checksum', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _cachedContentVersionMeta =
      const VerificationMeta('cachedContentVersion');
  @override
  late final GeneratedColumn<String> cachedContentVersion =
      GeneratedColumn<String>('cached_content_version', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        audioId,
        localPath,
        bytes,
        cachedAt,
        lastPlayedAt,
        cachedChecksum,
        cachedContentVersion
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audio_file_cache';
  @override
  VerificationContext validateIntegrity(Insertable<AudioFileCacheData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('audio_id')) {
      context.handle(_audioIdMeta,
          audioId.isAcceptableOrUnknown(data['audio_id']!, _audioIdMeta));
    } else if (isInserting) {
      context.missing(_audioIdMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(_localPathMeta,
          localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta));
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('bytes')) {
      context.handle(
          _bytesMeta, bytes.isAcceptableOrUnknown(data['bytes']!, _bytesMeta));
    } else if (isInserting) {
      context.missing(_bytesMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    if (data.containsKey('last_played_at')) {
      context.handle(
          _lastPlayedAtMeta,
          lastPlayedAt.isAcceptableOrUnknown(
              data['last_played_at']!, _lastPlayedAtMeta));
    }
    if (data.containsKey('cached_checksum')) {
      context.handle(
          _cachedChecksumMeta,
          cachedChecksum.isAcceptableOrUnknown(
              data['cached_checksum']!, _cachedChecksumMeta));
    }
    if (data.containsKey('cached_content_version')) {
      context.handle(
          _cachedContentVersionMeta,
          cachedContentVersion.isAcceptableOrUnknown(
              data['cached_content_version']!, _cachedContentVersionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {audioId};
  @override
  AudioFileCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AudioFileCacheData(
      audioId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}audio_id'])!,
      localPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_path'])!,
      bytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}bytes'])!,
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cached_at'])!,
      lastPlayedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_played_at']),
      cachedChecksum: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cached_checksum']),
      cachedContentVersion: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}cached_content_version']),
    );
  }

  @override
  $AudioFileCacheTable createAlias(String alias) {
    return $AudioFileCacheTable(attachedDatabase, alias);
  }
}

class AudioFileCacheData extends DataClass
    implements Insertable<AudioFileCacheData> {
  /// = audio_assets.id (24-hex sha256, includes audio_version).
  final String audioId;

  /// Absolute path to the cached binary on the device filesystem.
  final String localPath;

  /// Byte size of the cached file. Required for capacity calculation.
  final int bytes;

  /// When this row was first written. UTC epoch ms.
  final int cachedAt;

  /// When the audio was last played. UTC epoch ms. Nullable means
  /// "downloaded but never played" — also a valid state.
  final int? lastPlayedAt;

  /// SHA-256 of the binary as reported by `audio_assets.checksum_sha256`
  /// at download time. Used to detect server-side replacements.
  final String? cachedChecksum;

  /// content_version of the manifest package the audio was sourced from.
  /// Used by §7.4.1 trigger 2 for orphan detection.
  final String? cachedContentVersion;
  const AudioFileCacheData(
      {required this.audioId,
      required this.localPath,
      required this.bytes,
      required this.cachedAt,
      this.lastPlayedAt,
      this.cachedChecksum,
      this.cachedContentVersion});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['audio_id'] = Variable<String>(audioId);
    map['local_path'] = Variable<String>(localPath);
    map['bytes'] = Variable<int>(bytes);
    map['cached_at'] = Variable<int>(cachedAt);
    if (!nullToAbsent || lastPlayedAt != null) {
      map['last_played_at'] = Variable<int>(lastPlayedAt);
    }
    if (!nullToAbsent || cachedChecksum != null) {
      map['cached_checksum'] = Variable<String>(cachedChecksum);
    }
    if (!nullToAbsent || cachedContentVersion != null) {
      map['cached_content_version'] = Variable<String>(cachedContentVersion);
    }
    return map;
  }

  AudioFileCacheCompanion toCompanion(bool nullToAbsent) {
    return AudioFileCacheCompanion(
      audioId: Value(audioId),
      localPath: Value(localPath),
      bytes: Value(bytes),
      cachedAt: Value(cachedAt),
      lastPlayedAt: lastPlayedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPlayedAt),
      cachedChecksum: cachedChecksum == null && nullToAbsent
          ? const Value.absent()
          : Value(cachedChecksum),
      cachedContentVersion: cachedContentVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(cachedContentVersion),
    );
  }

  factory AudioFileCacheData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AudioFileCacheData(
      audioId: serializer.fromJson<String>(json['audioId']),
      localPath: serializer.fromJson<String>(json['localPath']),
      bytes: serializer.fromJson<int>(json['bytes']),
      cachedAt: serializer.fromJson<int>(json['cachedAt']),
      lastPlayedAt: serializer.fromJson<int?>(json['lastPlayedAt']),
      cachedChecksum: serializer.fromJson<String?>(json['cachedChecksum']),
      cachedContentVersion:
          serializer.fromJson<String?>(json['cachedContentVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'audioId': serializer.toJson<String>(audioId),
      'localPath': serializer.toJson<String>(localPath),
      'bytes': serializer.toJson<int>(bytes),
      'cachedAt': serializer.toJson<int>(cachedAt),
      'lastPlayedAt': serializer.toJson<int?>(lastPlayedAt),
      'cachedChecksum': serializer.toJson<String?>(cachedChecksum),
      'cachedContentVersion': serializer.toJson<String?>(cachedContentVersion),
    };
  }

  AudioFileCacheData copyWith(
          {String? audioId,
          String? localPath,
          int? bytes,
          int? cachedAt,
          Value<int?> lastPlayedAt = const Value.absent(),
          Value<String?> cachedChecksum = const Value.absent(),
          Value<String?> cachedContentVersion = const Value.absent()}) =>
      AudioFileCacheData(
        audioId: audioId ?? this.audioId,
        localPath: localPath ?? this.localPath,
        bytes: bytes ?? this.bytes,
        cachedAt: cachedAt ?? this.cachedAt,
        lastPlayedAt:
            lastPlayedAt.present ? lastPlayedAt.value : this.lastPlayedAt,
        cachedChecksum:
            cachedChecksum.present ? cachedChecksum.value : this.cachedChecksum,
        cachedContentVersion: cachedContentVersion.present
            ? cachedContentVersion.value
            : this.cachedContentVersion,
      );
  AudioFileCacheData copyWithCompanion(AudioFileCacheCompanion data) {
    return AudioFileCacheData(
      audioId: data.audioId.present ? data.audioId.value : this.audioId,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      bytes: data.bytes.present ? data.bytes.value : this.bytes,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      lastPlayedAt: data.lastPlayedAt.present
          ? data.lastPlayedAt.value
          : this.lastPlayedAt,
      cachedChecksum: data.cachedChecksum.present
          ? data.cachedChecksum.value
          : this.cachedChecksum,
      cachedContentVersion: data.cachedContentVersion.present
          ? data.cachedContentVersion.value
          : this.cachedContentVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AudioFileCacheData(')
          ..write('audioId: $audioId, ')
          ..write('localPath: $localPath, ')
          ..write('bytes: $bytes, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('cachedChecksum: $cachedChecksum, ')
          ..write('cachedContentVersion: $cachedContentVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(audioId, localPath, bytes, cachedAt,
      lastPlayedAt, cachedChecksum, cachedContentVersion);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AudioFileCacheData &&
          other.audioId == this.audioId &&
          other.localPath == this.localPath &&
          other.bytes == this.bytes &&
          other.cachedAt == this.cachedAt &&
          other.lastPlayedAt == this.lastPlayedAt &&
          other.cachedChecksum == this.cachedChecksum &&
          other.cachedContentVersion == this.cachedContentVersion);
}

class AudioFileCacheCompanion extends UpdateCompanion<AudioFileCacheData> {
  final Value<String> audioId;
  final Value<String> localPath;
  final Value<int> bytes;
  final Value<int> cachedAt;
  final Value<int?> lastPlayedAt;
  final Value<String?> cachedChecksum;
  final Value<String?> cachedContentVersion;
  final Value<int> rowid;
  const AudioFileCacheCompanion({
    this.audioId = const Value.absent(),
    this.localPath = const Value.absent(),
    this.bytes = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
    this.cachedChecksum = const Value.absent(),
    this.cachedContentVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AudioFileCacheCompanion.insert({
    required String audioId,
    required String localPath,
    required int bytes,
    required int cachedAt,
    this.lastPlayedAt = const Value.absent(),
    this.cachedChecksum = const Value.absent(),
    this.cachedContentVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : audioId = Value(audioId),
        localPath = Value(localPath),
        bytes = Value(bytes),
        cachedAt = Value(cachedAt);
  static Insertable<AudioFileCacheData> custom({
    Expression<String>? audioId,
    Expression<String>? localPath,
    Expression<int>? bytes,
    Expression<int>? cachedAt,
    Expression<int>? lastPlayedAt,
    Expression<String>? cachedChecksum,
    Expression<String>? cachedContentVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (audioId != null) 'audio_id': audioId,
      if (localPath != null) 'local_path': localPath,
      if (bytes != null) 'bytes': bytes,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (lastPlayedAt != null) 'last_played_at': lastPlayedAt,
      if (cachedChecksum != null) 'cached_checksum': cachedChecksum,
      if (cachedContentVersion != null)
        'cached_content_version': cachedContentVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AudioFileCacheCompanion copyWith(
      {Value<String>? audioId,
      Value<String>? localPath,
      Value<int>? bytes,
      Value<int>? cachedAt,
      Value<int?>? lastPlayedAt,
      Value<String?>? cachedChecksum,
      Value<String?>? cachedContentVersion,
      Value<int>? rowid}) {
    return AudioFileCacheCompanion(
      audioId: audioId ?? this.audioId,
      localPath: localPath ?? this.localPath,
      bytes: bytes ?? this.bytes,
      cachedAt: cachedAt ?? this.cachedAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      cachedChecksum: cachedChecksum ?? this.cachedChecksum,
      cachedContentVersion: cachedContentVersion ?? this.cachedContentVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (audioId.present) {
      map['audio_id'] = Variable<String>(audioId.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (bytes.present) {
      map['bytes'] = Variable<int>(bytes.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<int>(cachedAt.value);
    }
    if (lastPlayedAt.present) {
      map['last_played_at'] = Variable<int>(lastPlayedAt.value);
    }
    if (cachedChecksum.present) {
      map['cached_checksum'] = Variable<String>(cachedChecksum.value);
    }
    if (cachedContentVersion.present) {
      map['cached_content_version'] =
          Variable<String>(cachedContentVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AudioFileCacheCompanion(')
          ..write('audioId: $audioId, ')
          ..write('localPath: $localPath, ')
          ..write('bytes: $bytes, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('cachedChecksum: $cachedChecksum, ')
          ..write('cachedContentVersion: $cachedContentVersion, ')
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
  late final $PresetWordbooksTable presetWordbooks =
      $PresetWordbooksTable(this);
  late final $WordEntriesTable wordEntries = $WordEntriesTable(this);
  late final $WordBookAssignmentsTable wordBookAssignments =
      $WordBookAssignmentsTable(this);
  late final $ExampleSentencesTable exampleSentences =
      $ExampleSentencesTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $ReviewRecordsTable reviewRecords = $ReviewRecordsTable(this);
  late final $WordFormsTable wordForms = $WordFormsTable(this);
  late final $WordRelationsTable wordRelations = $WordRelationsTable(this);
  late final $WordPhrasesTable wordPhrases = $WordPhrasesTable(this);
  late final $MorphemeEntriesTable morphemeEntries =
      $MorphemeEntriesTable(this);
  late final $WordMorphemeMatchesTable wordMorphemeMatches =
      $WordMorphemeMatchesTable(this);
  late final $AudioFileCacheTable audioFileCache = $AudioFileCacheTable(this);
  late final Index idxCardStatesDue = Index('idx_card_states_due',
      'CREATE INDEX idx_card_states_due ON card_states (due)');
  late final Index idxCardStatesState = Index('idx_card_states_state',
      'CREATE INDEX idx_card_states_state ON card_states (state)');
  late final Index idxReviewLogsWordId = Index('idx_review_logs_word_id',
      'CREATE INDEX idx_review_logs_word_id ON review_logs (word_id)');
  late final Index idxReviewLogsReviewTime = Index(
      'idx_review_logs_review_time',
      'CREATE INDEX idx_review_logs_review_time ON review_logs (review_time_utc)');
  late final Index idxWbaBookOrder = Index('idx_wba_book_order',
      'CREATE INDEX idx_wba_book_order ON word_book_assignments (book_slug, sort_order)');
  late final Index idxEsWordOrder = Index('idx_es_word_order',
      'CREATE UNIQUE INDEX idx_es_word_order ON example_sentences (word_id, sort_order)');
  late final Index idxEsStableId = Index('idx_es_stable_id',
      'CREATE UNIQUE INDEX idx_es_stable_id ON example_sentences (stable_id)');
  late final Index idxWordFormsWord = Index('idx_word_forms_word',
      'CREATE INDEX idx_word_forms_word ON word_forms (word)');
  late final Index idxWordRelationsWord = Index('idx_word_relations_word',
      'CREATE INDEX idx_word_relations_word ON word_relations (word)');
  late final Index idxWordPhrasesWord = Index('idx_word_phrases_word',
      'CREATE INDEX idx_word_phrases_word ON word_phrases (word)');
  late final Index idxMorphemeEntriesNorm = Index('idx_morpheme_entries_norm',
      'CREATE INDEX idx_morpheme_entries_norm ON morpheme_entries (normalized_morpheme)');
  late final Index idxWordMorphemeMatchesWord = Index(
      'idx_word_morpheme_matches_word',
      'CREATE INDEX idx_word_morpheme_matches_word ON word_morpheme_matches (word)');
  late final Index idxAudioFileCacheLastPlayed = Index(
      'idx_audio_file_cache_last_played',
      'CREATE INDEX idx_audio_file_cache_last_played ON audio_file_cache (last_played_at)');
  late final Index idxAudioFileCacheContentVersion = Index(
      'idx_audio_file_cache_content_version',
      'CREATE INDEX idx_audio_file_cache_content_version ON audio_file_cache (cached_content_version)');
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
        presetWordbooks,
        wordEntries,
        wordBookAssignments,
        exampleSentences,
        sessions,
        reviewRecords,
        wordForms,
        wordRelations,
        wordPhrases,
        morphemeEntries,
        wordMorphemeMatches,
        audioFileCache,
        idxCardStatesDue,
        idxCardStatesState,
        idxReviewLogsWordId,
        idxReviewLogsReviewTime,
        idxWbaBookOrder,
        idxEsWordOrder,
        idxEsStableId,
        idxWordFormsWord,
        idxWordRelationsWord,
        idxWordPhrasesWord,
        idxMorphemeEntriesNorm,
        idxWordMorphemeMatchesWord,
        idxAudioFileCacheLastPlayed,
        idxAudioFileCacheContentVersion
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
  Value<String?> sessionId,
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
  Value<String?> sessionId,
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

  ColumnFilters<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnFilters(column));
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

  ColumnOrderings<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnOrderings(column));
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

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);
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
            Value<String?> sessionId = const Value.absent(),
          }) =>
              WordRecordsCompanion(
            id: id,
            wordId: wordId,
            bookId: bookId,
            studyType: studyType,
            actionResult: actionResult,
            createdAt: createdAt,
            synced: synced,
            sessionId: sessionId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String wordId,
            required String bookId,
            Value<String> studyType = const Value.absent(),
            required String actionResult,
            required String createdAt,
            Value<int> synced = const Value.absent(),
            Value<String?> sessionId = const Value.absent(),
          }) =>
              WordRecordsCompanion.insert(
            id: id,
            wordId: wordId,
            bookId: bookId,
            studyType: studyType,
            actionResult: actionResult,
            createdAt: createdAt,
            synced: synced,
            sessionId: sessionId,
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
typedef $$PresetWordbooksTableCreateCompanionBuilder = PresetWordbooksCompanion
    Function({
  required String slug,
  required String displayName,
  Value<int> totalWords,
  Value<String?> description,
  Value<int> sortOrder,
  Value<String?> contentVersion,
  Value<int> rowid,
});
typedef $$PresetWordbooksTableUpdateCompanionBuilder = PresetWordbooksCompanion
    Function({
  Value<String> slug,
  Value<String> displayName,
  Value<int> totalWords,
  Value<String?> description,
  Value<int> sortOrder,
  Value<String?> contentVersion,
  Value<int> rowid,
});

class $$PresetWordbooksTableFilterComposer
    extends Composer<_$AppDatabase, $PresetWordbooksTable> {
  $$PresetWordbooksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get slug => $composableBuilder(
      column: $table.slug, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalWords => $composableBuilder(
      column: $table.totalWords, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contentVersion => $composableBuilder(
      column: $table.contentVersion,
      builder: (column) => ColumnFilters(column));
}

class $$PresetWordbooksTableOrderingComposer
    extends Composer<_$AppDatabase, $PresetWordbooksTable> {
  $$PresetWordbooksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get slug => $composableBuilder(
      column: $table.slug, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalWords => $composableBuilder(
      column: $table.totalWords, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contentVersion => $composableBuilder(
      column: $table.contentVersion,
      builder: (column) => ColumnOrderings(column));
}

class $$PresetWordbooksTableAnnotationComposer
    extends Composer<_$AppDatabase, $PresetWordbooksTable> {
  $$PresetWordbooksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<int> get totalWords => $composableBuilder(
      column: $table.totalWords, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get contentVersion => $composableBuilder(
      column: $table.contentVersion, builder: (column) => column);
}

class $$PresetWordbooksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PresetWordbooksTable,
    PresetWordbook,
    $$PresetWordbooksTableFilterComposer,
    $$PresetWordbooksTableOrderingComposer,
    $$PresetWordbooksTableAnnotationComposer,
    $$PresetWordbooksTableCreateCompanionBuilder,
    $$PresetWordbooksTableUpdateCompanionBuilder,
    (
      PresetWordbook,
      BaseReferences<_$AppDatabase, $PresetWordbooksTable, PresetWordbook>
    ),
    PresetWordbook,
    PrefetchHooks Function()> {
  $$PresetWordbooksTableTableManager(
      _$AppDatabase db, $PresetWordbooksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PresetWordbooksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PresetWordbooksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PresetWordbooksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> slug = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<int> totalWords = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<String?> contentVersion = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PresetWordbooksCompanion(
            slug: slug,
            displayName: displayName,
            totalWords: totalWords,
            description: description,
            sortOrder: sortOrder,
            contentVersion: contentVersion,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String slug,
            required String displayName,
            Value<int> totalWords = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<String?> contentVersion = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PresetWordbooksCompanion.insert(
            slug: slug,
            displayName: displayName,
            totalWords: totalWords,
            description: description,
            sortOrder: sortOrder,
            contentVersion: contentVersion,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PresetWordbooksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PresetWordbooksTable,
    PresetWordbook,
    $$PresetWordbooksTableFilterComposer,
    $$PresetWordbooksTableOrderingComposer,
    $$PresetWordbooksTableAnnotationComposer,
    $$PresetWordbooksTableCreateCompanionBuilder,
    $$PresetWordbooksTableUpdateCompanionBuilder,
    (
      PresetWordbook,
      BaseReferences<_$AppDatabase, $PresetWordbooksTable, PresetWordbook>
    ),
    PresetWordbook,
    PrefetchHooks Function()>;
typedef $$WordEntriesTableCreateCompanionBuilder = WordEntriesCompanion
    Function({
  required String wordId,
  required String wordText,
  Value<String?> phonetic,
  required String meaning,
  Value<String?> translation,
  Value<String?> definition,
  Value<int> frequencyRank,
  Value<String?> wordForms,
  required int importedAt,
  Value<int> rowid,
});
typedef $$WordEntriesTableUpdateCompanionBuilder = WordEntriesCompanion
    Function({
  Value<String> wordId,
  Value<String> wordText,
  Value<String?> phonetic,
  Value<String> meaning,
  Value<String?> translation,
  Value<String?> definition,
  Value<int> frequencyRank,
  Value<String?> wordForms,
  Value<int> importedAt,
  Value<int> rowid,
});

class $$WordEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $WordEntriesTable> {
  $$WordEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get wordId => $composableBuilder(
      column: $table.wordId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get wordText => $composableBuilder(
      column: $table.wordText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phonetic => $composableBuilder(
      column: $table.phonetic, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get meaning => $composableBuilder(
      column: $table.meaning, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get translation => $composableBuilder(
      column: $table.translation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get definition => $composableBuilder(
      column: $table.definition, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get frequencyRank => $composableBuilder(
      column: $table.frequencyRank, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get wordForms => $composableBuilder(
      column: $table.wordForms, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get importedAt => $composableBuilder(
      column: $table.importedAt, builder: (column) => ColumnFilters(column));
}

class $$WordEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $WordEntriesTable> {
  $$WordEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get wordId => $composableBuilder(
      column: $table.wordId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get wordText => $composableBuilder(
      column: $table.wordText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phonetic => $composableBuilder(
      column: $table.phonetic, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get meaning => $composableBuilder(
      column: $table.meaning, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get translation => $composableBuilder(
      column: $table.translation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get definition => $composableBuilder(
      column: $table.definition, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get frequencyRank => $composableBuilder(
      column: $table.frequencyRank,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get wordForms => $composableBuilder(
      column: $table.wordForms, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get importedAt => $composableBuilder(
      column: $table.importedAt, builder: (column) => ColumnOrderings(column));
}

class $$WordEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordEntriesTable> {
  $$WordEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get wordId =>
      $composableBuilder(column: $table.wordId, builder: (column) => column);

  GeneratedColumn<String> get wordText =>
      $composableBuilder(column: $table.wordText, builder: (column) => column);

  GeneratedColumn<String> get phonetic =>
      $composableBuilder(column: $table.phonetic, builder: (column) => column);

  GeneratedColumn<String> get meaning =>
      $composableBuilder(column: $table.meaning, builder: (column) => column);

  GeneratedColumn<String> get translation => $composableBuilder(
      column: $table.translation, builder: (column) => column);

  GeneratedColumn<String> get definition => $composableBuilder(
      column: $table.definition, builder: (column) => column);

  GeneratedColumn<int> get frequencyRank => $composableBuilder(
      column: $table.frequencyRank, builder: (column) => column);

  GeneratedColumn<String> get wordForms =>
      $composableBuilder(column: $table.wordForms, builder: (column) => column);

  GeneratedColumn<int> get importedAt => $composableBuilder(
      column: $table.importedAt, builder: (column) => column);
}

class $$WordEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WordEntriesTable,
    WordEntry,
    $$WordEntriesTableFilterComposer,
    $$WordEntriesTableOrderingComposer,
    $$WordEntriesTableAnnotationComposer,
    $$WordEntriesTableCreateCompanionBuilder,
    $$WordEntriesTableUpdateCompanionBuilder,
    (WordEntry, BaseReferences<_$AppDatabase, $WordEntriesTable, WordEntry>),
    WordEntry,
    PrefetchHooks Function()> {
  $$WordEntriesTableTableManager(_$AppDatabase db, $WordEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> wordId = const Value.absent(),
            Value<String> wordText = const Value.absent(),
            Value<String?> phonetic = const Value.absent(),
            Value<String> meaning = const Value.absent(),
            Value<String?> translation = const Value.absent(),
            Value<String?> definition = const Value.absent(),
            Value<int> frequencyRank = const Value.absent(),
            Value<String?> wordForms = const Value.absent(),
            Value<int> importedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WordEntriesCompanion(
            wordId: wordId,
            wordText: wordText,
            phonetic: phonetic,
            meaning: meaning,
            translation: translation,
            definition: definition,
            frequencyRank: frequencyRank,
            wordForms: wordForms,
            importedAt: importedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String wordId,
            required String wordText,
            Value<String?> phonetic = const Value.absent(),
            required String meaning,
            Value<String?> translation = const Value.absent(),
            Value<String?> definition = const Value.absent(),
            Value<int> frequencyRank = const Value.absent(),
            Value<String?> wordForms = const Value.absent(),
            required int importedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              WordEntriesCompanion.insert(
            wordId: wordId,
            wordText: wordText,
            phonetic: phonetic,
            meaning: meaning,
            translation: translation,
            definition: definition,
            frequencyRank: frequencyRank,
            wordForms: wordForms,
            importedAt: importedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WordEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WordEntriesTable,
    WordEntry,
    $$WordEntriesTableFilterComposer,
    $$WordEntriesTableOrderingComposer,
    $$WordEntriesTableAnnotationComposer,
    $$WordEntriesTableCreateCompanionBuilder,
    $$WordEntriesTableUpdateCompanionBuilder,
    (WordEntry, BaseReferences<_$AppDatabase, $WordEntriesTable, WordEntry>),
    WordEntry,
    PrefetchHooks Function()>;
typedef $$WordBookAssignmentsTableCreateCompanionBuilder
    = WordBookAssignmentsCompanion Function({
  required String wordId,
  required String bookSlug,
  Value<int> sortOrder,
  Value<String?> sourceKey,
  Value<int> rowid,
});
typedef $$WordBookAssignmentsTableUpdateCompanionBuilder
    = WordBookAssignmentsCompanion Function({
  Value<String> wordId,
  Value<String> bookSlug,
  Value<int> sortOrder,
  Value<String?> sourceKey,
  Value<int> rowid,
});

class $$WordBookAssignmentsTableFilterComposer
    extends Composer<_$AppDatabase, $WordBookAssignmentsTable> {
  $$WordBookAssignmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get wordId => $composableBuilder(
      column: $table.wordId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bookSlug => $composableBuilder(
      column: $table.bookSlug, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceKey => $composableBuilder(
      column: $table.sourceKey, builder: (column) => ColumnFilters(column));
}

class $$WordBookAssignmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $WordBookAssignmentsTable> {
  $$WordBookAssignmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get wordId => $composableBuilder(
      column: $table.wordId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bookSlug => $composableBuilder(
      column: $table.bookSlug, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceKey => $composableBuilder(
      column: $table.sourceKey, builder: (column) => ColumnOrderings(column));
}

class $$WordBookAssignmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordBookAssignmentsTable> {
  $$WordBookAssignmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get wordId =>
      $composableBuilder(column: $table.wordId, builder: (column) => column);

  GeneratedColumn<String> get bookSlug =>
      $composableBuilder(column: $table.bookSlug, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get sourceKey =>
      $composableBuilder(column: $table.sourceKey, builder: (column) => column);
}

class $$WordBookAssignmentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WordBookAssignmentsTable,
    WordBookAssignment,
    $$WordBookAssignmentsTableFilterComposer,
    $$WordBookAssignmentsTableOrderingComposer,
    $$WordBookAssignmentsTableAnnotationComposer,
    $$WordBookAssignmentsTableCreateCompanionBuilder,
    $$WordBookAssignmentsTableUpdateCompanionBuilder,
    (
      WordBookAssignment,
      BaseReferences<_$AppDatabase, $WordBookAssignmentsTable,
          WordBookAssignment>
    ),
    WordBookAssignment,
    PrefetchHooks Function()> {
  $$WordBookAssignmentsTableTableManager(
      _$AppDatabase db, $WordBookAssignmentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordBookAssignmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordBookAssignmentsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordBookAssignmentsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> wordId = const Value.absent(),
            Value<String> bookSlug = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<String?> sourceKey = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WordBookAssignmentsCompanion(
            wordId: wordId,
            bookSlug: bookSlug,
            sortOrder: sortOrder,
            sourceKey: sourceKey,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String wordId,
            required String bookSlug,
            Value<int> sortOrder = const Value.absent(),
            Value<String?> sourceKey = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WordBookAssignmentsCompanion.insert(
            wordId: wordId,
            bookSlug: bookSlug,
            sortOrder: sortOrder,
            sourceKey: sourceKey,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WordBookAssignmentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WordBookAssignmentsTable,
    WordBookAssignment,
    $$WordBookAssignmentsTableFilterComposer,
    $$WordBookAssignmentsTableOrderingComposer,
    $$WordBookAssignmentsTableAnnotationComposer,
    $$WordBookAssignmentsTableCreateCompanionBuilder,
    $$WordBookAssignmentsTableUpdateCompanionBuilder,
    (
      WordBookAssignment,
      BaseReferences<_$AppDatabase, $WordBookAssignmentsTable,
          WordBookAssignment>
    ),
    WordBookAssignment,
    PrefetchHooks Function()>;
typedef $$ExampleSentencesTableCreateCompanionBuilder
    = ExampleSentencesCompanion Function({
  Value<int> id,
  required String wordId,
  Value<String?> stableId,
  required String sense,
  required String en,
  required String cn,
  Value<int> sortOrder,
});
typedef $$ExampleSentencesTableUpdateCompanionBuilder
    = ExampleSentencesCompanion Function({
  Value<int> id,
  Value<String> wordId,
  Value<String?> stableId,
  Value<String> sense,
  Value<String> en,
  Value<String> cn,
  Value<int> sortOrder,
});

class $$ExampleSentencesTableFilterComposer
    extends Composer<_$AppDatabase, $ExampleSentencesTable> {
  $$ExampleSentencesTableFilterComposer({
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

  ColumnFilters<String> get stableId => $composableBuilder(
      column: $table.stableId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sense => $composableBuilder(
      column: $table.sense, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get en => $composableBuilder(
      column: $table.en, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cn => $composableBuilder(
      column: $table.cn, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));
}

class $$ExampleSentencesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExampleSentencesTable> {
  $$ExampleSentencesTableOrderingComposer({
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

  ColumnOrderings<String> get stableId => $composableBuilder(
      column: $table.stableId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sense => $composableBuilder(
      column: $table.sense, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get en => $composableBuilder(
      column: $table.en, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cn => $composableBuilder(
      column: $table.cn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));
}

class $$ExampleSentencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExampleSentencesTable> {
  $$ExampleSentencesTableAnnotationComposer({
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

  GeneratedColumn<String> get stableId =>
      $composableBuilder(column: $table.stableId, builder: (column) => column);

  GeneratedColumn<String> get sense =>
      $composableBuilder(column: $table.sense, builder: (column) => column);

  GeneratedColumn<String> get en =>
      $composableBuilder(column: $table.en, builder: (column) => column);

  GeneratedColumn<String> get cn =>
      $composableBuilder(column: $table.cn, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$ExampleSentencesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ExampleSentencesTable,
    ExampleSentence,
    $$ExampleSentencesTableFilterComposer,
    $$ExampleSentencesTableOrderingComposer,
    $$ExampleSentencesTableAnnotationComposer,
    $$ExampleSentencesTableCreateCompanionBuilder,
    $$ExampleSentencesTableUpdateCompanionBuilder,
    (
      ExampleSentence,
      BaseReferences<_$AppDatabase, $ExampleSentencesTable, ExampleSentence>
    ),
    ExampleSentence,
    PrefetchHooks Function()> {
  $$ExampleSentencesTableTableManager(
      _$AppDatabase db, $ExampleSentencesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExampleSentencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExampleSentencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExampleSentencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> wordId = const Value.absent(),
            Value<String?> stableId = const Value.absent(),
            Value<String> sense = const Value.absent(),
            Value<String> en = const Value.absent(),
            Value<String> cn = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
          }) =>
              ExampleSentencesCompanion(
            id: id,
            wordId: wordId,
            stableId: stableId,
            sense: sense,
            en: en,
            cn: cn,
            sortOrder: sortOrder,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String wordId,
            Value<String?> stableId = const Value.absent(),
            required String sense,
            required String en,
            required String cn,
            Value<int> sortOrder = const Value.absent(),
          }) =>
              ExampleSentencesCompanion.insert(
            id: id,
            wordId: wordId,
            stableId: stableId,
            sense: sense,
            en: en,
            cn: cn,
            sortOrder: sortOrder,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ExampleSentencesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ExampleSentencesTable,
    ExampleSentence,
    $$ExampleSentencesTableFilterComposer,
    $$ExampleSentencesTableOrderingComposer,
    $$ExampleSentencesTableAnnotationComposer,
    $$ExampleSentencesTableCreateCompanionBuilder,
    $$ExampleSentencesTableUpdateCompanionBuilder,
    (
      ExampleSentence,
      BaseReferences<_$AppDatabase, $ExampleSentencesTable, ExampleSentence>
    ),
    ExampleSentence,
    PrefetchHooks Function()>;
typedef $$SessionsTableCreateCompanionBuilder = SessionsCompanion Function({
  required String id,
  required String kind,
  required String startedAt,
  Value<String?> endedAt,
  Value<int?> durationSeconds,
  Value<int> sessionMinutesTarget,
  Value<String?> cachedValidationStatus,
  Value<int> synced,
  Value<int> rowid,
});
typedef $$SessionsTableUpdateCompanionBuilder = SessionsCompanion Function({
  Value<String> id,
  Value<String> kind,
  Value<String> startedAt,
  Value<String?> endedAt,
  Value<int?> durationSeconds,
  Value<int> sessionMinutesTarget,
  Value<String?> cachedValidationStatus,
  Value<int> synced,
  Value<int> rowid,
});

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get endedAt => $composableBuilder(
      column: $table.endedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sessionMinutesTarget => $composableBuilder(
      column: $table.sessionMinutesTarget,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cachedValidationStatus => $composableBuilder(
      column: $table.cachedValidationStatus,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnFilters(column));
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get endedAt => $composableBuilder(
      column: $table.endedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sessionMinutesTarget => $composableBuilder(
      column: $table.sessionMinutesTarget,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cachedValidationStatus => $composableBuilder(
      column: $table.cachedValidationStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnOrderings(column));
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<String> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds, builder: (column) => column);

  GeneratedColumn<int> get sessionMinutesTarget => $composableBuilder(
      column: $table.sessionMinutesTarget, builder: (column) => column);

  GeneratedColumn<String> get cachedValidationStatus => $composableBuilder(
      column: $table.cachedValidationStatus, builder: (column) => column);

  GeneratedColumn<int> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$SessionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SessionsTable,
    Session,
    $$SessionsTableFilterComposer,
    $$SessionsTableOrderingComposer,
    $$SessionsTableAnnotationComposer,
    $$SessionsTableCreateCompanionBuilder,
    $$SessionsTableUpdateCompanionBuilder,
    (Session, BaseReferences<_$AppDatabase, $SessionsTable, Session>),
    Session,
    PrefetchHooks Function()> {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<String> startedAt = const Value.absent(),
            Value<String?> endedAt = const Value.absent(),
            Value<int?> durationSeconds = const Value.absent(),
            Value<int> sessionMinutesTarget = const Value.absent(),
            Value<String?> cachedValidationStatus = const Value.absent(),
            Value<int> synced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SessionsCompanion(
            id: id,
            kind: kind,
            startedAt: startedAt,
            endedAt: endedAt,
            durationSeconds: durationSeconds,
            sessionMinutesTarget: sessionMinutesTarget,
            cachedValidationStatus: cachedValidationStatus,
            synced: synced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String kind,
            required String startedAt,
            Value<String?> endedAt = const Value.absent(),
            Value<int?> durationSeconds = const Value.absent(),
            Value<int> sessionMinutesTarget = const Value.absent(),
            Value<String?> cachedValidationStatus = const Value.absent(),
            Value<int> synced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SessionsCompanion.insert(
            id: id,
            kind: kind,
            startedAt: startedAt,
            endedAt: endedAt,
            durationSeconds: durationSeconds,
            sessionMinutesTarget: sessionMinutesTarget,
            cachedValidationStatus: cachedValidationStatus,
            synced: synced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SessionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SessionsTable,
    Session,
    $$SessionsTableFilterComposer,
    $$SessionsTableOrderingComposer,
    $$SessionsTableAnnotationComposer,
    $$SessionsTableCreateCompanionBuilder,
    $$SessionsTableUpdateCompanionBuilder,
    (Session, BaseReferences<_$AppDatabase, $SessionsTable, Session>),
    Session,
    PrefetchHooks Function()>;
typedef $$ReviewRecordsTableCreateCompanionBuilder = ReviewRecordsCompanion
    Function({
  Value<int> id,
  required String reviewGroupId,
  required String wordId,
  required String actionResult,
  Value<String?> sessionId,
  required String createdAt,
  Value<int> synced,
  Value<int?> rating,
});
typedef $$ReviewRecordsTableUpdateCompanionBuilder = ReviewRecordsCompanion
    Function({
  Value<int> id,
  Value<String> reviewGroupId,
  Value<String> wordId,
  Value<String> actionResult,
  Value<String?> sessionId,
  Value<String> createdAt,
  Value<int> synced,
  Value<int?> rating,
});

class $$ReviewRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewRecordsTable> {
  $$ReviewRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reviewGroupId => $composableBuilder(
      column: $table.reviewGroupId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get wordId => $composableBuilder(
      column: $table.wordId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get actionResult => $composableBuilder(
      column: $table.actionResult, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnFilters(column));
}

class $$ReviewRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewRecordsTable> {
  $$ReviewRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reviewGroupId => $composableBuilder(
      column: $table.reviewGroupId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get wordId => $composableBuilder(
      column: $table.wordId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get actionResult => $composableBuilder(
      column: $table.actionResult,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnOrderings(column));
}

class $$ReviewRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewRecordsTable> {
  $$ReviewRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get reviewGroupId => $composableBuilder(
      column: $table.reviewGroupId, builder: (column) => column);

  GeneratedColumn<String> get wordId =>
      $composableBuilder(column: $table.wordId, builder: (column) => column);

  GeneratedColumn<String> get actionResult => $composableBuilder(
      column: $table.actionResult, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);
}

class $$ReviewRecordsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ReviewRecordsTable,
    ReviewRecord,
    $$ReviewRecordsTableFilterComposer,
    $$ReviewRecordsTableOrderingComposer,
    $$ReviewRecordsTableAnnotationComposer,
    $$ReviewRecordsTableCreateCompanionBuilder,
    $$ReviewRecordsTableUpdateCompanionBuilder,
    (
      ReviewRecord,
      BaseReferences<_$AppDatabase, $ReviewRecordsTable, ReviewRecord>
    ),
    ReviewRecord,
    PrefetchHooks Function()> {
  $$ReviewRecordsTableTableManager(_$AppDatabase db, $ReviewRecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> reviewGroupId = const Value.absent(),
            Value<String> wordId = const Value.absent(),
            Value<String> actionResult = const Value.absent(),
            Value<String?> sessionId = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<int> synced = const Value.absent(),
            Value<int?> rating = const Value.absent(),
          }) =>
              ReviewRecordsCompanion(
            id: id,
            reviewGroupId: reviewGroupId,
            wordId: wordId,
            actionResult: actionResult,
            sessionId: sessionId,
            createdAt: createdAt,
            synced: synced,
            rating: rating,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String reviewGroupId,
            required String wordId,
            required String actionResult,
            Value<String?> sessionId = const Value.absent(),
            required String createdAt,
            Value<int> synced = const Value.absent(),
            Value<int?> rating = const Value.absent(),
          }) =>
              ReviewRecordsCompanion.insert(
            id: id,
            reviewGroupId: reviewGroupId,
            wordId: wordId,
            actionResult: actionResult,
            sessionId: sessionId,
            createdAt: createdAt,
            synced: synced,
            rating: rating,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ReviewRecordsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ReviewRecordsTable,
    ReviewRecord,
    $$ReviewRecordsTableFilterComposer,
    $$ReviewRecordsTableOrderingComposer,
    $$ReviewRecordsTableAnnotationComposer,
    $$ReviewRecordsTableCreateCompanionBuilder,
    $$ReviewRecordsTableUpdateCompanionBuilder,
    (
      ReviewRecord,
      BaseReferences<_$AppDatabase, $ReviewRecordsTable, ReviewRecord>
    ),
    ReviewRecord,
    PrefetchHooks Function()>;
typedef $$WordFormsTableCreateCompanionBuilder = WordFormsCompanion Function({
  Value<int> id,
  required String word,
  required String formText,
  required String formType,
  Value<String?> pos,
  Value<String?> source,
});
typedef $$WordFormsTableUpdateCompanionBuilder = WordFormsCompanion Function({
  Value<int> id,
  Value<String> word,
  Value<String> formText,
  Value<String> formType,
  Value<String?> pos,
  Value<String?> source,
});

class $$WordFormsTableFilterComposer
    extends Composer<_$AppDatabase, $WordFormsTable> {
  $$WordFormsTableFilterComposer({
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

  ColumnFilters<String> get formText => $composableBuilder(
      column: $table.formText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get formType => $composableBuilder(
      column: $table.formType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pos => $composableBuilder(
      column: $table.pos, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));
}

class $$WordFormsTableOrderingComposer
    extends Composer<_$AppDatabase, $WordFormsTable> {
  $$WordFormsTableOrderingComposer({
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

  ColumnOrderings<String> get formText => $composableBuilder(
      column: $table.formText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get formType => $composableBuilder(
      column: $table.formType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pos => $composableBuilder(
      column: $table.pos, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));
}

class $$WordFormsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordFormsTable> {
  $$WordFormsTableAnnotationComposer({
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

  GeneratedColumn<String> get formText =>
      $composableBuilder(column: $table.formText, builder: (column) => column);

  GeneratedColumn<String> get formType =>
      $composableBuilder(column: $table.formType, builder: (column) => column);

  GeneratedColumn<String> get pos =>
      $composableBuilder(column: $table.pos, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$WordFormsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WordFormsTable,
    WordForm,
    $$WordFormsTableFilterComposer,
    $$WordFormsTableOrderingComposer,
    $$WordFormsTableAnnotationComposer,
    $$WordFormsTableCreateCompanionBuilder,
    $$WordFormsTableUpdateCompanionBuilder,
    (WordForm, BaseReferences<_$AppDatabase, $WordFormsTable, WordForm>),
    WordForm,
    PrefetchHooks Function()> {
  $$WordFormsTableTableManager(_$AppDatabase db, $WordFormsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordFormsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordFormsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordFormsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> word = const Value.absent(),
            Value<String> formText = const Value.absent(),
            Value<String> formType = const Value.absent(),
            Value<String?> pos = const Value.absent(),
            Value<String?> source = const Value.absent(),
          }) =>
              WordFormsCompanion(
            id: id,
            word: word,
            formText: formText,
            formType: formType,
            pos: pos,
            source: source,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String word,
            required String formText,
            required String formType,
            Value<String?> pos = const Value.absent(),
            Value<String?> source = const Value.absent(),
          }) =>
              WordFormsCompanion.insert(
            id: id,
            word: word,
            formText: formText,
            formType: formType,
            pos: pos,
            source: source,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WordFormsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WordFormsTable,
    WordForm,
    $$WordFormsTableFilterComposer,
    $$WordFormsTableOrderingComposer,
    $$WordFormsTableAnnotationComposer,
    $$WordFormsTableCreateCompanionBuilder,
    $$WordFormsTableUpdateCompanionBuilder,
    (WordForm, BaseReferences<_$AppDatabase, $WordFormsTable, WordForm>),
    WordForm,
    PrefetchHooks Function()>;
typedef $$WordRelationsTableCreateCompanionBuilder = WordRelationsCompanion
    Function({
  Value<int> id,
  required String word,
  required String targetWord,
  required String relationType,
  Value<String?> pos,
  Value<double?> confidence,
  Value<String?> source,
});
typedef $$WordRelationsTableUpdateCompanionBuilder = WordRelationsCompanion
    Function({
  Value<int> id,
  Value<String> word,
  Value<String> targetWord,
  Value<String> relationType,
  Value<String?> pos,
  Value<double?> confidence,
  Value<String?> source,
});

class $$WordRelationsTableFilterComposer
    extends Composer<_$AppDatabase, $WordRelationsTable> {
  $$WordRelationsTableFilterComposer({
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

  ColumnFilters<String> get targetWord => $composableBuilder(
      column: $table.targetWord, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get relationType => $composableBuilder(
      column: $table.relationType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pos => $composableBuilder(
      column: $table.pos, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));
}

class $$WordRelationsTableOrderingComposer
    extends Composer<_$AppDatabase, $WordRelationsTable> {
  $$WordRelationsTableOrderingComposer({
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

  ColumnOrderings<String> get targetWord => $composableBuilder(
      column: $table.targetWord, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get relationType => $composableBuilder(
      column: $table.relationType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pos => $composableBuilder(
      column: $table.pos, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));
}

class $$WordRelationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordRelationsTable> {
  $$WordRelationsTableAnnotationComposer({
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

  GeneratedColumn<String> get targetWord => $composableBuilder(
      column: $table.targetWord, builder: (column) => column);

  GeneratedColumn<String> get relationType => $composableBuilder(
      column: $table.relationType, builder: (column) => column);

  GeneratedColumn<String> get pos =>
      $composableBuilder(column: $table.pos, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$WordRelationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WordRelationsTable,
    WordRelation,
    $$WordRelationsTableFilterComposer,
    $$WordRelationsTableOrderingComposer,
    $$WordRelationsTableAnnotationComposer,
    $$WordRelationsTableCreateCompanionBuilder,
    $$WordRelationsTableUpdateCompanionBuilder,
    (
      WordRelation,
      BaseReferences<_$AppDatabase, $WordRelationsTable, WordRelation>
    ),
    WordRelation,
    PrefetchHooks Function()> {
  $$WordRelationsTableTableManager(_$AppDatabase db, $WordRelationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordRelationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordRelationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordRelationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> word = const Value.absent(),
            Value<String> targetWord = const Value.absent(),
            Value<String> relationType = const Value.absent(),
            Value<String?> pos = const Value.absent(),
            Value<double?> confidence = const Value.absent(),
            Value<String?> source = const Value.absent(),
          }) =>
              WordRelationsCompanion(
            id: id,
            word: word,
            targetWord: targetWord,
            relationType: relationType,
            pos: pos,
            confidence: confidence,
            source: source,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String word,
            required String targetWord,
            required String relationType,
            Value<String?> pos = const Value.absent(),
            Value<double?> confidence = const Value.absent(),
            Value<String?> source = const Value.absent(),
          }) =>
              WordRelationsCompanion.insert(
            id: id,
            word: word,
            targetWord: targetWord,
            relationType: relationType,
            pos: pos,
            confidence: confidence,
            source: source,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WordRelationsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WordRelationsTable,
    WordRelation,
    $$WordRelationsTableFilterComposer,
    $$WordRelationsTableOrderingComposer,
    $$WordRelationsTableAnnotationComposer,
    $$WordRelationsTableCreateCompanionBuilder,
    $$WordRelationsTableUpdateCompanionBuilder,
    (
      WordRelation,
      BaseReferences<_$AppDatabase, $WordRelationsTable, WordRelation>
    ),
    WordRelation,
    PrefetchHooks Function()>;
typedef $$WordPhrasesTableCreateCompanionBuilder = WordPhrasesCompanion
    Function({
  Value<int> id,
  required String word,
  required String phraseText,
  Value<String> phraseType,
  Value<int?> score,
  Value<String?> source,
});
typedef $$WordPhrasesTableUpdateCompanionBuilder = WordPhrasesCompanion
    Function({
  Value<int> id,
  Value<String> word,
  Value<String> phraseText,
  Value<String> phraseType,
  Value<int?> score,
  Value<String?> source,
});

class $$WordPhrasesTableFilterComposer
    extends Composer<_$AppDatabase, $WordPhrasesTable> {
  $$WordPhrasesTableFilterComposer({
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

  ColumnFilters<String> get phraseText => $composableBuilder(
      column: $table.phraseText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phraseType => $composableBuilder(
      column: $table.phraseType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get score => $composableBuilder(
      column: $table.score, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));
}

class $$WordPhrasesTableOrderingComposer
    extends Composer<_$AppDatabase, $WordPhrasesTable> {
  $$WordPhrasesTableOrderingComposer({
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

  ColumnOrderings<String> get phraseText => $composableBuilder(
      column: $table.phraseText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phraseType => $composableBuilder(
      column: $table.phraseType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get score => $composableBuilder(
      column: $table.score, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));
}

class $$WordPhrasesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordPhrasesTable> {
  $$WordPhrasesTableAnnotationComposer({
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

  GeneratedColumn<String> get phraseText => $composableBuilder(
      column: $table.phraseText, builder: (column) => column);

  GeneratedColumn<String> get phraseType => $composableBuilder(
      column: $table.phraseType, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$WordPhrasesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WordPhrasesTable,
    WordPhrase,
    $$WordPhrasesTableFilterComposer,
    $$WordPhrasesTableOrderingComposer,
    $$WordPhrasesTableAnnotationComposer,
    $$WordPhrasesTableCreateCompanionBuilder,
    $$WordPhrasesTableUpdateCompanionBuilder,
    (WordPhrase, BaseReferences<_$AppDatabase, $WordPhrasesTable, WordPhrase>),
    WordPhrase,
    PrefetchHooks Function()> {
  $$WordPhrasesTableTableManager(_$AppDatabase db, $WordPhrasesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordPhrasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordPhrasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordPhrasesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> word = const Value.absent(),
            Value<String> phraseText = const Value.absent(),
            Value<String> phraseType = const Value.absent(),
            Value<int?> score = const Value.absent(),
            Value<String?> source = const Value.absent(),
          }) =>
              WordPhrasesCompanion(
            id: id,
            word: word,
            phraseText: phraseText,
            phraseType: phraseType,
            score: score,
            source: source,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String word,
            required String phraseText,
            Value<String> phraseType = const Value.absent(),
            Value<int?> score = const Value.absent(),
            Value<String?> source = const Value.absent(),
          }) =>
              WordPhrasesCompanion.insert(
            id: id,
            word: word,
            phraseText: phraseText,
            phraseType: phraseType,
            score: score,
            source: source,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WordPhrasesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WordPhrasesTable,
    WordPhrase,
    $$WordPhrasesTableFilterComposer,
    $$WordPhrasesTableOrderingComposer,
    $$WordPhrasesTableAnnotationComposer,
    $$WordPhrasesTableCreateCompanionBuilder,
    $$WordPhrasesTableUpdateCompanionBuilder,
    (WordPhrase, BaseReferences<_$AppDatabase, $WordPhrasesTable, WordPhrase>),
    WordPhrase,
    PrefetchHooks Function()>;
typedef $$MorphemeEntriesTableCreateCompanionBuilder = MorphemeEntriesCompanion
    Function({
  Value<int> id,
  required String morpheme,
  required String normalizedMorpheme,
  required String morphemeType,
  required String meaningsJson,
  Value<String?> examplesJson,
  Value<String?> source,
  Value<String?> license,
});
typedef $$MorphemeEntriesTableUpdateCompanionBuilder = MorphemeEntriesCompanion
    Function({
  Value<int> id,
  Value<String> morpheme,
  Value<String> normalizedMorpheme,
  Value<String> morphemeType,
  Value<String> meaningsJson,
  Value<String?> examplesJson,
  Value<String?> source,
  Value<String?> license,
});

class $$MorphemeEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $MorphemeEntriesTable> {
  $$MorphemeEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get morpheme => $composableBuilder(
      column: $table.morpheme, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get normalizedMorpheme => $composableBuilder(
      column: $table.normalizedMorpheme,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get morphemeType => $composableBuilder(
      column: $table.morphemeType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get meaningsJson => $composableBuilder(
      column: $table.meaningsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get examplesJson => $composableBuilder(
      column: $table.examplesJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get license => $composableBuilder(
      column: $table.license, builder: (column) => ColumnFilters(column));
}

class $$MorphemeEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $MorphemeEntriesTable> {
  $$MorphemeEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get morpheme => $composableBuilder(
      column: $table.morpheme, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get normalizedMorpheme => $composableBuilder(
      column: $table.normalizedMorpheme,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get morphemeType => $composableBuilder(
      column: $table.morphemeType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get meaningsJson => $composableBuilder(
      column: $table.meaningsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get examplesJson => $composableBuilder(
      column: $table.examplesJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get license => $composableBuilder(
      column: $table.license, builder: (column) => ColumnOrderings(column));
}

class $$MorphemeEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MorphemeEntriesTable> {
  $$MorphemeEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get morpheme =>
      $composableBuilder(column: $table.morpheme, builder: (column) => column);

  GeneratedColumn<String> get normalizedMorpheme => $composableBuilder(
      column: $table.normalizedMorpheme, builder: (column) => column);

  GeneratedColumn<String> get morphemeType => $composableBuilder(
      column: $table.morphemeType, builder: (column) => column);

  GeneratedColumn<String> get meaningsJson => $composableBuilder(
      column: $table.meaningsJson, builder: (column) => column);

  GeneratedColumn<String> get examplesJson => $composableBuilder(
      column: $table.examplesJson, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get license =>
      $composableBuilder(column: $table.license, builder: (column) => column);
}

class $$MorphemeEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MorphemeEntriesTable,
    MorphemeEntry,
    $$MorphemeEntriesTableFilterComposer,
    $$MorphemeEntriesTableOrderingComposer,
    $$MorphemeEntriesTableAnnotationComposer,
    $$MorphemeEntriesTableCreateCompanionBuilder,
    $$MorphemeEntriesTableUpdateCompanionBuilder,
    (
      MorphemeEntry,
      BaseReferences<_$AppDatabase, $MorphemeEntriesTable, MorphemeEntry>
    ),
    MorphemeEntry,
    PrefetchHooks Function()> {
  $$MorphemeEntriesTableTableManager(
      _$AppDatabase db, $MorphemeEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MorphemeEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MorphemeEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MorphemeEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> morpheme = const Value.absent(),
            Value<String> normalizedMorpheme = const Value.absent(),
            Value<String> morphemeType = const Value.absent(),
            Value<String> meaningsJson = const Value.absent(),
            Value<String?> examplesJson = const Value.absent(),
            Value<String?> source = const Value.absent(),
            Value<String?> license = const Value.absent(),
          }) =>
              MorphemeEntriesCompanion(
            id: id,
            morpheme: morpheme,
            normalizedMorpheme: normalizedMorpheme,
            morphemeType: morphemeType,
            meaningsJson: meaningsJson,
            examplesJson: examplesJson,
            source: source,
            license: license,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String morpheme,
            required String normalizedMorpheme,
            required String morphemeType,
            required String meaningsJson,
            Value<String?> examplesJson = const Value.absent(),
            Value<String?> source = const Value.absent(),
            Value<String?> license = const Value.absent(),
          }) =>
              MorphemeEntriesCompanion.insert(
            id: id,
            morpheme: morpheme,
            normalizedMorpheme: normalizedMorpheme,
            morphemeType: morphemeType,
            meaningsJson: meaningsJson,
            examplesJson: examplesJson,
            source: source,
            license: license,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MorphemeEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MorphemeEntriesTable,
    MorphemeEntry,
    $$MorphemeEntriesTableFilterComposer,
    $$MorphemeEntriesTableOrderingComposer,
    $$MorphemeEntriesTableAnnotationComposer,
    $$MorphemeEntriesTableCreateCompanionBuilder,
    $$MorphemeEntriesTableUpdateCompanionBuilder,
    (
      MorphemeEntry,
      BaseReferences<_$AppDatabase, $MorphemeEntriesTable, MorphemeEntry>
    ),
    MorphemeEntry,
    PrefetchHooks Function()>;
typedef $$WordMorphemeMatchesTableCreateCompanionBuilder
    = WordMorphemeMatchesCompanion Function({
  Value<int> id,
  required String word,
  required String morpheme,
  required String normalizedMorpheme,
  required String morphemeType,
  required String position,
  required String meaningsJson,
  Value<String?> matchMethod,
  Value<double?> confidence,
  Value<String?> source,
});
typedef $$WordMorphemeMatchesTableUpdateCompanionBuilder
    = WordMorphemeMatchesCompanion Function({
  Value<int> id,
  Value<String> word,
  Value<String> morpheme,
  Value<String> normalizedMorpheme,
  Value<String> morphemeType,
  Value<String> position,
  Value<String> meaningsJson,
  Value<String?> matchMethod,
  Value<double?> confidence,
  Value<String?> source,
});

class $$WordMorphemeMatchesTableFilterComposer
    extends Composer<_$AppDatabase, $WordMorphemeMatchesTable> {
  $$WordMorphemeMatchesTableFilterComposer({
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

  ColumnFilters<String> get morpheme => $composableBuilder(
      column: $table.morpheme, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get normalizedMorpheme => $composableBuilder(
      column: $table.normalizedMorpheme,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get morphemeType => $composableBuilder(
      column: $table.morphemeType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get meaningsJson => $composableBuilder(
      column: $table.meaningsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get matchMethod => $composableBuilder(
      column: $table.matchMethod, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));
}

class $$WordMorphemeMatchesTableOrderingComposer
    extends Composer<_$AppDatabase, $WordMorphemeMatchesTable> {
  $$WordMorphemeMatchesTableOrderingComposer({
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

  ColumnOrderings<String> get morpheme => $composableBuilder(
      column: $table.morpheme, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get normalizedMorpheme => $composableBuilder(
      column: $table.normalizedMorpheme,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get morphemeType => $composableBuilder(
      column: $table.morphemeType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get meaningsJson => $composableBuilder(
      column: $table.meaningsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get matchMethod => $composableBuilder(
      column: $table.matchMethod, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));
}

class $$WordMorphemeMatchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordMorphemeMatchesTable> {
  $$WordMorphemeMatchesTableAnnotationComposer({
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

  GeneratedColumn<String> get morpheme =>
      $composableBuilder(column: $table.morpheme, builder: (column) => column);

  GeneratedColumn<String> get normalizedMorpheme => $composableBuilder(
      column: $table.normalizedMorpheme, builder: (column) => column);

  GeneratedColumn<String> get morphemeType => $composableBuilder(
      column: $table.morphemeType, builder: (column) => column);

  GeneratedColumn<String> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get meaningsJson => $composableBuilder(
      column: $table.meaningsJson, builder: (column) => column);

  GeneratedColumn<String> get matchMethod => $composableBuilder(
      column: $table.matchMethod, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$WordMorphemeMatchesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WordMorphemeMatchesTable,
    WordMorphemeMatche,
    $$WordMorphemeMatchesTableFilterComposer,
    $$WordMorphemeMatchesTableOrderingComposer,
    $$WordMorphemeMatchesTableAnnotationComposer,
    $$WordMorphemeMatchesTableCreateCompanionBuilder,
    $$WordMorphemeMatchesTableUpdateCompanionBuilder,
    (
      WordMorphemeMatche,
      BaseReferences<_$AppDatabase, $WordMorphemeMatchesTable,
          WordMorphemeMatche>
    ),
    WordMorphemeMatche,
    PrefetchHooks Function()> {
  $$WordMorphemeMatchesTableTableManager(
      _$AppDatabase db, $WordMorphemeMatchesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordMorphemeMatchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordMorphemeMatchesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordMorphemeMatchesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> word = const Value.absent(),
            Value<String> morpheme = const Value.absent(),
            Value<String> normalizedMorpheme = const Value.absent(),
            Value<String> morphemeType = const Value.absent(),
            Value<String> position = const Value.absent(),
            Value<String> meaningsJson = const Value.absent(),
            Value<String?> matchMethod = const Value.absent(),
            Value<double?> confidence = const Value.absent(),
            Value<String?> source = const Value.absent(),
          }) =>
              WordMorphemeMatchesCompanion(
            id: id,
            word: word,
            morpheme: morpheme,
            normalizedMorpheme: normalizedMorpheme,
            morphemeType: morphemeType,
            position: position,
            meaningsJson: meaningsJson,
            matchMethod: matchMethod,
            confidence: confidence,
            source: source,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String word,
            required String morpheme,
            required String normalizedMorpheme,
            required String morphemeType,
            required String position,
            required String meaningsJson,
            Value<String?> matchMethod = const Value.absent(),
            Value<double?> confidence = const Value.absent(),
            Value<String?> source = const Value.absent(),
          }) =>
              WordMorphemeMatchesCompanion.insert(
            id: id,
            word: word,
            morpheme: morpheme,
            normalizedMorpheme: normalizedMorpheme,
            morphemeType: morphemeType,
            position: position,
            meaningsJson: meaningsJson,
            matchMethod: matchMethod,
            confidence: confidence,
            source: source,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WordMorphemeMatchesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WordMorphemeMatchesTable,
    WordMorphemeMatche,
    $$WordMorphemeMatchesTableFilterComposer,
    $$WordMorphemeMatchesTableOrderingComposer,
    $$WordMorphemeMatchesTableAnnotationComposer,
    $$WordMorphemeMatchesTableCreateCompanionBuilder,
    $$WordMorphemeMatchesTableUpdateCompanionBuilder,
    (
      WordMorphemeMatche,
      BaseReferences<_$AppDatabase, $WordMorphemeMatchesTable,
          WordMorphemeMatche>
    ),
    WordMorphemeMatche,
    PrefetchHooks Function()>;
typedef $$AudioFileCacheTableCreateCompanionBuilder = AudioFileCacheCompanion
    Function({
  required String audioId,
  required String localPath,
  required int bytes,
  required int cachedAt,
  Value<int?> lastPlayedAt,
  Value<String?> cachedChecksum,
  Value<String?> cachedContentVersion,
  Value<int> rowid,
});
typedef $$AudioFileCacheTableUpdateCompanionBuilder = AudioFileCacheCompanion
    Function({
  Value<String> audioId,
  Value<String> localPath,
  Value<int> bytes,
  Value<int> cachedAt,
  Value<int?> lastPlayedAt,
  Value<String?> cachedChecksum,
  Value<String?> cachedContentVersion,
  Value<int> rowid,
});

class $$AudioFileCacheTableFilterComposer
    extends Composer<_$AppDatabase, $AudioFileCacheTable> {
  $$AudioFileCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get audioId => $composableBuilder(
      column: $table.audioId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get bytes => $composableBuilder(
      column: $table.bytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastPlayedAt => $composableBuilder(
      column: $table.lastPlayedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cachedChecksum => $composableBuilder(
      column: $table.cachedChecksum,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cachedContentVersion => $composableBuilder(
      column: $table.cachedContentVersion,
      builder: (column) => ColumnFilters(column));
}

class $$AudioFileCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $AudioFileCacheTable> {
  $$AudioFileCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get audioId => $composableBuilder(
      column: $table.audioId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get bytes => $composableBuilder(
      column: $table.bytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastPlayedAt => $composableBuilder(
      column: $table.lastPlayedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cachedChecksum => $composableBuilder(
      column: $table.cachedChecksum,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cachedContentVersion => $composableBuilder(
      column: $table.cachedContentVersion,
      builder: (column) => ColumnOrderings(column));
}

class $$AudioFileCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $AudioFileCacheTable> {
  $$AudioFileCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get audioId =>
      $composableBuilder(column: $table.audioId, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<int> get bytes =>
      $composableBuilder(column: $table.bytes, builder: (column) => column);

  GeneratedColumn<int> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  GeneratedColumn<int> get lastPlayedAt => $composableBuilder(
      column: $table.lastPlayedAt, builder: (column) => column);

  GeneratedColumn<String> get cachedChecksum => $composableBuilder(
      column: $table.cachedChecksum, builder: (column) => column);

  GeneratedColumn<String> get cachedContentVersion => $composableBuilder(
      column: $table.cachedContentVersion, builder: (column) => column);
}

class $$AudioFileCacheTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AudioFileCacheTable,
    AudioFileCacheData,
    $$AudioFileCacheTableFilterComposer,
    $$AudioFileCacheTableOrderingComposer,
    $$AudioFileCacheTableAnnotationComposer,
    $$AudioFileCacheTableCreateCompanionBuilder,
    $$AudioFileCacheTableUpdateCompanionBuilder,
    (
      AudioFileCacheData,
      BaseReferences<_$AppDatabase, $AudioFileCacheTable, AudioFileCacheData>
    ),
    AudioFileCacheData,
    PrefetchHooks Function()> {
  $$AudioFileCacheTableTableManager(
      _$AppDatabase db, $AudioFileCacheTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AudioFileCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AudioFileCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AudioFileCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> audioId = const Value.absent(),
            Value<String> localPath = const Value.absent(),
            Value<int> bytes = const Value.absent(),
            Value<int> cachedAt = const Value.absent(),
            Value<int?> lastPlayedAt = const Value.absent(),
            Value<String?> cachedChecksum = const Value.absent(),
            Value<String?> cachedContentVersion = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AudioFileCacheCompanion(
            audioId: audioId,
            localPath: localPath,
            bytes: bytes,
            cachedAt: cachedAt,
            lastPlayedAt: lastPlayedAt,
            cachedChecksum: cachedChecksum,
            cachedContentVersion: cachedContentVersion,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String audioId,
            required String localPath,
            required int bytes,
            required int cachedAt,
            Value<int?> lastPlayedAt = const Value.absent(),
            Value<String?> cachedChecksum = const Value.absent(),
            Value<String?> cachedContentVersion = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AudioFileCacheCompanion.insert(
            audioId: audioId,
            localPath: localPath,
            bytes: bytes,
            cachedAt: cachedAt,
            lastPlayedAt: lastPlayedAt,
            cachedChecksum: cachedChecksum,
            cachedContentVersion: cachedContentVersion,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AudioFileCacheTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AudioFileCacheTable,
    AudioFileCacheData,
    $$AudioFileCacheTableFilterComposer,
    $$AudioFileCacheTableOrderingComposer,
    $$AudioFileCacheTableAnnotationComposer,
    $$AudioFileCacheTableCreateCompanionBuilder,
    $$AudioFileCacheTableUpdateCompanionBuilder,
    (
      AudioFileCacheData,
      BaseReferences<_$AppDatabase, $AudioFileCacheTable, AudioFileCacheData>
    ),
    AudioFileCacheData,
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
  $$PresetWordbooksTableTableManager get presetWordbooks =>
      $$PresetWordbooksTableTableManager(_db, _db.presetWordbooks);
  $$WordEntriesTableTableManager get wordEntries =>
      $$WordEntriesTableTableManager(_db, _db.wordEntries);
  $$WordBookAssignmentsTableTableManager get wordBookAssignments =>
      $$WordBookAssignmentsTableTableManager(_db, _db.wordBookAssignments);
  $$ExampleSentencesTableTableManager get exampleSentences =>
      $$ExampleSentencesTableTableManager(_db, _db.exampleSentences);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$ReviewRecordsTableTableManager get reviewRecords =>
      $$ReviewRecordsTableTableManager(_db, _db.reviewRecords);
  $$WordFormsTableTableManager get wordForms =>
      $$WordFormsTableTableManager(_db, _db.wordForms);
  $$WordRelationsTableTableManager get wordRelations =>
      $$WordRelationsTableTableManager(_db, _db.wordRelations);
  $$WordPhrasesTableTableManager get wordPhrases =>
      $$WordPhrasesTableTableManager(_db, _db.wordPhrases);
  $$MorphemeEntriesTableTableManager get morphemeEntries =>
      $$MorphemeEntriesTableTableManager(_db, _db.morphemeEntries);
  $$WordMorphemeMatchesTableTableManager get wordMorphemeMatches =>
      $$WordMorphemeMatchesTableTableManager(_db, _db.wordMorphemeMatches);
  $$AudioFileCacheTableTableManager get audioFileCache =>
      $$AudioFileCacheTableTableManager(_db, _db.audioFileCache);
}
