import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:chat_app/api/api.dart';
import 'package:chat_app/helper/dialogs.dart';
import 'package:chat_app/main.dart';
import 'package:chat_app/screens/home_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<LoginScreen> {
  bool _isAnimated = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _isAnimated = true;
      });
    });
  }

  _handleGoogleBtnClick() {
    //for showing progress bar
    Dialogs.showProgressBar(context);
    _signInWithGoogle().then((user) async{
      //for hiding progress bar
      Navigator.pop(context);
      if (user != null) {
        log("\nUser:${user.user}");
        log("\nUserAdditionalInfo:${user.additionalUserInfo}");
if (await APIs.userExists()) {
   Navigator.pushReplacement(
             // ignore: use_build_context_synchronously
             context, MaterialPageRoute(builder: (_) => const HomeScreen()));
}else{
  await APIs.createUser().then((value) {
    Navigator.pushReplacement(
             context, MaterialPageRoute(builder: (_) => const HomeScreen()));
  });
}


        // Navigator.pushReplacement(
        //     context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    });
  }

  Future<UserCredential?> _signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      // Once signed in, return the UserCredential
      return await APIs.auth.signInWithCredential(credential);
    } catch (e) {
      log("\n_signInWithGoogle: $e");
      // ignore: use_build_context_synchronously
      Dialogs.showSnackbar(context, "something went wrong(check internet connection)");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // mq = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome To We Chat"),
      ),
      body: Stack(
        children: [
          AnimatedPositioned(
              duration: Duration(seconds: 1),
              right: _isAnimated ? mq.width * .25 : -mq.width * .5,
              top: mq.height * .15,
              width: mq.width * .5,
              child: Image.asset(
                'images/wechat.png',
              )),
          Positioned(
              bottom: mq.height * .15,
              width: mq.width * .9,
              left: mq.width * .05,
              child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 184, 233, 185),
                      shape: const StadiumBorder()),
                  onPressed: () {
                    _handleGoogleBtnClick();
                    // Navigator.pushReplacement(context,
                    //     MaterialPageRoute(builder: (_) => const HomeScreen()));
                  },
                  icon: Image.asset(
                    "images/search.png",
                    height: mq.height * .03,
                  ),
                  label: RichText(
                      text: const TextSpan(
                          style: TextStyle(color: Colors.black, fontSize: 16),
                          children: [
                        TextSpan(text: "login with "),
                        TextSpan(
                            text: "Google",
                            style: TextStyle(fontWeight: FontWeight.w500))
                      ]))))
        ],
      ),
    );
  }
}
