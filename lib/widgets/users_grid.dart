import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UsersGrid extends StatefulWidget {
  final List<String> uids;
  final List<String> usernames;

  const UsersGrid({super.key, required this.uids, required this.usernames});

  @override
  _UsersGridState createState() => _UsersGridState();
}

class _UsersGridState extends State<UsersGrid> {
  final authenticatedUser = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No users found.'),
            );
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('Something went wrong...'),
            );
          }
          final loadedUsers = snapshot.data!.docs;

          final usernames = [];
          final pictures = [];

          for (var user in loadedUsers) {
            if (widget.uids.contains(user['uid'])) {
              usernames.add(user['username']);
              pictures.add(user['image_url']);
            }
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Text(
                  'Participants',
                  style: TextStyle(
                    fontSize: 24, // Adjust the size as needed
                    fontWeight:
                        FontWeight.bold, // Optional: Set the font weight
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    //mainAxisSpacing: 10.0,
                    crossAxisSpacing: 0.0,
                  ),
                  itemCount: widget.usernames.length,
                  itemBuilder: (BuildContext context, int index) {
                    final username = usernames[index];
                    final picture = pictures[index];
                    //return Text(userUID);
                    return Padding(
                      padding: const EdgeInsets.only(top: 15.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(picture as String),
                            radius: 20.0, // Adjust the size of the avatar here
                          ),
                          const SizedBox(height: 4.0),
                          Text(username),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        });
  }
}
