import 'package:ag_selector/view/tabs.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const AGSelector());
}

class AGSelector extends StatelessWidget {
  const AGSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AG Selector',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Tabs(),
    );
  }
}
