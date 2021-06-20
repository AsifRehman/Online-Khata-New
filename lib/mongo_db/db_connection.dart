import 'dart:ffi';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:onlinekhata/sqflite_database/DbProvider.dart';
import 'package:onlinekhata/sqflite_database/model/LedgerModel.dart';
import 'package:onlinekhata/sqflite_database/model/PartyModel.dart';
import 'package:onlinekhata/utils/constants.dart';

var db;
DbProvider dbProvider = DbProvider();

void dbOpen() async {}

Future<void> openDbConnection() async {
  db = await Db.create(
      'mongodb+srv://asif:cosoftcon123@cluster0.k6lme.mongodb.net/faisal_saeed?retryWrites=true&w=majority');
  await db.open();
}

Future<void> getPartyData() async {
  try {

    var collection = db.collection('Party');

    await   dbProvider.addPartyItem(collection);


  } catch (e) {
    int  i=9;
  }
}
Future<void> getLedgerData() async {
  try {

    var ledgerCollection = db.collection('Ledger');
    await  dbProvider.addLedgerItem(ledgerCollection);


  } catch (e) {
    int i=0;
  }
}
