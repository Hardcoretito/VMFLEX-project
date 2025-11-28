import SwiftUI
import Combine
import CoreHaptics
import CoreBluetooth

// MARK: - Custom Styles

struct GlossyGoldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .foregroundColor(.white)
            .background(
                LinearGradient(gradient: Gradient(colors: [Color(hex: "FFD700"), Color(hex: "B8860B")]), startPoint: .top, endPoint: .bottom)
            )
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.2), radius: 3, x: 2, y: 2)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}


// MARK: - BLEManager (ObservableObject)
// This class will handle all CoreBluetooth logic and publish its state.
class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var connectionStatus = "Disconnected"
    @Published var isConnected = false

    private var centralManager: CBCentralManager?
    private var motorPeripheral: CBPeripheral?
    private var motorCharacteristic: CBCharacteristic?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            connectionStatus = "Scanning..."
            central.scanForPeripherals(withServices: [CBUUID(string: SERVICE_UUID)], options: nil)
        case .poweredOff:
            connectionStatus = "Bluetooth is Powered Off"
            isConnected = false
        // ... handle other states as needed
        default:
            connectionStatus = "Bluetooth is not available"
            isConnected = false
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if peripheral.name == "MotorControl" {
            print("Discovered MotorControl peripheral: \(peripheral)")
            centralManager?.stopScan()
            motorPeripheral = peripheral
            motorPeripheral?.delegate = self
            centralManager?.connect(peripheral, options: nil)
            connectionStatus = "Connecting..."
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to MotorControl peripheral")
        connectionStatus = "Connected"
        isConnected = true
        peripheral.discoverServices([CBUUID(string: SERVICE_UUID)])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect: \(error?.localizedDescription ?? "Unknown error")")
        connectionStatus = "Connection Failed"
        isConnected = false
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from MotorControl")
        connectionStatus = "Disconnected"
        isConnected = false
        // Start scanning again
        centralManager?.scanForPeripherals(withServices: [CBUUID(string: SERVICE_UUID)], options: nil)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics([CBUUID(string: CHARACTERISTIC_UUID)], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.uuid == CBUUID(string: CHARACTERISTIC_UUID) {
                motorCharacteristic = characteristic
                connectionStatus = "Ready"
            }
        }
    }

    func sendCommand(_ command: String) {
        guard let peripheral = motorPeripheral, let characteristic = motorCharacteristic else {
            print("Not ready to send command")
            return
        }
        let data = command.data(using: .utf8)!
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
        print("Sent command: \(command)")
    }
}

struct ContentView: View {
    @StateObject private var bleManager = BLEManager()
    
    @State private var selectedProgram: String? = nil
    @State private var motorDirection: String? = nil
    @State private var isManualMode = false
    @State private var intensity: Double = 0.5
    @State private var speed: Double = 0.5
    @State private var isVibrating = false
    @State private var engine: CHHapticEngine?

    let programs = ["Pulse", "Long", "Rhythmic", "Fast"]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                            Text("Vibration Control")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)                .padding(.top)

                            Text("BLE Status: \(bleManager.connectionStatus)")
                                .font(.headline)
                                .foregroundColor(bleManager.isConnected ? .green : .yellow)
            HStack(spacing: 10) {
                ForEach(programs, id: \.self) { program in
                    Button(program) {
                        selectedProgram = program
                        isManualMode = false
                        motorDirection = nil
                        stopVibration()
                    }
                    .buttonStyle(GlossyGoldButtonStyle())
                }
            }

            HStack(spacing: 20) {
                Button("Manual") {
                    isManualMode.toggle()
                    selectedProgram = nil
                    motorDirection = nil
                    stopVibration()
                }
                .buttonStyle(GlossyGoldButtonStyle())
                
                Button("CW") {
                    motorDirection = "cw"
                    bleManager.sendCommand("cw")
                }
                .buttonStyle(GlossyGoldButtonStyle())
                
                Button("CCW") {
                    motorDirection = "ccw"
                    bleManager.sendCommand("ccw")
                }
                .buttonStyle(GlossyGoldButtonStyle())
            }

            Spacer()

            ZStack {
                Circle()
                    .stroke(lineWidth: 20)
                    .foregroundColor(Color(hex: "B8860B").opacity(0.5))
                    .frame(width: 200, height: 200)

                Circle()
                    .fill(Color(hex: "FFD700"))
                    .frame(width: 200, height: 200)
                    .scaleEffect(isVibrating ? 1.0 : 0.95)
                    .animation(isVibrating ? Animation.easeInOut(duration: speed).repeatForever(autoreverses: true) : .default, value: isVibrating)
                
                Text(isVibrating ? "Vibrating..." : "Motor Off")
                    .font(.title2)
                    .foregroundColor(.black)
            }

            Spacer()

            if isManualMode {
                VStack {
                    Text("Intensity: \(intensity, specifier: "%.2f")")
                        .foregroundColor(.white)
                    Slider(value: $intensity, in: 0...1, onEditingChanged: { _ in
                        sendManualCommand()
                    })
                    
                    Text("Speed: \(speed, specifier: "%.2f")")
                        .foregroundColor(.white)
                    Slider(value: $speed, in: 0.1...2.0, onEditingChanged: { _ in
                        sendManualCommand()
                    })
                }
                .padding(.horizontal)
            }

            HStack(spacing: 50) {
                Button("ON") {
                    startVibration()
                }
                .buttonStyle(GlossyGoldButtonStyle())

                Button("OFF") {
                    stopVibration()
                }
                .buttonStyle(GlossyGoldButtonStyle())
            }
                            .padding(.bottom)
                        }
                    }        .onAppear(perform: setupHaptics)
    }

    func setupHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("There was an error creating the engine: \(error.localizedDescription)")
        }
    }

    func startVibration() {
        isVibrating = true
        if isManualMode {
            sendManualCommand()
        } else if let program = selectedProgram {
            bleManager.sendCommand("program:\(program)")
        } else if let direction = motorDirection {
            bleManager.sendCommand(direction)
        }
        playLocalHaptics()
    }

    func stopVibration() {
        isVibrating = false
        engine?.stop(completionHandler: nil)
        bleManager.sendCommand("stop")
    }
    
    func sendManualCommand() {
        let command = "manual:\(Int(intensity * 100)),\(Int(speed * 100))"
        bleManager.sendCommand(command)
    }
    
    func playLocalHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        var events = [CHHapticEvent]()
        if isManualMode {
            let hapticIntensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(intensity))
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            let event = CHHapticEvent(eventType: .hapticContinuous, parameters: [hapticIntensity, sharpness], relativeTime: 0, duration: 2.0)
            events.append(event)
        } else {
            switch selectedProgram {
            case "Pulse":
                for i in stride(from: 0, to: 2, by: 0.5) {
                    let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
                    let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity], relativeTime: i)
                    events.append(event)
                }
            // ... other cases
            default:
                break
            }
        }
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play local haptic pattern: \(error.localizedDescription)")
        }
    }
}

// BLE UUIDs - Make sure these match your Arduino code
let SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
let CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8"

#Preview {
    ContentView()
}