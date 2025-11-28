```cpp
#include <ArduinoBLE.h>

// --- Definições dos Pinos do Motor ---
// Altere estes pinos conforme a sua conexão com o driver do motor
const int motorPin1 = 2; // Pino de controle de direção 1
const int motorPin2 = 3; // Pino de controle de direção 2
const int speedPin  = 4; // Pino de controle de velocidade (PWM)

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
  while (!Serial); // Espera a porta serial conectar (útil para debug)

  // Configura os pinos do motor como saída
  pinMode(motorPin1, OUTPUT);
  pinMode(motorPin2, OUTPUT);
  pinMode(speedPin, OUTPUT);

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

  // Define a função que será chamada quando um valor for escrito na característica
  motorCharacteristic.setEventHandler(BLEWritten, onMotorCommand);

  // Começa a anunciar o dispositivo
  BLE.advertise();
  Serial.println("Dispositivo BLE 'MotorControl' anunciando...");
}

void loop() {
  // Aguarda por conexões de dispositivos BLE
  BLE.poll();

  // Se um programa estiver ativo, executa a lógica dele aqui
  if (isPulsing) {
    handlePulseProgram();
  }
}

// --- Funções de Controle do Motor ---

void motorStop() {
  digitalWrite(motorPin1, LOW);
  digitalWrite(motorPin2, LOW);
  analogWrite(speedPin, 0);
  isPulsing = false; // Para qualquer programa em execução
  Serial.println("Motor parado");
}

void motorClockwise(int speed) {
  digitalWrite(motorPin1, HIGH);
  digitalWrite(motorPin2, LOW);
  analogWrite(speedPin, speed);
  Serial.print("Motor girando no sentido horário com velocidade ");
  Serial.println(speed);
}

void motorCounterClockwise(int speed) {
  digitalWrite(motorPin1, LOW);
  digitalWrite(motorPin2, HIGH);
  analogWrite(speedPin, speed);
  Serial.print("Motor girando no sentido anti-horário com velocidade ");
  Serial.println(speed);
}


// --- Lógica dos Programas ---

void handlePulseProgram() {
  unsigned long currentMillis = millis();
  // Lógica simples de pulso: 500ms ligado, 500ms desligado
  if (currentMillis - previousMillis >= 500) {
    previousMillis = currentMillis;
    if (pulseStep % 2 == 0) {
      motorClockwise(255); // Ligado na velocidade máxima
    } else {
      motorStop(); // Desligado
    }
    pulseStep++;
  }
}

void startProgram(String programName) {
  motorStop(); // Garante que o motor está parado antes de iniciar um programa
  
  if (programName.equalsIgnoreCase("Pulse")) {
    isPulsing = true;
    pulseStep = 0;
    previousMillis = millis();
    Serial.println("Iniciando programa: Pulse");
  } else if (programName.equalsIgnoreCase("Long")) {
    motorClockwise(200); // Vibração longa e constante
    Serial.println("Iniciando programa: Long");
  } else if (programName.equalsIgnoreCase("Rhythmic")) {
    // Implemente a sua lógica para "Rhythmic" aqui
    // Exemplo: alternar entre duas velocidades
    motorClockwise(150);
    delay(200);
    motorClockwise(255);
    delay(200);
    Serial.println("Iniciando programa: Rhythmic (exemplo)");
  } else if (programName.equalsIgnoreCase("Fast")) {
    motorClockwise(255); // Vibração rápida e constante
    Serial.println("Iniciando programa: Fast");
  }
}


// --- Callback para Comandos Recebidos via BLE ---

void onMotorCommand(BLEDevice central, BLECharacteristic characteristic) {
  String command = motorCharacteristic.value();
  command.trim();
  Serial.print("Comando recebido: ");
  Serial.println(command);

  isPulsing = false; // Para programas ao receber novo comando

  if (command.equalsIgnoreCase("stop")) {
    motorStop();
  } else if (command.equalsIgnoreCase("cw")) {
    motorClockwise(255); // Velocidade máxima por padrão
  } else if (command.equalsIgnoreCase("ccw")) {
    motorCounterClockwise(255); // Velocidade máxima por padrão
  } else if (command.startsWith("program:")) {
    String programName = command.substring(8);
    startProgram(programName);
  } else if (command.startsWith("manual:")) {
    // Formato esperado: "manual:intensidade,velocidade" (ex: "manual:80,50")
    String params = command.substring(7);
    int commaIndex = params.indexOf(',');
    
    if (commaIndex != -1) {
      String intensityStr = params.substring(0, commaIndex);
      String speedStr = params.substring(commaIndex + 1);
      
      int intensity = intensityStr.toInt(); // 0-100
      // int speed = speedStr.toInt(); // Não usado neste exemplo, mas disponível
      
      // Mapeia a intensidade (0-100) para a velocidade do motor (0-255)
      int motorSpeed = map(intensity, 0, 100, 0, 255);
      
      motorClockwise(motorSpeed);
    }
  }
}
```