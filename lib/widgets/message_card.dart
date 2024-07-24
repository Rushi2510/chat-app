import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:chat_app/api/api.dart';
import 'package:chat_app/helper/dialogs.dart';
import 'package:chat_app/helper/my_date_util.dart';
import 'package:chat_app/main.dart';
import 'package:chat_app/models/message.dart';


class MessageCard extends StatefulWidget {
  const MessageCard({super.key, required this.message});

  final Message message;
  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  @override
  Widget build(BuildContext context) {
    bool isMe = APIs.user.uid == widget.message.fromId;
    return InkWell(
        onLongPress: () {
          showBottomSheet(isMe);
        },
        child: isMe ? _greenMessage() : _blueMessage());
  }

//sender or another user message
  Widget _blueMessage() {
    //update last read message if sender or receiver are different
    if (widget.message.read.isEmpty) {
      APIs.updateMessageReadStatus(widget.message);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        //message content
        Flexible(
          child: Container(
            padding: EdgeInsets.all(widget.message.type == Type.image
                ? mq.width * .03
                : mq.width * .04),
            margin: EdgeInsets.symmetric(
                vertical: mq.height * .01, horizontal: mq.width * .04),
            decoration: BoxDecoration(
                color: const Color.fromRGBO(226, 239, 248, 1),
                border: Border.all(color: Colors.lightBlue),
                //making borders curved
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                    bottomRight: Radius.circular(30))),
            child: widget.message.type == Type.text
                //show text
                ? Text(
                    widget.message.msg,
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                  )
                //show image
                : ClipRRect(
                    borderRadius: BorderRadius.circular(mq.height * .03),
                    child: CachedNetworkImage(
                      imageUrl: widget.message.msg,
                      placeholder: (context, url) => const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.image,
                        size: 70,
                      ),
                    ),
                  ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(right: mq.width * .04),
          child: Text(
            MyDateUtil.getFormattedTime(
                context: context, time: widget.message.sent),
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        )
      ],
    );
  }

//our or user message
  Widget _greenMessage() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            //for adding some space
            SizedBox(
              width: mq.width * .04,
            ),
            //double tick blue icon for message read
            if (widget.message.read.isNotEmpty)
              const Icon(
                Icons.done_all_rounded,
                color: Colors.blue,
                size: 20,
              ),

            //for adding some space

            const SizedBox(
              width: 2,
            ),
            //sent time
            Text(
              MyDateUtil.getFormattedTime(
                  context: context, time: widget.message.sent),
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
        //message content
        Flexible(
          child: Container(
            padding: EdgeInsets.all(widget.message.type == Type.image
                ? mq.width * .03
                : mq.width * .04),
            margin: EdgeInsets.symmetric(
                vertical: mq.height * .01, horizontal: mq.width * .04),
            decoration: BoxDecoration(
                color: Color.fromARGB(255, 232, 252, 233),
                border: Border.all(color: Colors.lightGreen),
                //making borders curved
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                    bottomLeft: Radius.circular(30))),
            child: widget.message.type == Type.text
                //show text
                ? Text(
                    widget.message.msg,
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                  )
                //show image
                : ClipRRect(
                    borderRadius: BorderRadius.circular(mq.height * .03),
                    child: CachedNetworkImage(
                      imageUrl: widget.message.msg,
                      placeholder: (context, url) => const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.image,
                        size: 70,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

//bottomsheet for modifying message details
  void showBottomSheet(bool isMe) {
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20))),
        builder: (_) {
          return ListView(
            shrinkWrap: true,
            children: [
//black divider
              Container(
                height: 4,
                decoration: const BoxDecoration(
                  color: Colors.grey,
                ),
                margin: EdgeInsets.symmetric(
                    vertical: mq.height * .015, horizontal: mq.width * .4),
              ),

//copy option

              widget.message.type == Type.text
                  ? _OptionItem(
                      icon: const Icon(
                        Icons.copy_all_rounded,
                        color: Colors.blue,
                        size: 26,
                      ),
                      name: "Copy Text",
                      onTap: () async {
                        await Clipboard.setData(
                                ClipboardData(text: widget.message.msg))
                            .then((value) {
//for hiding bottomsheet
                          Navigator.pop(context);

                          Dialogs.showSnackbar(context, "Text Copied!");
                        });
                      })
                  :
                  //save option
                  _OptionItem(
                      icon: const Icon(
                        Icons.download_rounded,
                        color: Colors.blue,
                        size: 26,
                      ),
                      name: "Save Image",
                      onTap: () async {
                        try {
                          log("Image URL: ${widget.message.msg}");
                          await GallerySaver.saveImage(widget.message.msg,
                                  albumName: "We Chat")
                              .then((success) {
                            //for hiding bottomsheet
                            Navigator.pop(context);
                            if (success != null && success) {
                              Dialogs.showSnackbar(
                                  context, "Image Successfully Saved!");
                            }
                          });
                        } catch (e) {
                          log("error while saving img: $e");
                        }
                      }),

//separator or divider
              if (isMe)
                Divider(
                  color: Colors.black54,
                  indent: mq.width * .04,
                  endIndent: mq.width * .04,
                ),

//edit option
              if (widget.message.type == Type.text && isMe)
                _OptionItem(
                    icon: const Icon(
                      Icons.edit,
                      color: Colors.blue,
                      size: 26,
                    ),
                    name: "Edit Message",
                    onTap: () {
                      //for hiding bottomsheet
                      Navigator.pop(context);

                      _showMessageUpdateDialog();
                    }),

//delete option
              if (isMe)
                _OptionItem(
                    icon: const Icon(
                      Icons.delete_forever_rounded,
                      color: Colors.red,
                      size: 26,
                    ),
                    name: "Delete Message",
                    onTap: () async {
                      await APIs.deleteMessage(widget.message).then((value) {
                        //for hiding bottomsheet
                        Navigator.pop(context);
                      });
                    }),

              //separator or divider
              Divider(
                color: Colors.black54,
                indent: mq.width * .04,
                endIndent: mq.width * .04,
              ),

//sent time
              _OptionItem(
                  icon: const Icon(
                    Icons.remove_red_eye,
                    color: Colors.blue,
                  ),
                  name:
                      "Sent At: ${MyDateUtil.getMessageTime(context: context, time: widget.message.sent)}",
                  onTap: () {}),

//read time
              _OptionItem(
                  icon: const Icon(
                    Icons.remove_red_eye,
                    color: Colors.green,
                  ),
                  name: widget.message.read.isEmpty
                      ? "Read At: Not seen yet"
                      : "Read At: ${MyDateUtil.getMessageTime(context: context, time: widget.message.read)}",
                  onTap: () {})
            ],
          );
        });
  }

//dialog for updating message content
  void _showMessageUpdateDialog() {
    String updatedMsg = widget.message.msg;

    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              contentPadding: const EdgeInsets.only(top: 20, bottom: 10, left: 24, right: 24),

              //title
              title:  const Row(
                children: [
                  Icon(
                    Icons.message,
                    color: Colors.blue,
                    size: 28,
                  ),
                  Text(
                    " Update Message",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  )
                ],
              ),

              content: TextFormField(
                maxLines: null,
                onChanged: (value) => updatedMsg = value,
                initialValue: updatedMsg,
                decoration: const InputDecoration(border: OutlineInputBorder()),
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

                //update button
                MaterialButton(
                  onPressed: () {
                    //hide alert dialog
                    Navigator.pop(context);
                    APIs.updateMessage(widget.message, updatedMsg);
                  },
                  child: const Text(
                    "Update",
                    style: TextStyle(color: Colors.blue, fontSize: 16),
                  ),
                )
              ],
            ));
  }
}

// ignore: must_be_immutable
class _OptionItem extends StatelessWidget {
  final Icon icon;
  final String name;
  VoidCallback onTap;
  _OptionItem({required this.icon, required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(),
      child: Padding(
        padding: EdgeInsets.only(
            left: mq.width * .05,
            top: mq.height * .015,
            bottom: mq.height * .025),
        child: Row(
          children: [
            icon,
            Flexible(
                child: Text(
              "    $name",
              style: const TextStyle(
                  fontSize: 15, color: Colors.black54, letterSpacing: 0.5),
            ))
          ],
        ),
      ),
    );
  }
}
