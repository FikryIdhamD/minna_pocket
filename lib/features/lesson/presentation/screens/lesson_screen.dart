import 'package:flutter/material.dart';

class LessonScreen extends StatelessWidget {
  const LessonScreen({super.key, required this.lesson});
  final int lesson;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(), body: Center(child: Text('LessonScreen $lesson')));
}
