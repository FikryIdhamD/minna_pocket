import 'package:flutter/material.dart';

class SankouScreen extends StatelessWidget {
  const SankouScreen({super.key, required this.lesson});
  final int lesson;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(), body: Center(child: Text('SankouScreen $lesson')));
}
