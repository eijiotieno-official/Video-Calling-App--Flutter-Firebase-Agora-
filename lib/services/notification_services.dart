import 'dart:math';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:video_call_app/main.dart';
import 'package:video_call_app/utils.dart';

class NotificationServices {
  static ReceivedAction? initialAction;

  static Future<void> initializeNotification() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'high_importance_channel',
          channelName: 'video call channel',
          channelDescription: 'channel for video calls',
          importance: NotificationImportance.Max,
          defaultPrivacy: NotificationPrivacy.Public,
          defaultColor: Colors.transparent,
          locked: true,
          enableVibration: true,
          defaultRingtoneType: DefaultRingtoneType.Ringtone,
        ),
      ],
    );

    initialAction = await AwesomeNotifications()
        .getInitialNotificationAction(removeFromActionEvents: false);
  }

  static Future<void> startListeningNotificationEvents() async {
    AwesomeNotifications()
        .setListeners(onActionReceivedMethod: onActionReceivedMethod);
  }

  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    if (receivedAction.buttonKeyPressed == "ACCEPT") {
      MyApp.navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/home', (route) => (route.settings.name != '/home') || route.isFirst,
          arguments: receivedAction);
    }
    if (receivedAction.buttonKeyPressed == "REJECT") {
      callsCollection.doc(receivedAction.payload!['id']).update(
        {
          'rejected': true,
        },
      );
    }
  }

  static Future<void> showNotification(
      {required RemoteMessage remoteMessage}) async {
    Random random = Random();
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: random.nextInt(1000000),
        channelKey: 'high_importance_channel',
        largeIcon: remoteMessage.data['photo'],
        title: remoteMessage.data['name'],
        body: "Incoming Video Call",
        autoDismissible: false,
        category: NotificationCategory.Call,
        notificationLayout: NotificationLayout.Default,
        locked: true,
        wakeUpScreen: true,
        backgroundColor: Colors.transparent,
        payload: {
          'user': remoteMessage.data['user'],
          'name': remoteMessage.data['name'],
          'photo': remoteMessage.data['photo'],
          'email': remoteMessage.data['email'],
          'id': remoteMessage.data['id'],
          'channel': remoteMessage.data['channel'],
          'caller': remoteMessage.data['caller'],
          'called': remoteMessage.data['called'],
          'active': remoteMessage.data['active'],
          'accepted': remoteMessage.data['accepted'],
          'rejected': remoteMessage.data['rejected'],
          'connected': remoteMessage.data['connected'],
        },
      ),
      actionButtons: [
        NotificationActionButton(
          key: "ACCEPT",
          label: "Accept",
          color: Colors.green,
          autoDismissible: true,
        ),
        NotificationActionButton(
          key: "REJECT",
          label: "Reject",
          color: Colors.red,
          autoDismissible: true,
        ),
      ],
    );
  }
}
