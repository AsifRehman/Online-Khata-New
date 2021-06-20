import 'dart:io';
import 'dart:async';

import 'package:onlinekhata/utils/constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'model/LedgerModel.dart';
import 'model/PartyModel.dart';

class DbProvider {
  Future<Database> init() async {
    Directory directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, databaseName);

    return await openDatabase(
      //open the database or create a database if there isn't any
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute(partyTable);
        await db.execute(legderTable);
        await db.execute(partLegTable);
        await db.execute(partLegSumTable);
      },
    );
  }

  static const partyTable = """
          CREATE TABLE IF NOT EXISTS Party (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          partyID TEXT,
          partyName TEXT,
          debit INTEGER,
          credit INTEGER,
          total INTEGER
          );""";

  static const legderTable = """
          CREATE TABLE IF NOT EXISTS Ledger (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          partyID TEXT,
          vocNo TEXT,
          tType TEXT,
          description TEXT,
          date INTEGER,
          debit INTEGER,
          credit INTEGER
          );""";

  static const partLegTable = """
          CREATE VIEW IF NOT EXISTS PartyLeg AS SELECT partyID, partyName, debit, credit, IFNULL(debit,0)-IFNULL(credit,0) as Bal FROM Party UNION ALL SELECT partyID, Null, debit, credit, IFNULL(debit,0)-IFNULL(credit,0) as Bal FROM Ledger;""";

  static const partLegSumTable = """
          CREATE VIEW IF NOT EXISTS PartyLegSum AS SELECT partyID, MAX(partyName) as partyName, debit, credit, SUM(Bal) as Bal FROM PartyLeg GROUP BY partyID;""";

  Future addPartyItem(var collection) async {
    final db = await init(); //open database

    await db.transaction((txn) async {
      var batch = txn.batch();

      await collection.find().forEach((v) async {
        final partyModel = PartyModel(
          partyID: v['PartyTypeId'].toString(),
          partyName: v['PartyName'].toString(),
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
        );

        await batch.insert(
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
    final db = await init(); //open database
    await db.transaction((txn) async {
      var batch = txn.batch();

      await ledgerCollection.find().forEach((v) async {
        final ledgerModel = LedgerModel(
            partyID: v['_id'].toString(),
            vocNo: v['VocNo'].toString(),
            tType: v['TType'].toString(),
            description: v['Description'].toString(),
            date: getDateTimeLedgerFormat(v['Date']),
            // date: 19939389822,
            debit: isKyNotNull(v['Debit']) ? v['Debit'] : 0,
            credit: isKyNotNull(v['Credit']) ? v['Credit'] : 0);

        await batch.insert(
          legderTableName,
          ledgerModel.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      });

      await batch.commit();
    });
  }

  Future<List<PartyModel>> fetchParties() async {
    final db = await init();
    final maps = await db.query(partyTableName);

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
    final db = await init();
    final maps = await db.query(partyLegSumCreateViewTableName);

    return List.generate(maps.length, (i) {
      //create a list of Categories
      return PartyModel(
        partyID: maps[i]['partyID'],
        partyName: maps[i]['partyName'],
        debit: maps[i]['debit'],
        credit: maps[i]['credit'],
        total: maps[i]['Bal'],
      );
    });
  }

  Future<List<PartyModel>> fetchPartyByPartName(String partyName) async {
    //returns the Categories as a list (array)

    final db = await init();
    final maps = await db.query(partyTableName,
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

    final db = await init();
    final maps = await db.query(partyLegSumCreateViewTableName,
        where: "LOWER(partyName) LIKE ?", whereArgs: ['%$partyName%']);

    return List.generate(maps.length, (i) {
      //create a list of Categories
      return PartyModel(
        partyID: maps[i]['partyID'],
        partyName: maps[i]['partyName'],
        debit: maps[i]['debit'],
        credit: maps[i]['credit'],
        total: maps[i]['Bal'],
      );
    });
  }

  Future<List<LedgerModel>> fetchLedger() async {
    final db = await init();
    final maps = await db.query(legderTableName);

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

    final db = await init();
    final maps = await db.query(legderTableName,
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

  Future closeDbConnection() async {
    final db = await init();

    await db.close();
  }
}
