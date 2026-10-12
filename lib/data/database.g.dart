// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CouponsTable extends Coupons with TableInfo<$CouponsTable, CouponRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CouponsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _merchantMeta = const VerificationMeta(
    'merchant',
  );
  @override
  late final GeneratedColumn<String> merchant = GeneratedColumn<String>(
    'merchant',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
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
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  @override
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
    'tag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _codeValueMeta = const VerificationMeta(
    'codeValue',
  );
  @override
  late final GeneratedColumn<String> codeValue = GeneratedColumn<String>(
    'code_value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _codeFormatMeta = const VerificationMeta(
    'codeFormat',
  );
  @override
  late final GeneratedColumn<String> codeFormat = GeneratedColumn<String>(
    'code_format',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _discountTypeMeta = const VerificationMeta(
    'discountType',
  );
  @override
  late final GeneratedColumn<String> discountType = GeneratedColumn<String>(
    'discount_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountValueMeta = const VerificationMeta(
    'discountValue',
  );
  @override
  late final GeneratedColumn<double> discountValue = GeneratedColumn<double>(
    'discount_value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _minSpendMeta = const VerificationMeta(
    'minSpend',
  );
  @override
  late final GeneratedColumn<double> minSpend = GeneratedColumn<double>(
    'min_spend',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _conditionsMeta = const VerificationMeta(
    'conditions',
  );
  @override
  late final GeneratedColumn<String> conditions = GeneratedColumn<String>(
    'conditions',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _validFromMeta = const VerificationMeta(
    'validFrom',
  );
  @override
  late final GeneratedColumn<DateTime> validFrom = GeneratedColumn<DateTime>(
    'valid_from',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
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
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    merchant,
    kind,
    createdAt,
    category,
    tag,
    codeValue,
    codeFormat,
    discountType,
    discountValue,
    minSpend,
    conditions,
    validFrom,
    expiresAt,
    status,
    imagePath,
    source,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'coupons';
  @override
  VerificationContext validateIntegrity(
    Insertable<CouponRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('merchant')) {
      context.handle(
        _merchantMeta,
        merchant.isAcceptableOrUnknown(data['merchant']!, _merchantMeta),
      );
    } else if (isInserting) {
      context.missing(_merchantMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('tag')) {
      context.handle(
        _tagMeta,
        tag.isAcceptableOrUnknown(data['tag']!, _tagMeta),
      );
    }
    if (data.containsKey('code_value')) {
      context.handle(
        _codeValueMeta,
        codeValue.isAcceptableOrUnknown(data['code_value']!, _codeValueMeta),
      );
    }
    if (data.containsKey('code_format')) {
      context.handle(
        _codeFormatMeta,
        codeFormat.isAcceptableOrUnknown(data['code_format']!, _codeFormatMeta),
      );
    }
    if (data.containsKey('discount_type')) {
      context.handle(
        _discountTypeMeta,
        discountType.isAcceptableOrUnknown(
          data['discount_type']!,
          _discountTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_discountTypeMeta);
    }
    if (data.containsKey('discount_value')) {
      context.handle(
        _discountValueMeta,
        discountValue.isAcceptableOrUnknown(
          data['discount_value']!,
          _discountValueMeta,
        ),
      );
    }
    if (data.containsKey('min_spend')) {
      context.handle(
        _minSpendMeta,
        minSpend.isAcceptableOrUnknown(data['min_spend']!, _minSpendMeta),
      );
    }
    if (data.containsKey('conditions')) {
      context.handle(
        _conditionsMeta,
        conditions.isAcceptableOrUnknown(data['conditions']!, _conditionsMeta),
      );
    }
    if (data.containsKey('valid_from')) {
      context.handle(
        _validFromMeta,
        validFrom.isAcceptableOrUnknown(data['valid_from']!, _validFromMeta),
      );
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
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
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CouponRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CouponRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      merchant: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merchant'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      tag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag'],
      ),
      codeValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code_value'],
      ),
      codeFormat: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code_format'],
      ),
      discountType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}discount_type'],
      )!,
      discountValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}discount_value'],
      ),
      minSpend: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}min_spend'],
      ),
      conditions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conditions'],
      ),
      validFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}valid_from'],
      ),
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
    );
  }

  @override
  $CouponsTable createAlias(String alias) {
    return $CouponsTable(attachedDatabase, alias);
  }
}

class CouponRow extends DataClass implements Insertable<CouponRow> {
  final String id;
  final String title;
  final String merchant;
  final String kind;
  final DateTime createdAt;
  final String? category;
  final String? tag;
  final String? codeValue;
  final String? codeFormat;
  final String discountType;
  final double? discountValue;
  final double? minSpend;
  final String? conditions;
  final DateTime? validFrom;
  final DateTime? expiresAt;
  final String status;
  final String? imagePath;
  final String source;
  const CouponRow({
    required this.id,
    required this.title,
    required this.merchant,
    required this.kind,
    required this.createdAt,
    this.category,
    this.tag,
    this.codeValue,
    this.codeFormat,
    required this.discountType,
    this.discountValue,
    this.minSpend,
    this.conditions,
    this.validFrom,
    this.expiresAt,
    required this.status,
    this.imagePath,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['merchant'] = Variable<String>(merchant);
    map['kind'] = Variable<String>(kind);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || tag != null) {
      map['tag'] = Variable<String>(tag);
    }
    if (!nullToAbsent || codeValue != null) {
      map['code_value'] = Variable<String>(codeValue);
    }
    if (!nullToAbsent || codeFormat != null) {
      map['code_format'] = Variable<String>(codeFormat);
    }
    map['discount_type'] = Variable<String>(discountType);
    if (!nullToAbsent || discountValue != null) {
      map['discount_value'] = Variable<double>(discountValue);
    }
    if (!nullToAbsent || minSpend != null) {
      map['min_spend'] = Variable<double>(minSpend);
    }
    if (!nullToAbsent || conditions != null) {
      map['conditions'] = Variable<String>(conditions);
    }
    if (!nullToAbsent || validFrom != null) {
      map['valid_from'] = Variable<DateTime>(validFrom);
    }
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<DateTime>(expiresAt);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    map['source'] = Variable<String>(source);
    return map;
  }

  CouponsCompanion toCompanion(bool nullToAbsent) {
    return CouponsCompanion(
      id: Value(id),
      title: Value(title),
      merchant: Value(merchant),
      kind: Value(kind),
      createdAt: Value(createdAt),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      tag: tag == null && nullToAbsent ? const Value.absent() : Value(tag),
      codeValue: codeValue == null && nullToAbsent
          ? const Value.absent()
          : Value(codeValue),
      codeFormat: codeFormat == null && nullToAbsent
          ? const Value.absent()
          : Value(codeFormat),
      discountType: Value(discountType),
      discountValue: discountValue == null && nullToAbsent
          ? const Value.absent()
          : Value(discountValue),
      minSpend: minSpend == null && nullToAbsent
          ? const Value.absent()
          : Value(minSpend),
      conditions: conditions == null && nullToAbsent
          ? const Value.absent()
          : Value(conditions),
      validFrom: validFrom == null && nullToAbsent
          ? const Value.absent()
          : Value(validFrom),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
      status: Value(status),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      source: Value(source),
    );
  }

  factory CouponRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CouponRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      merchant: serializer.fromJson<String>(json['merchant']),
      kind: serializer.fromJson<String>(json['kind']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      category: serializer.fromJson<String?>(json['category']),
      tag: serializer.fromJson<String?>(json['tag']),
      codeValue: serializer.fromJson<String?>(json['codeValue']),
      codeFormat: serializer.fromJson<String?>(json['codeFormat']),
      discountType: serializer.fromJson<String>(json['discountType']),
      discountValue: serializer.fromJson<double?>(json['discountValue']),
      minSpend: serializer.fromJson<double?>(json['minSpend']),
      conditions: serializer.fromJson<String?>(json['conditions']),
      validFrom: serializer.fromJson<DateTime?>(json['validFrom']),
      expiresAt: serializer.fromJson<DateTime?>(json['expiresAt']),
      status: serializer.fromJson<String>(json['status']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'merchant': serializer.toJson<String>(merchant),
      'kind': serializer.toJson<String>(kind),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'category': serializer.toJson<String?>(category),
      'tag': serializer.toJson<String?>(tag),
      'codeValue': serializer.toJson<String?>(codeValue),
      'codeFormat': serializer.toJson<String?>(codeFormat),
      'discountType': serializer.toJson<String>(discountType),
      'discountValue': serializer.toJson<double?>(discountValue),
      'minSpend': serializer.toJson<double?>(minSpend),
      'conditions': serializer.toJson<String?>(conditions),
      'validFrom': serializer.toJson<DateTime?>(validFrom),
      'expiresAt': serializer.toJson<DateTime?>(expiresAt),
      'status': serializer.toJson<String>(status),
      'imagePath': serializer.toJson<String?>(imagePath),
      'source': serializer.toJson<String>(source),
    };
  }

  CouponRow copyWith({
    String? id,
    String? title,
    String? merchant,
    String? kind,
    DateTime? createdAt,
    Value<String?> category = const Value.absent(),
    Value<String?> tag = const Value.absent(),
    Value<String?> codeValue = const Value.absent(),
    Value<String?> codeFormat = const Value.absent(),
    String? discountType,
    Value<double?> discountValue = const Value.absent(),
    Value<double?> minSpend = const Value.absent(),
    Value<String?> conditions = const Value.absent(),
    Value<DateTime?> validFrom = const Value.absent(),
    Value<DateTime?> expiresAt = const Value.absent(),
    String? status,
    Value<String?> imagePath = const Value.absent(),
    String? source,
  }) => CouponRow(
    id: id ?? this.id,
    title: title ?? this.title,
    merchant: merchant ?? this.merchant,
    kind: kind ?? this.kind,
    createdAt: createdAt ?? this.createdAt,
    category: category.present ? category.value : this.category,
    tag: tag.present ? tag.value : this.tag,
    codeValue: codeValue.present ? codeValue.value : this.codeValue,
    codeFormat: codeFormat.present ? codeFormat.value : this.codeFormat,
    discountType: discountType ?? this.discountType,
    discountValue: discountValue.present
        ? discountValue.value
        : this.discountValue,
    minSpend: minSpend.present ? minSpend.value : this.minSpend,
    conditions: conditions.present ? conditions.value : this.conditions,
    validFrom: validFrom.present ? validFrom.value : this.validFrom,
    expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
    status: status ?? this.status,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    source: source ?? this.source,
  );
  CouponRow copyWithCompanion(CouponsCompanion data) {
    return CouponRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      merchant: data.merchant.present ? data.merchant.value : this.merchant,
      kind: data.kind.present ? data.kind.value : this.kind,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      category: data.category.present ? data.category.value : this.category,
      tag: data.tag.present ? data.tag.value : this.tag,
      codeValue: data.codeValue.present ? data.codeValue.value : this.codeValue,
      codeFormat: data.codeFormat.present
          ? data.codeFormat.value
          : this.codeFormat,
      discountType: data.discountType.present
          ? data.discountType.value
          : this.discountType,
      discountValue: data.discountValue.present
          ? data.discountValue.value
          : this.discountValue,
      minSpend: data.minSpend.present ? data.minSpend.value : this.minSpend,
      conditions: data.conditions.present
          ? data.conditions.value
          : this.conditions,
      validFrom: data.validFrom.present ? data.validFrom.value : this.validFrom,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      status: data.status.present ? data.status.value : this.status,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CouponRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('merchant: $merchant, ')
          ..write('kind: $kind, ')
          ..write('createdAt: $createdAt, ')
          ..write('category: $category, ')
          ..write('tag: $tag, ')
          ..write('codeValue: $codeValue, ')
          ..write('codeFormat: $codeFormat, ')
          ..write('discountType: $discountType, ')
          ..write('discountValue: $discountValue, ')
          ..write('minSpend: $minSpend, ')
          ..write('conditions: $conditions, ')
          ..write('validFrom: $validFrom, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('status: $status, ')
          ..write('imagePath: $imagePath, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    merchant,
    kind,
    createdAt,
    category,
    tag,
    codeValue,
    codeFormat,
    discountType,
    discountValue,
    minSpend,
    conditions,
    validFrom,
    expiresAt,
    status,
    imagePath,
    source,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CouponRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.merchant == this.merchant &&
          other.kind == this.kind &&
          other.createdAt == this.createdAt &&
          other.category == this.category &&
          other.tag == this.tag &&
          other.codeValue == this.codeValue &&
          other.codeFormat == this.codeFormat &&
          other.discountType == this.discountType &&
          other.discountValue == this.discountValue &&
          other.minSpend == this.minSpend &&
          other.conditions == this.conditions &&
          other.validFrom == this.validFrom &&
          other.expiresAt == this.expiresAt &&
          other.status == this.status &&
          other.imagePath == this.imagePath &&
          other.source == this.source);
}

class CouponsCompanion extends UpdateCompanion<CouponRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> merchant;
  final Value<String> kind;
  final Value<DateTime> createdAt;
  final Value<String?> category;
  final Value<String?> tag;
  final Value<String?> codeValue;
  final Value<String?> codeFormat;
  final Value<String> discountType;
  final Value<double?> discountValue;
  final Value<double?> minSpend;
  final Value<String?> conditions;
  final Value<DateTime?> validFrom;
  final Value<DateTime?> expiresAt;
  final Value<String> status;
  final Value<String?> imagePath;
  final Value<String> source;
  final Value<int> rowid;
  const CouponsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.merchant = const Value.absent(),
    this.kind = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.category = const Value.absent(),
    this.tag = const Value.absent(),
    this.codeValue = const Value.absent(),
    this.codeFormat = const Value.absent(),
    this.discountType = const Value.absent(),
    this.discountValue = const Value.absent(),
    this.minSpend = const Value.absent(),
    this.conditions = const Value.absent(),
    this.validFrom = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.status = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CouponsCompanion.insert({
    required String id,
    required String title,
    required String merchant,
    required String kind,
    required DateTime createdAt,
    this.category = const Value.absent(),
    this.tag = const Value.absent(),
    this.codeValue = const Value.absent(),
    this.codeFormat = const Value.absent(),
    required String discountType,
    this.discountValue = const Value.absent(),
    this.minSpend = const Value.absent(),
    this.conditions = const Value.absent(),
    this.validFrom = const Value.absent(),
    this.expiresAt = const Value.absent(),
    required String status,
    this.imagePath = const Value.absent(),
    required String source,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       merchant = Value(merchant),
       kind = Value(kind),
       createdAt = Value(createdAt),
       discountType = Value(discountType),
       status = Value(status),
       source = Value(source);
  static Insertable<CouponRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? merchant,
    Expression<String>? kind,
    Expression<DateTime>? createdAt,
    Expression<String>? category,
    Expression<String>? tag,
    Expression<String>? codeValue,
    Expression<String>? codeFormat,
    Expression<String>? discountType,
    Expression<double>? discountValue,
    Expression<double>? minSpend,
    Expression<String>? conditions,
    Expression<DateTime>? validFrom,
    Expression<DateTime>? expiresAt,
    Expression<String>? status,
    Expression<String>? imagePath,
    Expression<String>? source,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (merchant != null) 'merchant': merchant,
      if (kind != null) 'kind': kind,
      if (createdAt != null) 'created_at': createdAt,
      if (category != null) 'category': category,
      if (tag != null) 'tag': tag,
      if (codeValue != null) 'code_value': codeValue,
      if (codeFormat != null) 'code_format': codeFormat,
      if (discountType != null) 'discount_type': discountType,
      if (discountValue != null) 'discount_value': discountValue,
      if (minSpend != null) 'min_spend': minSpend,
      if (conditions != null) 'conditions': conditions,
      if (validFrom != null) 'valid_from': validFrom,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (status != null) 'status': status,
      if (imagePath != null) 'image_path': imagePath,
      if (source != null) 'source': source,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CouponsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? merchant,
    Value<String>? kind,
    Value<DateTime>? createdAt,
    Value<String?>? category,
    Value<String?>? tag,
    Value<String?>? codeValue,
    Value<String?>? codeFormat,
    Value<String>? discountType,
    Value<double?>? discountValue,
    Value<double?>? minSpend,
    Value<String?>? conditions,
    Value<DateTime?>? validFrom,
    Value<DateTime?>? expiresAt,
    Value<String>? status,
    Value<String?>? imagePath,
    Value<String>? source,
    Value<int>? rowid,
  }) {
    return CouponsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      merchant: merchant ?? this.merchant,
      kind: kind ?? this.kind,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      tag: tag ?? this.tag,
      codeValue: codeValue ?? this.codeValue,
      codeFormat: codeFormat ?? this.codeFormat,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      minSpend: minSpend ?? this.minSpend,
      conditions: conditions ?? this.conditions,
      validFrom: validFrom ?? this.validFrom,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      imagePath: imagePath ?? this.imagePath,
      source: source ?? this.source,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (merchant.present) {
      map['merchant'] = Variable<String>(merchant.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    if (codeValue.present) {
      map['code_value'] = Variable<String>(codeValue.value);
    }
    if (codeFormat.present) {
      map['code_format'] = Variable<String>(codeFormat.value);
    }
    if (discountType.present) {
      map['discount_type'] = Variable<String>(discountType.value);
    }
    if (discountValue.present) {
      map['discount_value'] = Variable<double>(discountValue.value);
    }
    if (minSpend.present) {
      map['min_spend'] = Variable<double>(minSpend.value);
    }
    if (conditions.present) {
      map['conditions'] = Variable<String>(conditions.value);
    }
    if (validFrom.present) {
      map['valid_from'] = Variable<DateTime>(validFrom.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CouponsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('merchant: $merchant, ')
          ..write('kind: $kind, ')
          ..write('createdAt: $createdAt, ')
          ..write('category: $category, ')
          ..write('tag: $tag, ')
          ..write('codeValue: $codeValue, ')
          ..write('codeFormat: $codeFormat, ')
          ..write('discountType: $discountType, ')
          ..write('discountValue: $discountValue, ')
          ..write('minSpend: $minSpend, ')
          ..write('conditions: $conditions, ')
          ..write('validFrom: $validFrom, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('status: $status, ')
          ..write('imagePath: $imagePath, ')
          ..write('source: $source, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CouponsTable coupons = $CouponsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [coupons];
}

typedef $$CouponsTableCreateCompanionBuilder = CouponsCompanion Function({
  required String id,
  required String title,
  required String merchant,
  required String kind,
  required DateTime createdAt,
  Value<String?> category,
  Value<String?> tag,
  Value<String?> codeValue,
  Value<String?> codeFormat,
  required String discountType,
  Value<double?> discountValue,
  Value<double?> minSpend,
  Value<String?> conditions,
  Value<DateTime?> validFrom,
  Value<DateTime?> expiresAt,
  required String status,
  Value<String?> imagePath,
  required String source,
  Value<int> rowid,
});
typedef $$CouponsTableUpdateCompanionBuilder = CouponsCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String> merchant,
  Value<String> kind,
  Value<DateTime> createdAt,
  Value<String?> category,
  Value<String?> tag,
  Value<String?> codeValue,
  Value<String?> codeFormat,
  Value<String> discountType,
  Value<double?> discountValue,
  Value<double?> minSpend,
  Value<String?> conditions,
  Value<DateTime?> validFrom,
  Value<DateTime?> expiresAt,
  Value<String> status,
  Value<String?> imagePath,
  Value<String> source,
  Value<int> rowid,
});

class $$CouponsTableFilterComposer
    extends Composer<_$AppDatabase, $CouponsTable> {
  $$CouponsTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get merchant => $composableBuilder(
    column: $table.merchant,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codeValue => $composableBuilder(
    column: $table.codeValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codeFormat => $composableBuilder(
    column: $table.codeFormat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get discountType => $composableBuilder(
    column: $table.discountType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get discountValue => $composableBuilder(
    column: $table.discountValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get minSpend => $composableBuilder(
    column: $table.minSpend,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conditions => $composableBuilder(
    column: $table.conditions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get validFrom => $composableBuilder(
    column: $table.validFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CouponsTableOrderingComposer
    extends Composer<_$AppDatabase, $CouponsTable> {
  $$CouponsTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get merchant => $composableBuilder(
    column: $table.merchant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codeValue => $composableBuilder(
    column: $table.codeValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codeFormat => $composableBuilder(
    column: $table.codeFormat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get discountType => $composableBuilder(
    column: $table.discountType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get discountValue => $composableBuilder(
    column: $table.discountValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get minSpend => $composableBuilder(
    column: $table.minSpend,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conditions => $composableBuilder(
    column: $table.conditions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get validFrom => $composableBuilder(
    column: $table.validFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CouponsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CouponsTable> {
  $$CouponsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get merchant =>
      $composableBuilder(column: $table.merchant, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => column);

  GeneratedColumn<String> get codeValue =>
      $composableBuilder(column: $table.codeValue, builder: (column) => column);

  GeneratedColumn<String> get codeFormat => $composableBuilder(
    column: $table.codeFormat,
    builder: (column) => column,
  );

  GeneratedColumn<String> get discountType => $composableBuilder(
    column: $table.discountType,
    builder: (column) => column,
  );

  GeneratedColumn<double> get discountValue => $composableBuilder(
    column: $table.discountValue,
    builder: (column) => column,
  );

  GeneratedColumn<double> get minSpend =>
      $composableBuilder(column: $table.minSpend, builder: (column) => column);

  GeneratedColumn<String> get conditions => $composableBuilder(
    column: $table.conditions,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get validFrom =>
      $composableBuilder(column: $table.validFrom, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$CouponsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CouponsTable,
          CouponRow,
          $$CouponsTableFilterComposer,
          $$CouponsTableOrderingComposer,
          $$CouponsTableAnnotationComposer,
          $$CouponsTableCreateCompanionBuilder,
          $$CouponsTableUpdateCompanionBuilder,
          (CouponRow, BaseReferences<_$AppDatabase, $CouponsTable, CouponRow>),
          CouponRow,
          PrefetchHooks Function()
        > {
  $$CouponsTableTableManager(_$AppDatabase db, $CouponsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CouponsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CouponsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CouponsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> merchant = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String?> tag = const Value.absent(),
                Value<String?> codeValue = const Value.absent(),
                Value<String?> codeFormat = const Value.absent(),
                Value<String> discountType = const Value.absent(),
                Value<double?> discountValue = const Value.absent(),
                Value<double?> minSpend = const Value.absent(),
                Value<String?> conditions = const Value.absent(),
                Value<DateTime?> validFrom = const Value.absent(),
                Value<DateTime?> expiresAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CouponsCompanion(
                id: id,
                title: title,
                merchant: merchant,
                kind: kind,
                createdAt: createdAt,
                category: category,
                tag: tag,
                codeValue: codeValue,
                codeFormat: codeFormat,
                discountType: discountType,
                discountValue: discountValue,
                minSpend: minSpend,
                conditions: conditions,
                validFrom: validFrom,
                expiresAt: expiresAt,
                status: status,
                imagePath: imagePath,
                source: source,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String merchant,
                required String kind,
                required DateTime createdAt,
                Value<String?> category = const Value.absent(),
                Value<String?> tag = const Value.absent(),
                Value<String?> codeValue = const Value.absent(),
                Value<String?> codeFormat = const Value.absent(),
                required String discountType,
                Value<double?> discountValue = const Value.absent(),
                Value<double?> minSpend = const Value.absent(),
                Value<String?> conditions = const Value.absent(),
                Value<DateTime?> validFrom = const Value.absent(),
                Value<DateTime?> expiresAt = const Value.absent(),
                required String status,
                Value<String?> imagePath = const Value.absent(),
                required String source,
                Value<int> rowid = const Value.absent(),
              }) => CouponsCompanion.insert(
                id: id,
                title: title,
                merchant: merchant,
                kind: kind,
                createdAt: createdAt,
                category: category,
                tag: tag,
                codeValue: codeValue,
                codeFormat: codeFormat,
                discountType: discountType,
                discountValue: discountValue,
                minSpend: minSpend,
                conditions: conditions,
                validFrom: validFrom,
                expiresAt: expiresAt,
                status: status,
                imagePath: imagePath,
                source: source,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CouponsTable, CouponRow>(table),
                  BaseReferences<_$AppDatabase, $CouponsTable, CouponRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CouponsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CouponsTable,
      CouponRow,
      $$CouponsTableFilterComposer,
      $$CouponsTableOrderingComposer,
      $$CouponsTableAnnotationComposer,
      $$CouponsTableCreateCompanionBuilder,
      $$CouponsTableUpdateCompanionBuilder,
      (CouponRow, BaseReferences<_$AppDatabase, $CouponsTable, CouponRow>),
      CouponRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CouponsTableTableManager get coupons =>
      $$CouponsTableTableManager(_db, _db.coupons);
}
