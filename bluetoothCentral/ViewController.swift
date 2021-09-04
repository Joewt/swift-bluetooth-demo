//
//  ViewController.swift
//  bluetoothCentral
//
//  Created by 乔酱 on 2021/9/4.
//

import UIKit
import CoreBluetooth

let heartRateServiceUUID = CBUUID(string: "180D")
let controlPointCharacteristicUUID = CBUUID(string: "2A39")
let sensortLocationCharacteristicUUID = CBUUID(string: "2A38")
let measurementCharcteristicUUID = CBUUID(string: "2A37")

class ViewController: UIViewController {
    
    var centralManager: CBCentralManager!
    var heartRatePeripheral: CBPeripheral!
    var controlPointCharacteristic: CBCharacteristic?
    

    @IBOutlet weak var sensorLocationLabel: UILabel!
    @IBOutlet weak var heartRateLabel: UILabel!
    @IBOutlet weak var writeCharacteristicTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        centralManager  = CBCentralManager(delegate: self, queue: nil)
    }

    @IBAction func write(_ sender: Any) {
        
        guard let chartic = controlPointCharacteristic else {
            return
        }
        
        heartRatePeripheral.writeValue(writeCharacteristicTextField.text!.data(using: .utf8)!, for: chartic, type: .withResponse)
        
        
        
    }
    
}

extension ViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state{
        
        case .unknown:
            print("未知")
        case .resetting:
            print("重置中")
        case .unsupported:
            print("不支持ble")
        case .unauthorized:
            print("未授权")
        case .poweredOff:
            print("蓝牙未开启")
        case .poweredOn:
            print("蓝牙已开启")
            // 1 扫描周围设备
            central.scanForPeripherals(withServices: [heartRateServiceUUID])
            
        @unknown default:
            print("unknown")
        }
    }
    
    // 2 发现外设
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        heartRatePeripheral = peripheral // 3. 赋值给全局变量
        central.stopScan() // 4. 停止扫描
        central.connect(peripheral, options: nil)// 3 连接外设

    }
    
    // 连接成功
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // 发现服务
        peripheral.delegate = self
        peripheral.discoverServices([heartRateServiceUUID])
    }
    
    // 连接失败
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("连接失败")
    }
    
    // 连接断开
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        central.connect(peripheral, options: nil) // 重新连接
    }
    
}

extension ViewController: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let err = error {
            print("未找到服务,err:\(err.localizedDescription)")
        }
        
        guard let service = peripheral.services?.first else {
            return
        }
        
        // 找到特征
        peripheral.discoverCharacteristics([
            controlPointCharacteristicUUID,
            sensortLocationCharacteristicUUID,
            measurementCharcteristicUUID
            ], for: service)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let err = error {
            print("没有找到特征,err:\(err.localizedDescription)")
        }
        
        guard let characterstics = service.characteristics else {
            return
        }
        
        for chartic in characterstics {
            if chartic.properties.contains(.write) {
                peripheral.writeValue("1000".data(using: .utf8)!, for: chartic, type: .withResponse)
                controlPointCharacteristic = chartic
            }
            
            
            if chartic.properties.contains(.read) {
                peripheral.readValue(for: chartic)
            }
            
            if chartic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: chartic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let err = error {
            print("写入失败,err:\(err.localizedDescription)")
            return
        }
        print("write success")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let err = error {
            print("读取失败,err:\(err.localizedDescription)")
            return
        }
        
        
        switch characteristic.uuid {
        case sensortLocationCharacteristicUUID:
            sensorLocationLabel.text = String(data: characteristic.value!, encoding: .utf8)
        case measurementCharcteristicUUID:
//            heartRateLabel.text = String(data: characteristic.value!, encoding: .utf8)
        
            // todo: 设置虚拟外设的时候
            guard let heartRate = Int(String(data: characteristic.value!, encoding: .utf8)!) else {
                return
            }
            heartRateLabel.text = "\(heartRate)"

        default:
            break
        }
    }
    
}
