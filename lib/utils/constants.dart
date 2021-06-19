import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';


Firestore databaseReference = Firestore.instance;
SharedPreferences sharedPreferences;


final String databaseName = "online_khata.db";
final String partyTableName = "Party";
final String legderTableName = "Ledger";



setLocalDb(bool localDb) async {
  sharedPreferences = await SharedPreferences.getInstance();
  sharedPreferences.setBool("localDb", localDb);
  sharedPreferences.commit();
}

Future<bool> getLocalDb() async {
  sharedPreferences = await SharedPreferences.getInstance();
  return sharedPreferences.getBool("localDb");
}


String getDateTimeFormat(String date) {
  final DateTime now = DateTime.parse(date);
  // final DateFormat formatter = DateFormat('dd MMM yyyy h:mm a');
  final DateFormat formatter = DateFormat('dd MMM yyyy');
  final String formatted = formatter.format(now);

  return formatted;
}


bool isKeyNotNull(Object param1) {
  if (param1 != null && param1 !="")
    return true;
  else
    return false;
}


bool isKyNotNull(Object param1) {
  if (param1 != null)
    return true;
  else
    return false;
}