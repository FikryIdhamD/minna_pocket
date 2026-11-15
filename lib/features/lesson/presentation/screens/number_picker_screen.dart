import 'package:flutter/material.dart';

class NumberPickerScreen extends StatelessWidget {
  const NumberPickerScreen(
      {super.key, required this.lesson, required this.section});
  final int lesson;
  final String section;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(),
      body: Center(child: Text('NumberPickerScreen $lesson $section')));
}
