import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'app.dart';

void main()async {
    WidgetsFlutterBinding.ensureInitialized();
  await Purchases.configure(PurchasesConfiguration("goog_wDuWPyUXJWSqxPwCnOteZSKmKhq"));

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
