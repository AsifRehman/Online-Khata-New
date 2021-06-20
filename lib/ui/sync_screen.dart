import 'dart:io';

import 'package:flutter/material.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:onlinekhata/ui/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:onlinekhata/mongo_db/db_connection.dart';
import 'package:onlinekhata/sqflite_database/DbProvider.dart';
import 'package:onlinekhata/sqflite_database/model/PartyModel.dart';
import 'package:onlinekhata/utils/constants.dart';

class SyncScreen extends StatefulWidget {
  static String id = 'sync_screen';

  @override
  _SyncScreenState createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  bool loading = false;
  DbProvider dbProvider = DbProvider();
  List<PartyModel> partyModelList = List();
  List<DocumentSnapshot> _partiesList = [];
  List<DocumentSnapshot> _ledgerList = [];

  bool viewHomeBtn = false;

  @override
  void initState() {
    getLocalDb().then((value) {
      if (value != null && value == true) {
        setState(() {
          viewHomeBtn = true;
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            backgroundColor: Colors.blue,
            body: ModalProgressHUD(
                inAsyncCall: loading,
                child: Container(
                  margin: EdgeInsets.fromLTRB(0.0, 0, 0.0, 5.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => HomeScreen()));
                        },
                        child: Visibility(
                          visible: viewHomeBtn,
                          child: Container(
                            height: 40,
                            margin: EdgeInsets.fromLTRB(20.0, 0, 20.0, 0.0),
                            padding: const EdgeInsets.all(5.0),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset("assets/ic_home.png",
                                    width: 18, height: 18, color: Colors.white),
                                Container(
                                    margin:
                                        EdgeInsets.fromLTRB(5.0, 0, 0.0, 0.0),
                                    child: Text(
                                      'Go To Home',
                                      style: TextStyle(color: Colors.white),
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          getPartiesFromServer();
                        },
                        child: Container(
                          margin: EdgeInsets.fromLTRB(20.0, 15, 20.0, 0.0),
                          height: 40,
                          padding: const EdgeInsets.all(5.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset("assets/ic_synchronize.png",
                                  width: 18, height: 18, color: Colors.white),
                              Container(
                                  margin:
                                      EdgeInsets.fromLTRB(5.0, 0, 12.0, 0.0),
                                  child: Text(
                                    'Sync Data',
                                    style: TextStyle(color: Colors.white),
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ))));
  }

  getPartiesFromServer() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        setState(() {
          loading = true;
        });

        openDbConnection().then((value) async {
          getPartyData().then((value) async {
            getLedger();
          });
          // getLedger();

// setState(() {
//   viewHomeBtn=true;
//   loading= false;
// });
        });
      }
    } on SocketException catch (_) {
      setState(() {
        loading = false;
      });
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: new Text("No Network Connection"),
              content: new Text("Please connect to an Internet connection"),
              actions: <Widget>[
                new FlatButton(
                  child: new Text('OK'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          });
    }
  }

  getLedger() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        await getLedgerData().then((value) {
          setLocalDb(true);
          setState(() {
            loading = false;
            viewHomeBtn = true;
          });
          showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: new Text("Alert"),
                  content: new Text("Data Synced Successfully."),
                  actions: <Widget>[
                    new FlatButton(
                      child: new Text('OK'),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                );
              });
        });
      }
    } on SocketException catch (_) {
      setState(() {
        loading = false;
      });
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: new Text("No Network Connection"),
              content: new Text("Please connect to an Internet connection"),
              actions: <Widget>[
                new FlatButton(
                  child: new Text('OK'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          });
    }
  }

  int getDateTimeFormat(Timestamp date) {
    return date.microsecondsSinceEpoch;
  }
}
