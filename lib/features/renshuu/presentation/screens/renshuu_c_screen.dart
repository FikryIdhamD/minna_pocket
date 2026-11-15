import 'package:flutter/material.dart';

class RenshuuCScreen extends StatelessWidget {
  const RenshuuCScreen({super.key, required this.lesson, required this.no});
  final int lesson;
  final int no;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(),
      body: Center(child: Text('RenshuuCScreen $lesson $no')));
}
