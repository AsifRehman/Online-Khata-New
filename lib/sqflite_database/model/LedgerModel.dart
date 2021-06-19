import 'package:cloud_firestore/cloud_firestore.dart';

class LedgerModel {
  String partyID;
  String vocNo;
  String tType;
  String description;
  int date;
  int debit;
  int credit;

  LedgerModel(
      {this.partyID,
      this.vocNo,
      this.tType,
      this.description,
      this.date,
      this.debit,
      this.credit});

  Map<String, dynamic> toMap() {
    // used when inserting data to the database
    return <String, dynamic>{
      "partyID": partyID,
      "vocNo": vocNo,
      "tType": tType,
      "description": description,
      "date": date,
      "debit": debit,
      "credit": credit,
    };
  }
}
