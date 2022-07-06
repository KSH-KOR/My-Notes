import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as devtools show log;

import 'package:mynotes/constants/routes.dart';

enum MenuAction { logout }

class NotesViewState extends StatefulWidget {
  const NotesViewState({Key? key}) : super(key: key);

  @override
  State<NotesViewState> createState() => _NotesViewStateState();
}

class _NotesViewStateState extends State<NotesViewState> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Main UI"),
        actions: [
          PopupMenuButton<MenuAction>(
            onSelected: (value) async {
              switch(value){
                case MenuAction.logout:
                  final shouldLogout = await showLogOutDialog(context);
                  if(shouldLogout){
                    await FirebaseAuth.instance.signOut();
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      loginRoute,
                     (_) => false);
                  }
              }
            },
            itemBuilder: (contest) {
              return const [
                PopupMenuItem<MenuAction>(
                    value: MenuAction.logout, 
                    child: Text("Log out"))
              ];
            },
          )
        ],
      ),
      body: const Text("hello"),
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
                child: const Text('Log out')
            ),
          ],
        );
      }).then((value) => value ?? false);
}
