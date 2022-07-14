import 'package:flutter/material.dart';
import 'package:mynotes/enums/menu_action.dart';
import 'package:mynotes/services/crud/notes_service.dart';
import '../../services/auth/auth_service.dart';

import 'package:mynotes/constants/routes.dart';


class NotesViewState extends StatefulWidget {
  const NotesViewState({Key? key}) : super(key: key);

  @override
  State<NotesViewState> createState() => _NotesViewStateState();
}

class _NotesViewStateState extends State<NotesViewState> {
  late final NotesService _notesService;
  late final DatabaseUser owner;
  String get userEmail => AuthService.firebase()
      .currentUser!
      .email!; //we can assume every user has email at this point2

  @override
  void initState() {
    _notesService = NotesService();
    // _notesService.open(); // do not need to call open() since every functions in notesService is ensured that db is open
    super.initState();
  }

  @override
  void dispose() {
    _notesService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Your notes"),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.of(context)
                          .pushNamed(newNoteRoute);
              },
            ), 
            PopupMenuButton<MenuAction>(
              onSelected: (value) async {
                switch (value) {
                  case MenuAction.logout:
                    final shouldLogout = await showLogOutDialog(context);
                    if (shouldLogout) {
                      await AuthService.firebase().logOut();
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil(loginRoute, (_) => false);
                    }
                    break;
                }
              },
              itemBuilder: (contest) {
                return const [
                  PopupMenuItem<MenuAction>(
                      value: MenuAction.logout, child: Text("Log out"))
                ];
              },
            ), 
          ],
        ),
        body: FutureBuilder(
          future: _notesService.getOrCreateUser(email: userEmail),
          builder:
              (BuildContext context, AsyncSnapshot<DatabaseUser> snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.done:
                return StreamBuilder(
                  stream: _notesService.allNotes,
                  builder: (BuildContext context,
                      AsyncSnapshot<List<DatabaseNote>> snapshot) {
                    switch (snapshot.connectionState) {
                      case ConnectionState.waiting:
                        return const Text('waiting for all notes...');
                      default:
                        return const CircularProgressIndicator();
                    }
                  },
                );
              default:
                return const CircularProgressIndicator();
            }
          },
        ),
        
      );
  }
}

Future<bool> showLogOutDialog(BuildContext context) {
  return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Log out'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: const Text('Log out')),
          ],
        );
      }).then((value) => value ?? false);
}
