import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:video_call_app/models/call.dart';
import 'package:video_call_app/models/user.dart';
import 'package:video_call_app/user_photo.dart';
import 'package:video_call_app/utils.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

const appID = "YOUR OWN APP ID PROVIDED BY AGORA";
const tokenBaseUrl = "https://[LINK NAME].herokuapp.com";

class VideoPage extends StatefulWidget {
  final UserModel user;
  final CallModel call;
  const VideoPage({super.key, required this.user, required this.call});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  RtcEngine? rtcEngine;
  String? token;
  int uid = 0;
  bool localUserJoined = false;
  String? callID;
  int? remoteUid;

  @override
  void initState() {
    setState(() {
      callID = widget.call.id;
      rtcEngine = createAgoraRtcEngine();
    });
    super.initState();
    Future.delayed(const Duration(milliseconds: 1000)).then(
      (_) {
        getToken();
      },
    );
  }

  @override
  void dispose() {
    rtcEngine!.release();
    rtcEngine!.leaveChannel();
    super.dispose();
  }

  Future<void> getToken() async {
    final response = await http.get(Uri.parse(
        '$tokenBaseUrl/rtc/${widget.call.channel}/publisher/uid/$uid?expiry=3600'));
    if (response.statusCode == 200) {
      setState(() {
        token = jsonDecode(response.body)['rtcToken'];
      });
      initializeCall();
    }
  }

  Future<void> initializeCall() async {
    await [Permission.microphone, Permission.camera].request();

    await rtcEngine?.initialize(const RtcEngineContext(appId: appID));

    await rtcEngine?.enableVideo();

    rtcEngine?.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          setState(() {
            localUserJoined = true;
          });
          if (widget.call.id == null) {
            //MAKE A CALL
            makeCall();
          }
        },
        onUserJoined: (connection, _remoteUid, elapsed) {
          setState(() {
            remoteUid = _remoteUid;
          });
        },
        onLeaveChannel: (connection, stats) {
          callsCollection.doc(widget.call.id).update(
            {
              'active': false,
            },
          );
          Navigator.pop(context);
        },
        onUserOffline: (connection, _remoteUid, reason) {
          setState(() {
            remoteUid = null;
          });
          rtcEngine?.leaveChannel();
          rtcEngine?.release();
          Navigator.pop(context);
          callsCollection.doc(widget.call.id).update(
            {
              'active': false,
            },
          );
        },
      ),
    );

    await joinVideoChannel();
  }

  makeCall() async {
    DocumentReference callDocRef = callsCollection.doc();
    setState(() {
      callID = callDocRef.id;
    });
    await callDocRef.set(
      {
        'id': callDocRef.id,
        'channel': widget.call.channel,
        'caller': widget.call.caller,
        'called': widget.call.called,
        'active': true,
        'accepted': false,
        'rejected': false,
        'connected': false,
      },
    );
  }

  Future joinVideoChannel() async {
    await rtcEngine?.startPreview();

    ChannelMediaOptions options = const ChannelMediaOptions(
      clientRoleType: ClientRoleType.clientRoleBroadcaster,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    );

    await rtcEngine?.joinChannel(
        token: token!,
        channelId: widget.call.channel,
        uid: uid,
        options: options);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          title: Text(
            widget.user.name,
            style: const TextStyle(
              color: Colors.black,
            ),
          ),
        ),
        body: localUserJoined == false || callID == null
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : StreamBuilder<DocumentSnapshot>(
                stream: callsCollection.doc(callID!).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {

                    CallModel call = CallModel(
                      id: snapshot.data!['id'],
                      channel: snapshot.data!['channel'],
                      caller: snapshot.data!['caller'],
                      called: snapshot.data!['called'],
                      active: snapshot.data!['active'],
                      accepted: snapshot.data!['accepted'],
                      rejected: snapshot.data!['rejected'],
                      connected: snapshot.data!['connected'],
                    );

                    return call.rejected == true
                        ? const Text("Call Declined")
                        : Stack(
                            children: [
                              //OTHER USER'S VIDEO WIDGET
                              Center(
                                child: remoteVideo(call: call),
                              ),
                              //LOCAL USER VIDEO WIDGET
                              if (rtcEngine != null)
                                Positioned.fill(
                                  child: Align(
                                    alignment: Alignment.topLeft,
                                    child: SizedBox(
                                      width: 100,
                                      height: 150,
                                      child: AgoraVideoView(
                                        controller: VideoViewController(
                                          rtcEngine: rtcEngine!,
                                          canvas: VideoCanvas(uid: uid),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned.fill(
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 40),
                                    child: FloatingActionButton(
                                      backgroundColor: Colors.red,
                                      onPressed: () {
                                        rtcEngine?.leaveChannel();
                                      },
                                      child: const Icon(
                                        Icons.call_end_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                  }
                  return const SizedBox.shrink();
                },
              ),
      ),
    );
  }

  Widget remoteVideo({required CallModel call}) {
    return Stack(
      children: [
        if (remoteUid != null)
          AgoraVideoView(
            controller: VideoViewController.remote(
              rtcEngine: rtcEngine!,
              canvas: VideoCanvas(uid: remoteUid),
              connection: RtcConnection(channelId: call.channel),
            ),
          ),
        if (remoteUid == null)
          Positioned.fill(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  userPhoto(radius: 50, url: widget.user.photo),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(call.connected == false
                        ? "Connecting to ${widget.user.name}"
                        : "Waiting Response"),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
