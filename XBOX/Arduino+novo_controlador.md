```cpp
#include <ArduinoBLE.h>

// --- Definições dos Pinos para o Driver BTS7960 ---
const int R_EN = 5;  // Pino de ativação direito (Right Enable)
const int L_EN = 6;  // Pino de ativação esquerdo (Left Enable)
const int R_PWM = 9; // Pino PWM para velocidade no sentido horário (CW)
const int L_PWM = 10;// Pino PWM para velocidade no sentido anti-horário (CCW)

// --- Definições do Bluetooth Low Energy (BLE) ---
// UUIDs devem ser exatamente os mesmos que os da sua aplicação iOS
const char* deviceServiceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
const char* deviceCharacteristicUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
const char* localName = "MotorControl"; // Nome que o seu iPhone irá procurar

BLEService motorService(deviceServiceUuid);
BLEStringCharacteristic motorCharacteristic(deviceCharacteristicUuid, BLERead | BLEWrite, 20);

// Variáveis para controlar os programas de vibração
unsigned long previousMillis = 0;
bool isPulsing = false;
int pulseStep = 0;

void setup() {
  Serial.begin(9600);
  while (!Serial);

  // Configura os pinos do driver como saída
  pinMode(R_EN, OUTPUT);
  pinMode(L_EN, OUTPUT);
  pinMode(R_PWM, OUTPUT);
  pinMode(L_PWM, OUTPUT);

  // Ativa ambos os lados do driver H-Bridge
  digitalWrite(R_EN, HIGH);
  digitalWrite(L_EN, HIGH);

  // Garante que o motor está parado no início
  analogWrite(R_PWM, 0);
  analogWrite(L_PWM, 0);

  // Inicia o BLE
  if (!BLE.begin()) {
    Serial.println("Falha ao iniciar o BLE!");
    while (1);
  }

  // Configura o nome do dispositivo e os UUIDs
  BLE.setLocalName(localName);
  BLE.setAdvertisedService(motorService);
  motorService.addCharacteristic(motorCharacteristic);
  BLE.addService(motorService);

  // Define a função de callback para quando um comando for recebido
  motorCharacteristic.setEventHandler(BLEWritten, onMotorCommand);

  // Começa a anunciar o dispositivo
  BLE.advertise();
  Serial.println("Dispositivo BLE 'MotorControl' com BTS7960 pronto.");
}

void loop() {
  BLE.poll();
  if (isPulsing) {
    handlePulseProgram();
  }
}

// --- Funções de Controle do Motor para BTS7960 ---

void motorStop() {
  analogWrite(R_PWM, 0);
  analogWrite(L_PWM, 0);
  isPulsing = false;
  Serial.println("Motor parado");
}

void motorClockwise(int speed) {
  analogWrite(L_PWM, 0); // Desliga o PWM do sentido oposto
  analogWrite(R_PWM, speed); // Define a velocidade para o sentido horário
  Serial.print("Motor girando CW com velocidade ");
  Serial.println(speed);
}

void motorCounterClockwise(int speed) {
  analogWrite(R_PWM, 0); // Desliga o PWM do sentido oposto
  analogWrite(L_PWM, speed); // Define a velocidade para o sentido anti-horário
  Serial.print("Motor girando CCW com velocidade ");
  Serial.println(speed);
}


// --- Lógica dos Programas (não precisa de alteração) ---

void handlePulseProgram() {
  unsigned long currentMillis = millis();
  if (currentMillis - previousMillis >= 500) {
    previousMillis = currentMillis;
    if (pulseStep % 2 == 0) {
      motorClockwise(255);
    } else {
      motorStop();
    }
    pulseStep++;
  }
}

void startProgram(String programName) {
  motorStop();
  if (programName.equalsIgnoreCase("Pulse")) {
    isPulsing = true;
    pulseStep = 0;
    previousMillis = millis();
    Serial.println("Iniciando programa: Pulse");
  } else if (programName.equalsIgnoreCase("Long")) {
    motorClockwise(200);
  } else if (programName.equalsIgnoreCase("Rhythmic")) {
    motorClockwise(150);
    delay(200);
    motorClockwise(255);
    delay(200);
  } else if (programName.equalsIgnoreCase("Fast")) {
    motorClockwise(255);
  }
}


// --- Callback para Comandos Recebidos via BLE (não precisa de alteração) ---

void onMotorCommand(BLEDevice central, BLECharacteristic characteristic) {
  String command = motorCharacteristic.value();
  command.trim();
  Serial.print("Comando recebido: ");
  Serial.println(command);

  isPulsing = false;

  if (command.equalsIgnoreCase("stop")) {
    motorStop();
  } else if (command.equalsIgnoreCase("cw")) {
    motorClockwise(255);
  } else if (command.equalsIgnoreCase("ccw")) {
    motorCounterClockwise(255);
  } else if (command.startsWith("program:")) {
    String programName = command.substring(8);
    startProgram(programName);
  } else if (command.startsWith("manual:")) {
    String params = command.substring(7);
    int commaIndex = params.indexOf(',');
    if (commaIndex != -1) {
      String intensityStr = params.substring(0, commaIndex);
      int intensity = intensityStr.toInt();
      int motorSpeed = map(intensity, 0, 100, 0, 255);
      motorClockwise(motorSpeed); // Por padrão, o modo manual gira em CW
    }
  }
}
```