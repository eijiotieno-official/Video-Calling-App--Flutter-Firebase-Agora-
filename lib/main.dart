import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:video_call_app/firebase_options.dart';
import 'package:video_call_app/pages/home.dart';
import 'package:video_call_app/services/auth_services.dart';
import 'package:video_call_app/services/notification_services.dart';
import 'package:video_call_app/utils.dart';

Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage remoteMessage) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  //SHOW NOTIFICATION
  await NotificationServices.showNotification(remoteMessage: remoteMessage);
  await callsCollection.doc(remoteMessage.data['id']).update(
    {
      'connected': true,
    },
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationServices.initializeNotification();
  await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
    if (!isAllowed) {
      AwesomeNotifications().requestPermissionToSendNotifications(
          channelKey: "high_importance_channel");
    }
  });

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  FirebaseMessaging.onMessage.listen(
    (RemoteMessage remoteMessage) async {
      await NotificationServices.showNotification(remoteMessage: remoteMessage);
      await callsCollection.doc(remoteMessage.data['id']).update(
        {
          'connected': true,
        },
      );
    },
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const String homeRoute = '/home';

  @override
  void initState() {
    NotificationServices.startListeningNotificationEvents();
    super.initState();
  }

  List<Route<dynamic>> onGenerateInitialRoutes(String initialRouteName) {
    List<Route<dynamic>> pageStack = [];

    pageStack.add(MaterialPageRoute(builder: (_) => const CheckAuthStatus()));

    if (NotificationServices.initialAction != null) {
      pageStack.add(MaterialPageRoute(
          builder: (_) => Home(
                receivedAction: NotificationServices.initialAction,
              )));
    }

    return pageStack;
  }

  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case homeRoute:
        ReceivedAction receivedAction = settings.arguments as ReceivedAction;
        return MaterialPageRoute(
            builder: (_) => Home(
                  receivedAction: receivedAction,
                ));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: MyApp.navigatorKey,
      onGenerateInitialRoutes: onGenerateInitialRoutes,
      onGenerateRoute: onGenerateRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}

class CheckAuthStatus extends StatefulWidget {
  const CheckAuthStatus({super.key});

  @override
  State<CheckAuthStatus> createState() => _CheckAuthStatusState();
}

class _CheckAuthStatusState extends State<CheckAuthStatus> {
  AuthServices authServices = AuthServices();
  @override
  void initState() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user == null) {
        //AUTHENTICATE USER
        await authServices.authenticateUser(context: context);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) {
              return const Home(receivedAction: null);
            },
          ),
        );
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}
