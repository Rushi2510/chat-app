import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chat_app/api/api.dart';
import 'package:chat_app/helper/dialogs.dart';
import 'package:chat_app/main.dart';
import 'package:chat_app/models/chat_user.dart';
import 'package:chat_app/screens/profile_screen.dart';
import 'package:chat_app/widgets/chat_user_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //for storing all users
  List<ChatUser> _list = [];
  //for storing searched items
  final List<ChatUser> _searchList = [];
  //for storing search status
  bool _isSearching = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    APIs.getSelfInfo();



    //for updating user active status according to lifecycle events
    //resume --active or online
    //pause --inactive or offline
    SystemChannels.lifecycle.setMessageHandler((message) {
      log("message: $message");
      if (APIs.auth.currentUser != null) {
        if (message.toString().contains("pause")) {
          APIs.updateActiveStatus(false);
        }
        if (message.toString().contains("resume")) {
          APIs.updateActiveStatus(true);
        }
      }

      return Future.value(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      //for hiding keyboard when tap is detected on screen
      onTap: () => FocusScope.of(context).unfocus(),
      // ignore: deprecated_member_use
      child: WillPopScope(
        //if search is on and back button is pressed close search
        //or else simple close current screen on back button click
        onWillPop: () {
          if (_isSearching) {
            setState(() {
              _isSearching = !_isSearching;
            });
            return Future.value(false);
          } else {
            return Future.value(true);
          }
        },
        child: Scaffold(
           
            //app bar
            appBar: AppBar(
              leading: const Icon(Icons.home),
              title: _isSearching
                  ? TextField(
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "name/email",
                      ),
                      style: const TextStyle(fontSize: 17, letterSpacing: 0.5),
                      autofocus: true,
                      onChanged: (val) {
                        _searchList.clear();
                        for (var i in _list) {
                          if (i.name
                                  .toLowerCase()
                                  .contains(val.toLowerCase()) ||
                              i.about
                                  .toLowerCase()
                                  .contains(val.toLowerCase())) {
                            _searchList.add(i);
                          }
                          setState(() {
                            _searchList;
                          });
                        }
                      },
                    )
                  : const Text("We Chat"),
              actions: [
                IconButton(
                    onPressed: () {
                      setState(() {
                        _isSearching = !_isSearching;
                      });
                    },
                    icon: Icon(_isSearching
                        ? CupertinoIcons.clear_circled_solid
                        : Icons.search)),
                IconButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ProfileScreen(
                                    user: APIs.me,
                                  )));
                    },
                    icon: const Icon(Icons.more_vert))
              ],
            ),
            
           //floating button to add new user
            floatingActionButton: Padding(


              padding: const EdgeInsets.all(8.0),
              child: FloatingActionButton(
                onPressed: () {
                  _addChatUserDialog();
                },
                backgroundColor: Colors.green,
                elevation: 1,
                child: const Icon(
                  Icons.add_comment_sharp,
                  color: Colors.white,
                ),
              ),
            ),
           
           //body
            body: StreamBuilder(
              stream: APIs.getMyUsersId(),

              //get id of only known users
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                        //if data is loading
                        case ConnectionState.waiting:
                        case ConnectionState.none:
                          return const Center(
                              child: CircularProgressIndicator());
                        //if some or all data is loaded then show it
                        case ConnectionState.active:
                        case ConnectionState.done:
                return  StreamBuilder(
                    stream: APIs.getAllUser(
                        snapshot.data?.docs.map((e) => e.id).toList() ?? []),
                   
                   //get only those user, who's ids are provided
                    builder: (context, snapshot) {
                      switch (snapshot.connectionState) {
                        //if data is loading
                        case ConnectionState.waiting:
                        case ConnectionState.none:
                          // return const Center(
                          //     child: CircularProgressIndicator());
                        //if some or all data is loaded then show it
                        case ConnectionState.active:
                        case ConnectionState.done:
                          final data = snapshot.data?.docs;
                          _list =  data
                                  ?.map((e) => ChatUser.fromJson(e.data()))
                                  .toList() ??
                              [];
                          if (_list.isNotEmpty) {
                            return ListView.builder(
                              padding: EdgeInsets.only(top: mq.height * .01),
                              itemCount: _isSearching
                                  ? _searchList.length
                                  : _list.length,
                              physics: const BouncingScrollPhysics(),
                              itemBuilder: (context, index) {
                                return ChatUserCard(
                                  user: _isSearching
                                      ? _searchList[index]
                                      : _list[index],
                                );
                                // return Text("Name: ${list[index]}");
                              },
                            );
                          } else {
                            return const Center(
                                child: Text(
                              "No Connetion Found",
                              style: TextStyle(fontSize: 20),
                            ));
                          }
                      }
                    },
                  );
                }
                
              },
            )),
      ),
    );
  }

//for adding new chat user
  void _addChatUserDialog() {
    String email = "";

    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              contentPadding: const EdgeInsets.only(
                  top: 20, bottom: 10, left: 24, right: 24),

              //title
              title: const Row(
                children: [
                  Icon(
                    Icons.person_add,
                    color: Colors.blue,
                    size: 28,
                  ),
                  Text(
                    "  Add User",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  )
                ],
              ),

              content: TextFormField(
                maxLines: null,
                onChanged: (value) => email = value,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Email Id",
                    prefixIcon: Icon(
                      Icons.email_rounded,
                      color: Colors.blue,
                    )),
              ),

              //actions
              actions: [
                //cancel button
                MaterialButton(
                  onPressed: () {
                    //hide alert dialog
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.blue, fontSize: 16),
                  ),
                ),

                //add button
                MaterialButton(
                  onPressed: () async {
                    //hide alert dialog
                    Navigator.pop(context);
                    if (email.isNotEmpty) {
                      await APIs.addChatUser(email).then((value) {
                        if (!value) {
                          Dialogs.showSnackbar(
                              context, "User does not Exists!");
                        }
                      });
                    }
                  },
                  child: const Text(
                    "Add",
                    style: TextStyle(color: Colors.blue, fontSize: 16),
                  ),
                )
              ],
            ));
  }
}
