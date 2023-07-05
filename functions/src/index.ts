import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {DocumentData} from "firebase-admin/firestore";

admin.initializeApp();

export const makeCall = functions.firestore
  .document("calls/{id}")
  .onCreate(async (callSnapshot) => {
    const call = callSnapshot.data();
    let callerData: DocumentData;
    let tokens: string | string[] = [];
    const users = admin.firestore().collection("users").get();
    users
      .then((usersSnapshot) => {
        usersSnapshot.forEach(async (userDoc) => {
          const user = userDoc.data();
          if (user.id == call.caller) {
            callerData = user;
          }
          if (user.id == call.called) {
            tokens = user.tokens;
          }
        });
      })
      .then(async (doc) => {
        if (call.active == true) {
          const callPayload = {
            data: {
              user: callerData.id,
              name: callerData.name,
              photo: callerData.photo,
              email: callerData.email,
              id: call.id,
              channel: call.channel,
              caller: call.caller,
              called: call.called,
              active: call.active.toString(),
              accepted: call.accepted.toString(),
              rejected: call.rejected.toString(),
              connected: call.connected.toString(),
            },
          };
          await admin.messaging().sendToDevice(tokens, callPayload);
        }
      });
  });
