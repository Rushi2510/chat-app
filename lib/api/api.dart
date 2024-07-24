// ignore_for_file: unused_import

import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart';
import 'package:chat_app/models/chat_user.dart';
import 'package:chat_app/models/message.dart';
// import 'notification_access_token.dart';
import 'package:googleapis_auth/auth_io.dart';

class APIs {
  //for storing self information
  static late ChatUser me;
  //to return current user
  static User get user => auth.currentUser!;

//for accesing firebase messaging (Push Notification)
  static FirebaseMessaging fMessaging = FirebaseMessaging.instance;

  //for getting firebase messaging token
  static Future<void> getFirebaseMessagingToken() async {
    await fMessaging.requestPermission();
    await fMessaging.getToken().then((t) {
      if (t != null) {
        me.pushToken = t;
        log("push_token: $t");
      }
    });
  }

// for sending push notification
  static Future<void> sendPushNotification() async {}

  //for authentication
  static FirebaseAuth auth = FirebaseAuth.instance;
//for accesing cloud firestore database
  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  //for accesing firebase storage
  static FirebaseStorage storage = FirebaseStorage.instance;
//for checking if user exists or not?
  static Future<bool> userExists() async {
    return (await firestore.collection("users").doc(user.uid).get()).exists;
  }

  //for adding an chat user for our conversation
  static Future<bool> addChatUser(String email) async {
    final data = await firestore
        .collection("users")
        .where("email", isEqualTo: email)
        .get();

    log("data: ${data.docs}");

    if (data.docs.isNotEmpty && data.docs.first.id != user.uid) {
      //user exist

      log("user exist: ${data.docs.first.data()}");

      firestore
          .collection("users")
          .doc(user.uid)
          .collection("my_users")
          .doc(data.docs.first.id)
          .set({});

      return true;
    } else {
      //user does not exist
      return false;
    }
  }

//for getting current user info
  static Future<void> getSelfInfo() async {
    await firestore.collection("users").doc(user.uid).get().then((user) async {
      if (user.exists) {
        me = ChatUser.fromJson(user.data()!);
        await getFirebaseMessagingToken();
        //for setting user status to active
        APIs.updateActiveStatus(true);
        log("My Data: ${user.data()}");
      } else {
        await createUser().then((value) => getSelfInfo());
      }
    });
  }

  //for creating a new user
  static Future<void> createUser() async {
    final time = DateTime.now().microsecondsSinceEpoch.toString();
    final chatUser = ChatUser(
        name: user.displayName.toString(),
        about: "Hey, I'm using We Chat!",
        createdAt: time,
        lastActive: time,
        isOnline: false,
        id: user.uid,
        email: user.email.toString(),
        image: user.photoURL.toString(),
        pushToken: "");

    return await firestore
        .collection("users")
        .doc(user.uid)
        .set(chatUser.toJson());
  }

  // for getting Id's of known users from firestore database
  static Stream<QuerySnapshot<Map<String, dynamic>>> getMyUsersId() {
    return firestore
        .collection("users")
        .doc(user.uid)
        .collection("my_users")
        .snapshots();
  }

// for getting all users from firestore database
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUser(
      List<String> userIds) {
    log("\nUserIds: $userIds");
    return firestore
        .collection("users")
        .where("id", whereIn: userIds.isEmpty ? [""] : userIds)

        //.where("id", isNotEqualTo: user.uid)
        .snapshots();
  }

  //for adding an user to my user when first message is send
  static Future<void> sendFirstMessage(
      ChatUser chatUser, String msg, Type type) async {
    await firestore
        .collection("users")
        .doc(chatUser.id)
        .collection("my_users")
        .doc(user.uid)
        .set({}).then((value) => sendMessage(chatUser, msg, type));
    ;
  }

//for updating user information
  static Future<void> updateUserInfo() async {
    await firestore
        .collection("users")
        .doc(user.uid)
        .update({"name": me.name, "about": me.about});
  }

//update profile picture of user
  static Future<void> updateProfilePicture(File file) async {
//getting image file extension
    final ext = file.path.split(".").last;
    log("Extension: ${ext}");

//storage file ref with path
    final ref = storage.ref().child("profile_pictures/${user.uid}.$ext");

//uploading image
    await ref
        .putFile(file, SettableMetadata(contentType: "image/$ext"))
        .then((p0) {
      log("Data transferred: ${p0.bytesTransferred / 1000} kb");
    });

//updating image in firestore database
    me.image = await ref.getDownloadURL();
    await firestore.collection("users").doc(user.uid).update({
      "image": me.image,
    });
  }

//for getting specific user info
  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserInfo(
      ChatUser chatUser) {
    return firestore
        .collection("users")
        .where("id", isEqualTo: chatUser.id)
        .snapshots();
  }

//update online or last active status of user
  static Future<void> updateActiveStatus(bool isOnline) async {
    firestore.collection("users").doc(user.uid).update({
      "is_online": isOnline,
      "last_active": DateTime.now().millisecondsSinceEpoch.toString(),
      "push_token": me.pushToken,
    });
  }

  /*****************Chat Screen Related APIs***********************/

  // chats(collection) --> conversation_id (doc) --> messages (collection) --> message(doc)

//useful for getting conversation id
  static String getConversationID(String id) => user.uid.hashCode <= id.hashCode
      ? "${user.uid}_$id"
      : "${id}_${user.uid}";
//for getting all messages of a specific conversation from firestore database
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(
      ChatUser user) {
    return firestore
        .collection("chats/${getConversationID(user.id)}/messages/")
        .orderBy('sent', descending: true)
        .snapshots();
  }

//for sending message
  static Future<void> sendMessage(
      ChatUser chatUser, String msg, Type type) async {
//message sending time (also used as id)
    final time = DateTime.now().millisecondsSinceEpoch.toString();

//message to send
    final Message message = Message(
        toId: chatUser.id,
        msg: msg,
        read: "",
        type: type,
        sent: time,
        fromId: user.uid);

    final ref = firestore
        .collection("chats/${getConversationID(chatUser.id)}/messages/");
    await ref.doc(time).set(message.toJson());
  }

  //update read status of message
  static Future<void> updateMessageReadStatus(Message message) async {
    firestore
        .collection("chats/${getConversationID(message.fromId)}/messages/")
        .doc(message.sent)
        .update({'read': DateTime.now().millisecondsSinceEpoch.toString()});
  }

// get only last message of specific chat
  static Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessage(
      ChatUser user) {
    return firestore
        .collection("chats/${getConversationID(user.id)}/messages/")
        .orderBy('sent', descending: true)
        .limit(1)
        .snapshots();
  }

  //send chat image
  static Future<void> sendChatImage(ChatUser chatUser, File file) async {
    //getting image file extension
    final ext = file.path.split(".").last;

//storage file ref with path
    final ref = storage.ref().child(
        "images/${getConversationID(chatUser.id)}/${DateTime.now().millisecondsSinceEpoch}.$ext");

//uploading image
    await ref
        .putFile(file, SettableMetadata(contentType: "image/$ext"))
        .then((p0) {
      log("Data transferred: ${p0.bytesTransferred / 1000} kb");
    });

//updating image in firestore database
    final imageUrl = await ref.getDownloadURL();
    await sendMessage(chatUser, imageUrl, Type.image);
  }

//delete message
  static Future<void> deleteMessage(Message message) async {
    await firestore
        .collection("chats/${getConversationID(message.toId)}/messages/")
        .doc(message.sent)
        .delete();

    if (message.type == Type.image) {
      await storage.refFromURL(message.msg).delete();
    }
  }

//update message
  static Future<void> updateMessage(Message message, String updatedMsg) async {
    await firestore
        .collection("chats/${getConversationID(message.toId)}/messages/")
        .doc(message.sent)
        .update({"msg": updatedMsg});
  }
}
