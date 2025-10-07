/*  Marcador pádel ESP32
    - Usa tus matrices mat1..mat5 para 0,15,30,40,+
    - Dos tiras WS2812 (8x8 cada una) muestran la puntuación visual
    - MAX7219 (MD_Parola) muestra FIJO el nombre del jugador que SACA (patrón [0,2,1,3])
    - No enciende LEDs hasta recibir 4 nombres por Bluetooth (cada uno en su línea, terminado en '\n')
    - Enviar "0\n" -> punto equipo IZQUIERDA, "1\n" -> punto equipo DERECHA
*/

#include <Adafruit_NeoPixel.h>
#include <MD_Parola.h>
#include <MD_MAX72xx.h>
#include <SPI.h>
#include "BluetoothSerial.h"

// ------------------ HARDWARE ------------------
#define WS2812_PIN_1 5
#define WS2812_PIN_2 27
#define NUM_LEDS 64
Adafruit_NeoPixel leds_1 = Adafruit_NeoPixel(NUM_LEDS, WS2812_PIN_1, NEO_GRB + NEO_KHZ800);
Adafruit_NeoPixel leds_2 = Adafruit_NeoPixel(NUM_LEDS, WS2812_PIN_2, NEO_GRB + NEO_KHZ800);

#define HARDWARE_TYPE MD_MAX72XX::FC16_HW
#define MAX_DEVICES 4
#define CLK_PIN 14
#define DATA_PIN 13
#define CS_PIN 12
MD_Parola textoMatriz = MD_Parola(HARDWARE_TYPE, DATA_PIN, CLK_PIN, CS_PIN, MAX_DEVICES);

BluetoothSerial SerialBT;

// ------------------ HARDWARE LEDs físicos ------------------
const int ledsTeam0[3] = {18, 19, 21};  // equipo izquierda
const int ledsTeam1[3] = {4, 22, 23};   // equipo derecha

// ------------------ TUS MATRICES 8x8 (exactas) ------------------
const int mat1[8][8] = {
  {0, 0, 1, 1, 1, 1, 0, 0},
  {0, 0, 1, 0, 0, 1, 0, 0},
  {0, 0, 1, 0, 0, 1, 0, 0},
  {0, 0, 1, 0, 0, 1, 0, 0},
  {0, 0, 1, 0, 0, 1, 0, 0},
  {0, 0, 1, 0, 0, 1, 0, 0},
  {0, 0, 1, 0, 0, 1, 0, 0},
  {0, 0, 1, 1, 1, 1, 0, 0},
};

const int mat2[8][8] = {
  {0, 0, 1, 0, 0, 1, 1, 1},
  {0, 1, 1, 0, 0, 1, 0, 0},
  {1, 0, 1, 0, 0, 1, 0, 0},
  {0, 0, 1, 0, 0, 1, 0, 0},
  {0, 0, 1, 0, 0, 1, 1, 1},
  {0, 0, 1, 0, 0, 0, 0, 1},
  {0, 0, 1, 0, 0, 0, 0, 1},
  {0, 0, 1, 0, 0, 1, 1, 1},
};

const int mat3[8][8] = {
  {1, 1, 1, 0, 1, 1, 1, 1},
  {0, 0, 1, 0, 1, 0, 0, 1},
  {0, 0, 1, 0, 1, 0, 0, 1},
  {0, 0, 1, 0, 1, 0, 0, 1},
  {1, 1, 1, 0, 1, 0, 0, 1},
  {0, 0, 1, 0, 1, 0, 0, 1},
  {0, 0, 1, 0, 1, 0, 0, 1},
  {1, 1, 1, 0, 1, 1, 1, 1},
};

const int mat4[8][8] = {
  {1, 0, 1, 0, 0, 1, 1, 1},
  {1, 0, 1, 0, 0, 1, 0, 1},
  {1, 0, 1, 0, 0, 1, 0, 1},
  {1, 1, 1, 0, 0, 1, 0, 1},
  {0, 0, 1, 0, 0, 1, 0, 1},
  {0, 0, 1, 0, 0, 1, 0, 1},
  {0, 0, 1, 0, 0, 1, 0, 1},
  {0, 0, 1, 0, 0, 1, 1, 1},
};

const int mat5[8][8] = {
  {0, 0, 0, 1, 1, 0, 0, 0},
  {0, 0, 0, 1, 1, 0, 0, 0},
  {0, 0, 0, 1, 1, 0, 0, 0},
  {1, 1, 1, 1, 1, 1, 1, 1},
  {1, 1, 1, 1, 1, 1, 1, 1},
  {0, 0, 0, 1, 1, 0, 0, 0},
  {0, 0, 0, 1, 1, 0, 0, 0},
  {0, 0, 0, 1, 1, 0, 0, 0},
};

// ------------------ ESTADO PARTIDO ------------------
String jugadoresArr[4];
int nombresRecibidos = 0;
bool iniciado = false;

// puntos: 0=0, 1=15, 2=30, 3=40
int puntosLeft = 0;
int puntosRight = 0;
// ventaja: -1 = ninguna, 0 = izquierda, 1 = derecha
int advTeam = -1;

// juegos
int juegosLeft = 0;
int juegosRight = 0;

// orden de servidor por juego: [0,2,1,3]
const int serverOrder[4] = {0, 2, 1, 3};
int gameIndex = 0; // juego actual

int contPatron = 1; // alternancia visual (opcional)

// ------------------ FUNCIONES AUXILIARES ------------------

// Dibuja la matriz int mat[8][8] en la tira WS (fila por fila, izquierda->derecha)
void drawMatrixOnWS(Adafruit_NeoPixel &leds, const int mat[8][8], uint32_t color) {
  int index = 0;
  for (int r = 0; r < 8; ++r) {
    for (int c = 0; c < 8; ++c) {
      if (mat[r][c] == 1) leds.setPixelColor(index, color);
      else leds.setPixelColor(index, 0);
      index++;
    }
  }
  leds.show();
}

// Actualiza ambas matrices WS con la puntuación actual (usa mat1..mat5)
void updateScoreWS() {
  uint32_t colorLeft = leds_1.Color(255, 0, 0);   // rojo para izquierda
  uint32_t colorRight = leds_2.Color(0, 255, 0);  // verde para derecha

  // izquierda
  if (advTeam == 0) {
    drawMatrixOnWS(leds_1, mat5, colorLeft); // '+'
  } else {
    switch (puntosLeft) {
      case 0: drawMatrixOnWS(leds_1, mat1, colorLeft); break; // 0
      case 1: drawMatrixOnWS(leds_1, mat2, colorLeft); break; // 15
      case 2: drawMatrixOnWS(leds_1, mat3, colorLeft); break; // 30
      default: drawMatrixOnWS(leds_1, mat4, colorLeft); break; // 40
    }
  }

  // derecha
  if (advTeam == 1) {
    drawMatrixOnWS(leds_2, mat5, colorRight); // '+'
  } else {
    switch (puntosRight) {
      case 0: drawMatrixOnWS(leds_2, mat1, colorRight); break; // 0
      case 1: drawMatrixOnWS(leds_2, mat2, colorRight); break; // 15
      case 2: drawMatrixOnWS(leds_2, mat3, colorRight); break; // 30
      default: drawMatrixOnWS(leds_2, mat4, colorRight); break; // 40
    }
  }
}

// convierte a mayúsculas
String toUpperCaseStr(const String &s) {
  String r = s; r.toUpperCase(); return r;
}
// abreviación: si <=6 caracteres muestra todo, si no devuelve primeras 3 letras
String abbrev(const String &s) {
  String up = toUpperCaseStr(s);
  if (up.length() <= 6) return up;
  return up.substring(0, 3);
}

// MUESTRA EL SERVIDOR EN LA MAX7219 de forma FIJA.
void mostrarServidorEnMAX() {
  int serverPlayer = serverOrder[gameIndex % 4];
  String name = jugadoresArr[serverPlayer];
  String disp = abbrev(name);

  textoMatriz.displayClear();
  textoMatriz.displayText(disp.c_str(), PA_CENTER, 0, 0, PA_PRINT, PA_PRINT);
  textoMatriz.displayReset();
}

// ------------------ ACTUALIZAR LEDs FÍSICOS DE JUEGOS ------------------
void updateGameLeds() {
  // actualizar LEDs equipo 0
  for (int i = 0; i < 3; i++) {
    if (i < juegosLeft) digitalWrite(ledsTeam0[i], HIGH);
    else digitalWrite(ledsTeam0[i], LOW);
  }
  // actualizar LEDs equipo 1
  for (int i = 0; i < 3; i++) {
    if (i < juegosRight) digitalWrite(ledsTeam1[i], HIGH);
    else digitalWrite(ledsTeam1[i], LOW);
  }
}

// Gana juego el equipo 'team' (0 izquierda, 1 derecha)
void winGame(int team) {
  if (team == 0) juegosLeft++;
  else juegosRight++;

  // actualizar LEDs físicos de juegos
  updateGameLeds();

  // reset puntos y ventaja
  puntosLeft = 0;
  puntosRight = 0;
  advTeam = -1;

  // siguiente juego -> cambia servidor
  gameIndex++;

  // refrescar displays
  updateScoreWS();
  mostrarServidorEnMAX();
}

// Procesa punto marcado por 'team' (0 izquierda, 1 derecha)
void procesarPunto(int team) {
  // efecto visual opcional (usa mat2 como parpadeo)
  if (team == 0) drawMatrixOnWS(leds_1, mat2, leds_1.Color(255,0,0));
  else drawMatrixOnWS(leds_2, mat2, leds_2.Color(0,255,0));
  contPatron++; if (contPatron > 4) contPatron = 1;

  // Lógica tenis con ventaja correcta:
  if (puntosLeft >= 3 && puntosRight >= 3) {
    // Deuce / Ventaja zone
    if (advTeam == -1) {
      advTeam = team;
    } else {
      if (advTeam == team) {
        winGame(team);
        return;
      } else {
        advTeam = -1;
      }
    }
  } else {
    // zona normal
    if (team == 0) puntosLeft++;
    else puntosRight++;

    if (puntosLeft >= 4 && puntosRight <= 2) { winGame(0); return; }
    if (puntosRight >= 4 && puntosLeft <= 2) { winGame(1); return; }
  }

  updateScoreWS();
}

// ------------------ SETUP / LOOP ------------------
void setup() {
  Serial.begin(115200);
  Serial.println("ESP32 marcador pádel - arrancando...");
  SerialBT.begin("ESP32_LED");

  leds_1.begin(); leds_1.show();
  leds_2.begin(); leds_2.show();

  // inicializar MAX7219 (MD_Parola)
  textoMatriz.begin();
  textoMatriz.setIntensity(8);
  textoMatriz.setTextAlignment(PA_CENTER);
  textoMatriz.displayClear();

  // configurar LEDs físicos como salida
  for (int i = 0; i < 3; i++) {
    pinMode(ledsTeam0[i], OUTPUT);
    pinMode(ledsTeam1[i], OUTPUT);
    digitalWrite(ledsTeam0[i], LOW);
    digitalWrite(ledsTeam1[i], LOW);
  }
}

void loop() {
  // 1) Recolectar 4 nombres por Bluetooth
  if (!iniciado) {
    while (SerialBT.available()) {
      String line = SerialBT.readStringUntil('\n');
      line.trim();
      if (line.length() == 0) continue;

      if (nombresRecibidos < 4) {
        jugadoresArr[nombresRecibidos] = line;
        Serial.print("Nombre recibido #");
        Serial.print(nombresRecibidos + 1);
        Serial.print(": ");
        Serial.println(line);
        nombresRecibidos++;
      }

      if (nombresRecibidos >= 4) {
        iniciado = true;
        puntosLeft = 0; puntosRight = 0; advTeam = -1;
        juegosLeft = 0; juegosRight = 0;
        gameIndex = 0; contPatron = 1;
        mostrarServidorEnMAX();
        updateScoreWS();
        updateGameLeds();
        Serial.println("PARTIDO INICIADO: MAX muestra servidor y WS 0-0");
      }
    }
    delay(10);
    return;
  }

  // 2) Partido iniciado: procesar comandos 0/1 como puntos
  if (SerialBT.available()) {
    String line = SerialBT.readStringUntil('\n');
    line.trim();
    if (line.length() > 0) {
      Serial.print("Dato recibido: ");
      Serial.println(line);
      if (line == "0") {
        procesarPunto(0);
      } else if (line == "1") {
        procesarPunto(1);
      } else {
        Serial.println("Comando desconocido. Usa '0' o '1'.");
      }
    }
  }

  textoMatriz.displayAnimate();
  delay(20);
}
