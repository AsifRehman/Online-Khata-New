import 'dart:io';
import 'dart:async';

import 'package:onlinekhata/utils/constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'model/LedgerModel.dart';
import 'model/PartyModel.dart';

class sqliteDbProvider {
  Future<Database> init() async {
    Directory directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, databaseName);

    return await openDatabase(
      //open the database or create a database if there isn't any
      path,
      version: 1,
      onCreate: (Database sqliteDb, int version) async {
        await sqliteDb.execute(partyTable);
        await sqliteDb.execute(legderTable);
        await sqliteDb.execute(partLegTable);
        await sqliteDb.execute(partLegSumTable);
      },
    );
  }

  static const partyTable = """
          CREATE TABLE IF NOT EXISTS Party (
          partyID INTEGER PRIMARY KEY AUTOINCREMENT,
          partyName TEXT,
          partyTypeId INTEGER,
          debit INTEGER,
          credit INTEGER,
          total INTEGER,
          ts INTEGER
          );""";

  static const legderTable = """
          CREATE TABLE IF NOT EXISTS Ledger (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          partyID INTEGER,
          vocNo INTEGER,
          tType TEXT,
          description TEXT,
          date INTEGER,
          debit INTEGER,
          credit INTEGER,
          ts INTEGER
          );""";

  static const partLegTable = """
          CREATE VIEW IF NOT EXISTS PartyLeg AS SELECT partyID, partyName, debit, credit, IFNULL(debit,0)-IFNULL(credit,0) as Bal FROM Party UNION ALL SELECT partyID, Null, debit, credit, IFNULL(debit,0)-IFNULL(credit,0) as Bal FROM Ledger;""";

  static const partLegSumTable = """
          CREATE VIEW IF NOT EXISTS PartyLegSum AS SELECT partyID, MAX(partyName) as partyName, debit, credit, SUM(Bal) as Bal FROM PartyLeg GROUP BY partyID;""";

  Future addPartyItem(var collection) async {
    final sqliteDb = await init(); //open database

    await sqliteDb.transaction((txn) async {
      var batch = txn.batch();

      await collection.find().forEach((v) async {
        final partyModel = PartyModel(
          partyID: v['_id'],
          partyName: v['PartyName'].toString(),
          partyTypeId: v['PartyTypeId'],
          debit: isKyNotNull(v['Debit'].toString()) ? v['Debit'] : 0,
          credit: isKyNotNull(v['Credit']) ? v['Credit'] : 0,
          total: v['Credit'] == null
              ? v['Debit']
              : v['Debit'] == null
                  ? v['Credit']
                  : (int.parse(v['Debit'].toString()) -
                              int.parse(v['Credit'].toString())) >
                          0
                      ? (int.parse(v['Debit'].toString()) -
                          int.parse(v['Credit'].toString()))
                      : (int.parse(v['Debit'].toString()) -
                              int.parse(v['Credit'].toString()))
                          .abs(),
          ts: v['ts'],
        );

        batch.insert(
          partyTableName,
          partyModel.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      });

      await batch.commit();
    });
  }

  //Leger table
  Future addLedgerItem(var ledgerCollection) async {
    final sqliteDb = await init(); //open database
    await sqliteDb.transaction((txn) async {
      var batch = txn.batch();

      await ledgerCollection.find().forEach((v) async {
        final ledgerModel = LedgerModel(
            partyID: v['_id'],
            vocNo: v['VocNo'].toString(),
            tType: v['TType'].toString(),
            description: v['Description'].toString(),
            date: getDateTimeLedgerFormat(v['Date']),
            // date: 19939389822,
            debit: isKyNotNull(v['Debit']) ? v['Debit'] : 0,
            credit: isKyNotNull(v['Credit']) ? v['Credit'] : 0);

        batch.insert(
          legderTableName,
          ledgerModel.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      });

      await batch.commit();
    });
  }

  Future<List<PartyModel>> fetchParties() async {
    final sqliteDb = await init();
    final maps = await sqliteDb.query(partyTableName);

    return List.generate(maps.length, (i) {
      //create a list of Categories
      return PartyModel(
        partyID: maps[i]['partyID'],
        partyName: maps[i]['partyName'],
        debit: maps[i]['debit'],
        credit: maps[i]['credit'],
        total: maps[i]['total'],
      );
    });
  }

  Future<List<PartyModel>> fetchPartyLegSum() async {
    final sqliteDb = await init();
    final maps = await sqliteDb.query(partyLegSumCreateViewTableName);

    return List.generate(maps.length, (i) {
      //create a list of Categories
      return PartyModel(
        partyID: maps[i]['partyID'].toString(),
        partyName: maps[i]['partyName'],
        debit: maps[i]['debit'],
        credit: maps[i]['credit'],
        total: maps[i]['Bal'],
      );
    });
  }

  Future<List<PartyModel>> fetchPartyByPartName(String partyName) async {
    //returns the Categories as a list (array)

    final sqliteDb = await init();
    final maps = await sqliteDb.query(partyTableName,
        where: "LOWER(partyName) LIKE ?", whereArgs: ['%$partyName%']);

    return List.generate(maps.length, (i) {
      //create a list of Categories
      return PartyModel(
        partyID: maps[i]['partyID'],
        partyName: maps[i]['partyName'],
        debit: maps[i]['debit'],
        credit: maps[i]['credit'],
        total: maps[i]['total'],
      );
    });
  }

  Future<List<PartyModel>> fetchPartyLegSumByPartName(String partyName) async {
    //returns the Categories as a list (array)

    final sqliteDb = await init();
    final maps = await sqliteDb.query(partyLegSumCreateViewTableName,
        where: "LOWER(partyName) LIKE ?", whereArgs: ['%$partyName%']);

    return List.generate(maps.length, (i) {
      //create a list of Categories
      return PartyModel(
        partyID: maps[i]['partyID'].toString(),
        partyName: maps[i]['partyName'],
        debit: maps[i]['debit'],
        credit: maps[i]['credit'],
        total: maps[i]['Bal'],
      );
    });
  }

  Future<List<LedgerModel>> fetchLedger() async {
    final sqliteDb = await init();
    final maps = await sqliteDb.query(legderTableName);

    return List.generate(maps.length, (i) {
      //create a list of Categories
      return LedgerModel(
        partyID: maps[i]['partyID'],
        vocNo: maps[i]['vocNo'],
        tType: maps[i]['tType'],
        description: maps[i]['description'],
        date: maps[i]['date'],
        debit: maps[i]['debit'],
        credit: maps[i]['credit'],
      );
    });
  }

  Future<List<LedgerModel>> fetchLedgerByPartyId(String partyId) async {
    //returns the Categories as a list (array)

    final sqliteDb = await init();
    final maps = await sqliteDb.query(legderTableName,
        where: "partyID = ?",
        orderBy: "date DESC",
        whereArgs: [
          partyId
        ]); //query all the rows in a table as an array of maps

    return List.generate(maps.length, (i) {
      //create a list of Categories
      return LedgerModel(
        partyID: maps[i]['partyID'],
        vocNo: maps[i]['vocNo'],
        tType: maps[i]['tType'],
        description: maps[i]['description'],
        date: maps[i]['date'],
        debit: maps[i]['debit'],
        credit: maps[i]['credit'],
      );
    });
  }

  Future closesqliteDbConnection() async {
    final sqliteDb = await init();

    await sqliteDb.close();
  }
}
