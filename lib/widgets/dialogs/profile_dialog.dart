import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:chat_app/main.dart';
import 'package:chat_app/models/chat_user.dart';
import 'package:chat_app/screens/view_profile_screen.dart';

class ProfileDialog extends StatelessWidget {
  const ProfileDialog({super.key, required this.user});

  final ChatUser user;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SizedBox(
        height: mq.height * .35,
        width: mq.width * .6,
        child: Stack(
          children: [
            Positioned(
              left: mq.width * .04,
              top:  mq.height * .02,
              width:  mq.width * .55,
              
              child: Text(
                user.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ),
            Positioned(
             top: mq.height * .075,
             left: mq.width * .14,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(mq.height * .25),
                child: CachedNetworkImage(
                  width: mq.width * .5,
                  imageUrl: user.image,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) =>
                      const CircleAvatar(child: Icon(CupertinoIcons.person)),
                ),
              ),
            ),
             Positioned(
                top: 8,
                right: 8,
                child: MaterialButton(
                   onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ViewProfileScreen(user: user)));
                   },
                   shape: const CircleBorder(),
                   padding: const EdgeInsets.all(0),
                   minWidth: 0,
                  child: const Icon(
                    Icons.info_outline,
                    color: Colors.blue,
                    size: 30,
                  ),
                ))
          ],
        ),
      ),
    );
  }
}
