// Copyright (c) 2024 EShare Authors. All rights reserved.

// ignore_for_file: implementation_imports

import 'package:corekit/src/base/base_model.dart';
import 'package:corekit/src/store/model_transformation.dart';
import 'package:foundation/foundation.dart';
import 'package:path/path.dart';
import 'package:rusty_dart/rusty_dart.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/src/api/log_level.dart';
import 'package:sembast_sqflite/sembast_sqflite.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:utils/utils.dart';

final Set<Future<void> Function(Transaction)> _ledger = {};

abstract class CoreDatabase {
  CoreDatabase(
    String name, {
    this.enableLog = false,
  }) : _dbName = '$name.store',
       _eternal = false;

  /// For when data stored in the db should persist beyond
  /// a user's session
  CoreDatabase.eternal(
    String name, {
    this.enableLog = false,
  }) : _dbName = '${name}_eternal.store',
       _eternal = true;

  late Database _db;
  late DatabaseFactory _dbFactory;
  late String _dbPath;
  final bool _eternal;
  final String _dbName;
  final bool enableLog;

  /// Initialize the database
  ///
  /// This must be invoked before any other functions are accessed
  Future<void> init() async {
    _setupLogging();
    _dbPath = join(await PathUtil().dBDirPath, _dbName);
    return _open();
  }

  /// Clear the database of all data
  ///
  /// Unless it is marked as eternal
  Future<void> purge() async {
    await close();
    if (_eternal) return;

    await _dbFactory.deleteDatabase(_dbPath);
    return _open();
  }

  /// Close the database
  ///
  /// If you've triggered this, make sure you open the
  /// db my invoking the [init] function
  Future<void> close() async {
    return _db.close();
  }

  Future<void> _open() async {
    _dbFactory = getDatabaseFactorySqflite(sqflite.databaseFactory);
    _db = await _dbFactory.openDatabase(_dbPath);
  }

  // Toggle logs for the database
  // Since sembast does not provide any apis
  // to toggle it's logging, we had to import
  // it's internal file
  void _setupLogging() {
    sembastLogLevel = enableLog ? SembastLogLevel.verbose : SembastLogLevel.none;
  }

  /// Open a store to perform CRUD operation
  ///
  /// Store name is derived from the it's model type
  ///
  /// Additionally you can also append a [suffix] to the name
  /// to avoid clashing
  CoreStore<T> openStore<T extends BaseModel>({String? suffix});

  /// Run all CRUD operations added in the batch
  Future<void> runBatch() async {
    await _db.transaction((txn) async {
      for (final entry in _ledger) {
        await entry(txn);
      }
    });

    _ledger.clear();
  }
}

abstract class CoreStore<T extends BaseModel> with ModelTransformation {
  CoreStore(
    this._db, {
    String? suffix,
  }) {
    final baseName = resolveStoreName;
    final storeName = suffix.isNullOrEmpty ? baseName : '$baseName-$suffix';
    _ref = stringMapStoreFactory.store(storeName);
  }

  final Database _db;
  late final StoreRef<String, Map<String, Object?>> _ref;

  /// Insert/update a model with value from field marked as [@primaryKey] as key.
  ///
  /// If a model exists with the same primaryKey, it will be replaced with the passed model
  ///
  /// If no field is marked as [@primaryKey], models will be added without any key.
  ///
  /// if [merge] is true and the field exists, data is merged
  ///
  /// Multiple insert operations should always be scoped inside a batch
  /// by enabling [inBatch]
  Future<void> insert(List<T> models, {bool clear = false, bool merge = true, bool inBatch = false}) async {
    if (inBatch) {
      _ledger.add((txn) => _insert(models, transaction: txn, merge: merge));
    } else {
      await _db.transaction((txn) async {
        await _insert(models, transaction: txn);
      });
    }
  }

  /// Fetch data from the [CoreStore].
  /// via the usage of either [primaryKey] or [finder] to filter records.
  Future<Result<List<T>, FailureFoundation>> fetch({String? primaryKey, Finder? finder}) async {
    assert(primaryKey.isNull || finder.isNull, "Both 'primaryKey' and 'finder' can't be used at the same time.");

    if (primaryKey.isNotNull) {
      final record = await _ref.record(primaryKey!).get(_db);

      if (record.isNull) return Ok([]);

      return toModel(record!).match(ok: (value) => Ok([value]), err: (e) => Err(e));
    }
    final records = await _ref.find(_db, finder: finder);
    final models = <T>[];
    FailureFoundation? failure;

    for (final record in records) {
      final model = toModel(record.value);
      if (model.isErr) {
        failure = model.err!;
        break;
      }

      models.add(model.ok!);
    }

    if (failure.isNotNull) return Err(failure!);

    return Ok(models);
  }

  /// Fetches and groups data by [groupBy]
  ///
  /// This will return an empty map if the field passed to [groupBy] does not exist in the model
  ///
  /// Given the following list:
  /// ```
  /// [
  ///   Animal(name: Cat, group: Feline),
  ///   Animal(name: Tiger, group: Feline),
  ///   Animal(name: Dog, group: Canine),
  ///   Animal(name: Wolf, group: Canine),
  /// ]
  /// ```
  ///
  /// This would be grouped by (Animal.group) as follows:
  ///
  /// ```
  /// {
  ///   Feline : [
  ///               Animal(name: Cat, group: Feline),
  ///               Animal(name: Tiger, group: Feline),
  ///            ],
  ///   Canine : [
  ///               Animal(name: Dog, group: Canine),
  ///               Animal(name: Wolf, group: Canine),
  ///            ],
  /// }
  /// ```
  Future<Result<Map<String, List<T>>, FailureFoundation>> fetchAndGroup({
    required String groupBy,
    Finder? finder,
  }) async {
    final records = await _ref.find(_db, finder: finder);

    return transformMapToGroup(
      groupBy: groupBy,
      records: records,
      resolver: toModel,
    );
  }

  /// Fetches the first data from the [CoreStore].
  ///
  /// Either use [primaryKey] or [finder] to filter records.
  Future<Result<T, FailureFoundation>> fetchFirst({String? primaryKey, Finder? finder}) async {
    assert(
      primaryKey.isNull || finder.isNull,
      "Both 'primaryKey' and 'finder' can't be used at the same time.",
    );

    final Map<String, Object?>? record;
    if (primaryKey.isNull) {
      final result = await _ref.findFirst(_db, finder: finder);
      record = result?.value;
    } else {
      record = await _ref.record(primaryKey!).get(_db);
    }

    if (record.isNull) {
      return Err(
        const FailureFoundation(
          'No record found',
          source: 'dao',
        ),
      );
    }

    return toModel(record!);
  }

  /// Remove data from the db
  ///
  /// via the usage of [primaryKey] or by filtering through [finder]
  Future<void> delete({String? primaryKey, Finder? finder}) async {
    assert(primaryKey.isNull || finder.isNull, "Both 'primaryKey' and 'finder' can't be used at the same time.");

    if (primaryKey.isNull) {
      await _ref.delete(_db, finder: finder);
    }

    await _ref.record(primaryKey!).delete(_db);
  }

  Future<void> _insert(
    List<T> models, {
    bool clear = false,
    bool merge = true,
    required Transaction transaction,
  }) async {
    if (clear) await _ref.delete(transaction);

    for (final model in models) {
      final pk = model.primaryKey;
      final json = model.toJson();

      if (pk.isNullOrEmpty) {
        await _ref.add(transaction, json);
      } else {
        await _ref.record(pk!).put(transaction, json, merge: merge);
      }
    }
  }

  String get resolveStoreName;

  Result<T, FailureFoundation> toModel(Map<String, dynamic> record);
}
