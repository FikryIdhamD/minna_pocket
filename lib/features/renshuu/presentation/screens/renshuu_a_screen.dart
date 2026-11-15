import 'package:flutter/material.dart';

class RenshuuAScreen extends StatelessWidget {
  const RenshuuAScreen({super.key, required this.lesson, required this.no});
  final int lesson;
  final int no;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(),
      body: Center(child: Text('RenshuuAScreen $lesson $no')));
}
