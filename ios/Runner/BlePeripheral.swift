import CoreBluetooth
import Flutter

/// The BLE advertiser and GATT server for TB Chat. The Dart side (BleLink) owns the protocol;
/// this only advertises, hands up writes and sends notifications.
final class BlePeripheral: NSObject, FlutterPlugin, CBPeripheralManagerDelegate {
  private let channel: FlutterMethodChannel
  private var manager: CBPeripheralManager?
  private var txCharacteristic: CBMutableCharacteristic?
  private var rxUuid: CBUUID?
  private var serviceUuid: CBUUID?
  private var serviceAdded = false
  private var startResult: FlutterResult?
  private var centrals: [String: CBCentral] = [:]
  private var outbox: [(central: CBCentral, value: Data, result: FlutterResult)] = []

  private init(channel: FlutterMethodChannel) {
    self.channel = channel
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "tb_chat/ble_peripheral", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(BlePeripheral(channel: channel), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any]
    switch call.method {
    case "start":
      start(args: args, result: result)
    case "stopAdvertising":
      manager?.stopAdvertising()
      result(nil)
    case "notify":
      guard let device = args?["device"] as? String, let central = centrals[device],
        let value = args?["value"] as? FlutterStandardTypedData
      else {
        return result(FlutterError(code: "not_subscribed", message: "Central is gone", details: nil))
      }
      outbox.append((central, value.data, result))
      pump()
    case "disconnect":
      // iOS can't drop a central; the Dart side tells the other phone to disconnect instead.
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func start(args: [String: Any]?, result: @escaping FlutterResult) {
    guard let service = args?["service"] as? String, let tx = args?["tx"] as? String,
      let rx = args?["rx"] as? String
    else {
      return result(FlutterError(code: "bad_args", message: nil, details: nil))
    }
    if serviceUuid == nil {
      serviceUuid = CBUUID(string: service)
      rxUuid = CBUUID(string: rx)
      txCharacteristic = CBMutableCharacteristic(
        type: CBUUID(string: tx), properties: [.notify], value: nil, permissions: [.readable])
    }
    startResult = result
    if manager == nil {
      manager = CBPeripheralManager(delegate: self, queue: nil)
    } else {
      proceed()
    }
  }

  /// Moves a pending start along. The manager isn't usable until it reports powered on.
  private func proceed() {
    guard startResult != nil, let manager = manager else { return }
    switch manager.state {
    case .poweredOn:
      if serviceAdded {
        advertise()
      } else if let serviceUuid = serviceUuid, let rxUuid = rxUuid, let tx = txCharacteristic {
        let service = CBMutableService(type: serviceUuid, primary: true)
        let rx = CBMutableCharacteristic(
          type: rxUuid, properties: [.write], value: nil, permissions: [.writeable])
        service.characteristics = [rx, tx]
        manager.add(service)
      }
    case .unknown, .resetting:
      break
    default:
      finishStart(error: "Bluetooth isn't available (state \(manager.state.rawValue))")
    }
  }

  private func advertise() {
    guard let manager = manager, let serviceUuid = serviceUuid else { return }
    if manager.isAdvertising { return finishStart(error: nil) }
    manager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [serviceUuid]])
  }

  private func finishStart(error: String?) {
    let result = startResult
    startResult = nil
    result?(error.map { FlutterError(code: "start_failed", message: $0, details: nil) })
  }

  /// Sends queued notifications until iOS says its queue is full; it calls back when there's room.
  private func pump() {
    guard let manager = manager, let tx = txCharacteristic else { return }
    while let next = outbox.first {
      guard manager.updateValue(next.value, for: tx, onSubscribedCentrals: [next.central]) else { return }
      outbox.removeFirst()
      next.result(nil)
    }
  }

  func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
    if peripheral.state != .poweredOn { serviceAdded = false }
    proceed()
  }

  func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
    if let error = error { return finishStart(error: error.localizedDescription) }
    serviceAdded = true
    advertise()
  }

  func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
    finishStart(error: error?.localizedDescription)
  }

  func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
    pump()
  }

  func peripheralManager(
    _ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic
  ) {
    let device = central.identifier.uuidString
    centrals[device] = central
    channel.invokeMethod("mtu", arguments: ["device": device, "maxLength": central.maximumUpdateValueLength])
  }

  func peripheralManager(
    _ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic
  ) {
    let device = central.identifier.uuidString
    centrals[device] = nil
    outbox.removeAll { item in
      guard item.central.identifier == central.identifier else { return false }
      item.result(FlutterError(code: "not_subscribed", message: "Central is gone", details: nil))
      return true
    }
    channel.invokeMethod("disconnected", arguments: ["device": device])
  }

  func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
    for request in requests {
      guard request.characteristic.uuid == rxUuid, let value = request.value else { continue }
      channel.invokeMethod(
        "write",
        arguments: [
          "device": request.central.identifier.uuidString,
          "value": FlutterStandardTypedData(bytes: value),
        ])
    }
    if let first = requests.first { peripheral.respond(to: first, withResult: .success) }
  }
}
