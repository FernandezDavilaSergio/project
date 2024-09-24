import 'package:flutter/material.dart';
import 'pages/home_page.dart'; // Asegúrate de que este import sea correcto

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(), // Llama a HomePage desde home_page.dart
    );
  }
}
