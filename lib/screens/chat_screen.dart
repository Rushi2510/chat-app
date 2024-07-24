import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chat_app/api/api.dart';
import 'package:chat_app/helper/my_date_util.dart';
import 'package:chat_app/models/chat_user.dart';
import 'package:chat_app/screens/view_profile_screen.dart';
import 'package:chat_app/widgets/message_card.dart';
import '../main.dart';
import '../models/message.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser user;
  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
// for storing all messages
  List<Message> _list = [];

// for handling message text changes
  final _textController = TextEditingController();

//_showEmoji --for storing value of showing or hiding emoji
//_isUploading --for checking if image is uploading or not?
//sendButton -- for send the message if type something in text field
  bool _showEmoji = false, _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: PopScope(
        //if emojis are shown and back button is pressed then hide emojis
        //or else simple close current screen on back button click
        // onWillPop: () {
        //   if (_showEmoji) {
        //     setState(() {
        //       _showEmoji = !_showEmoji;
        //     });
        //     return Future.value(false);
        //   } else {
        //     return Future.value(true);
        //   }
        // },
        canPop: !_showEmoji,
        onPopInvoked: (_) async {
          if (_showEmoji) {
            setState(() => _showEmoji = !_showEmoji);
          } else {
            Navigator.of(context).pop();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            flexibleSpace: _appBar(),
          ),
          // backgroundColor:  const Color.fromRGBO(226, 239, 248, 1),
          //body
          body: SafeArea(
            child: Column(children: [
              Expanded(
                child: StreamBuilder(
                  // stream:  APIs.getAllUser(),
                  builder: (context, snapshot) {
                    switch (snapshot.connectionState) {
                      //if data is loading
                      case ConnectionState.waiting:
                      case ConnectionState.none:
                        return const SizedBox();
                      //if some or all data is loaded then show it
                      case ConnectionState.active:
                      case ConnectionState.done:
                        final data = snapshot.data?.docs;

                        _list = data
                                ?.map((e) => Message.fromJson(e.data()))
                                .toList() ??
                            [];

                        if (_list.isNotEmpty) {
                          return ListView.builder(
                              reverse: true,
                              padding: EdgeInsets.only(top: mq.height * .01),
                              itemCount: _list.length,
                              physics: const BouncingScrollPhysics(),
                              itemBuilder: (context, index) {
                                return MessageCard(
                                  message: _list[index],
                                );
                              });
                        } else {
                          return const Center(
                              child: Text(
                            "Say hii!👋",
                            style: TextStyle(fontSize: 20),
                          ));
                        }
                    }
                  },
                  stream: APIs.getAllMessages(widget.user),
                ),
              ),

              //progress indicator for showing uploading
              if (_isUploading)
                const Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ))),
              //chat input filed
              _chatInput(),

              //show emojis on keyboard emoji button click and vice versa
              if (_showEmoji)
                EmojiPicker(
                  textEditingController: _textController,
                  config: Config(
                    height: 256,
                    emojiViewConfig: EmojiViewConfig(
                        emojiSizeMax: 28 * (Platform.isIOS ? 1.20 : 1.0),
                        columns: 8),
                  ),
                )
            ]),
          ),
        ),
      ),
    );
  }

  Widget _appBar() {
    return SafeArea(
      child: InkWell(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ViewProfileScreen(user: widget.user)));
          },
          child: StreamBuilder(
            stream: APIs.getUserInfo(widget.user),
            builder: (context, snapshot) {
              final data = snapshot.data?.docs;
              final list =
                  data?.map((e) => ChatUser.fromJson(e.data())).toList() ?? [];

              return Row(
                children: [
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      //back button
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      )),
                  //user profile picture
                  ClipRRect(
                    borderRadius: BorderRadius.circular(mq.height * .3),
                    child: CachedNetworkImage(
                      height: mq.height * .05,
                      width: mq.height * .05,
                      imageUrl:
                          list.isNotEmpty ? list[0].image : widget.user.image,
                      // placeholder: (context, url) => CircularProgressIndicator(),
                      errorWidget: (context, url, error) => const CircleAvatar(
                          child: Icon(CupertinoIcons.person)),
                    ),
                  ),
                  //for adding some space
                  const SizedBox(
                    width: 10,
                  ),
                  //user name and last seen time
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        //user name
                        list.isNotEmpty ? list[0].name : widget.user.name,
                        style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w500),
                      ),
                      //for adding some space
                      const SizedBox(
                        height: 2,
                      ),
                      Text(
                        //last seen time for user
                        list.isNotEmpty
                            ? list[0].isOnline
                                ? "Online"
                                : MyDateUtil.getLastActiveTime(
                                    context: context,
                                    lastActive: list[0].lastActive)
                            : MyDateUtil.getLastActiveTime(
                                context: context,
                                lastActive: widget.user.lastActive),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      )
                    ],
                  )
                ],
              );
            },
          )),
    );
  }

//bottom chat input field
  Widget _chatInput() {
   
    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: mq.height * .01, horizontal: mq.width * .025),
      child: Row(
        children: [
          //input field and buttons
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50)),
              child: Row(
                children: [
                  IconButton(
                      //emoji button
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        setState(() => _showEmoji = !_showEmoji);
                      },
                      icon: const Icon(
                        Icons.emoji_emotions,
                        color: Colors.blueAccent,
                        size: 25,
                      )),
                  Expanded(
                      child: TextField(
                    controller: _textController,
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                   
                    onTap: () {
                      if (_showEmoji) setState(() => _showEmoji = !_showEmoji);
                    },
                    decoration: const InputDecoration(
                        hintText: "Type Something...",
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none),
                  )),
                  IconButton(
                      //pick image from gallery button
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        // Picking multiple images
                        final List<XFile> images =
                            await picker.pickMultiImage(imageQuality: 70);

                        //uploading and sending image one by one
                        for (var i in images) {
                          setState(() => _isUploading = true);
                          await APIs.sendChatImage(widget.user, File(i.path));
                          setState(() => _isUploading = false);
                        }
                      },
                      icon: const Icon(
                        Icons.image,
                        color: Colors.blueAccent,
                        size: 26,
                      )),
                  IconButton(
                      //take image from camera button
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        // Pick an image.
                        final XFile? image = await picker.pickImage(
                            source: ImageSource.camera, imageQuality: 70);
                        if (image != null) {
                          setState(() => _isUploading = true);
                          await APIs.sendChatImage(
                              widget.user, File(image.path));
                          setState(() => _isUploading = false);
                        }
                      },
                      icon: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.blueAccent,
                        size: 26,
                      )),

                  //adding some space
                  SizedBox(
                    width: mq.width * .02,
                  )
                ],
              ),
            ),
          ),
          //send message button audio record button
          MaterialButton(
           
            onPressed: () {
              if (_textController.text.isNotEmpty) {
                if (_list.isEmpty) {
                  //on first message (add user to my_user collection of chat user)
                  APIs.sendFirstMessage(
                      widget.user, _textController.text, Type.text);
                } else {
                  //simply send message
                  APIs.sendMessage(
                      widget.user, _textController.text, Type.text);
                }

                _textController.text = "";
              }
            },
            color: Colors.green,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(10),
            minWidth: 0,
            child: const Icon(
              Icons.send ,
              size: 28,
              color: Colors.white,
            ),
          )
        ],
      ),
    );
  }
}
