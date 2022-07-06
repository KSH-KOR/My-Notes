import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as devtools show log;

import 'package:mynotes/constants/routes.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({Key? key}) : super(key: key);

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
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
      appBar: AppBar(title: const Text('Register'),),
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
              labelText: 'Password',
              hintText: 'Enter your password here',
            ),
          ),
          TextButton(
              onPressed: _toggle, child: Text(_obscureText ? "Show" : "Hide")),
          TextButton(
            onPressed: () async {
              final email = _email.text;
              final password = _password.text;
              try {
                final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                  email: email, 
                  password: password
                );
                devtools.log(userCredential.toString());
              } on FirebaseAuthException catch (e) {
                bool isEmailWrong = true;
                bool isPwWrong = true;
                if (e.code == 'weak-password') {
                  devtools.log('Weak password');
                  isEmailWrong = false;
                } else if (e.code == 'email-already-in-use') {
                  devtools.log('Email is already in use');
                } else if (e.code == 'invalid-email') {
                  devtools.log('Invalid email entered');
                  isPwWrong = false;
                } else {
                  devtools.log(e.code);
                }
                if (isEmailWrong) _email.clear();
                if (isPwWrong) _password.clear();
              }
            },
            child: const Text('register'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                loginRoute, 
                (route) => false);
            },
            child: const Text('Already registered? Click here to login!'))
        ],
      ),
    );
  }
}
