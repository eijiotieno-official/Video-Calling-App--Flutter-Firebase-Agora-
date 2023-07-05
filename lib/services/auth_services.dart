import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:video_call_app/pages/home.dart';
import 'package:video_call_app/utils.dart';

class AuthServices {
  Future authenticateUser({required BuildContext context}) async {
    await signInWithGoogle().then(
      (UserCredential userCredential) async {
        if (userCredential.user?.uid != null) {
          await userExists(id: userCredential.user!.uid).then(
            (exists) async {
              if (exists) {
                FirebaseMessaging.instance.getToken().then(
                  (token) async {
                    await usersCollection.doc(userCredential.user!.uid).update(
                      {
                        'tokens': FieldValue.arrayUnion([token]),
                      },
                    );
                  },
                );
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return const Home(receivedAction: null);
                    },
                  ),
                );
              } else {
                await createUser(userCredential: userCredential).then(
                  (created) {
                    if (created) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return const Home(receivedAction: null);
                          },
                        ),
                      );
                    }
                  },
                );
              }
            },
          );
        }
      },
    );
  }

  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount? googleSignInAccount =
        await GoogleSignIn().signIn();

    final GoogleSignInAuthentication? googleSignInAuthentication =
        await googleSignInAccount?.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleSignInAuthentication?.accessToken,
      idToken: googleSignInAuthentication?.idToken,
    );

    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<bool> createUser({required UserCredential userCredential}) async {
    bool created = false;
    await FirebaseMessaging.instance.getToken().then(
      (token) async {
        await usersCollection.doc(userCredential.user?.uid).set(
          {
            'id': userCredential.user?.uid,
            'name': userCredential.user?.displayName,
            'email': userCredential.user?.email,
            'photo': userCredential.user?.photoURL,
            'tokens': [token],
          },
        ).then((value) => created = true);
      },
    );
    return created;
  }

  Future<bool> userExists({required String id}) async {
    bool exists = false;
    await usersCollection.where('id', isEqualTo: id).get().then(
      (user) {
        exists = user.docs.isEmpty ? false : true;
      },
    );
    return exists;
  }
}
