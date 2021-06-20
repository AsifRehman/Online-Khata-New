class LedgerModel {
  int id;
  int partyID;
  String vocNo;
  String tType;
  String description;
  int date;
  int debit;
  int credit;
  int ts;

  LedgerModel({
    this.partyID,
    this.vocNo,
    this.tType,
    this.description,
    this.date,
    this.debit,
    this.credit,
    this.ts,
  });

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
      "ts": ts,
    };
  }
}
