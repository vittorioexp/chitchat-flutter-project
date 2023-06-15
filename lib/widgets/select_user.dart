import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SelectUser extends StatefulWidget {
  const SelectUser({super.key});

  @override
  State<SelectUser> createState() => _SelectUserState();
}

class _SelectUserState extends State<SelectUser> {
  final authenticatedUser = FirebaseAuth.instance.currentUser!;
  List<String> selectedUsers = [];
  List<String> selectedUserUIDs = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select users'),
        actions: [
          if (selectedUsers.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                Navigator.of(context).pop({
                  'usernames': selectedUsers,
                  'uids': selectedUserUIDs,
                });
              },
            ),
        ],
      ),
      body: StreamBuilder(
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
                child: Text('An error occurred, please try again later'));
          }

          final loadedUsers = snapshot.data!.docs
              .where((u) => u['email'] != authenticatedUser.email)
              .toList();

          return ListView.builder(
            itemCount: loadedUsers.length,
            itemBuilder: (context, index) {
              final user = loadedUsers[index].data();
              final uid = loadedUsers[index].id;
              final username = user['username'];

              return ListTile(
                title: Text(username),
                onTap: () {
                  setState(() {
                    if (selectedUsers.contains(username)) {
                      selectedUsers.remove(username);
                      selectedUserUIDs.remove(uid);
                    } else {
                      selectedUsers.add(username);
                      selectedUserUIDs.add(uid);
                    }
                  });
                },
                trailing: Icon(
                  selectedUsers.contains(username)
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
