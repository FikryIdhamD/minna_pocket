import 'package:flutter/material.dart';

class MondaishuuResultScreen extends StatelessWidget {
  const MondaishuuResultScreen({super.key, required this.setId});
  final String setId;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(),
      body: Center(child: Text('MondaishuuResultScreen $setId')));
}
