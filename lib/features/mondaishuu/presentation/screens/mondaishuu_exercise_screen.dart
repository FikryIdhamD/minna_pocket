import 'package:flutter/material.dart';

class MondaishuuExerciseScreen extends StatelessWidget {
  const MondaishuuExerciseScreen(
      {super.key,
      required this.setId,
      required this.exNo,
      this.onlyWrong = false});
  final String setId;
  final int exNo;
  final bool onlyWrong;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(),
      body: Center(
          child: Text('MondaishuuExerciseScreen $setId $exNo $onlyWrong')));
}
