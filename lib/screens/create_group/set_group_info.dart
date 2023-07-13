import 'dart:io';

import 'package:chitchat/screens/chats.dart';
import 'package:chitchat/widgets/user_image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

final _firebase = FirebaseAuth.instance;
final authenticatedUser = FirebaseAuth.instance.currentUser!;

class SetGroupInfoScreen extends StatefulWidget {
  final List<String> usernames;
  final List<String> uids;

  const SetGroupInfoScreen(
      {super.key, required this.usernames, required this.uids});

  @override
  State<SetGroupInfoScreen> createState() => _SetGroupInfoScreenState();
}

class _SetGroupInfoScreenState extends State<SetGroupInfoScreen> {
  final _form = GlobalKey<FormState>();
  File? _selectedImage;
  var _enteredName = '';
  var _enteredDescription = '';
  var _isLoading = false;

  _submit() async {
    final isValid = _form.currentState!.validate();

    if (!isValid) {
      return;
    }
    try {
      if (_selectedImage == null) {
        throw Exception('Please, select a profile photo');
      }

      _form.currentState!.save();

      setState(() {
        _isLoading = true;
      });
      // Check image size
      final imageFile = _selectedImage!;
      final imageBytes = await imageFile.readAsBytes();
      final imageSizeKB = imageBytes.lengthInBytes / 1024;
      const maxImageSizeMB = 5;
      const maxImageSizeKB = maxImageSizeMB * 1024;
      if (imageSizeKB > maxImageSizeKB) {
        throw Exception(
            'The selected image exceeds the maximum allowed size of $maxImageSizeMB MB.');
      }

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('group_images')
          .child('${Timestamp.now().hashCode}.jpg');

      await storageRef.putFile(_selectedImage!);
      final imageUrl = await storageRef.getDownloadURL();

      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(authenticatedUser.uid)
          .get();

      final chatName = _enteredName.isEmpty
          ? '${userData['username']}, ${widget.usernames.join(', ')}'
          : _enteredName;

      await FirebaseFirestore.instance.collection('chats').add({
        'lastActivity': Timestamp.now(),
        'name': chatName,
        'description': _enteredDescription,
        'participants': [authenticatedUser.uid, ...widget.uids],
        'image_url': imageUrl,
        'preview_message': 'No message yet...'
      });
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const ChatsScreen()),
          (Route<dynamic> route) => false);
    } on Exception catch (error) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tmpGroupName = 'Group with ${widget.usernames.join(', ')}';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.onPrimary,
      appBar: AppBar(
        title: Text(tmpGroupName),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 500),
                //elevation: 10,
                //margin: const EdgeInsets.all(0),
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
                            'Create group',
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
                          CustomImagePicker(
                            title: 'Add group picture',
                            onPickImage: (pickedImage) {
                              _selectedImage = pickedImage;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            decoration: InputDecoration(
                              hintText: 'Name',
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
                                  value.trim().length < 5) {
                                return 'Invalid group name.';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enteredName = value!;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            validator: (value) {
                              if (value != null && value.trim().length > 500) {
                                return 'Group description is too long.';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enteredDescription = value!;
                            },
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 5),
                          if (_isLoading) const SizedBox(height: 20),
                          if (_isLoading) const CircularProgressIndicator(),
                          const SizedBox(height: 10),
                          if (!_isLoading)
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
                                  child: const Text('Create'),
                                ),
                              ),
                            ),
                          const SizedBox(height: 15),
                        ],
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
