import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mynotes/constants/routes.dart';
import 'dart:developer' as devtools show log;

import '../utilities/show_error_dialog.dart';


class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _email;
  late final TextEditingController _password;
  late bool _obscureText;

  @override
  void initState() {
    //automatically called when homepage is created
    _email = TextEditingController();
    _password = TextEditingController();
    _obscureText = true;
    super.initState();
  }

  @override
  void dispose() {
    //automatically called when homepage is disposed
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  // Toggles the password show status
  void _toggle() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login'),),
      body: Column(
        children: [
          TextField(
            controller: _email,
            enableSuggestions: false,
            autocorrect: false,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
                labelText: 'Email', hintText: 'Enter your email here'),
          ),
          TextField(
            controller: _password,
            obscureText: _obscureText,
            enableSuggestions: false,
            autocorrect: false,
            decoration: const InputDecoration(
                labelText: 'Password', hintText: 'Enter your password here'),
          ),
          TextButton(
              onPressed: _toggle, child: Text(_obscureText ? "Show" : "Hide")),
          TextButton(
            onPressed: () async {
              final email = _email.text;
              final password = _password.text;
              try {
                await FirebaseAuth.instance.signInWithEmailAndPassword(
                  email: email, 
                  password: password
                );
                Navigator.of(context).pushNamedAndRemoveUntil(
                  notesRoute,
                  (route) => false,
                );
              } on FirebaseAuthException catch (e) {
                bool isEmailWrong = true;
                bool isPwWrong = true;
                if (e.code == 'user-not-found') {
                  await showErrorDialog(context, "User not found");
                } else if (e.code == 'wrong-password') {
                  await showErrorDialog(context, "Wrong password");
                  isEmailWrong = false;
                } else if (e.code == 'invalid-email') {
                  await showErrorDialog(context, "Invalid email");
                } else {
                  await showErrorDialog(context, 'Something else happened: ${e.code}');
                }
                if (isEmailWrong) _email.clear();
                if (isPwWrong) _password.clear();
              } catch (e) {
                await showErrorDialog(context, "unknown error occured \nerror message: $e");
              }
            },
            child: const Text('login'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                registerRoute, 
                (route) => false);
            },
            child: const Text('Not registered yet? Click here to register!'),
          ),
        ],
      ),
    );
  }
}


