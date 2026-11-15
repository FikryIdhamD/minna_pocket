import 'package:flutter/material.dart';

class KosakataScreen extends StatelessWidget {
  const KosakataScreen({super.key, required this.lesson});
  final int lesson;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(), body: Center(child: Text('KosakataScreen $lesson')));
}
