import 'package:flutter/material.dart';
import 'page/SelectBar.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GUS ForKlift',
      theme: ThemeData(
        // 主題色設定為藍色
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue, // ← 藍色
        ),
        useMaterial3: true, // Material 3 樣式（可選）
      ),
      home: SelectBarPage(), // 直接導向 SelectBar
      debugShowCheckedModeBanner: false,
    );
  }
}