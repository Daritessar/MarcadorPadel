import 'package:flutter/material.dart';
import 'winner_screen.dart';

class Marcador {
  int puntosA = 0;
  int puntosB = 0;
  int juegosA = 0;
  int juegosB = 0;
  int setsA = 0;
  int setsB = 0;

  List<Map<String, dynamic>> historial = [];
  List<Map<String, int>> historialSets = []; // 👈 Guarda los juegos por set

  void sumarPunto(String equipo) {
    historial.add({
      'puntosA': puntosA,
      'puntosB': puntosB,
      'juegosA': juegosA,
      'juegosB': juegosB,
      'setsA': setsA,
      'setsB': setsB,
      'historialSets': List<Map<String, int>>.from(historialSets),
    });

    if (equipo == 'A') {
      _actualizarPunto('A');
    } else {
      _actualizarPunto('B');
    }
  }

  void deshacer() {
    if (historial.isNotEmpty) {
      final ultimo = historial.removeLast();
      puntosA = ultimo['puntosA'];
      puntosB = ultimo['puntosB'];
      juegosA = ultimo['juegosA'];
      juegosB = ultimo['juegosB'];
      setsA = ultimo['setsA'];
      setsB = ultimo['setsB'];
      historialSets = List<Map<String, int>>.from(ultimo['historialSets']);
    }
  }

  void reiniciar() {
    puntosA = 0;
    puntosB = 0;
    juegosA = 0;
    juegosB = 0;
    setsA = 0;
    setsB = 0;
    historial.clear();
    historialSets.clear();
  }

  void _actualizarPunto(String equipo) {
    if (equipo == 'A') {
      if (puntosA < 3) {
        puntosA++;
      } else {
        if (puntosB < 3 || (puntosB == 3 && puntosA == 4)) {
          puntosA = 0;
          puntosB = 0;
          juegosA++;
          _verificarSet();
        } else if (puntosB == 3) {
          puntosA++;
        } else if (puntosB == 4) {
          puntosB = 3;
        }
      }
    } else {
      if (puntosB < 3) {
        puntosB++;
      } else {
        if (puntosA < 3 || (puntosA == 3 && puntosB == 4)) {
          puntosA = 0;
          puntosB = 0;
          juegosB++;
          _verificarSet();
        } else if (puntosA == 3) {
          puntosB++;
        } else if (puntosA == 4) {
          puntosA = 3;
        }
      }
    }
  }

  void _verificarSet() {
    if (juegosA >= 6 && juegosA - juegosB >= 2) {
      setsA++;
      historialSets.add({'A': juegosA, 'B': juegosB}); // 👈 Guarda set terminado
      juegosA = 0;
      juegosB = 0;
    } else if (juegosB >= 6 && juegosB - juegosA >= 2) {
      setsB++;
      historialSets.add({'A': juegosA, 'B': juegosB});
      juegosA = 0;
      juegosB = 0;
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

  bool hayGanador() {
    return setsA == 3 || setsB == 3;
  }

  String ganador() {
    return setsA == 3 ? 'Equipo A' : 'Equipo B';
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

    if (marcador.hayGanador()) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => WinnerScreen(
            ganador: marcador.ganador(),
            setsA: marcador.setsA,
            setsB: marcador.setsB,
            historialSets: marcador.historialSets, // 👈 Se pasa aquí
            onReiniciar: () {
              setState(() {
                marcador.reiniciar();
              });
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => ScoreScreen()),
              );
            },
          ),
        ),
      );
    }
  }

  void deshacer() {
    setState(() {
      marcador.deshacer();
    });
  }

  void reiniciar() {
    setState(() {
      marcador.reiniciar();
    });
  }

  Widget _buildLuces(int sets) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return Container(
          margin: EdgeInsets.all(4),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < sets ? Colors.green : Colors.grey[300],
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Marcador de Pádel')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Equipo A: ${marcador.puntosToString(marcador.puntosA)} | Juegos: ${marcador.juegosA}',
              style: TextStyle(fontSize: 24)),
          _buildLuces(marcador.setsA),
          SizedBox(height: 10),
          Text('Equipo B: ${marcador.puntosToString(marcador.puntosB)} | Juegos: ${marcador.juegosB}',
              style: TextStyle(fontSize: 24)),
          _buildLuces(marcador.setsB),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(onPressed: () => sumarPunto('A'), child: Text('Punto A')),
              SizedBox(width: 20),
              ElevatedButton(onPressed: () => sumarPunto('B'), child: Text('Punto B')),
            ],
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(onPressed: deshacer, child: Text('Deshacer')),
              SizedBox(width: 20),
              ElevatedButton(onPressed: reiniciar, child: Text('Reiniciar')),
            ],
          ),
        ],
      ),
    );
  }
}

