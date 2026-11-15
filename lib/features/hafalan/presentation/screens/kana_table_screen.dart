import 'package:flutter/material.dart';

class KanaTableScreen extends StatelessWidget {
  const KanaTableScreen({super.key, required this.script});
  final String script;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(), body: Center(child: Text('KanaTableScreen $script')));
}
