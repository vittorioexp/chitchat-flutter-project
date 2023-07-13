import 'package:chitchat/screens/chat.dart';
import 'package:chitchat/screens/create_group/select_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authenticatedUser = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
            icon: Icon(
              Icons.exit_to_app,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
              MaterialPageRoute(builder: (ctx) => const SelectUserScreen()));
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .orderBy('lastActivity', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No chats found.'),
            );
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('Something went wrong...'),
            );
          }
          final loadedchats = snapshot.data!.docs;
          final chatsWithUser = loadedchats.where((chat) {
            final participants = chat['participants'] as List<dynamic>;
            return participants.contains(authenticatedUser.uid);
          }).toList();

          if (chatsWithUser.isEmpty) {
            return const Center(
              child: Text('No chats found.'),
            );
          }

          return ListView.builder(
            reverse: false,
            itemCount: chatsWithUser.length,
            itemBuilder: (context, index) {
              final chatWithUser = chatsWithUser[index].data();
              return ListTile(
                leading: CircleAvatar(
                  radius: 26,
                  backgroundImage: chatWithUser['image_url'].toString() != ""
                      ? NetworkImage(chatWithUser['image_url'])
                      : Image.asset('assets/images/default_profile_photo_1.png')
                          .image,
                ),
                title: Text((chatWithUser['name'].length > 40)
                    ? '${chatWithUser['name'].substring(0, 37)}...'
                    : chatWithUser['name']),
                subtitle: Text(
                    chatWithUser['preview_message'] ?? 'No message yet...'),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (ctx) =>
                          ChatScreen(chatId: chatsWithUser[index].id)));
                },
              );
            },
          );
        },
      ),
    );
  }
}
