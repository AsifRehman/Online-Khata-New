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
          CREATE VIEW IF NOT EXISTS PartyLegSum AS SELECT partyID, MAX(partyName) as partyName, SUM(Bal) as Bal FROM PartyLeg GROUP BY partyID;""";

  Future<int> addPartyItem(PartyModel item) async {
    final db = await init(); //open database

    return db.insert(
      partyTableName,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
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
    final maps = await db.query(partLegSumTable);

    return List.generate(maps.length, (i) {
      //create a list of Categories
      return PartyModel(
        partyID: maps[i]['partyID'],
        partyName: maps[i]['partyName'],
        // debit: maps[i]['debit'],
        // credit: maps[i]['credit'],
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

  //Leger table

  Future<int> addLedgerItem(LedgerModel item) async {
    final db = await init(); //open database

    return db.insert(
      legderTableName,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
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
       where: "partyID = ?" ,
      orderBy: "date DESC",
      whereArgs: [
          partyId
        ]
    ); //query all the rows in a table as an array of maps

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

// Future<int> updateTotalSumOfCategories(String categoryId) async{
//
//   final db = await init();
//   int result = await db.rawUpdate('''
//   UPDATE $billsCategoryTableName
//   SET totalBillsCost = (SELECT SUM(billCost) FROM $billsTableName WHERE billCategoryId = ?)
//    WHERE categoryId = ?
//   ''',
//       [categoryId, categoryId]);
//
//   return result;
// }
}
