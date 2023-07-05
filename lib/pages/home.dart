import 'dart:convert';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:video_call_app/models/call.dart';
import 'package:video_call_app/models/user.dart';
import 'package:video_call_app/pages/video.dart';
import 'package:video_call_app/user_photo.dart';
import 'package:video_call_app/utils.dart';

class Home extends StatefulWidget {
  final ReceivedAction? receivedAction;
  const Home({super.key, required this.receivedAction});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  handleNotification() {
    if (widget.receivedAction != null) {
      Map userMap = widget.receivedAction!.payload!;
      UserModel user = UserModel(
          id: userMap['user'],
          name: userMap['name'],
          photo: userMap['photo'],
          email: userMap['email']);
      CallModel call = CallModel(
        id: userMap['id'],
        channel: userMap['channel'],
        caller: userMap['caller'],
        called: userMap['called'],
        active: jsonDecode(userMap['active']),
        accepted: true,
        rejected: jsonDecode(userMap['rejected']),
        connected: true,
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return VideoPage(call: call, user: user);
          },
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1000)).then(
      (value) {
        handleNotification();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            "VIDEO CALLING APP",
            style: TextStyle(
              color: Colors.black,
            ),
          ),
        ),
        body: StreamBuilder<List<DocumentSnapshot>>(
          stream: usersData(),
          builder: (context, userSnapshot) {
            if (userSnapshot.hasData) {
              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: userSnapshot.data!.length,
                itemBuilder: (context, index) {
                  var data = userSnapshot.data![index];
                  UserModel user = UserModel(
                      id: data['id'],
                      name: data['name'],
                      photo: data['photo'],
                      email: data['email']);

                  return user.id == currentUser
                      ? const SizedBox.shrink()
                      : ListTile(
                          leading: userPhoto(radius: 20, url: user.photo),
                          title: Text(user.name),
                          trailing: IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) {
                                    return VideoPage(
                                      user: user,
                                      call: CallModel(
                                        id: null,
                                        channel: "video$currentUser${user.id}",
                                        caller: currentUser,
                                        called: user.id,
                                        active: null,
                                        accepted: null,
                                        rejected: null,
                                        connected: null,
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.video_call_rounded,
                              color: Colors.blue,
                            ),
                          ),
                        );
                },
              );
            }
            return const Center(
              child: Text("NO USERS"),
            );
          },
        ),
      ),
    );
  }
}
