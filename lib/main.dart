import 'package:flutter/material.dart';
import 'marcador.dart';


void main() {
  runApp(PadelScoreApp());
}

class PadelScoreApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Marcador Pádel',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: ScoreScreen(),
    );
  }
}

