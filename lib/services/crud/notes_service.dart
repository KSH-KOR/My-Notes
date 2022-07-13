
// work with sqlite database
// create, read, update, delete, find users and notes

// import dependencies
import 'dart:async' show StreamController;

import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:path/path.dart' as path show join;
import 'package:path_provider/path_provider.dart' as path_provider;

import 'crud_exception.dart';

// ## we need to construct our database path
// grab and hold up current database path
// every application developed with flutter have their own document directory
// join path of the document directory using the path dependency with the name specified in the database

// ## we need database users
// create databaseuser class inside notes_service.dart

// ## why stream?
// if note service directly talks to a database 
// == if note service doesnt have a ability to cache the note 
// => as soon as it got a command, 
// it doesnt know what to do 
// but it goes to the database and conduct the command
// => not good idea which is accessing the database everytime (for example, read entire things to just delete one row)
// => so it needs to be cached inside the application before the service go and hit the database
// 1. have a local list of notes <- caching
// 2. the local list is manipulated by user
// 3. if things are changed, UI automatically fetch or update the database

class NotesService { /*NotesService class should be singleton */

  NotesService._privateConstructor();
  static final NotesService _instance = NotesService._privateConstructor();
  factory NotesService() => _instance;

  sqflite.Database? _db; // from sqflite dependency

  //caching data -> reactive program
  //we need the stream and stream controller to cache data
  //stream controller is a mananger of stream for your interface
  List<DatabaseNote> _notes = []; //local list of fethced notes
  final _notesStreamController = 
    StreamController<List<DatabaseNote>>.broadcast(); /*<List<DatabaseNote>> is data type that the stream contains*/

  //getter for getting all the notes
  // streamController _notesStreamController contains _notes
  Stream<List<DatabaseNote>> get allNotes => _notesStreamController.stream; 

  Future<void> _cacheNotes() async {
    final allNotes = await getAllNotes();
    _notes = allNotes.toList();
    _notesStreamController.add(_notes);
  }

  sqflite.Database _getDatabaseOrThrow() {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpen();
    } else {
      return db;
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpen();
    } else {
      await db.close();
      _db = null;
    }
  }
  // ensure db is open by calling open() function
  Future<void> _ensureDbIsOpen() async{
    try{
      await open();
    } on DatabaseAlreadyOpenException{
      //empty
    }
  }
  //we need an async function that open database
  Future<void> open() async {
    //open and hold up the database
    if (_db != null) {
      throw DatabaseAlreadyOpenException();
    }
    try {
      //why try catch? -> in getApplicationDocumentsDirectory(), Throws a `MissingPlatformDirectoryException` if the system is unable to provide the directory.
      final docsPath = await path_provider
          .getApplicationDocumentsDirectory(); //get document directory
      final dbPath = path.join(docsPath.path,
          dbName); //join document directory and database file name
      final db = await sqflite.openDatabase(
          dbPath); //open database & if it doesnt exist then create the new one
      _db = db;

      //to create user table when the database doesn't exist
      await db.execute(createUserTable);

      //to create note table when the database doesn't exist
      await db.execute(createNoteTable);

      await _cacheNotes();
      //question: how flutter application create database table and read it?

    } on path_provider.MissingPlatformDirectoryException {
      throw UnableToGetDocumentsDirectory();
    }
  }

  Future<void> deleteUser({
    required String email,
  }) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      userTable,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (deletedCount != 1) throw CouldNotDeleteUser();
  }

  Future<DatabaseUser> createUser({
    required String email,
  }) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      //look for a given email on the email column in the user table
      userTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (results.isNotEmpty) throw UserAlreadyExist();

    final newUserId = await db.insert(userTable, {
      //for id, it will autumatically be increased by 1
      emailColumn: email.toLowerCase(),
    });

    return DatabaseUser(
      id: newUserId,
      email: email,
    );
  }

  Future<DatabaseUser> getUser({
    required String email,
  }) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      //look for a given email on the email column in the user table
      userTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (results.isEmpty) throw CouldNotFindUser();
    return DatabaseUser.fromRow(results.first);
  }

  Future<DatabaseUser> getOrCreateUser({required String email,}) async {
    late final DatabaseUser user;
    try{ 
      user = await getUser(email: email);
    } on CouldNotFindUser{
      user = await createUser(email: email);
    } catch(_){
      rethrow; // in case there is unexpected error, then throw it to the call site (break point)
    }
    return user;
  }

  Future<DatabaseNote> createNote({
    required DatabaseUser owner,
  }) async {
    // the ownder could be simply created from anywhere,
    // So we want to make sure if that ownder is really a user in database
    // for example, you can hack the note by creating databaseuser manually when you know a email is used in database.
    // make sure ownder exists in the database with the correct id
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final dbUser = await getUser(email: owner.email);
    if (dbUser != owner) throw CouldNotFindUser();

    // create note
    const text = '';
    final newNoteId = await db.insert(noteTable, {
      userIdColumn: owner.id,
      textColumn: text,
      isSyncedWithCloudColumn: 1,
    });

    final newNote = DatabaseNote(
        id: newNoteId, userId: owner.id, text: text, isSyncedWithCloud: true);

    _notes.add(newNote);
    _notesStreamController.add(_notes);

    return newNote;
  }

  Future<void> deleteNote({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    // delete note
    final deletedCount = await db.delete(
      noteTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if(deletedCount == 0) throw CouldNotDeleteNote();
    final countBeforeDeleting = _notes.length;
    _notes.removeWhere((note) => note.id == id);
    if(countBeforeDeleting != _notes.length) _notesStreamController.add(_notes);
  }

  Future<int> deleteAllNotes() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(noteTable);
    _notes = [];
    _notesStreamController.add(_notes);
    return deletedCount;
  }

  Future<DatabaseNote> getNote({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final notes = await db.query(
      //look for a given email on the email column in the note table
      userTable,
      limit: 1,
      where: 'id = ?',
      whereArgs: [id],
    );
    if(notes.isEmpty){
      throw CouldNotFindNote();
    } else{
      // creating an instance of databasenote updates local cache as well
      final foundNote =  DatabaseNote.fromRow(notes.first);  
      // remove old note with the same id and add the new one and then update stream
      _notes.removeWhere((note) => note.id == id);
      _notes.add(foundNote);
      _notesStreamController.add(_notes);
      return foundNote;
    }
    
  }

  Future<Iterable<DatabaseNote>> getAllNotes() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final notes = await db.query(noteTable);
    return notes.map((noteRow) => DatabaseNote.fromRow(noteRow));
  }

  //pass a note that you want to update and an update context which is a text
  Future<DatabaseNote> updateNote({
    required DatabaseNote note,
    required String text,
  }) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    await getNote(id: note.id); //check if the passed note exist in the noteTable of the database
    final updatedCount = await db.update(
      noteTable,
      {
        textColumn: text,
        isSyncedWithCloudColumn: 0,
      },
    );
    if (updatedCount == 0) {
      throw CouldNotUpdateNote();
    } else{
      final updatedNote = await getNote(id: note.id);
      _notes.removeWhere((elementNote) => elementNote.id == updatedNote.id);
      _notes.add(updatedNote);
      _notesStreamController.add(_notes);
      return updatedNote;
    }
    
  }

}

@immutable
class DatabaseUser {
  final int id;
  final String email;

  const DatabaseUser({
    required this.id,
    required this.email,
  });

  DatabaseUser.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        email = map[emailColumn] as String;

  @override
  String toString() => 'Person, ID = $id, email = $email';

  @override
  bool operator ==(covariant DatabaseUser other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// we also need a class for our notes
// create DatabaseNote in notes_service.dart

class DatabaseNote {
  final int id;
  final int userId;
  final String text;
  final bool isSyncedWithCloud;

  DatabaseNote({
    required this.id,
    required this.userId,
    required this.text,
    required this.isSyncedWithCloud,
  });

  DatabaseNote.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        userId = map[userIdColumn] as int,
        text = map[textColumn] as String,
        isSyncedWithCloud = (map[isSyncedWithCloudColumn] as int) == 1
            ? true
            : false; // is_synched_with_cloud is Integer in sqlite database. so read it as integer and interpret it as bool

  @override
  String toString() =>
      'Note, ID = $id, userId = $userId, isSyncedWithCloud = $isSyncedWithCloud, text = $text';

  @override
  bool operator ==(covariant DatabaseNote other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

const dbName = 'notes.db';
const noteTable = 'note';
const userTable = 'user';
const idColumn = 'id';
const emailColumn = 'email';
const userIdColumn = 'user_id';
const textColumn = 'text';
const isSyncedWithCloudColumn = 'is_synced_with_cloud';
const createUserTable = '''
  CREATE TABLE IF NOT EXISTS "user" (
    "id"	INTEGER NOT NULL,
    "email"	INTEGER NOT NULL UNIQUE,
    PRIMARY KEY("id" AUTOINCREMENT)
  );
''';
const createNoteTable = '''
CREATE TABLE IF NOT EXISTS "note" (
  "id"	INTEGER NOT NULL,
  "user_id"	INTEGER NOT NULL,
  "text"	TEXT,
  "is_Synced_with_cloud"	INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY("user_id") REFERENCES "user"("id"),
  PRIMARY KEY("id" AUTOINCREMENT)
);
''';
