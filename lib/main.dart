import 'package:flutter/material.dart';

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

// Clase que maneja toda la lógica del marcador
class Marcador {
  int puntosA = 0; // 0=0, 1=15, 2=30, 3=40, 4=Ad
  int puntosB = 0;
  int juegosA = 0;
  int juegosB = 0;
  List<bool> setsA = [false, false, false]; // 3 sets
  List<bool> setsB = [false, false, false];

  List<Map<String, dynamic>> historial = [];

  void sumarPunto(String equipo) {
    // Guardamos el estado actual
    historial.add({
      'puntosA': puntosA,
      'puntosB': puntosB,
      'juegosA': juegosA,
      'juegosB': juegosB,
      'setsA': List.from(setsA),
      'setsB': List.from(setsB),
    });

    if (equipo == 'A') _actualizarPunto('A');
    else _actualizarPunto('B');
  }

  void deshacer() {
    if (historial.isNotEmpty) {
      final ultimo = historial.removeLast();
      puntosA = ultimo['puntosA'];
      puntosB = ultimo['puntosB'];
      juegosA = ultimo['juegosA'];
      juegosB = ultimo['juegosB'];
      setsA = List<bool>.from(ultimo['setsA']);
      setsB = List<bool>.from(ultimo['setsB']);
    }
  }

  void _actualizarPunto(String equipo) {
    if (equipo == 'A') {
      if (puntosA < 3) puntosA++;
      else {
        if (puntosB < 3 || (puntosB == 3 && puntosA == 4)) {
          // gana el juego
          puntosA = 0;
          puntosB = 0;
          juegosA++;
          _revisarSet('A');
        } else if (puntosB == 3) {
          puntosA++; // ventaja
        } else if (puntosB == 4) {
          puntosB = 3; // vuelve a deuce
        }
      }
    } else {
      if (puntosB < 3) puntosB++;
      else {
        if (puntosA < 3 || (puntosA == 3 && puntosB == 4)) {
          puntosB = 0;
          puntosA = 0;
          juegosB++;
          _revisarSet('B');
        } else if (puntosA == 3) {
          puntosB++; // ventaja
        } else if (puntosA == 4) {
          puntosA = 3;
        }
      }
    }
  }

  void _revisarSet(String equipo) {
    if (equipo == 'A' && juegosA >= 6) {
      for (int i = 0; i < setsA.length; i++) {
        if (!setsA[i]) {
          setsA[i] = true; // enciende la luz
          break;
        }
      }
      juegosA = 0;
      puntosA = 0;
      puntosB = 0;
    } else if (equipo == 'B' && juegosB >= 6) {
      for (int i = 0; i < setsB.length; i++) {
        if (!setsB[i]) {
          setsB[i] = true;
          break;
        }
      }
      juegosB = 0;
      puntosA = 0;
      puntosB = 0;
    }
  }

  String puntosToString(int puntos) {
    switch (puntos) {
      case 0:
        return '0';
      case 1:
        return '15';
      case 2:
        return '30';
      case 3:
        return '40';
      case 4:
        return 'Ad';
      default:
        return '';
    }
  }
}

class ScoreScreen extends StatefulWidget {
  @override
  _ScoreScreenState createState() => _ScoreScreenState();
}

class _ScoreScreenState extends State<ScoreScreen> {
  Marcador marcador = Marcador();

  void sumarPunto(String equipo) {
    setState(() {
      marcador.sumarPunto(equipo);
    });
  }

  void deshacer() {
    setState(() {
      marcador.deshacer();
    });
  }

  Widget buildSetsRow(List<bool> sets) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: sets
          .map((encendida) => Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: encendida ? Colors.green : Colors.grey[400],
                ),
              ))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Marcador de Pádel')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Equipo A: ${marcador.puntosToString(marcador.puntosA)} | Juegos: ${marcador.juegosA}',
            style: TextStyle(fontSize: 24),
          ),
          buildSetsRow(marcador.setsA),
          SizedBox(height: 20),
          Text(
            'Equipo B: ${marcador.puntosToString(marcador.puntosB)} | Juegos: ${marcador.juegosB}',
            style: TextStyle(fontSize: 24),
          ),
          buildSetsRow(marcador.setsB),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => sumarPunto('A'),
                child: Text('Punto A'),
              ),
              SizedBox(width: 20),
              ElevatedButton(
                onPressed: () => sumarPunto('B'),
                child: Text('Punto B'),
              ),
            ],
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: deshacer,
            child: Text('Deshacer'),
          ),
        ],
      ),
    );
  }
}
