import 'package:mongo_dart/mongo_dart.dart';

var db;

void dbOpen() async {}

Future<void> openDbConnection() async {
  db = await Db.create(
      'mongodb+srv://asif:cosoftcon123@cluster0.k6lme.mongodb.net/fsp?retryWrites=true&w=majority');
  await db.open();
}

Future<List<String>> getPartyData() async {
  try {
    List<String> s= new List();
    var collection = db.collection('Party');

    await collection.find().forEach((v) {
      // print(v);
      s.add(v['PartyName']);
    });

    return s;
  } catch (e) {
    var i = 0;
  }
}
