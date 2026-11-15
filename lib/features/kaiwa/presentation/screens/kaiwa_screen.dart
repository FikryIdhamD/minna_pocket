import 'package:flutter/material.dart';

class KaiwaScreen extends StatelessWidget {
  const KaiwaScreen({super.key, required this.lesson});
  final int lesson;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(), body: Center(child: Text('KaiwaScreen $lesson')));
}
