import 'package:flutter/material.dart';

class RenshuuBScreen extends StatelessWidget {
  const RenshuuBScreen({super.key, required this.lesson, required this.no});
  final int lesson;
  final int no;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(),
      body: Center(child: Text('RenshuuBScreen $lesson $no')));
}
