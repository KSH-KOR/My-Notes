import 'package:flutter/material.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/services/auth/auth_user.dart';
import 'package:mynotes/services/crud/notes_service.dart';
import 'package:path/path.dart';

/// create new note when user open this view
/// and keep hold up the note
/// createNote function in notes_service returns future object
/// (not immediately got result from the function)
/// -> need FutureBuilder in a body in Scaffold
///

///

///
/// keep hold up NoteService, Text editing controller
/// TextField <- kepp track the text user entered
/// automatically sync the text in TextField on a database
///

class NewNoteView extends StatefulWidget {
  const NewNoteView({Key? key}) : super(key: key);

  @override
  State<NewNoteView> createState() => _NewNoteViewState();
}

class _NewNoteViewState extends State<NewNoteView> {
  DatabaseNote? _note;
  late final NotesService _notesService;
  late final TextEditingController _textEditingController;

  @override
  void initState() {
    _notesService = NotesService();
    _textEditingController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _deleteNoteIfTextIsEmpty();
    _saveNoteIfTextIsEmpty();
    _textEditingController.dispose();
    super.dispose();
  }

  /// when you rebuild this view, we dont want to keep recreating notes everytime
  /// we want to keep hold a current note
  /// check if a user has already created a note first
  /// if so, dont recreate one but just return
  /// otherwise, NoteService -> createNote() and return it to here
  Future<DatabaseNote> createNewNote() async {
    final existingNote = _note;
    if (existingNote != null) {
      return existingNote;
    } else {
      return await _notesService.createNote(
          owner: await _notesService.getUser(
              email: AuthService.firebase().currentUser!.email!));
    }
  }

  /// when user goes back to note view from new note view
  /// If text is empty -> delete the note
  /// other wise -> automatically save the note
  Future<void> _deleteNoteIfTextIsEmpty() async {
    final note = _note;
    if (_textEditingController.text.isEmpty && note != null) {
      await _notesService.deleteNote(id: note.id);
    }
  }

  Future<void> _saveNoteIfTextIsEmpty() async {
    final note = _note;
    final text = _textEditingController.text;
    if (text.isNotEmpty && note != null) {
      await _notesService.updateNote(
        note: note,
        text: text,
      );
    }
  }

  /// constantly update the note on database, as users type text in the TextField
  /// -> need Text Controller Listener function
  /// how it work:
  /// 1. take the current note
  /// 2. if it exist
  /// 3. take the text in TextEditingController
  /// 4. update the data on database
  Future<void> _textControllerListener() async {
    final note = _note;
    late final String currText;
    if (note != null) {
      currText = _textEditingController.text;
      await _notesService.updateNote(note: note, text: currText);
    }
  }

  /// in case the listener already has been added in the controller
  /// remove it first
  /// and then add it back
  void _setupTextControllerListener() async {
    _textEditingController.removeListener(_textControllerListener);
    _textEditingController.addListener(_textControllerListener);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Note')),
      body: FutureBuilder(
        future: createNewNote(),
        builder: (context, snapshot) {
          switch(snapshot.connectionState){
            case ConnectionState.done:
              _note = snapshot.data as DatabaseNote; //a data in snapshot is what future section returned which is return value of createNewNote()
              _setupTextControllerListener();
              return TextField(
                controller: _textEditingController,
                keyboardType: TextInputType.multiline,
                maxLength: null,
                decoration: const InputDecoration(hintText: 'start typing note here'),
              );
            default:
              return const CircularProgressIndicator();
          }
        },
      )
    );
  }
}
