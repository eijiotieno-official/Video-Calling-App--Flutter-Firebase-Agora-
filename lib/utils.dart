import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

String currentUser = FirebaseAuth.instance.currentUser!.uid;

CollectionReference usersCollection =
    FirebaseFirestore.instance.collection("users");

CollectionReference callsCollection =
    FirebaseFirestore.instance.collection("calls");

//GET SINGLE USER DATA
Stream<DocumentSnapshot> userData({required String id}) async* {
  yield await usersCollection.doc(id).get();
}

//GET ALL USERS' DATA
Stream<List<DocumentSnapshot>> usersData() async* {
  List<DocumentSnapshot> users = [];
  await usersCollection.get().then(
    (value) {
      if (value.docs.isNotEmpty) {
        for (var element in value.docs) {
          users.add(element);
        }
      }
    },
  );

  yield users;
}
