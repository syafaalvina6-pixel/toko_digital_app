import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/cart_provider.dart';
import 'pages/catalog_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Kopi & Kafe Shop', // <-- UBAH TEKS DI SINI
        theme: ThemeData(
          primarySwatch: Colors.brown,
        ),
        home: const CatalogPage(),
      ),
    );
  }
}