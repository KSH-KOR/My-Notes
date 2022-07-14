import 'dart:math';

import 'package:mynotes/services/auth/auth_exceptions.dart';
import 'package:mynotes/services/auth/auth_provider.dart';
import 'package:mynotes/services/auth/auth_user.dart';
import 'package:test/test.dart';

void main() {
  group('Mock Authentication', () {
    final provider = MockAuthProvider();
    test(
      'Should not be initialized to begin with',
      () {
        expect(
          provider.isInitialized,
          false,
        );
      },
    );
    test(
      'Cannot log out if not initailized',
      () {
        expect(
          //expect NotInitializedException when you try to log out if not initialized
          provider.logOut(),
          throwsA(const TypeMatcher<NotInitializedException>()),
        );
      },
    );
    test(
      'cannot create user if not initialized',
      () {
        expect(
          provider.createUser(email: '', password: ''),
          throwsA(const TypeMatcher<NotInitializedException>()),
        );
      },
    );
    test(
      'Should be able to be initialized',
      () async {
        await provider.initialize();
        expect(
          provider.isInitialized,
          true,
        );
      },
    );
    test(
      'User should be null after initailization',
      () {
        expect(
          provider.currentUser,
          null,
        );
      },
    );
    test(
      'Should be able to initialize in less than 2 seconds',
      () async {
        await provider.initialize();
        expect(
          provider.isInitialized,
          true,
        );
      },
      timeout: const Timeout(Duration(seconds: 2)),
    );
    test(
      'Create user Should delegate to logIn function',
      () async {
        provider.initialize();
        expect(provider.isInitialized, true);
        final badEmailUser = await provider.createUser(
          email: 'foo@bar.com',
          password: 'anypassword',
        );
        expect(
          badEmailUser,
          throwsA(const TypeMatcher<UserNotFoundAuthException>()),
        );
        final badPasswordUser = await provider.createUser(
          email: 'someone@email.com',
          password: 'foobar',
        );
        expect(
          badPasswordUser,
          throwsA(const TypeMatcher<UserNotFoundAuthException>()),
        );
        final user = await provider.createUser(
          email: 'email', 
          password: 'password',
        );
        expect( //expect the user just created is the same in provider's user
          provider._user,
          user,
        );
        expect(user.isEmailVerified, false);
      },
    );
    test(
      'Login user should be able to get verified',
      () async {
        provider.sendEmailVerification();
        final user = provider.currentUser;
        expect(user, isNotNull);
        expect(user!.isEmailVerified, true);
      },
    );
    test(
      'Should be able to log out and log in again',
      () async {
        await provider.logOut();
        expect(provider._user, null);
        await provider.logIn(email: 'email', password: 'password');
        final user = provider.currentUser;
        expect(user, isNotNull);
      },
      
    );

  });
}

class NotInitializedException implements Exception {}

class MockAuthProvider implements AuthProvider {
  AuthUser? _user;
  var _isInitialized = false;
  bool get isInitialized => _isInitialized;

  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) async {
    if (!_isInitialized) throw NotInitializedException();
    await Future.delayed(const Duration(seconds: 1));
    return logIn(
      email: email,
      password: password,
    );
  }

  @override
  AuthUser? get currentUser => _user;

  @override
  Future<void> initialize() async {
    //await Future.delayed(const Duration(seconds: 1)); //fake wait
    _isInitialized = true;
  }

  @override
  Future<AuthUser> logIn({
    required String email,
    required String password,
  }) {
    if (!_isInitialized) throw NotInitializedException();
    if (email == 'foo@bar.com')
      throw UserNotFoundAuthException(); // wrong email test
    if (password == 'foobar')
      throw WrongPasswordAuthException(); // wrong password test
    final user = AuthUser(isEmailVerified: false, email: email);
    _user = user;
    return Future.value(user);
  }

  @override
  Future<void> logOut() async {
    if (!_isInitialized) throw NotInitializedException();
    if (_user == null) throw UserNotFoundAuthException();
    await Future.delayed(const Duration(seconds: 1)); //fake wait
    _user = null; // mock log out
  }

  @override
  Future<void> sendEmailVerification() async {
    if (!_isInitialized) throw NotInitializedException();
    final user = _user;
    if (user == null) throw UserNotFoundAuthException();
    await Future.delayed(const Duration(seconds: 1)); //fake wait
    const newUser = AuthUser(isEmailVerified: false, email: '');
    _user = newUser;
  }
}
