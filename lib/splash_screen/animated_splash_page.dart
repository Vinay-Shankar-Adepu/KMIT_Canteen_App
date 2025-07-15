import 'package:flutter/material.dart';
import 'dart:async';

class AnimatedSplashPage extends StatefulWidget {
  final Widget initialScreen;

  const AnimatedSplashPage({super.key, required this.initialScreen});

  @override
  State<AnimatedSplashPage> createState() => _AnimatedSplashPageState();
}

class _AnimatedSplashPageState extends State<AnimatedSplashPage> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => widget.initialScreen),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: Image.asset('assets/splash/logo_splash.gif')),
    );
  }
}
