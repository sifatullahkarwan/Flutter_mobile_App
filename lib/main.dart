import 'package:flutter/material.dart';
import 'package:pixelwipe/pages/home_page.dart';
import 'package:pixelwipe/pages/landing_page.dart';
import 'package:pixelwipe/pages/object_removal/object_removal_setup.dart';
import 'app.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PixelWipe',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        fontFamily: 'Inter',
      ),
      home: App(),
      debugShowCheckedModeBanner: false,
    );
  }
}
