import 'package:flutter/material.dart';
import 'marcador.dart';

class WinnerScreen extends StatelessWidget {
  final String ganador;
  final int setsA;
  final int setsB;
  final List<Map<String, int>> historialSets; // 👈 Nuevos datos
  final VoidCallback onReiniciar;

  const WinnerScreen({
    required this.ganador,
    required this.setsA,
    required this.setsB,
    required this.historialSets,
    required this.onReiniciar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Resultado final')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¡$ganador gana el partido!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 20),
            Text('Resultado final: $setsA - $setsB',
                style: TextStyle(fontSize: 22)),
            SizedBox(height: 20),

            // 👇 Muestra detalle de sets
            ...historialSets.asMap().entries.map((entry) {
              int index = entry.key + 1;
              int a = entry.value['A']!;
              int b = entry.value['B']!;
              return Text('Set $index: $a - $b', style: TextStyle(fontSize: 20));
            }).toList(),

            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                onReiniciar();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => ScoreScreen()),
                  (route) => false,
                );
              },
              child: Text('Reiniciar partido'),
            ),
          ],
        ),
      ),
    );
  }
}
