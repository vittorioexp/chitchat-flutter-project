import 'dart:io';

import 'package:chitchat/widgets/user_image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() {
    return AuthScreenState();
  }
}

class AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();

  var _isLoggingIn = false;
  var _enteredEmail = '';
  var _enteredUsername = '';
  var _enteredPassword = '';
  File? _selectedImage;
  var _isAuthenticating = false;

  void _submit() async {
    final isValid = _form.currentState!.validate();

    if (!isValid) {
      return;
    }
    try {
      if (!_isLoggingIn && _selectedImage == null) {
        throw Exception('Please, select a profile photo');
      }

      _form.currentState!.save();

      setState(() {
        _isAuthenticating = true;
      });
      if (_isLoggingIn) {
        await _firebase.signInWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassword);
      } else {
        final userCredentials = await _firebase.createUserWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassword);

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('${userCredentials.user!.uid}.jpg');

        await storageRef.putFile(_selectedImage!);
        final imageUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredentials.user!.uid)
            .set(
          {
            'uid': userCredentials.user!.uid,
            'username': _enteredUsername,
            'email': _enteredEmail,
            'image_url': imageUrl,
          },
        );
      }
    } on FirebaseAuthException catch (error) {
      var authFailedMessage = 'Authentication failed';
      if (error.code == 'email-already-in-use') {
        authFailedMessage = 'Email address already in use';
      }
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authFailedMessage)),
      );
    } on Exception catch (error) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
    setState(() {
      _isAuthenticating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                constraints: const BoxConstraints(maxWidth: 500),
                child: Card(
                  elevation: 10,
                  margin: const EdgeInsets.all(0),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _form,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 10),
                            Text(
                              _isLoggingIn ? 'Login' : 'Create account',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge!
                                  .copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 30,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 30),
                            if (!_isLoggingIn)
                              UserImagePicker(
                                onPickImage: (pickedImage) {
                                  _selectedImage = pickedImage;
                                },
                              ),
                            if (!_isLoggingIn) const SizedBox(height: 20),
                            TextFormField(
                              decoration: InputDecoration(
                                hintText: 'E-mail',
                                border: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    width: 1,
                                    color: Colors.grey,
                                  ),
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              textCapitalization: TextCapitalization.none,
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty ||
                                    !value.contains('@')) {
                                  return 'Invalid email address.';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _enteredEmail = value!;
                              },
                            ),
                            const SizedBox(height: 20),
                            if (!_isLoggingIn)
                              TextFormField(
                                decoration: InputDecoration(
                                  hintText: 'Username',
                                  border: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                      width: 1,
                                      color: Colors.grey,
                                    ),
                                    borderRadius: BorderRadius.circular(5.0),
                                  ),
                                ),
                                enableSuggestions: false,
                                onSaved: (value) {
                                  _enteredUsername = value!;
                                },
                                validator: (value) {
                                  if (value == null ||
                                      value.trim().isEmpty ||
                                      value.trim().length < 4) {
                                    return 'Invalid username';
                                  }
                                  return null;
                                },
                              ),
                            if (!_isLoggingIn) const SizedBox(height: 20),
                            TextFormField(
                              decoration: InputDecoration(
                                hintText: 'Password',
                                border: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    width: 1,
                                    color: Colors.grey,
                                  ),
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                              ),
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.trim().length < 6) {
                                  return 'Password must be at least 6 characters long.';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _enteredPassword = value!;
                              },
                            ),
                            const SizedBox(height: 5),
                            if (_isAuthenticating) const SizedBox(height: 20),
                            if (_isAuthenticating)
                              const CircularProgressIndicator(),
                            const SizedBox(height: 5),
                            if (!_isAuthenticating)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _isLoggingIn
                                        ? 'Do not have an account?'
                                        : 'Already have an account?',
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _isLoggingIn = !_isLoggingIn;
                                      });
                                    },
                                    child: Text(
                                      _isLoggingIn
                                          ? 'Click here to create one.'
                                          : 'Click here to log in.',
                                    ),
                                  ),
                                ],
                              ),
                            if (!_isAuthenticating)
                              Container(
                                width: double.infinity,
                                alignment: Alignment.center,
                                child: SizedBox(
                                  width: 100,
                                  child: ElevatedButton(
                                    onPressed: _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      _isLoggingIn ? 'Login' : 'Signup',
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
