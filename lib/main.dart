import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

void main()  {
WidgetsFlutterBinding.ensureInitialized();
runApp(SqliteApp()); }

class SqliteApp extends StatefulWidget {
  const SqliteApp({Key? key}) : super(key: key);

  @override
  _SqliteAppState createState() => _SqliteAppState();
}

class _SqliteAppState extends State<SqliteApp> {
  final TextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: TextController,
          ),
        ),
        body : Center (
          child :FutureBuilder<List<Grocery>>(
            future: DatabaseHelper.instance.getGroceries(),
            builder: (BuildContext context, AsyncSnapshot<List<Grocery>> snapshot) {
              if (!snapshot.hasData) {
                return Center(child: Text ('Loading...'));
              }
              return snapshot.data!.isEmpty
              ? Center(child: Text('No Groceries in List.'))
                    :
               ListView(
                children : snapshot.data!.map((Grocery){
                  return Center(
                    child: ListTile(
                      title: Text(Grocery.name),
                    )
                  );
                }).toList(),
              );
            }
          ),
        )
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.save),
          onPressed: () async {
            await DatabaseHelper.instance.add(
              grocery(name: TextController.text),
            );
          },
        ),
      ),
    );
  }
}

class Grocery {
  final int? id;
  final String name;

  Grocery({this.id, required this.name});

  factory Grocery.fromMap(Map<String, dynamic> json) => new Grocery(
        id: json['id'],
        name: json['name'],
      );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;
  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'groceries.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
}
}

Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE groceries(
          id INTEGER PRIMARY KEY,
          name TEXT
      )
      ''');
  }

  Future<List<Grocery>> getGroceries() async {
    Database db = await instance.database;
    var groceries = await db.query('groceries', orderBy: 'name');
    List<Grocery> groceryList = groceries.isNotEmpty
        ? groceries.map((c) => Grocery.fromMap(c)).toList()
        : [];
    return groceryList;
  }

  Future<int> add(Grocery grocery) async {
    Database db = await instance.database;
    return await db.insert('groceries', grocery.toMap());
  }

   Future<int> remove(int id) async {
    Database db = await instance.database;
    return await db.delete('groceries', where: 'id = ?', whereArgs: [id]);
  }