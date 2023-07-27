import 'dart:io';

import 'package:chitchat/screens/chats.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'package:chitchat/widgets/custom_image_picker.dart';

final authenticatedUser = FirebaseAuth.instance.currentUser!;

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final authenticatedUser = FirebaseAuth.instance.currentUser!;
  final _form = GlobalKey<FormState>();
  File? _selectedImage;
  var _enteredName = '';
  List<String> selectedUsernames = [];
  List<String> selectedUserUIDs = [];
  late TextEditingController searchController;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

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

      setState(() {});

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
          ? '${userData['username']}, ${selectedUsernames.join(', ')}'
          : _enteredName;

      await FirebaseFirestore.instance.collection('chats').add({
        'lastActivity': Timestamp.now(),
        'name': chatName,
        'participants': [authenticatedUser.uid, ...selectedUserUIDs],
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

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New group'),
        actions: [
          if (selectedUsernames.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                _submit();
              },
            ),
        ],
      ),
      body: Container(
        constraints: const BoxConstraints(maxWidth: 1000),
        alignment: Alignment.center,
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              alignment: Alignment.topLeft,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: CustomImagePicker(
                      title: 'Add picture',
                      label: false,
                      image: 'assets/images/default_upload_photo_3.png',
                      onPickImage: (pickedImage) {
                        _selectedImage = pickedImage;
                      },
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Form(
                      key: _form,
                      child: TextFormField(
                        decoration: const InputDecoration(
                          hintText: 'Name your group',
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
                    ),
                  ),
                  const SizedBox(width: 10)
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: searchController,
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Search users',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .orderBy('username')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    //return const CircularProgressIndicator();
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No users found'));
                  }

                  if (snapshot.hasError) {
                    return const Center(
                        child:
                            Text('An error occurred, please try again later'));
                  }

                  final loadedUsers = snapshot.data!.docs
                      .where((u) =>
                          u['email'] != authenticatedUser.email &&
                          u['username']
                              .toString()
                              .toLowerCase()
                              .contains(searchQuery.toLowerCase()))
                      .toList();

                  return SingleChildScrollView(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: loadedUsers.length,
                      itemBuilder: (context, index) {
                        final user = loadedUsers[index].data();
                        final uid = loadedUsers[index].id;
                        final username = user['username'];
                        final imageUrl = user['image_url'];

                        return Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: imageUrl != null
                                  ? NetworkImage(imageUrl)
                                  : const AssetImage(
                                          'assets/images/default_profile_photo_1.png')
                                      as ImageProvider<Object>,
                            ),
                            title: Text(
                              username.length > 40
                                  ? '${username.substring(0, 40)}...'
                                  : username,
                            ),
                            trailing: selectedUsernames.contains(username)
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check,
                                          color:
                                              Theme.of(context).primaryColor),
                                      const SizedBox(width: 8),
                                      const Text('Added'),
                                      const SizedBox(width: 8),
                                    ],
                                  )
                                : ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        selectedUsernames.add(username);
                                        selectedUserUIDs.add(uid);
                                      });
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context)
                                          .appBarTheme
                                          .backgroundColor,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                            onTap: () {
                              setState(() {
                                if (selectedUsernames.contains(username)) {
                                  selectedUsernames.remove(username);
                                  selectedUserUIDs.remove(uid);
                                } else {
                                  selectedUsernames.add(username);
                                  selectedUserUIDs.add(uid);
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
