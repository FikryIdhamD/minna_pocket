import 'package:flutter/material.dart';

class MondaishuuSetScreen extends StatelessWidget {
  const MondaishuuSetScreen({super.key, required this.setId});
  final String setId;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(),
      body: Center(child: Text('MondaishuuSetScreen $setId')));
}
