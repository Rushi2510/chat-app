import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chat_app/api/api.dart';
import 'package:chat_app/helper/dialogs.dart';
import 'package:chat_app/models/chat_user.dart';
import 'package:chat_app/screens/auth/login_screen.dart';

import '../main.dart';

// profile screen --to show sign in user info
class ProfileScreen extends StatefulWidget {
  final ChatUser user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _image;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        //app bar
        appBar: AppBar(
          title: const Text("Profile Screen"),
        ),
        //floating button for logout user
        floatingActionButton: Padding(
          padding: const EdgeInsets.all(8.0),
          child: FloatingActionButton.extended(
              onPressed: () async {
                //for showing progress dialog
                Dialogs.showProgressBar(context);

                await APIs.updateActiveStatus(false);

                //signout from app
                await APIs.auth.signOut().then((value) async {
                  await GoogleSignIn().signOut().then((value) {
                    // ignore: use_build_context_synchronously
                    //for hiding progress dialog
                    Navigator.pop(context);
                    // ignore: use_build_context_synchronously
                    //for moving to home screen
                    Navigator.pop(context);

                    APIs.auth = FirebaseAuth.instance;
                    //replacing home screen with login screen
                    Navigator.pushReplacement(
                        // ignore: use_build_context_synchronously
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()));
                  });
                });
              },
              backgroundColor: Colors.redAccent,
              elevation: 1,
              icon: const Icon(
                Icons.logout,
                color: Colors.white,
              ),
              label: const Text(
                "Logout",
                style: TextStyle(color: Colors.white),
              )),
        ),
        // body
        body: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: mq.width * .05),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  //for adding some space
                  SizedBox(
                    width: mq.width,
                    height: mq.height * .03,
                  ),
                  //user profile picture
                  Stack(
                    children: [
                      _image != null
                          ? ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(mq.height * .1),
                              child: Image.file(
                                File(_image!),
                                height: mq.height * .2,
                                width: mq.height * .2,
                                fit: BoxFit.cover,
                              ),
                            )
                          : ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(mq.height * .1),
                              child: CachedNetworkImage(
                                height: mq.height * .2,
                                width: mq.height * .2,
                                imageUrl: widget.user.image,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) =>
                                    const CircleAvatar(
                                        child: Icon(CupertinoIcons.person)),
                              ),
                            ),

                      //edit image button
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: MaterialButton(
                          onPressed: () {
                            showBottomSheet();
                          },
                          color: Colors.white,
                          shape: const CircleBorder(),
                          child:  const Icon(Icons.edit, color: Colors.green),
                        ),
                      )
                    ],
                  ),
                  //for adding some space
                  SizedBox(
                    width: mq.width,
                    height: mq.height * .03,
                  ),
                  // user email label
                  Text(
                    widget.user.email,
                    style: const TextStyle(color: Colors.black54, fontSize: 16),
                  ),

                  //for adding some space
                  SizedBox(
                    width: mq.width,
                    height: mq.height * .05,
                  ),
                  //name input field
                  TextFormField(
                    initialValue: widget.user.name,
                    onSaved: (val) => APIs.me.name = val ?? "",
                    validator: (val) =>
                        val != null && val.isNotEmpty ? null : "Required Field",
                    decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        hintText: "eg. Happy Singh",
                        label: const Text("Name")),
                  ),
                  //for adding some space
                  SizedBox(
                    width: mq.width,
                    height: mq.height * .02,
                  ),
                  //about input field
                  TextFormField(
                    initialValue: widget.user.about,
                    onSaved: (val) => APIs.me.about = val ?? "",
                    validator: (val) =>
                        val != null && val.isNotEmpty ? null : "Required Field",
                    decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.info_outline),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        hintText: "eg. Feeling Happy",
                        label: const Text("About")),
                  ),
                  //for adding some space
                  SizedBox(
                    width: mq.width,
                    height: mq.height * .05,
                  ),
                  //update profile button
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        APIs.updateUserInfo().then((value) {
                          Dialogs.showSnackbar(
                              context, "Profile Updated Successfully!");
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        minimumSize: Size(mq.width * .5, mq.height * .06),
                        backgroundColor: Colors.green.shade300),
                    icon: const Icon(
                      Icons.edit,
                      size: 28,
                      color: Colors.black,
                    ),
                    label: const Text(
                      "UPDATE",
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void showBottomSheet() {

    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20))),
        builder: (_) {
          return ListView(
            shrinkWrap: true,
            padding:
                EdgeInsets.only(top: mq.height * .03, bottom: mq.height * .09),
            children: [
              //pick profile picture label
              const Text(
                "Pick Profile Picture",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
              //for adding some space
              SizedBox(
                height: mq.height * .02,
              ),
              //buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  //pick profile pic from gallery
                  ElevatedButton(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        // Pick an image.
                        final XFile? image = await picker.pickImage(
                            source: ImageSource.gallery, imageQuality: 80);
                        if (image != null) {
                          log("image path: ${image.path} --mime type:${image.mimeType}");
                          setState(() {
                            _image = image.path;
                          });

                          APIs.updateProfilePicture(File(_image!));
                          // for hiding bottom sheet
                          // ignore: use_build_context_synchronously
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          fixedSize: Size(mq.width * .3, mq.height * .15),
                          shape: const CircleBorder()),
                      child: Image.asset('images/gallery.png')),

                  //take picture from camera
                  ElevatedButton(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        // Pick an image.
                        final XFile? image = await picker.pickImage(
                            source: ImageSource.camera, imageQuality: 80);
                        if (image != null) {
                          log("image path: ${image.path} ");
                          setState(() {
                            _image = image.path;
                          });

                          APIs.updateProfilePicture(File(_image!));
                          // for hiding bottom sheet
                          // ignore: use_build_context_synchronously
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          fixedSize: Size(mq.width * .3, mq.height * .15),
                          shape: const CircleBorder()),
                      child: Image.asset('images/camera.png'))
                ],
              )
            ],
          );
        });
  }

}
