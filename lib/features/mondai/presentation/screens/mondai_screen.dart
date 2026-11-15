import 'package:flutter/material.dart';

class MondaiScreen extends StatelessWidget {
  const MondaiScreen({super.key, required this.lesson, required this.no});
  final int lesson;
  final int no;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(), body: Center(child: Text('MondaiScreen $lesson $no')));
}
