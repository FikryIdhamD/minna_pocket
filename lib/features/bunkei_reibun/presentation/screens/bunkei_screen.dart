import 'package:flutter/material.dart';

class BunkeiScreen extends StatelessWidget {
  const BunkeiScreen({super.key, required this.lesson});
  final int lesson;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(), body: Center(child: Text('BunkeiScreen $lesson')));
}
