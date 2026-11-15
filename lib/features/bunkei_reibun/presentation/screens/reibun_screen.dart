import 'package:flutter/material.dart';

class ReibunScreen extends StatelessWidget {
  const ReibunScreen({super.key, required this.lesson});
  final int lesson;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(), body: Center(child: Text('ReibunScreen $lesson')));
}
