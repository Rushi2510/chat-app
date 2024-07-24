import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chat_app/api/api.dart';

import 'package:chat_app/main.dart';
import 'package:chat_app/screens/auth/login_screen.dart';
import 'package:chat_app/screens/home_screen.dart';

//splash screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<SplashScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      //exit full-screen
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

      SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(statusBarColor: Colors.transparent, ));
      if (APIs.auth.currentUser != null) {
        //goto homescreen
        log("\nUser: ${APIs.auth.currentUser}");
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => (const HomeScreen())));
      } else
         {
          //goto login screen
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => (const LoginScreen())));
        }
    });
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome To We Chat"),
      ),
      body: Stack(
        children: [
          Positioned(
              right: mq.width * .25,
              top: mq.height * .15,
              width: mq.width * .5,
              child: Image.asset(
                'images/wechat.png',
              )),
          Positioned(
              bottom: mq.height * .15,
              width: mq.width,
              child: const Text(
                "MADE IN INDIA WITH ❤️",
                style: TextStyle(
                    color: Colors.black87, fontSize: 16, letterSpacing: .5),
                textAlign: TextAlign.center,
              ))
        ],
      ),
    );
  }
}
