import 'package:flutter/material.dart';

class BunpouScreen extends StatelessWidget {
  const BunpouScreen({super.key, required this.lesson, required this.no});
  final int lesson;
  final int no;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(), body: Center(child: Text('BunpouScreen $lesson $no')));
}
